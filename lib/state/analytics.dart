import '../models/focus_session.dart';
import '../models/practice_exam.dart';
import '../models/study_task.dart';

/// Pure analytics over the user's real records. No state, no I/O — every number
/// shown on the dashboard and analysis screens is derived here so it can be unit
/// tested and can never become a hard-coded "fake" metric.
bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Aggregated, real metrics for the dashboard.
class DashboardStats {
  const DashboardStats({
    required this.todayCompletedTasks,
    required this.todayTotalTasks,
    required this.todayStudyMinutes,
    required this.todayFocusSessions,
    required this.weeklyStudyHours,
  });

  final int todayCompletedTasks;
  final int todayTotalTasks;
  final int todayStudyMinutes;
  final int todayFocusSessions;

  /// Monday→Sunday study hours for the active week.
  final List<double> weeklyStudyHours;

  double get todayCompletionRatio =>
      todayTotalTasks == 0 ? 0 : todayCompletedTasks / todayTotalTasks;

  double get todayStudyHours => todayStudyMinutes / 60;

  static DashboardStats compute({
    required List<StudyTask> tasks,
    required List<FocusSession> sessions,
    required DateTime today,
    required DateTime weekStart,
  }) {
    final todays = tasks
        .where((t) => _sameDay(t.scheduledDate, today))
        .toList();
    final todaySessions = sessions
        .where((s) => _sameDay(s.startedAt, today))
        .toList();
    final weekStartDate = _dateOnly(weekStart);
    final weekly = List<double>.filled(7, 0);
    for (final session in sessions) {
      final day = _dateOnly(session.startedAt);
      final index = day.difference(weekStartDate).inDays;
      if (index >= 0 && index < 7) {
        weekly[index] += session.durationMinutes / 60;
      }
    }
    return DashboardStats(
      todayCompletedTasks: todays.where((t) => t.completed).length,
      todayTotalTasks: todays.length,
      todayStudyMinutes: todaySessions.fold(
        0,
        (sum, s) => sum + s.durationMinutes,
      ),
      todayFocusSessions: todaySessions.length,
      weeklyStudyHours: weekly,
    );
  }
}

/// Per-subject roll-up across every exam of a given type.
class SubjectStat {
  const SubjectStat({
    required this.subject,
    required this.correct,
    required this.wrong,
    required this.blank,
    required this.net,
  });

  final String subject;
  final int correct;
  final int wrong;
  final int blank;
  final double net;

  int get questionCount => correct + wrong + blank;

  /// Net success rate in 0..1, used for the progress bars.
  double get successRate =>
      questionCount == 0 ? 0 : (net / questionCount).clamp(0, 1);

  String get detailLabel => '$correct D / $wrong Y';
}

/// Aggregated analysis metrics for one exam type (TYT/AYT).
class AnalysisStats {
  const AnalysisStats({
    required this.exams,
    required this.averageNet,
    required this.subjects,
    required this.weakest,
    required this.netSeries,
  });

  final List<PracticeExam> exams; // newest first
  final double averageNet;
  final List<SubjectStat> subjects;
  final SubjectStat? weakest;
  final List<double> netSeries; // oldest → newest

  int get examCount => exams.length;

  static AnalysisStats compute(List<PracticeExam> allExams, String type) {
    final filtered = allExams.where((exam) => exam.type == type).toList()
      ..sort((a, b) => b.takenAt.compareTo(a.takenAt));

    final average = filtered.isEmpty
        ? 0.0
        : filtered.map((e) => e.totalNet).reduce((a, b) => a + b) /
              filtered.length;

    final bySubject = <String, List<ExamSubjectResult>>{};
    for (final exam in filtered) {
      for (final result in exam.subjects) {
        bySubject.putIfAbsent(result.subject, () => []).add(result);
      }
    }
    final subjects = bySubject.entries.map((entry) {
      final results = entry.value;
      return SubjectStat(
        subject: entry.key,
        correct: results.fold(0, (s, r) => s + r.correct),
        wrong: results.fold(0, (s, r) => s + r.wrong),
        blank: results.fold(0, (s, r) => s + r.blank),
        net: results.fold(0.0, (s, r) => s + r.net),
      );
    }).toList()..sort((a, b) => b.net.compareTo(a.net));

    final withQuestions = subjects.where((s) => s.questionCount > 0).toList();
    SubjectStat? weakest;
    if (withQuestions.isNotEmpty) {
      weakest = withQuestions.reduce(
        (a, b) => a.successRate <= b.successRate ? a : b,
      );
    }

    // Chronological net series (oldest → newest), last 10.
    final series = filtered.reversed.map((exam) => exam.totalNet).toList();
    final trimmed = series.length > 10
        ? series.sublist(series.length - 10)
        : series;

    return AnalysisStats(
      exams: filtered,
      averageNet: average,
      subjects: subjects,
      weakest: weakest,
      netSeries: trimmed,
    );
  }
}
