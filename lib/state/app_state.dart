import 'dart:async';

import 'package:flutter/material.dart';

import '../models/study_task.dart';
import '../services/app_repository.dart';

class AppState extends ChangeNotifier {
  AppState({
    int initialTab = 0,
    bool dark = false,
    this.repository,
    String? initialUserName,
  }) : tabIndex = initialTab,
       themeMode = dark ? ThemeMode.dark : ThemeMode.light {
    if (initialUserName != null && initialUserName.trim().isNotEmpty) {
      userName = initialUserName.trim();
    }
  }

  final AppRepository? repository;
  static int _idSequence = 0;

  int tabIndex;
  ThemeMode themeMode;
  String userName = 'Ali Yılmaz';
  String grade = '12. Sınıf';
  String studyField = 'Sayısal';
  String targetUniversity = 'ODTÜ';
  String targetDepartment = 'Bilgisayar Mühendisliği';
  int targetRank = 5000;
  int dailyQuestionGoal = 120;
  int dailyStudyMinutes = 240;
  final Set<String> prioritySubjects = {'Matematik', 'Fizik'};
  bool dailyReminder = true;
  bool taskReminder = true;
  bool motivationReminder = false;
  bool examReminder = true;
  TimeOfDay reminderTime = const TimeOfDay(hour: 19, minute: 0);
  DateTime weekStart = DateTime(2023, 10, 16);
  int selectedDay = 1;
  String focusSubject = 'Matematik - Limit & Türev';
  int focusMinutes = 25;
  int remainingSeconds = 25 * 60;
  String timerMode = 'focus';
  bool timerRunning = false;
  int completedFocusSessions = 3;
  int totalFocusMinutes = 75;
  bool showAllExams = false;
  String examType = 'TYT';
  Timer? _timer;
  bool assistantTyping = false;

  final List<CoachMessage> coachMessages = [
    CoachMessage(
      id: 'welcome',
      text:
          'Merhaba Ali! Bugünkü programında Geometri ve Fizik görevlerin var. Nereden başlamak istersin?',
      fromUser: false,
      time: DateTime(2026, 6, 29, 9),
    ),
  ];

  final List<StudyTask> tasks = [
    StudyTask(
      id: 'sample-math-derivative',
      subject: 'Matematik',
      title: 'Türev - Kurallar ve Uygulamalar',
      time: '09:00 - 10:30',
      color: const Color(0xFF2563EB),
      scheduledDate: DateTime(2023, 10, 17),
      completed: true,
    ),
    StudyTask(
      id: 'sample-turkish-paragraph',
      subject: 'Türkçe',
      title: 'Paragrafta Anlam Soru Çözümü',
      time: '10:45 - 11:30',
      color: const Color(0xFF8B5CF6),
      scheduledDate: DateTime(2023, 10, 17),
      completed: true,
    ),
    StudyTask(
      id: 'sample-geometry-triangles',
      subject: 'Geometri',
      title: 'Üçgenler - Benzerlik ve Alan',
      time: '13:00 - 14:30',
      detail: 'Konu Anlatımı + 40 Soru',
      color: const Color(0xFF10B981),
      scheduledDate: DateTime(2023, 10, 17),
    ),
    StudyTask(
      id: 'sample-physics-motion',
      subject: 'Fizik',
      title: 'Hareket - İvme Grafikleri',
      time: '15:00 - 16:30',
      color: const Color(0xFF0EA5E9),
      scheduledDate: DateTime(2023, 10, 17),
    ),
  ];

  final List<PracticeExam> exams = [
    const PracticeExam(
      id: 'sample-tyt-ozdebir',
      name: 'Türkiye Geneli Özdebir TYT',
      date: '12 Mayıs 2024',
      net: 85,
      type: 'TYT',
    ),
    const PracticeExam(
      id: 'sample-ayt-school-4',
      name: 'Kurum İçi AYT Denemesi 4',
      date: '05 Mayıs 2024',
      net: 62.5,
      type: 'AYT',
    ),
    const PracticeExam(
      id: 'sample-tyt-bilgi-sarmal',
      name: 'Türkiye Geneli Bilgi Sarmal',
      date: '28 Nisan 2024',
      net: 78.5,
      type: 'TYT',
    ),
    const PracticeExam(
      id: 'sample-tyt-school-8',
      name: 'Kurum İçi TYT Denemesi 8',
      date: '21 Nisan 2024',
      net: 74.25,
      type: 'TYT',
    ),
  ];

  Future<void> hydrate() async {
    final repository = this.repository;
    if (repository == null) return;
    final snapshot = await repository.load();
    if (snapshot == null) {
      await Future.wait([
        repository.saveSettings(_settingsMap()),
        ...tasks.map(repository.saveTask),
        ...exams.map(repository.saveExam),
        ...coachMessages.map(repository.saveMessage),
      ]);
      return;
    }
    _applySettings(snapshot.settings);
    tasks
      ..clear()
      ..addAll(snapshot.tasks);
    exams
      ..clear()
      ..addAll(snapshot.exams);
    coachMessages
      ..clear()
      ..addAll(snapshot.messages);
  }

