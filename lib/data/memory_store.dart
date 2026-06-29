import 'dart:async';

import '../models/coach_message.dart';
import '../models/focus_session.dart';
import '../models/practice_exam.dart';
import '../models/study_task.dart';
import '../models/user_profile.dart';
import 'repositories.dart';

/// In-memory [AppRepositories] used by tests and offline/local scenarios.
/// Each [watch] synchronously emits the current value to a new listener and
/// then forwards live mutations, so there is no race between subscribing and
/// the first write (mirroring how Firestore snapshots behave).
AppRepositories memoryRepositories({
  UserProfile? profile,
  List<StudyTask> tasks = const [],
  List<PracticeExam> exams = const [],
  List<FocusSession> focusSessions = const [],
  List<CoachMessage> coachMessages = const [],
}) {
  return AppRepositories(
    profile: InMemoryProfileRepository(profile),
    tasks: InMemoryTaskRepository(tasks),
    exams: InMemoryExamRepository(exams),
    focus: InMemoryFocusRepository(focusSessions),
    coach: InMemoryCoachRepository(coachMessages),
  );
}

/// Emits [current] to every new listener, then forwards [updates].
Stream<T> _seeded<T>(T Function() current, Stream<T> updates) {
  return Stream.multi((controller) {
    controller.add(current());
    final sub = updates.listen(
      controller.add,
      onError: controller.addError,
      onDone: controller.close,
    );
    controller.onCancel = sub.cancel;
  });
}

class InMemoryProfileRepository implements ProfileRepository {
  InMemoryProfileRepository([this._profile]);

  UserProfile? _profile;
  final _controller = StreamController<UserProfile?>.broadcast();

  @override
  Stream<UserProfile?> watch() => _seeded(() => _profile, _controller.stream);

  @override
  Future<void> save(UserProfile profile, {bool isNew = false}) async {
    _profile = profile;
    _controller.add(_profile);
  }
}

class InMemoryTaskRepository implements TaskRepository {
  InMemoryTaskRepository([List<StudyTask> seed = const []])
    : _items = [...seed];

  final List<StudyTask> _items;
  final _controller = StreamController<List<StudyTask>>.broadcast();
  int _seq = 0;

  List<StudyTask> _sorted() {
    final copy = [..._items]..sort((a, b) {
      final byDate = a.scheduledDate.compareTo(b.scheduledDate);
      return byDate != 0 ? byDate : a.startMinutes.compareTo(b.startMinutes);
    });
    return List.unmodifiable(copy);
  }

  @override
  Stream<List<StudyTask>> watch() => _seeded(_sorted, _controller.stream);

  @override
  Future<String> save(StudyTask task) async {
    final id = task.id.isEmpty ? 'task-${++_seq}' : task.id;
    final stored = task.copyWith(
      id: id,
      createdAt: task.createdAt ?? DateTime.now(),
    );
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      _items[index] = stored;
    } else {
      _items.add(stored);
    }
    _controller.add(_sorted());
    return id;
  }

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((item) => item.id == id);
    _controller.add(_sorted());
  }
}

class InMemoryExamRepository implements ExamRepository {
  InMemoryExamRepository([List<PracticeExam> seed = const []])
    : _items = [...seed];

  final List<PracticeExam> _items;
  final _controller = StreamController<List<PracticeExam>>.broadcast();
  int _seq = 0;

  List<PracticeExam> _sorted() {
    final copy = [..._items]..sort((a, b) => b.takenAt.compareTo(a.takenAt));
    return List.unmodifiable(copy);
  }

  @override
  Stream<List<PracticeExam>> watch() => _seeded(_sorted, _controller.stream);

  @override
  Future<String> save(PracticeExam exam) async {
    final id = exam.id.isEmpty ? 'exam-${++_seq}' : exam.id;
    final stored = exam.copyWith(
      id: id,
      createdAt: exam.createdAt ?? DateTime.now(),
    );
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      _items[index] = stored;
    } else {
      _items.add(stored);
    }
    _controller.add(_sorted());
    return id;
  }

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((item) => item.id == id);
    _controller.add(_sorted());
  }
}

class InMemoryFocusRepository implements FocusRepository {
  InMemoryFocusRepository([List<FocusSession> seed = const []])
    : _items = [...seed];

  final List<FocusSession> _items;
  final _controller = StreamController<List<FocusSession>>.broadcast();
  int _seq = 0;

  List<FocusSession> _sorted() {
    final copy = [..._items]..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return List.unmodifiable(copy);
  }

  @override
  Stream<List<FocusSession>> watch() => _seeded(_sorted, _controller.stream);

  @override
  Future<void> add(FocusSession session) async {
    _items.add(session.id.isEmpty ? _withId(session) : session);
    _controller.add(_sorted());
  }

  FocusSession _withId(FocusSession session) => FocusSession(
    id: 'focus-${++_seq}',
    subject: session.subject,
    startedAt: session.startedAt,
    endedAt: session.endedAt,
    createdAt: session.createdAt ?? DateTime.now(),
  );
}

class InMemoryCoachRepository implements CoachRepository {
  InMemoryCoachRepository([List<CoachMessage> seed = const []])
    : _items = [...seed];

  final List<CoachMessage> _items;
  final _controller = StreamController<List<CoachMessage>>.broadcast();
  int _seq = 0;

  List<CoachMessage> _sorted() {
    final copy = [..._items]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return List.unmodifiable(copy);
  }

  @override
  Stream<List<CoachMessage>> watch() => _seeded(_sorted, _controller.stream);

  @override
  Future<void> add(CoachMessage message) async {
    _items.add(message.id.isEmpty ? message.copyWith(id: 'msg-${++_seq}') : message);
    _controller.add(_sorted());
  }

  @override
  Future<void> clear() async {
    _items.clear();
    _controller.add(_sorted());
  }
}
