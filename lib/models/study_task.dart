import 'package:flutter/material.dart';

/// Lifecycle state of a scheduled study task.
enum TaskStatus {
  planned,
  completed,
  skipped;

  static TaskStatus fromName(String? name) => TaskStatus.values.firstWhere(
    (status) => status.name == name,
    orElse: () => TaskStatus.planned,
  );
}

/// A single scheduled study block.
///
/// Time is stored structurally as [startMinutes]/[endMinutes] (minutes past
/// midnight) rather than a free-text label, so reminders can be scheduled and
/// durations computed reliably.
@immutable
class StudyTask {
  const StudyTask({
    this.id = '',
    required this.subject,
    required this.title,
    required this.scheduledDate,
    required this.startMinutes,
    required this.endMinutes,
    required this.color,
    this.detail,
    this.status = TaskStatus.planned,
    this.createdAt,
  });

  final String id;
  final String subject;
  final String title;

  /// Date-only (local midnight) the task is scheduled for.
  final DateTime scheduledDate;
  final int startMinutes;
  final int endMinutes;
  final Color color;
  final String? detail;
  final TaskStatus status;
  final DateTime? createdAt;

  bool get completed => status == TaskStatus.completed;

  int get durationMinutes => (endMinutes - startMinutes).clamp(0, 24 * 60);

  String get startLabel => _hhmm(startMinutes);
  String get endLabel => _hhmm(endMinutes);
  String get timeLabel => '$startLabel - $endLabel';

  StudyTask copyWith({
    String? id,
    String? subject,
    String? title,
    DateTime? scheduledDate,
    int? startMinutes,
    int? endMinutes,
    Color? color,
    String? detail,
    TaskStatus? status,
    DateTime? createdAt,
  }) {
    return StudyTask(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      title: title ?? this.title,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      startMinutes: startMinutes ?? this.startMinutes,
      endMinutes: endMinutes ?? this.endMinutes,
      color: color ?? this.color,
      detail: detail ?? this.detail,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  StudyTask toggleCompleted() =>
      copyWith(status: completed ? TaskStatus.planned : TaskStatus.completed);

  Map<String, Object?> toMap() => {
    'subject': subject,
    'title': title,
    'scheduledAt': DateTime(
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
    ).millisecondsSinceEpoch,
    'startMinutes': startMinutes,
    'endMinutes': endMinutes,
    'color': color.toARGB32(),
    'detail': detail,
    'status': status.name,
  };

  factory StudyTask.fromMap(String id, Map<String, dynamic> map) {
    final scheduledAt = (map['scheduledAt'] as num?)?.toInt() ?? 0;
    final createdAtMs = (map['createdAt'] as num?)?.toInt();
    return StudyTask(
      id: id,
      subject: map['subject'] as String? ?? '',
      title: map['title'] as String? ?? '',
      scheduledDate: DateTime.fromMillisecondsSinceEpoch(scheduledAt),
      startMinutes: (map['startMinutes'] as num?)?.toInt() ?? 9 * 60,
      endMinutes: (map['endMinutes'] as num?)?.toInt() ?? 10 * 60,
      color: Color((map['color'] as num?)?.toInt() ?? 0xFF2563EB),
      detail: map['detail'] as String?,
      status: TaskStatus.fromName(map['status'] as String?),
      createdAt: createdAtMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(createdAtMs),
    );
  }

  static String _hhmm(int minutes) {
    final clamped = minutes.clamp(0, 24 * 60);
    final h = (clamped ~/ 60).toString().padLeft(2, '0');
    final m = (clamped % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }
}
