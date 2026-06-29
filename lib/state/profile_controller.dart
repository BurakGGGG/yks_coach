import 'dart:async';

import 'package:flutter/material.dart';

import '../data/repositories.dart';
import '../models/user_profile.dart';

/// Owns the student profile, goals, notification preferences and theme — the
/// `users/{uid}` document. Subscribes to the repository stream so changes from
/// another device are reflected live.
class ProfileController extends ChangeNotifier {
  ProfileController(this._repository, {String? suggestedName})
    : _suggestedName = suggestedName ?? '' {
    _subscription = _repository.watch().listen(_onProfile);
  }

  final ProfileRepository _repository;
  final String _suggestedName;
  late final StreamSubscription<UserProfile?> _subscription;

  UserProfile _profile = const UserProfile();
  bool _loaded = false;
  final _firstLoad = Completer<void>();

  /// The current profile. Empty defaults until the first snapshot lands.
  UserProfile get profile => _profile;
  bool get loaded => _loaded;
  bool get onboardingCompleted => _loaded && _profile.onboardingCompleted;

  /// A name to pre-fill onboarding with (e.g. the Google display name).
  String get suggestedName => _suggestedName;

  /// Completes after the first snapshot, so routing can decide onboarding.
  Future<void> get firstLoad => _firstLoad.future;

  void _onProfile(UserProfile? profile) {
    _profile = profile ?? const UserProfile();
    _loaded = true;
    if (!_firstLoad.isCompleted) _firstLoad.complete();
    notifyListeners();
  }

  Future<void> _save(UserProfile next, {bool isNew = false}) async {
    _profile = next;
    notifyListeners();
    await _repository.save(next, isNew: isNew);
  }

  /// Persists the full profile collected during onboarding.
  Future<void> completeOnboarding(UserProfile profile) =>
      _save(profile.copyWith(onboardingCompleted: true), isNew: true);

  Future<void> updateProfile({
    required String name,
    required String grade,
    required String studyField,
    required String university,
    required String department,
    required int rank,
  }) => _save(
    _profile.copyWith(
      userName: name,
      grade: grade,
      studyField: studyField,
      targetUniversity: university,
      targetDepartment: department,
      targetRank: rank,
    ),
  );

  Future<void> updateGoals({
    required int questions,
    required int studyMinutes,
    required List<String> subjects,
  }) => _save(
    _profile.copyWith(
      dailyQuestionGoal: questions,
      dailyStudyMinutes: studyMinutes,
      prioritySubjects: subjects,
    ),
  );

  Future<void> updateNotifications({
    bool? daily,
    bool? task,
    bool? motivation,
    bool? exam,
    TimeOfDay? time,
  }) => _save(
    _profile.copyWith(
      dailyReminder: daily,
      taskReminder: task,
      motivationReminder: motivation,
      examReminder: exam,
      reminderMinutes: time == null ? null : time.hour * 60 + time.minute,
    ),
  );

  Future<void> setTheme(bool dark) =>
      _save(_profile.copyWith(themeMode: dark ? ThemeMode.dark : ThemeMode.light));

  Future<void> setFocusMinutes(int minutes) =>
      _save(_profile.copyWith(focusMinutes: minutes));

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
