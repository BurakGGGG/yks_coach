import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

abstract interface class AuthGateway {
  User? get currentUser;

  Future<User> ensureAnonymousUser();
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  });
  Future<UserCredential> registerWithEmail({
    required String name,
    required String email,
    required String password,
  });
  Future<UserCredential> signInWithGoogle();
  Future<void> sendPasswordReset(String email);
  Future<void> resendVerificationEmail();
  Future<User?> reloadUser({bool refreshToken = false});
  Future<void> reauthenticateForDeletion({String? password});
  Future<void> signOut();
}

class AuthService implements AuthGateway {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;
  bool _googleInitialized = false;
  bool _languageConfigured = false;

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Future<User> ensureAnonymousUser() async {
    if (!_languageConfigured) {
      await _auth.setLanguageCode('tr');
      _languageConfigured = true;
    }
    final current = _auth.currentUser;
    if (current != null) return current;
    final credential = await _auth.signInAnonymously();
    final user = credential.user;
    if (user == null) throw StateError('Anonim oturum oluşturulamadı.');
    return user;
  }

  @override
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) => _auth.signInWithEmailAndPassword(
    email: email.trim().toLowerCase(),
    password: password,
  );

  @override
  Future<UserCredential> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final current = _auth.currentUser;
    final UserCredential result;
    if (current?.isAnonymous ?? false) {
      final credential = EmailAuthProvider.credential(
        email: normalizedEmail,
        password: password,
      );
      result = await current!.linkWithCredential(credential);
    } else {
      result = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
    }
    await result.user?.updateDisplayName(name.trim());
    await result.user?.sendEmailVerification();
    await result.user?.reload();
    return result;
  }

  @override
  Future<UserCredential> signInWithGoogle() async {
    final current = _auth.currentUser;
    if (kIsWeb) {
      final provider = GoogleAuthProvider()
        ..setCustomParameters({'prompt': 'select_account'});
      if (current?.isAnonymous ?? false) {
        try {
          return await current!.linkWithPopup(provider);
        } on FirebaseAuthException catch (error) {
          if (!_credentialBelongsToExistingAccount(error.code)) rethrow;
        }
      }
      return _auth.signInWithPopup(provider);
    }

    if (!_googleInitialized) {
      await GoogleSignIn.instance.initialize();
      _googleInitialized = true;
    }
    final googleUser = await GoogleSignIn.instance.authenticate();
    final googleAuth = googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) {
      throw StateError('Google kimlik belirteci alınamadı.');
    }
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    if (current?.isAnonymous ?? false) {
      try {
        return await current!.linkWithCredential(credential);
      } on FirebaseAuthException catch (error) {
        if (!_credentialBelongsToExistingAccount(error.code)) rethrow;
      }
    }
    return _auth.signInWithCredential(credential);
  }

  @override
  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());

  @override
  Future<void> resendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous || user.emailVerified) return;
    await user.sendEmailVerification();
  }

  @override
  Future<User?> reloadUser({bool refreshToken = false}) async {
    await _auth.currentUser?.reload();
    if (refreshToken) await _auth.currentUser?.getIdToken(true);
    return _auth.currentUser;
  }

  @override
  Future<void> reauthenticateForDeletion({String? password}) async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) {
      throw FirebaseAuthException(code: 'user-not-found');
    }
    final providers = user.providerData.map((data) => data.providerId).toSet();
    if (providers.contains(GoogleAuthProvider.PROVIDER_ID)) {
      if (kIsWeb) {
        final provider = GoogleAuthProvider()
          ..setCustomParameters({'prompt': 'select_account'});
        await user.reauthenticateWithPopup(provider);
      } else {
        if (!_googleInitialized) {
          await GoogleSignIn.instance.initialize();
          _googleInitialized = true;
        }
        final googleUser = await GoogleSignIn.instance.authenticate();
        final idToken = googleUser.authentication.idToken;
        if (idToken == null) {
          throw StateError('Google kimlik belirteci alınamadı.');
        }
        await user.reauthenticateWithCredential(
          GoogleAuthProvider.credential(idToken: idToken),
        );
      }
    } else if (providers.contains(EmailAuthProvider.PROVIDER_ID)) {
      final value = password ?? '';
      final email = user.email;
      if (email == null || value.isEmpty) {
        throw FirebaseAuthException(code: 'wrong-password');
      }
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: value),
      );
    } else {
      throw FirebaseAuthException(code: 'operation-not-allowed');
    }
    await user.getIdToken(true);
  }

  @override
  Future<void> signOut() async {
    if (!kIsWeb && _googleInitialized) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        // Firebase oturumunu kapatmak Google SDK durumundan bağımsızdır.
      }
    }
    await _auth.signOut();
  }

  static bool _credentialBelongsToExistingAccount(String code) =>
      code == 'credential-already-in-use' ||
      code == 'account-exists-with-different-credential';
}
