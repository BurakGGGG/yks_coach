import 'dart:async';
import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../data/repositories.dart';
import '../firebase_options.dart';
import '../models/device_registration.dart';
import '../models/study_task.dart';
import '../models/user_profile.dart';

const _reminderChannelId = 'study_reminders_v1';
const _updatesChannelId = 'coach_updates_v1';
const _installationKey = 'notification_installation_id_v1';

/// Must remain top-level and entry-point annotated for Android background FCM.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}

abstract interface class NotificationGateway {
  bool get supported;
  String get timeZone;
  Stream<String> get notificationTaps;
  String? takeInitialTarget();

  Future<bool> isAuthorized();
  Future<bool> requestAuthorization();
  Future<void> synchronize({
    required DeviceRepository devices,
    required UserProfile profile,
    required List<StudyTask> tasks,
  });
  Future<void> deactivate(DeviceRepository devices);
}

/// Android-only notification integration. Web push and iOS are intentionally
/// outside the first MVP; on those platforms every operation is a no-op.
class AndroidNotificationService implements NotificationGateway {
  AndroidNotificationService({
    FlutterLocalNotificationsPlugin? localNotifications,
    FirebaseMessaging? messaging,
  }) : _local = localNotifications ?? FlutterLocalNotificationsPlugin(),
       _messaging = messaging ?? FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _local;
  final FirebaseMessaging _messaging;
  final _tapController = StreamController<String>.broadcast();
  final _preferences = SharedPreferencesAsync();

  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  StreamSubscription<String>? _tokenSubscription;
  DeviceRepository? _boundDevices;
  UserProfile? _boundProfile;
  String? _installationId;
  String? _initialTarget;
  bool _initialized = false;
  String _timeZone = 'Europe/Istanbul';

  @override
  bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  String get timeZone => _timeZone;

  @override
  Stream<String> get notificationTaps => _tapController.stream;

