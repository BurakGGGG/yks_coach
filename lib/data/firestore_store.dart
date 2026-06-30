import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/coach_message.dart';
import '../models/device_registration.dart';
import '../models/focus_session.dart';
import '../models/practice_exam.dart';
import '../models/study_task.dart';
import '../models/user_profile.dart';
import 'repositories.dart';

/// Firestore-backed [AppRepositories] for a signed-in user.
///
/// Every collection is rooted at `users/{uid}` so the security rules can scope
/// access by owner. Reads are live snapshots so two devices stay in sync;
/// `createdAt` / `updatedAt` are written with server timestamps, never trusted
/// from the client clock.
AppRepositories firestoreRepositories(
  String uid, {
  FirebaseFirestore? firestore,
}) {
  final db = firestore ?? FirebaseFirestore.instance;
  final userDoc = db.collection('users').doc(uid);
  return AppRepositories(
    profile: _FirestoreProfileRepository(userDoc),
    tasks: _FirestoreTaskRepository(userDoc.collection('tasks')),
    exams: _FirestoreExamRepository(userDoc.collection('exams')),
    focus: _FirestoreFocusRepository(userDoc.collection('focusSessions')),
    coach: _FirestoreCoachRepository(userDoc.collection('coachMessages')),
    devices: _FirestoreDeviceRepository(userDoc.collection('devices')),
  );
}

/// Converts top-level server [Timestamp]s (`createdAt` / `updatedAt`) into
/// epoch-millis so the Firestore-agnostic models can parse them uniformly.
/// Nested values (e.g. the `subjects` array) are left untouched.
Map<String, dynamic> _normalize(Map<String, dynamic> data) {
  final result = Map<String, dynamic>.of(data);
  for (final entry in data.entries) {
    if (entry.value is Timestamp) {
      result[entry.key] = (entry.value as Timestamp).millisecondsSinceEpoch;
    }
  }
  return result;
}

class _FirestoreProfileRepository implements ProfileRepository {
  _FirestoreProfileRepository(this._doc);

  final DocumentReference<Map<String, dynamic>> _doc;

  @override
  Stream<UserProfile?> watch() => _doc.snapshots().map(
    (snapshot) => snapshot.exists && snapshot.data() != null
        ? UserProfile.fromMap(snapshot.data()!)
        : null,
  );

  @override
  Future<void> save(UserProfile profile, {bool isNew = false}) => _doc.set({
    ...profile.toMap(),
    'updatedAt': FieldValue.serverTimestamp(),
    if (isNew) 'createdAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}

class _FirestoreTaskRepository implements TaskRepository {
  _FirestoreTaskRepository(this._collection);

  final CollectionReference<Map<String, dynamic>> _collection;

  @override
  Stream<List<StudyTask>> watch() => _collection
      .orderBy('scheduledAt', descending: true)
      .limit(500)
      .snapshots()
      .map((snapshot) {
        final tasks = snapshot.docs
            .map((doc) => StudyTask.fromMap(doc.id, _normalize(doc.data())))
            .toList();
        // Secondary sort by start time without needing a composite index.
        tasks.sort((a, b) {
          final byDate = a.scheduledDate.compareTo(b.scheduledDate);
          return byDate != 0
              ? byDate
              : a.startMinutes.compareTo(b.startMinutes);
        });
        return tasks;
      });

  @override
  Future<String> save(StudyTask task) async {
    final doc = task.id.isEmpty ? _collection.doc() : _collection.doc(task.id);
    await doc.set({
      ...task.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (task.id.isEmpty) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return doc.id;
  }

  @override
  Future<void> delete(String id) => _collection.doc(id).delete();
}

class _FirestoreExamRepository implements ExamRepository {
  _FirestoreExamRepository(this._collection);

  final CollectionReference<Map<String, dynamic>> _collection;

  @override
  Stream<List<PracticeExam>> watch() => _collection
      .orderBy('takenAt', descending: true)
      .limit(100)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => PracticeExam.fromMap(doc.id, _normalize(doc.data())))
            .toList(),
      );

  @override
  Future<String> save(PracticeExam exam) async {
    final doc = exam.id.isEmpty ? _collection.doc() : _collection.doc(exam.id);
    await doc.set({
      ...exam.toMap(),
      if (exam.id.isEmpty) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return doc.id;
  }

  @override
  Future<void> delete(String id) => _collection.doc(id).delete();
}

class _FirestoreFocusRepository implements FocusRepository {
  _FirestoreFocusRepository(this._collection);

  final CollectionReference<Map<String, dynamic>> _collection;

  @override
  Stream<List<FocusSession>> watch() => _collection
      .orderBy('startedAt', descending: true)
      .limit(500)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => FocusSession.fromMap(doc.id, _normalize(doc.data())))
            .toList(),
      );

  @override
  Future<void> add(FocusSession session) => _collection.add({
    ...session.toMap(),
    'createdAt': FieldValue.serverTimestamp(),
  });
}

class _FirestoreCoachRepository implements CoachRepository {
  _FirestoreCoachRepository(this._collection);

  final CollectionReference<Map<String, dynamic>> _collection;

  @override
  Stream<List<CoachMessage>> watch() => _collection
      .orderBy('createdAt')
      .limit(100)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => CoachMessage.fromMap(doc.id, _normalize(doc.data())))
            .toList(),
      );

  @override
  Future<void> add(CoachMessage message) => _collection.add({
    ...message.toMap(),
    'createdAt': FieldValue.serverTimestamp(),
  });

  @override
  Future<void> clear() async {
    final snapshot = await _collection.get();
    if (snapshot.docs.isEmpty) return;
    final batch = _collection.firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}

class _FirestoreDeviceRepository implements DeviceRepository {
  _FirestoreDeviceRepository(this._collection);

  final CollectionReference<Map<String, dynamic>> _collection;

  @override
  Future<void> save(DeviceRegistration registration) async {
    final doc = _collection.doc(registration.installationId);
    await _collection.firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(doc);
      transaction.set(doc, {
        ...registration.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (!snapshot.exists) 'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  @override
  Future<void> delete(String installationId) =>
      _collection.doc(installationId).delete();
}
