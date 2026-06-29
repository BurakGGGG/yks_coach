import 'package:flutter/foundation.dart';

/// A completed focus (Pomodoro) study session, stored under
/// `users/{uid}/focusSessions`. Duration is derived from the real wall-clock
/// start/end so it stays accurate even if the app was backgrounded.
@immutable
class FocusSession {
  const FocusSession({
    this.id = '',
    required this.subject,
    required this.startedAt,
    required this.endedAt,
    this.createdAt,
  });

  final String id;
  final String subject;
  final DateTime startedAt;
  final DateTime endedAt;
  final DateTime? createdAt;

  int get durationMinutes {
    final seconds = endedAt.difference(startedAt).inSeconds;
    return seconds <= 0 ? 0 : (seconds / 60).round();
  }

  Map<String, Object?> toMap() => {
    'subject': subject,
    'startedAt': startedAt.millisecondsSinceEpoch,
    'endedAt': endedAt.millisecondsSinceEpoch,
    'durationMinutes': durationMinutes,
  };

  factory FocusSession.fromMap(String id, Map<String, dynamic> map) {
    final createdAtMs = (map['createdAt'] as num?)?.toInt();
    return FocusSession(
      id: id,
      subject: map['subject'] as String? ?? '',
      startedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['startedAt'] as num?)?.toInt() ?? 0,
      ),
      endedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['endedAt'] as num?)?.toInt() ?? 0,
      ),
      createdAt: createdAtMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(createdAtMs),
    );
  }
}
