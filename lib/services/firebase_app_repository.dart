import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/study_task.dart';
import 'app_repository.dart';

class FirebaseAppRepository implements AppRepository {
  FirebaseAppRepository._(this._userDocument);

  final DocumentReference<Map<String, dynamic>> _userDocument;

  CollectionReference<Map<String, dynamic>> get _tasks =>
      _userDocument.collection('tasks');
  CollectionReference<Map<String, dynamic>> get _exams =>
      _userDocument.collection('exams');
  CollectionReference<Map<String, dynamic>> get _messages =>
      _userDocument.collection('coachMessages');

  static Future<FirebaseAppRepository> connect() async {
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser ?? (await auth.signInAnonymously()).user;
    if (user == null) {
      throw StateError('Firebase anonim oturumu oluşturulamadı.');
    }
    return FirebaseAppRepository._(
      FirebaseFirestore.instance.collection('users').doc(user.uid),
    );
  }

  @override
  Future<AppSnapshot?> load() async {
    final results = await Future.wait([
      _userDocument.get(),
      _tasks.orderBy('scheduledAt').get(),
      _exams.orderBy('createdAt', descending: true).get(),
      _messages.orderBy('time').limit(100).get(),
    ]);
    final user = results[0] as DocumentSnapshot<Map<String, dynamic>>;
    if (!user.exists) return null;
    final taskDocuments = results[1] as QuerySnapshot<Map<String, dynamic>>;
    final examDocuments = results[2] as QuerySnapshot<Map<String, dynamic>>;
    final messageDocuments = results[3] as QuerySnapshot<Map<String, dynamic>>;
    return AppSnapshot(
      settings: user.data() ?? const {},
      tasks: taskDocuments.docs
          .map((document) => StudyTask.fromMap(document.id, document.data()))
          .toList(),
      exams: examDocuments.docs
          .map((document) => PracticeExam.fromMap(document.id, document.data()))
          .toList(),
      messages: messageDocuments.docs
          .map((document) => CoachMessage.fromMap(document.id, document.data()))
          .toList(),
    );
  }

  @override
  Future<void> saveSettings(Map<String, Object?> settings) => _userDocument.set(
    {...settings, 'updatedAt': FieldValue.serverTimestamp()},
    SetOptions(merge: true),
  );

  @override
  Future<void> saveTask(StudyTask task) => _tasks.doc(task.id).set({
    ...task.toMap(),
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  @override
  Future<void> saveExam(PracticeExam exam) => _exams.doc(exam.id).set({
    ...exam.toMap(),
    'createdAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  @override
  Future<void> deleteExam(String examId) => _exams.doc(examId).delete();

  @override
  Future<void> saveMessage(CoachMessage message) => _messages
      .doc(message.id)
      .set({...message.toMap(), 'createdAt': FieldValue.serverTimestamp()});
}
