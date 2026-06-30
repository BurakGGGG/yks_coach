import 'package:flutter/material.dart';

import '../data/repositories.dart';
import '../models/user_profile.dart';
import '../services/notification_service.dart';
import '../services/coach_service.dart';
import 'analytics.dart';
import 'coach_controller.dart';
import 'exam_controller.dart';
import 'focus_controller.dart';
import 'notification_controller.dart';
import 'profile_controller.dart';
import 'schedule_controller.dart';

/// Composition root that wires the per-domain controllers together for one
/// signed-in user. It is itself a [ChangeNotifier] that re-emits whenever any
/// child changes, so a single top-level listener keeps the whole UI reactive
/// while logic stays separated by domain.
class AppController extends ChangeNotifier with WidgetsBindingObserver {
  AppController({
    required AppRepositories repositories,
    int initialTab = 0,
    String? suggestedName,
    NotificationGateway? notificationGateway,
    CoachGateway? coachGateway,
  }) : tabIndex = initialTab {
    profile = ProfileController(
      repositories.profile,
      suggestedName: suggestedName,
    );
    schedule = ScheduleController(repositories.tasks);
    exams = ExamController(repositories.exams);
    coach = CoachController(repositories.coach, gateway: coachGateway);
    focus = FocusController(
      repositories.focus,
      focusMinutes: profile.profile.focusMinutes,
      onFocusMinutesChanged: profile.setFocusMinutes,
    );
    notifications = NotificationController(
      profile: profile,
      schedule: schedule,
      devices: repositories.devices,
      gateway: notificationGateway,
    );

    _children = [profile, schedule, focus, exams, coach, notifications];
    for (final child in _children) {
      child.addListener(notifyListeners);
    }
    profile.addListener(_syncFocusPreference);
    notifications.addListener(_routeNotificationTap);
    WidgetsBinding.instance.addObserver(this);
  }

  late final ProfileController profile;
  late final ScheduleController schedule;
  late final FocusController focus;
  late final ExamController exams;
  late final CoachController coach;
  late final NotificationController notifications;
  late final List<ChangeNotifier> _children;

  int tabIndex;

  ThemeMode get themeMode => profile.profile.themeMode;
  bool get onboardingCompleted => profile.onboardingCompleted;
  String? _pendingScreen;

  /// Completes once the profile's first snapshot arrives — used by routing to
  /// decide between onboarding and the main shell.
  Future<void> get whenReady => profile.firstLoad;

  /// Real, derived dashboard metrics for the *current* week (independent of the
  /// week the user is browsing on the Program screen).
  DashboardStats get dashboardStats {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    return DashboardStats.compute(
      tasks: schedule.tasks,
      sessions: focus.sessions,
      today: today,
      weekStart: weekStart,
    );
  }

  void setTab(int value) {
    tabIndex = value;
    notifyListeners();
  }

  void toggleTheme(bool dark) => profile.setTheme(dark);

  Future<void> completeOnboarding(UserProfile value) => profile
      .completeOnboarding(value.copyWith(timeZone: notifications.timeZone));

  /// Returns a non-tab screen requested by a notification exactly once.
  String? takePendingScreen() {
    final value = _pendingScreen;
    _pendingScreen = null;
    return value;
  }

  /// Jumps to the Focus tab pre-loaded with a task's subject/title.
  void startTaskFocus(String subject, String title) {
    focus.selectSubject('$subject - $title');
    setTab(1);
  }

  void _syncFocusPreference() =>
      focus.applyPreferredMinutes(profile.profile.focusMinutes);

  void _routeNotificationTap() {
    final target = notifications.takePendingTarget();
    if (target == null) return;
    switch (target) {
      case 'focus':
        setTab(1);
      case 'analysis':
        setTab(2);
      case 'program':
        setTab(3);
      case 'assistant':
        _pendingScreen = target;
        notifyListeners();
      default:
        setTab(0);
    }
  }

  Future<void> deactivateNotifications() => notifications.deactivate();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      focus.syncWithClock();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    profile.removeListener(_syncFocusPreference);
    notifications.removeListener(_routeNotificationTap);
    for (final child in _children) {
      child.removeListener(notifyListeners);
      child.dispose();
    }
    super.dispose();
  }
}

/// Inherited access to the [AppController] for the signed-in session.
class AppScope extends InheritedNotifier<AppController> {
  const AppScope({
    required AppController notifier,
    required super.child,
    super.key,
  }) : super(notifier: notifier);

  static AppController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope bulunamadı');
    return scope!.notifier!;
  }
}
