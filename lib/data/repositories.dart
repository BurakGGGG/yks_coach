import '../models/coach_message.dart';
import '../models/device_registration.dart';
import '../models/focus_session.dart';
import '../models/practice_exam.dart';
import '../models/study_task.dart';
import '../models/user_profile.dart';

/// Streams and mutates the single `users/{uid}` document.
abstract interface class ProfileRepository {
  /// Emits the current profile (or `null` when the document does not exist
  /// yet), then every change.
  Stream<UserProfile?> watch();

  /// Writes the profile. [isNew] stamps `createdAt` for the first write.
  Future<void> save(UserProfile profile, {bool isNew = false});
}

/// Streams and mutates `users/{uid}/tasks`.
abstract interface class TaskRepository {
  Stream<List<StudyTask>> watch();

  /// Creates or updates a task, returning its id (generated when empty).
  Future<String> save(StudyTask task);
  Future<void> delete(String id);
}

/// Streams and mutates `users/{uid}/exams`.
abstract interface class ExamRepository {
  Stream<List<PracticeExam>> watch();
  Future<String> save(PracticeExam exam);
  Future<void> delete(String id);
}

/// Streams and appends to `users/{uid}/focusSessions`.
abstract interface class FocusRepository {
  Stream<List<FocusSession>> watch();
  Future<void> add(FocusSession session);
}

/// Streams and mutates `users/{uid}/coachMessages`.
abstract interface class CoachRepository {
  Stream<List<CoachMessage>> watch();
  Future<void> add(CoachMessage message);

  /// Deletes the whole conversation ("Geçmişi temizle").
  Future<void> clear();
}

/// Registers the current Android installation for FCM delivery.
abstract interface class DeviceRepository {
  Future<void> save(DeviceRegistration registration);
  Future<void> delete(String installationId);
}

/// Bundle of every domain repository for one signed-in user. Controllers depend
/// on the narrow interfaces above; the composition root wires a concrete bundle
/// (Firestore in the app, in-memory in tests).
class AppRepositories {
  AppRepositories({
    required this.profile,
    required this.tasks,
    required this.exams,
    required this.focus,
    required this.coach,
    required this.devices,
  });

  final ProfileRepository profile;
  final TaskRepository tasks;
  final ExamRepository exams;
  final FocusRepository focus;
  final CoachRepository coach;
  final DeviceRepository devices;
}