  void setTab(int value) {
    tabIndex = value;
    notifyListeners();
  }

  void toggleTheme(bool dark) {
    themeMode = dark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    _persistSettings();
  }

  void selectDay(int value) {
    selectedDay = value;
    notifyListeners();
  }

  DateTime get selectedDate => weekStart.add(Duration(days: selectedDay));

  List<StudyTask> get selectedDayTasks => tasks
      .where((task) => _isSameDay(task.scheduledDate, selectedDate))
      .toList();

  void changeWeek(int offset) {
    weekStart = weekStart.add(Duration(days: 7 * offset));
    selectedDay = 0;
    notifyListeners();
  }

  void toggleTask(StudyTask task) {
    task.completed = !task.completed;
    notifyListeners();
    _persist(repository?.saveTask(task));
  }

  void addTask(StudyTask task) {
    final storedTask = task.id.isEmpty
        ? task.copyWith(id: _newId('task'))
        : task;
    tasks.add(storedTask);
    notifyListeners();
    _persist(repository?.saveTask(storedTask));
  }

  void startTask(StudyTask task) {
    focusSubject = '${task.subject} - ${task.title}';
    _persistSettings();
    setTab(1);
  }

  void selectFocusSubject(String value) {
    focusSubject = value;
    notifyListeners();
    _persistSettings();
  }

  void setTimerMode(String mode) {
    timerMode = mode;
    final minutes = switch (mode) {
      'shortBreak' => 5,
      'longBreak' => 15,
      _ => focusMinutes,
    };
    _setTimerDuration(minutes);
  }

  void setFocusMinutes(int value) {
    focusMinutes = value;
    timerMode = 'focus';
    _setTimerDuration(value);
    _persistSettings();
  }

  void _setTimerDuration(int minutes) {
    remainingSeconds = minutes * 60;
    timerRunning = false;
    _timer?.cancel();
    notifyListeners();
  }

