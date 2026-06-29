import '../models/study_task.dart';

class AppSnapshot {
  const AppSnapshot({
    required this.settings,
    required this.tasks,
    required this.exams,
    required this.messages,
  });

  final Map<String, dynamic> settings;
  final List<StudyTask> tasks;
  final List<PracticeExam> exams;
  final List<CoachMessage> messages;
}

abstract interface class AppRepository {
  Future<AppSnapshot?> load();

  Future<void> saveSettings(Map<String, Object?> settings);

  Future<void> saveTask(StudyTask task);

  Future<void> saveExam(PracticeExam exam);

  Future<void> deleteExam(String examId);

  Future<void> saveMessage(CoachMessage message);
}
