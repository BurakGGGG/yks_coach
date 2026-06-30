import 'package:flutter/foundation.dart';

/// One Android installation registered for FCM under
/// `users/{uid}/devices/{installationId}`.
@immutable
class DeviceRegistration {
  const DeviceRegistration({
    required this.installationId,
    required this.fcmToken,
    required this.timeZone,
    required this.dailyReminder,
    required this.taskReminder,
    required this.motivationReminder,
    required this.examReminder,
  });

  final String installationId;
  final String fcmToken;
  final String timeZone;
  final bool dailyReminder;
  final bool taskReminder;
  final bool motivationReminder;
  final bool examReminder;

  Map<String, Object> toMap() => {
    'installationId': installationId,
    'fcmToken': fcmToken,
    'platform': 'android',
    'timeZone': timeZone,
    'dailyReminder': dailyReminder,
    'taskReminder': taskReminder,
    'motivationReminder': motivationReminder,
    'examReminder': examReminder,
  };
}
