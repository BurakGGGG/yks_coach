import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yks_coach/data/repositories.dart';
import 'package:yks_coach/models/user_profile.dart';
import 'package:yks_coach/state/profile_controller.dart';

void main() {
  test('failed profile write restores the last server-backed value', () async {
    final repository = _FailingProfileRepository();
    final controller = ProfileController(repository);
    addTearDown(controller.dispose);
    addTearDown(repository.close);

    const original = UserProfile(
      userName: 'Ada Yılmaz',
      grade: '12. Sınıf',
      studyField: 'Sayısal',
      targetRank: 5000,
      onboardingCompleted: true,
    );
    repository.emit(original);
    await controller.firstLoad;

    await expectLater(
      controller.updateProfile(
        name: 'Başka İsim',
        grade: original.grade,
        studyField: original.studyField,
        university: '',
        department: '',
        rank: original.targetRank,
      ),
      throwsA(isA<StateError>()),
    );

    expect(controller.profile.userName, original.userName);
  });

  test('first profile stream error unblocks routing with an error', () async {
    final repository = _FailingProfileRepository();
    final controller = ProfileController(repository);
    addTearDown(controller.dispose);
    addTearDown(repository.close);
    final firstLoad = expectLater(
      controller.firstLoad,
      throwsA(isA<StateError>()),
    );

    repository.emitError(StateError('firestore unavailable'));

    await firstLoad;
  });
}

class _FailingProfileRepository implements ProfileRepository {
  final _controller = StreamController<UserProfile?>.broadcast();

  @override
  Stream<UserProfile?> watch() => _controller.stream;

  @override
  Future<void> save(UserProfile profile, {bool isNew = false}) async {
    throw StateError('write failed');
  }

  void emit(UserProfile profile) => _controller.add(profile);

  void emitError(Object error) => _controller.addError(error);

  Future<void> close() => _controller.close();
}
