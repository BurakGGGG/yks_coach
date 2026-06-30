import 'package:flutter/material.dart';

import '../services/schema.dart';

/// The student's profile, goals and preferences — the `users/{uid}` document.
///
/// This is the single source of truth for everything the onboarding flow
/// collects plus notification/theme preferences. Stats (study time, sessions,
/// nets) are intentionally *not* stored here; they are derived from the
/// `tasks`, `focusSessions` and `exams` subcollections so the numbers can never
/// drift from the user's real activity.
@immutable
class UserProfile {
  const UserProfile({
    this.userName = '',
    this.grade = '',
    this.studyField = '',
    this.targetUniversity = '',
    this.targetDepartment = '',
    this.targetRank = 0,
    this.dailyQuestionGoal = 80,
    this.dailyStudyMinutes = 180,
    this.prioritySubjects = const [],
    this.dailyReminder = false,
    this.taskReminder = false,
    this.motivationReminder = false,
    this.examReminder = false,
    this.reminderMinutes = 19 * 60,
    this.focusMinutes = 25,
    this.themeMode = ThemeMode.light,
    this.onboardingCompleted = false,
    this.locale = 'tr_TR',
    this.timeZone = 'Europe/Istanbul',
    this.schemaVersion = kCurrentSchemaVersion,
  });

  final String userName;
  final String grade;
  final String studyField;
  final String targetUniversity;
  final String targetDepartment;
  final int targetRank;
  final int dailyQuestionGoal;
  final int dailyStudyMinutes;
  final List<String> prioritySubjects;
  final bool dailyReminder;
  final bool taskReminder;
  final bool motivationReminder;
  final bool examReminder;

  /// Daily-summary reminder time, stored as minutes past midnight.
  final int reminderMinutes;

  /// Preferred default Pomodoro focus length in minutes.
  final int focusMinutes;

  final ThemeMode themeMode;
  final bool onboardingCompleted;
  final String locale;
  final String timeZone;
  final int schemaVersion;

  TimeOfDay get reminderTime => TimeOfDay(
    hour: (reminderMinutes ~/ 60).clamp(0, 23),
    minute: (reminderMinutes % 60).clamp(0, 59),
  );

  bool get isDark => themeMode == ThemeMode.dark;

  UserProfile copyWith({
    String? userName,
    String? grade,
    String? studyField,
    String? targetUniversity,
    String? targetDepartment,
    int? targetRank,
    int? dailyQuestionGoal,
    int? dailyStudyMinutes,
    List<String>? prioritySubjects,
    bool? dailyReminder,
    bool? taskReminder,
    bool? motivationReminder,
    bool? examReminder,
    int? reminderMinutes,
    int? focusMinutes,
    ThemeMode? themeMode,
    bool? onboardingCompleted,
    String? locale,
    String? timeZone,
  }) {
    return UserProfile(
      userName: userName ?? this.userName,
      grade: grade ?? this.grade,
      studyField: studyField ?? this.studyField,
      targetUniversity: targetUniversity ?? this.targetUniversity,
      targetDepartment: targetDepartment ?? this.targetDepartment,
      targetRank: targetRank ?? this.targetRank,
      dailyQuestionGoal: dailyQuestionGoal ?? this.dailyQuestionGoal,
      dailyStudyMinutes: dailyStudyMinutes ?? this.dailyStudyMinutes,
      prioritySubjects: prioritySubjects ?? this.prioritySubjects,
      dailyReminder: dailyReminder ?? this.dailyReminder,
      taskReminder: taskReminder ?? this.taskReminder,
      motivationReminder: motivationReminder ?? this.motivationReminder,
      examReminder: examReminder ?? this.examReminder,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      focusMinutes: focusMinutes ?? this.focusMinutes,
      themeMode: themeMode ?? this.themeMode,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      locale: locale ?? this.locale,
      timeZone: timeZone ?? this.timeZone,
    );
  }

  /// The fields this client owns. Server-managed fields (`createdAt`,
  /// `updatedAt`) are added by the repository, never here.
  Map<String, Object?> toMap() => {
    'userName': userName,
    'grade': grade,
    'studyField': studyField,
    'targetUniversity': targetUniversity,
    'targetDepartment': targetDepartment,
    'targetRank': targetRank,
    'dailyQuestionGoal': dailyQuestionGoal,
    'dailyStudyMinutes': dailyStudyMinutes,
    'prioritySubjects': [...prioritySubjects]..sort(),
    'dailyReminder': dailyReminder,
    'taskReminder': taskReminder,
    'motivationReminder': motivationReminder,
    'examReminder': examReminder,
    'reminderMinutes': reminderMinutes,
    'focusMinutes': focusMinutes,
    'themeMode': isDark ? 'dark' : 'light',
    'onboardingCompleted': onboardingCompleted,
    'locale': locale,
    'timeZone': timeZone,
    'schemaVersion': schemaVersion,
  };

  /// Reads a raw `users/{uid}` document, migrating it forward first so callers
  /// always see the current shape.
  factory UserProfile.fromMap(Map<String, dynamic> raw) {
    final data = migrateUserData(raw);
    final subjects = data['prioritySubjects'];
    return UserProfile(
      userName: data['userName'] as String? ?? '',
      grade: data['grade'] as String? ?? '',
      studyField: data['studyField'] as String? ?? '',
      targetUniversity: data['targetUniversity'] as String? ?? '',
      targetDepartment: data['targetDepartment'] as String? ?? '',
      targetRank: (data['targetRank'] as num?)?.toInt() ?? 0,
      dailyQuestionGoal: (data['dailyQuestionGoal'] as num?)?.toInt() ?? 80,
      dailyStudyMinutes: (data['dailyStudyMinutes'] as num?)?.toInt() ?? 180,
      prioritySubjects: subjects is List
          ? subjects.whereType<String>().toList()
          : const [],
      dailyReminder: data['dailyReminder'] as bool? ?? false,
      taskReminder: data['taskReminder'] as bool? ?? false,
      motivationReminder: data['motivationReminder'] as bool? ?? false,
      examReminder: data['examReminder'] as bool? ?? false,
      reminderMinutes: (data['reminderMinutes'] as num?)?.toInt() ?? 19 * 60,
      focusMinutes: (data['focusMinutes'] as num?)?.toInt() ?? 25,
      themeMode: data['themeMode'] == 'dark' ? ThemeMode.dark : ThemeMode.light,
      onboardingCompleted: data['onboardingCompleted'] as bool? ?? false,
      locale: data['locale'] as String? ?? 'tr_TR',
      timeZone: data['timeZone'] as String? ?? 'Europe/Istanbul',
      schemaVersion:
          (data['schemaVersion'] as num?)?.toInt() ?? kCurrentSchemaVersion,
    );
  }
}
