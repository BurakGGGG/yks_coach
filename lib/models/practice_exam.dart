import 'package:flutter/foundation.dart';

/// Per-subject result inside a practice exam. Net is always derived from the
/// raw counts using the official YKS rule: `net = correct - wrong / 4`.
@immutable
class ExamSubjectResult {
  const ExamSubjectResult({
    required this.subject,
    required this.correct,
    required this.wrong,
    required this.blank,
  });

  final String subject;
  final int correct;
  final int wrong;
  final int blank;

  int get questionCount => correct + wrong + blank;

  double get net {
    final value = correct - wrong / 4;
    return value < 0 ? 0 : value;
  }

  Map<String, Object?> toMap() => {
    'subject': subject,
    'correct': correct,
    'wrong': wrong,
    'blank': blank,
  };

  factory ExamSubjectResult.fromMap(Map<String, dynamic> map) =>
      ExamSubjectResult(
        subject: map['subject'] as String? ?? '',
        correct: (map['correct'] as num?)?.toInt() ?? 0,
        wrong: (map['wrong'] as num?)?.toInt() ?? 0,
        blank: (map['blank'] as num?)?.toInt() ?? 0,
      );
}

/// A completed practice exam (TYT or AYT) with a per-subject breakdown.
@immutable
class PracticeExam {
  const PracticeExam({
    this.id = '',
    required this.name,
    required this.type,
    required this.takenAt,
    required this.subjects,
    this.createdAt,
  });

  final String id;
  final String name;
  final String type; // 'TYT' | 'AYT'
  final DateTime takenAt;
  final List<ExamSubjectResult> subjects;
  final DateTime? createdAt;

  double get totalNet => subjects.fold(0, (sum, subject) => sum + subject.net);

  int get totalCorrect =>
      subjects.fold(0, (sum, subject) => sum + subject.correct);

  int get totalWrong => subjects.fold(0, (sum, subject) => sum + subject.wrong);

  int get totalQuestions =>
      subjects.fold(0, (sum, subject) => sum + subject.questionCount);

  PracticeExam copyWith({String? id, DateTime? createdAt}) => PracticeExam(
    id: id ?? this.id,
    name: name,
    type: type,
    takenAt: takenAt,
    subjects: subjects,
    createdAt: createdAt ?? this.createdAt,
  );

  Map<String, Object?> toMap() => {
    'name': name,
    'type': type,
    'takenAt': takenAt.millisecondsSinceEpoch,
    'subjects': subjects.map((subject) => subject.toMap()).toList(),
    'totalNet': double.parse(totalNet.toStringAsFixed(2)),
  };

  factory PracticeExam.fromMap(String id, Map<String, dynamic> map) {
    final rawSubjects = map['subjects'];
    final createdAtMs = (map['createdAt'] as num?)?.toInt();
    return PracticeExam(
      id: id,
      name: map['name'] as String? ?? '',
      type: map['type'] as String? ?? 'TYT',
      takenAt: DateTime.fromMillisecondsSinceEpoch(
        (map['takenAt'] as num?)?.toInt() ?? 0,
      ),
      subjects: rawSubjects is List
          ? rawSubjects
                .whereType<Map<String, dynamic>>()
                .map(ExamSubjectResult.fromMap)
                .toList()
          : const [],
      createdAt: createdAtMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(createdAtMs),
    );
  }
}