  Future<void> initialize() async {
    if (!supported || _initialized) return;
    tz_data.initializeTimeZones();
    try {
      final detected = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(detected.identifier));
      _timeZone = detected.identifier;
    } on Object {
      tz.setLocalLocation(tz.getLocation(_timeZone));
    }

    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (response) {
        _emitTarget(response.payload);
      },
    );

    final android = _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _reminderChannelId,
        'Çalışma hatırlatmaları',
        description: 'Günlük plan ve görev başlangıç hatırlatmaları',
        importance: Importance.high,
      ),
    );
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _updatesChannelId,
        'Koç güncellemeleri',
        description: 'Motivasyon ve analiz bildirimleri',
        importance: Importance.defaultImportance,
      ),
    );

    final launch = await _local.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      _initialTarget = _validatedTarget(launch?.notificationResponse?.payload);
    }
    final initialRemote = await _messaging.getInitialMessage();
    if (initialRemote != null) {
      _initialTarget = _targetFromRemote(initialRemote);
    }

    _foregroundSubscription = FirebaseMessaging.onMessage.listen(
      _showForegroundMessage,
    );
    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => _emitTarget(_targetFromRemote(message)),
    );
    _initialized = true;
  }

  @override
  String? takeInitialTarget() {
    final target = _initialTarget;
    _initialTarget = null;
    return target;
  }

  @override
  Future<bool> isAuthorized() async {
    if (!supported) return false;
    await initialize();
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Future<bool> requestAuthorization() async {
    if (!supported) return false;
    await initialize();
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Future<void> synchronize({
    required DeviceRepository devices,
    required UserProfile profile,
    required List<StudyTask> tasks,
  }) async {
    if (!supported) return;
    await initialize();
    await _local.cancelAllPendingNotifications();

    final anyEnabled =
        profile.dailyReminder ||
        profile.taskReminder ||
        profile.motivationReminder ||
        profile.examReminder;
    final authorized = await isAuthorized();
    if (!anyEnabled || !authorized) {
      if (_boundDevices != null) await _deleteRegistration(_boundDevices!);
      _boundDevices = null;
      _boundProfile = null;
      await _tokenSubscription?.cancel();
      _tokenSubscription = null;
      return;
    }

    _boundDevices = devices;
    _boundProfile = profile;
    await _saveCurrentToken();
    _tokenSubscription ??= _messaging.onTokenRefresh.listen((token) async {
      final currentDevices = _boundDevices;
      final currentProfile = _boundProfile;
      if (currentDevices == null || currentProfile == null) return;
      await _saveRegistration(currentDevices, currentProfile, token);
    });

    if (profile.dailyReminder) {
      await _scheduleDailySummary(profile.reminderMinutes);
    }
    if (profile.taskReminder) {
      await _scheduleTasks(tasks);
    }
  }

  @override
  Future<void> deactivate(DeviceRepository devices) async {
    if (!supported) return;
    await _local.cancelAllPendingNotifications();
    await _deleteRegistration(devices);
    _boundDevices = null;
    _boundProfile = null;
    await _tokenSubscription?.cancel();
    _tokenSubscription = null;
  }

  Future<void> _saveCurrentToken() async {
    final devices = _boundDevices;
    final profile = _boundProfile;
    if (devices == null || profile == null) return;
    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;
    await _saveRegistration(devices, profile, token);
  }

  Future<void> _saveRegistration(
    DeviceRepository devices,
    UserProfile profile,
    String token,
  ) async {
    final installationId = await _getInstallationId();
    await devices.save(
      DeviceRegistration(
        installationId: installationId,
        fcmToken: token,
        timeZone: _timeZone,
        dailyReminder: profile.dailyReminder,
        taskReminder: profile.taskReminder,
        motivationReminder: profile.motivationReminder,
        examReminder: profile.examReminder,
      ),
    );
  }

  Future<void> _deleteRegistration(DeviceRepository devices) async {
    final id = await _getInstallationId();
    await devices.delete(id);
  }

  Future<String> _getInstallationId() async {
    if (_installationId != null) return _installationId!;
    final saved = await _preferences.getString(_installationKey);
    if (saved != null && saved.isNotEmpty) {
      _installationId = saved;
      return saved;
    }
    final random = Random.secure();
    final id = List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    await _preferences.setString(_installationKey, id);
    _installationId = id;
    return id;
  }

  Future<void> _scheduleDailySummary(int reminderMinutes) async {
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      reminderMinutes ~/ 60,
      reminderMinutes % 60,
    );
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
    await _local.zonedSchedule(
      id: 1000,
      title: 'Bugünün planı hazır',
      body: 'Çalışma programını gözden geçirip ilk adımı başlat.',
      scheduledDate: next,
      notificationDetails: _reminderDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'program',
    );
  }

  Future<void> _scheduleTasks(List<StudyTask> tasks) async {
    final now = tz.TZDateTime.now(tz.local);
    final upcoming =
        tasks
            .where((task) => task.status == TaskStatus.planned)
            .map((task) => (task: task, reminder: _taskReminderDate(task)))
            .where((entry) => entry.reminder.isAfter(now))
            .toList()
          ..sort((a, b) => a.reminder.compareTo(b.reminder));

    for (final entry in upcoming.take(50)) {
      final task = entry.task;
      await _local.zonedSchedule(
        id: 10000 + _stableId(task.id),
        title: 'Görevin 10 dakika sonra başlıyor',
        body: '${task.subject} · ${task.title}',
        scheduledDate: entry.reminder,
        notificationDetails: _reminderDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'program',
      );
    }
  }

  tz.TZDateTime _taskReminderDate(StudyTask task) => tz.TZDateTime(
    tz.local,
    task.scheduledDate.year,
    task.scheduledDate.month,
    task.scheduledDate.day,
    task.startMinutes ~/ 60,
    task.startMinutes % 60,
  ).subtract(const Duration(minutes: 10));

  Future<void> _showForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    await _local.show(
      id: _stableId(message.messageId ?? DateTime.now().toIso8601String()),
      title: notification.title ?? 'Zihin Rehberi',
      body: notification.body,
      notificationDetails: _updateDetails,
      payload: _targetFromRemote(message),
    );
  }

  void _emitTarget(String? raw) {
    final target = _validatedTarget(raw);
    if (target != null) _tapController.add(target);
  }

  String _targetFromRemote(RemoteMessage message) =>
      _validatedTarget(message.data['target']) ?? 'dashboard';

  String? _validatedTarget(Object? raw) {
    final value = raw?.toString();
    return const {
          'dashboard',
          'focus',
          'analysis',
          'program',
          'assistant',
        }.contains(value)
        ? value
        : null;
  }

  int _stableId(String value) {
    var hash = 0x811C9DC5;
    for (final unit in value.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0x7FFFFFFF;
    }
    return hash;
  }

  static const _reminderDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      _reminderChannelId,
      'Çalışma hatırlatmaları',
      channelDescription: 'Günlük plan ve görev başlangıç hatırlatmaları',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    ),
  );

  static const _updateDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      _updatesChannelId,
      'Koç güncellemeleri',
      channelDescription: 'Motivasyon ve analiz bildirimleri',
      importance: Importance.defaultImportance,
      icon: '@mipmap/ic_launcher',
    ),
  );

  Future<void> dispose() async {
    await _foregroundSubscription?.cancel();
    await _openedSubscription?.cancel();
    await _tokenSubscription?.cancel();
    await _tapController.close();
  }
}
