import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yks_coach/data/memory_store.dart';
import 'package:yks_coach/data/repositories.dart';
import 'package:yks_coach/models/study_task.dart';
import 'package:yks_coach/models/user_profile.dart';
import 'package:yks_coach/services/notification_service.dart';
import 'package:yks_coach/state/app_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('izin reddedilince tercih açılmaz', () async {
    final gateway = _FakeNotificationGateway(permissionResult: false);
    final app = AppController(
      repositories: memoryRepositories(profile: _profile),
      notificationGateway: gateway,
    );
    addTearDown(app.dispose);
    addTearDown(gateway.close);
    await app.whenReady;

    final saved = await app.notifications.updatePreferences(daily: true);

    expect(saved, isFalse);
    expect(app.profile.profile.dailyReminder, isFalse);
    expect(gateway.permissionRequests, 1);
  });

  test('izin verilince tercih kaydolur ve zamanlama yenilenir', () async {
    final gateway = _FakeNotificationGateway(permissionResult: true);
    final app = AppController(
      repositories: memoryRepositories(profile: _profile),
      notificationGateway: gateway,
    );
    addTearDown(app.dispose);
    addTearDown(gateway.close);
    await app.whenReady;
    gateway.syncCalls = 0;

    final saved = await app.notifications.updatePreferences(task: true);

    expect(saved, isTrue);
    expect(app.profile.profile.taskReminder, isTrue);
    expect(gateway.syncCalls, greaterThan(0));
  });

  test('bildirim hedefi doğru sekmeyi açar', () async {
    final gateway = _FakeNotificationGateway(permissionResult: true);
    final app = AppController(
      repositories: memoryRepositories(profile: _profile),
      notificationGateway: gateway,
    );
    addTearDown(app.dispose);
    addTearDown(gateway.close);
    await app.whenReady;

    gateway.emit('analysis');
    await Future<void>.delayed(Duration.zero);

    expect(app.tabIndex, 2);
  });
}

const _profile = UserProfile(userName: 'Ada Yılmaz', onboardingCompleted: true);

class _FakeNotificationGateway implements NotificationGateway {
  _FakeNotificationGateway({required this.permissionResult});

  final bool permissionResult;
  final _taps = StreamController<String>.broadcast();
  bool authorized = false;
  int permissionRequests = 0;
  int syncCalls = 0;

  @override
  bool get supported => true;

  @override
  String get timeZone => 'Europe/Istanbul';

  @override
  Stream<String> get notificationTaps => _taps.stream;

  @override
  Future<bool> isAuthorized() async => authorized;

  @override
  Future<bool> requestAuthorization() async {
    permissionRequests++;
    authorized = permissionResult;
    return authorized;
  }

  @override
  Future<void> synchronize({
    required DeviceRepository devices,
    required UserProfile profile,
    required List<StudyTask> tasks,
  }) async {
    syncCalls++;
  }

  @override
  Future<void> deactivate(DeviceRepository devices) async {}

  @override
  String? takeInitialTarget() => null;

  void emit(String target) => _taps.add(target);

  Future<void> close() => _taps.close();
}
