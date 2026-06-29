import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/repositories.dart';
import '../models/practice_exam.dart';
import 'analytics.dart';

/// Owns practice exams (`users/{uid}/exams`) and the TYT/AYT view selection.
class ExamController extends ChangeNotifier {
  ExamController(this._repository) {
    _subscription = _repository.watch().listen(_onExams);
  }

  final ExamRepository _repository;
  late final StreamSubscription<List<PracticeExam>> _subscription;

  List<PracticeExam> _exams = const [];
  String _examType = 'TYT';
  bool _showAll = false;

  List<PracticeExam> get exams => _exams;
  String get examType => _examType;
  bool get showAll => _showAll;

  /// Real per-type analysis derived from the stored exams.
  AnalysisStats get stats => AnalysisStats.compute(_exams, _examType);

  void _onExams(List<PracticeExam> exams) {
    _exams = exams;
    notifyListeners();
  }

  void setExamType(String type) {
    _examType = type;
    _showAll = false;
    notifyListeners();
  }

  void toggleShowAll() {
    _showAll = !_showAll;
    notifyListeners();
  }

  Future<void> addExam(PracticeExam exam) => _repository.save(exam);

  Future<void> removeExam(String id) => _repository.delete(id);

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
