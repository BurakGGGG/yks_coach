import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/account_service.dart';
import 'services/notification_service.dart';
import 'services/coach_service.dart';
import 'services/crash_reporting_service.dart';
import 'state/auth_session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final tab = int.tryParse(Uri.base.queryParameters['tab'] ?? '') ?? 0;
  final dark = Uri.base.queryParameters['theme'] == 'dark';
  final screen = Uri.base.queryParameters['screen'];
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error) {
    runApp(_FirebaseBootstrapFailure(message: error.toString()));
    return;
  }
  await configureCrashReporting();
  final notifications = AndroidNotificationService();
  if (kIsWeb) {
    await FirebaseAppCheck.instance.activate(
      providerWeb: ReCaptchaEnterpriseProvider(
        '6Lc1Cj4tAAAAAK4Nx5dpE_rHQeRWaoypdxvowsTv',
      ),
    );
  } else if (defaultTargetPlatform == TargetPlatform.android) {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await notifications.initialize();
  }
  final session = AuthSession(
    auth: AuthService(),
    initialTab: tab.clamp(0, 3),
    initialDark: dark,
    initialScreen: screen,
    notificationGateway: notifications,
    coachGateway: FirebaseCoachGateway(),
    accountGateway: FirebaseAccountGateway(),
  );
  runApp(YksCoachRoot(session: session));
  unawaited(session.initialize());
}

class _FirebaseBootstrapFailure extends StatelessWidget {
  const _FirebaseBootstrapFailure({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Firebase başlatılamadı.\n$message'),
        ),
      ),
    ),
  );
}
