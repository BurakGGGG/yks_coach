import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
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
  final session = AuthSession(
    auth: AuthService(),
    initialTab: tab.clamp(0, 3),
    initialDark: dark,
    initialScreen: screen,
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
