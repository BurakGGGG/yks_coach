import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../data/firestore_store.dart';
import '../services/auth_service.dart';
import '../services/account_service.dart';
import '../services/notification_service.dart';
import '../services/coach_service.dart';
import 'app_controller.dart';

enum AuthStage { loading, authentication, verification, ready, failure }

class AuthSession extends ChangeNotifier {
  AuthSession({
    required this.auth,
    required this.initialTab,
    required this.initialDark,
    this.initialScreen,
    this.notificationGateway,
    this.coachGateway,
    this.accountGateway,
  });

  final AuthGateway auth;
  final int initialTab;
  final bool initialDark;
  final String? initialScreen;
  final NotificationGateway? notificationGateway;
  final CoachGateway? coachGateway;
  final AccountGateway? accountGateway;

  AuthStage stage = AuthStage.loading;
  AppController? app;
  User? user;
  bool busy = false;
  String? errorMessage;
  int _routeGeneration = 0;

  Future<void> initialize() async {
    try {
      await auth.ensureAnonymousUser();
      await _routeCurrentUser();
    } catch (error) {
      stage = AuthStage.failure;
      errorMessage = _messageFor(error);
      notifyListeners();
    }
  }

  Future<void> signInWithEmail(String email, String password) => _run(() async {
    await auth.signInWithEmail(email: email, password: password);
    await _routeCurrentUser();
  });

  Future<void> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) => _run(() async {
    await auth.registerWithEmail(name: name, email: email, password: password);
    await _routeCurrentUser();
  });

  Future<void> signInWithGoogle() => _run(() async {
    await auth.signInWithGoogle();
    await auth.reloadUser(refreshToken: true);
    await _routeCurrentUser();
  });

  Future<bool> sendPasswordReset(String email) async {
    var sent = false;
    await _run(() async {
      await auth.sendPasswordReset(email);
      sent = true;
    }, routeAfter: false);
    return sent;
  }

  Future<bool> resendVerificationEmail() async {
    var sent = false;
    await _run(() async {
      await auth.resendVerificationEmail();
      sent = true;
    }, routeAfter: false);
    return sent;
  }

  Future<void> checkEmailVerification() => _run(() async {
    await auth.reloadUser(refreshToken: true);
    await _routeCurrentUser();
  });

  Future<void> signOut() => _run(() async {
    await _deactivateNotificationsBestEffort();
    app?.dispose();
    app = null;
    await auth.signOut();
    await auth.ensureAnonymousUser();
    await _routeCurrentUser();
  });

  bool get deletionRequiresPassword {
    final providers = user?.providerData
        .map((provider) => provider.providerId)
        .toSet();
    if (providers == null ||
        providers.contains(GoogleAuthProvider.PROVIDER_ID)) {
      return false;
    }
    return providers.contains(EmailAuthProvider.PROVIDER_ID);
  }

  Future<bool> deleteAccount({String? password}) async {
    var deleted = false;
    await _run(() async {
      final gateway = accountGateway;
      if (gateway == null) throw StateError('Hesap servisi hazır değil.');
      await auth.reauthenticateForDeletion(password: password);
      await _deactivateNotificationsBestEffort();
      await gateway.deleteAccount();
      app?.dispose();
      app = null;
      await auth.signOut();
      await auth.ensureAnonymousUser();
      await _routeCurrentUser();
      deleted = true;
    });
    return deleted;
  }

  Future<void> retry() async {
    stage = AuthStage.loading;
    errorMessage = null;
    notifyListeners();
    await initialize();
  }

  void clearError() {
    if (errorMessage == null) return;
    errorMessage = null;
    notifyListeners();
  }

  Future<void> _routeCurrentUser() async {
    final generation = ++_routeGeneration;
    final current = auth.currentUser ?? await auth.ensureAnonymousUser();
    user = current;
    errorMessage = null;
    if (current.isAnonymous) {
      stage = AuthStage.authentication;
      notifyListeners();
      return;
    }
    if (!current.emailVerified) {
      stage = AuthStage.verification;
      notifyListeners();
      return;
    }

    stage = AuthStage.loading;
    notifyListeners();
    final nextApp = AppController(
      repositories: firestoreRepositories(current.uid),
      initialTab: initialTab,
      suggestedName: current.displayName,
      notificationGateway: notificationGateway,
      coachGateway: coachGateway,
    );
    try {
      await nextApp.whenReady;
    } on Object {
      nextApp.dispose();
      rethrow;
    }
    if (generation != _routeGeneration) {
      nextApp.dispose();
      return;
    }
    app?.dispose();
    app = nextApp;
    stage = AuthStage.ready;
    notifyListeners();
  }

  Future<void> _deactivateNotificationsBestEffort() async {
    try {
      await app?.deactivateNotifications();
    } on Object {
      // Signing out and account deletion must not be blocked by a stale local
      // notification or a transient device-token cleanup failure.
    }
  }

  Future<void> _run(
    Future<void> Function() operation, {
    bool routeAfter = true,
  }) async {
    if (busy) return;
    busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await operation();
      if (routeAfter && stage != AuthStage.ready) notifyListeners();
    } catch (error) {
      errorMessage = _messageFor(error);
      notifyListeners();
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  String _messageFor(Object error) {
    if (error is GoogleSignInException) {
      return error.code == GoogleSignInExceptionCode.canceled
          ? 'Google ile giriş iptal edildi.'
          : 'Google ile giriş tamamlanamadı. Yapılandırmayı kontrol et.';
    }
    if (error is FirebaseAuthException) {
      return switch (error.code) {
        'invalid-email' => 'Geçerli bir e-posta adresi gir.',
        'email-already-in-use' => 'Bu e-posta adresiyle kayıtlı bir hesap var.',
        'weak-password' => 'Şifre güvenlik koşullarını karşılamıyor.',
        'invalid-credential' ||
        'user-not-found' ||
        'wrong-password' => 'E-posta veya şifre hatalı.',
        'user-disabled' => 'Bu hesap devre dışı bırakılmış.',
        'too-many-requests' =>
          'Çok fazla deneme yapıldı. Bir süre sonra tekrar dene.',
        'network-request-failed' => 'İnternet bağlantısını kontrol et.',
        'credential-already-in-use' =>
          'Bu giriş bilgisi başka bir hesaba bağlı.',
        'operation-not-allowed' =>
          'Bu giriş yöntemi Firebase projesinde etkin değil.',
        'requires-recent-login' =>
          'Hesabı silmeden önce kimliğini yeniden doğrulamalısın.',
        _ => 'Kimlik doğrulama işlemi tamamlanamadı.',
      };
    }
    if (error is FirebaseFunctionsException) {
      return switch (error.code) {
        'failed-precondition' =>
          'Güvenli doğrulama yenilenemedi. Tekrar giriş yapıp dene.',
        'unauthenticated' ||
        'permission-denied' => 'Hesap silme yetkisi doğrulanamadı.',
        _ => 'Hesap ve veriler silinemedi. Tekrar dene.',
      };
    }
    return 'Beklenmeyen bir hata oluştu. Tekrar dene.';
  }

  @override
  void dispose() {
    app?.dispose();
    super.dispose();
  }
}

class AuthScope extends InheritedNotifier<AuthSession> {
  const AuthScope({
    required AuthSession notifier,
    required super.child,
    super.key,
  }) : super(notifier: notifier);

  static AuthSession of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope bulunamadı');
    return scope!.notifier!;
  }

  static AuthSession? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AuthScope>()?.notifier;
}
