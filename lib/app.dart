import 'package:flutter/material.dart';

import 'screens/assistant_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/goals_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/profile_screen.dart';
import 'state/app_controller.dart';
import 'state/auth_session.dart';
import 'theme/app_theme.dart';
import 'widgets/app_shell.dart';

class YksCoachRoot extends StatelessWidget {
  const YksCoachRoot({required this.session, super.key});

  final AuthSession session;

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      notifier: session,
      child: AnimatedBuilder(
        animation: session,
        builder: (context, _) => AnimatedBuilder(
          animation: session.app ?? session,
          builder: (context, _) {
            final app = session.app;
            return MaterialApp(
              title: 'Zihin Rehberi',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: app?.themeMode ?? ThemeMode.light,
              home: switch (session.stage) {
                AuthStage.authentication => const AuthScreen(),
                AuthStage.verification => const EmailVerificationScreen(),
                AuthStage.ready when app != null => AppScope(
                  notifier: app,
                  child: app.onboardingCompleted
                      ? _initialScreen(session.initialScreen)
                      : const OnboardingScreen(),
                ),
                AuthStage.failure => const AuthFailureScreen(),
                _ => const AuthLoadingScreen(),
              },
            );
          },
        ),
      ),
    );
  }
}

/// Test/preview harness that mounts an [AppController] directly without the auth
/// flow.
class YksCoachApp extends StatelessWidget {
  const YksCoachApp({required this.controller, this.initialScreen, super.key});

  final AppController controller;
  final String? initialScreen;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      notifier: controller,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => MaterialApp(
          title: 'Zihin Rehberi',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: controller.themeMode,
          home: _initialScreen(initialScreen),
        ),
      ),
    );
  }
}

Widget _initialScreen(String? screen) => switch (screen) {
  'profile' => const ProfileScreen(),
  'goals' => const GoalsScreen(),
  'notifications' => const NotificationsScreen(),
  'assistant' => const AssistantScreen(),
  _ => const AppShell(),
};
