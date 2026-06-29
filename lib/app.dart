import 'package:flutter/material.dart';

import 'screens/auth_screen.dart';
import 'screens/assistant_screen.dart';
import 'screens/goals_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/profile_screen.dart';
import 'state/auth_session.dart';
import 'state/app_state.dart';
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
          animation: session.appState ?? session,
          builder: (context, _) {
            final state = session.appState;
            return MaterialApp(
              title: 'Zihin Rehberi',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: state?.themeMode ?? ThemeMode.light,
              home: switch (session.stage) {
                AuthStage.authentication => const AuthScreen(),
                AuthStage.verification => const EmailVerificationScreen(),
                AuthStage.ready when state != null => AppScope(
                  notifier: state,
                  child: _initialScreen(session.initialScreen),
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

class YksCoachApp extends StatelessWidget {
  const YksCoachApp({required this.state, this.initialScreen, super.key});

  final AppState state;
  final String? initialScreen;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      notifier: state,
      child: AnimatedBuilder(
        animation: state,
        builder: (context, _) => MaterialApp(
          title: 'Zihin Rehberi',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: state.themeMode,
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
