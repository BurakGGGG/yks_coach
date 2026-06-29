import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/repositories.dart';
import '../models/study_task.dart';

/// Owns the weekly study schedule (`users/{uid}/tasks`) and which day is in
/// focus. The week runs Monday→Sunday (weekend included) based on the device's
/// current date.
class ScheduleController extends ChangeNotifier {
  ScheduleController(this._repository, {DateTime? today}) {
    final now = today ?? DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    _weekStart = start.subtract(Duration(days: start.weekday - 1));
    _selectedDay = (now.weekday - 1).clamp(0, 6);
    _subscription = _repository.watch().listen(_onTasks);
  }

  final TaskRepository _repository;
  late final StreamSubscription<List<StudyTask>> _subscription;

  List<StudyTask> _tasks = const [];
  late DateTime _weekStart;
  late int _selectedDay;

  List<StudyTask> get tasks => _tasks;
  DateTime get weekStart => _weekStart;
  int get selectedDay => _selectedDay;
  DateTime get selectedDate => _weekStart.add(Duration(days: _selectedDay));

  List<StudyTask> get selectedDayTasks => _tasks
      .where((task) => _sameDay(task.scheduledDate, selectedDate))
      .toList();

  void _onTasks(List<StudyTask> tasks) {
    _tasks = tasks;
    notifyListeners();
  }

  void selectDay(int index) {
    _selectedDay = index.clamp(0, 6);
    notifyListeners();
  }

  void changeWeek(int offset) {
    _weekStart = _weekStart.add(Duration(days: 7 * offset));
    notifyListeners();
  }

  Future<void> addTask(StudyTask task) => _repository.save(task);

  Future<void> updateTask(StudyTask task) => _repository.save(task);

  Future<void> toggleTask(StudyTask task) =>
      _repository.save(task.toggleCompleted());

  Future<void> deleteTask(String id) => _repository.delete(id);

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