  void toggleTimer() {
    if (timerRunning) {
      timerRunning = false;
      _timer?.cancel();
      notifyListeners();
      return;
    }
    timerRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (remainingSeconds <= 1) {
        remainingSeconds = 0;
        timerRunning = false;
        _timer?.cancel();
        if (timerMode == 'focus') {
          completedFocusSessions++;
          totalFocusMinutes += focusMinutes;
          _persistSettings();
        }
      } else {
        remainingSeconds--;
      }
      notifyListeners();
    });
    notifyListeners();
  }

  void resetTimer() {
    _timer?.cancel();
    timerRunning = false;
    remainingSeconds = switch (timerMode) {
      'shortBreak' => 5 * 60,
      'longBreak' => 15 * 60,
      _ => focusMinutes * 60,
    };
    notifyListeners();
  }

  void setExamType(String value) {
    examType = value;
    notifyListeners();
  }

  void toggleAllExams() {
    showAllExams = !showAllExams;
    notifyListeners();
  }

  void addExam(PracticeExam exam) {
    final storedExam = exam.id.isEmpty
        ? exam.copyWith(id: _newId('exam'))
        : exam;
    exams.insert(0, storedExam);
    notifyListeners();
    _persist(repository?.saveExam(storedExam));
  }

  void removeExam(PracticeExam exam) {
    exams.remove(exam);
    notifyListeners();
    _persist(repository?.deleteExam(exam.id));
  }

  void updateProfile({
    required String name,
    required String newGrade,
    required String field,
    required String university,
    required String department,
    required int rank,
  }) {
    userName = name;
    grade = newGrade;
    studyField = field;
    targetUniversity = university;
    targetDepartment = department;
    targetRank = rank;
    notifyListeners();
    _persistSettings();
  }

  void updateGoals({
    required int questions,
    required int studyMinutes,
    required Set<String> subjects,
  }) {
    dailyQuestionGoal = questions;
    dailyStudyMinutes = studyMinutes;
    prioritySubjects
      ..clear()
      ..addAll(subjects);
    notifyListeners();
    _persistSettings();
  }

  void updateNotification({
    bool? daily,
    bool? task,
    bool? motivation,
    bool? exam,
    TimeOfDay? time,
  }) {
    dailyReminder = daily ?? dailyReminder;
    taskReminder = task ?? taskReminder;
    motivationReminder = motivation ?? motivationReminder;
    examReminder = exam ?? examReminder;
    reminderTime = time ?? reminderTime;
    notifyListeners();
    _persistSettings();
  }

  Future<void> sendCoachMessage(String text) async {
    final value = text.trim();
    if (value.isEmpty || assistantTyping) return;
    final userMessage = CoachMessage(
      id: _newId('message'),
      text: value,
      fromUser: true,
      time: DateTime.now(),
    );
    coachMessages.add(userMessage);
    _persist(repository?.saveMessage(userMessage));
    assistantTyping = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 650));
    final coachMessage = CoachMessage(
      id: _newId('message'),
      text: _coachReply(value),
      fromUser: false,
      time: DateTime.now(),
    );
    coachMessages.add(coachMessage);
    _persist(repository?.saveMessage(coachMessage));
    assistantTyping = false;
    notifyListeners();
  }

  String _coachReply(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('program')) {
      return 'Bugün için önce 40 dakikalık Geometri konu tekrarı, ardından 25 dakikalık Fizik soru çözümü öneriyorum. Program sekmesinden ilk oturumu başlatabilirsin.';
    }
    if (lower.contains('motiv') || lower.contains('yorul')) {
      return 'Kısa bir mola verip sadece bir sonraki 25 dakikaya odaklan. Küçük ve tamamlanabilir hedefler çalışma isteğini geri getirir.';
    }
    if (lower.contains('net') || lower.contains('deneme')) {
      return 'Son TYT ortalaman 78.5 net. En hızlı gelişim alanın Fizik; yanlışlarını konu başlığına göre ayırıp iki gün sonra tekrar çözmeni öneriyorum.';
    }
    return 'Bunu çalışma planına çevirebilirim. Hangi ders ve bugün ayırabileceğin süreyi yazarsan net bir oturum önereyim.';
  }

  Map<String, Object?> _settingsMap() => {
    'userName': userName,
    'grade': grade,
    'studyField': studyField,
    'targetUniversity': targetUniversity,
    'targetDepartment': targetDepartment,
    'targetRank': targetRank,
    'dailyQuestionGoal': dailyQuestionGoal,
    'dailyStudyMinutes': dailyStudyMinutes,
    'prioritySubjects': prioritySubjects.toList()..sort(),
    'dailyReminder': dailyReminder,
    'taskReminder': taskReminder,
    'motivationReminder': motivationReminder,
    'examReminder': examReminder,
    'reminderMinutes': reminderTime.hour * 60 + reminderTime.minute,
    'themeMode': themeMode == ThemeMode.dark ? 'dark' : 'light',
    'focusSubject': focusSubject,
    'focusMinutes': focusMinutes,
    'completedFocusSessions': completedFocusSessions,
    'totalFocusMinutes': totalFocusMinutes,
  };

  void _applySettings(Map<String, dynamic> settings) {
    userName = settings['userName'] as String? ?? userName;
    grade = settings['grade'] as String? ?? grade;
    studyField = settings['studyField'] as String? ?? studyField;
    targetUniversity =
        settings['targetUniversity'] as String? ?? targetUniversity;
    targetDepartment =
        settings['targetDepartment'] as String? ?? targetDepartment;
    targetRank = settings['targetRank'] as int? ?? targetRank;
    dailyQuestionGoal =
        settings['dailyQuestionGoal'] as int? ?? dailyQuestionGoal;
    dailyStudyMinutes =
        settings['dailyStudyMinutes'] as int? ?? dailyStudyMinutes;
    final subjects = settings['prioritySubjects'];
    if (subjects is List) {
      prioritySubjects
        ..clear()
        ..addAll(subjects.whereType<String>());
    }
    dailyReminder = settings['dailyReminder'] as bool? ?? dailyReminder;
    taskReminder = settings['taskReminder'] as bool? ?? taskReminder;
    motivationReminder =
        settings['motivationReminder'] as bool? ?? motivationReminder;
    examReminder = settings['examReminder'] as bool? ?? examReminder;
    final reminderMinutes =
        settings['reminderMinutes'] as int? ??
        reminderTime.hour * 60 + reminderTime.minute;
    reminderTime = TimeOfDay(
      hour: (reminderMinutes ~/ 60).clamp(0, 23),
      minute: (reminderMinutes % 60).clamp(0, 59),
    );
    themeMode = settings['themeMode'] == 'dark'
        ? ThemeMode.dark
        : ThemeMode.light;
    focusSubject = settings['focusSubject'] as String? ?? focusSubject;
    focusMinutes = settings['focusMinutes'] as int? ?? focusMinutes;
    completedFocusSessions =
        settings['completedFocusSessions'] as int? ?? completedFocusSessions;
    totalFocusMinutes =
        settings['totalFocusMinutes'] as int? ?? totalFocusMinutes;
    remainingSeconds = focusMinutes * 60;
  }

  void _persistSettings() {
    final repository = this.repository;
    if (repository != null) _persist(repository.saveSettings(_settingsMap()));
  }

  void _persist(Future<void>? operation) {
    if (operation == null) return;
    unawaited(
      operation.catchError((Object error, StackTrace stackTrace) {
        debugPrint('Firebase senkronizasyon hatası: $error');
      }),
    );
  }

  String _newId(String prefix) {
    _idSequence++;
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}-$_idSequence';
  }

  bool _isSameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({required AppState notifier, required super.child, super.key})
    : super(notifier: notifier);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope bulunamadı');
    return scope!.notifier!;
  }
}
