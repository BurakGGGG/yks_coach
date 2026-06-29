import 'package:flutter/material.dart';

class StudyTask {
  StudyTask({
    this.id = '',
    required this.subject,
    required this.title,
    required this.time,
    required this.color,
    required this.scheduledDate,
    this.detail,
    this.completed = false,
  });

  final String id;
  final String subject;
  final String title;
  final String time;
  final Color color;
  final DateTime scheduledDate;
  final String? detail;
  bool completed;

  StudyTask copyWith({String? id, bool? completed}) => StudyTask(
    id: id ?? this.id,
    subject: subject,
    title: title,
    time: time,
    color: color,
    scheduledDate: scheduledDate,
    detail: detail,
    completed: completed ?? this.completed,
  );

  Map<String, Object?> toMap() => {
    'subject': subject,
    'title': title,
    'time': time,
    'color': color.toARGB32(),
    'scheduledAt': scheduledDate.millisecondsSinceEpoch,
    'detail': detail,
    'completed': completed,
  };

  factory StudyTask.fromMap(String id, Map<String, dynamic> map) => StudyTask(
    id: id,
    subject: map['subject'] as String? ?? '',
    title: map['title'] as String? ?? '',
    time: map['time'] as String? ?? '',
    color: Color(map['color'] as int? ?? 0xFF2563EB),
    scheduledDate: DateTime.fromMillisecondsSinceEpoch(
      map['scheduledAt'] as int? ?? 0,
    ),
    detail: map['detail'] as String?,
    completed: map['completed'] as bool? ?? false,
  );
}

class PracticeExam {
  const PracticeExam({
    this.id = '',
    required this.name,
    required this.date,
    required this.net,
    required this.type,
  });

  final String id;
  final String name;
  final String date;
  final double net;
  final String type;

  PracticeExam copyWith({String? id}) => PracticeExam(
    id: id ?? this.id,
    name: name,
    date: date,
    net: net,
    type: type,
  );

  Map<String, Object?> toMap() => {
    'name': name,
    'date': date,
    'net': net,
    'type': type,
  };

  factory PracticeExam.fromMap(String id, Map<String, dynamic> map) =>
      PracticeExam(
        id: id,
        name: map['name'] as String? ?? '',
        date: map['date'] as String? ?? '',
        net: (map['net'] as num?)?.toDouble() ?? 0,
        type: map['type'] as String? ?? 'TYT',
      );
}

class CoachMessage {
  const CoachMessage({
    this.id = '',
    required this.text,
    required this.fromUser,
    required this.time,
  });

  final String id;
  final String text;
  final bool fromUser;
  final DateTime time;

  CoachMessage copyWith({String? id}) => CoachMessage(
    id: id ?? this.id,
    text: text,
    fromUser: fromUser,
    time: time,
  );

  Map<String, Object?> toMap() => {
    'text': text,
    'fromUser': fromUser,
    'time': time.millisecondsSinceEpoch,
  };

  factory CoachMessage.fromMap(String id, Map<String, dynamic> map) =>
      CoachMessage(
        id: id,
        text: map['text'] as String? ?? '',
        fromUser: map['fromUser'] as bool? ?? false,
        time: DateTime.fromMillisecondsSinceEpoch(map['time'] as int? ?? 0),
      );
}
