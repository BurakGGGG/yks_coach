import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yks_coach/models/focus_session.dart';
import 'package:yks_coach/models/practice_exam.dart';
import 'package:yks_coach/models/study_task.dart';
import 'package:yks_coach/models/user_profile.dart';
import 'package:yks_coach/state/analytics.dart';

void main() {
  group('net hesabı (doğru - yanlış / 4)', () {
    test('yanlışlar dörtte bir oranında düşülür', () {
      const result = ExamSubjectResult(
        subject: 'Matematik',
        correct: 30,
        wrong: 4,
        blank: 6,
      );
      expect(result.net, 29);
      expect(result.questionCount, 40);
    });

    test('net negatif olmaz', () {
      const result = ExamSubjectResult(
        subject: 'Fizik',
        correct: 1,
        wrong: 8,
        blank: 0,
      );
      expect(result.net, 0);
    });

    test('toplam net ders netlerinin toplamıdır', () {
      final exam = PracticeExam(
        name: 'Deneme',
        type: 'TYT',
        takenAt: DateTime(2026, 1, 1),
        subjects: const [
          ExamSubjectResult(subject: 'Matematik', correct: 30, wrong: 4, blank: 6),
          ExamSubjectResult(subject: 'Türkçe', correct: 35, wrong: 0, blank: 5),
        ],
      );
      expect(exam.totalNet, 64);
      expect(exam.totalQuestions, 80);
    });
  });

  group('AnalysisStats', () {
    PracticeExam exam(String id, DateTime date, int mCorrect, int mWrong) {
      return PracticeExam(
        id: id,
        name: id,
        type: 'TYT',
        takenAt: date,
        subjects: [
          ExamSubjectResult(subject: 'Matematik', correct: mCorrect, wrong: mWrong, blank: 0),
          const ExamSubjectResult(subject: 'Türkçe', correct: 35, wrong: 0, blank: 5),
        ],
      );
    }

    test('ortalama, seri (eskiden yeniye) ve zayıf ders doğru hesaplanır', () {
      final exams = [
        exam('eski', DateTime(2026, 1, 1), 30, 4), // net 29 + 35 = 64
        exam('yeni', DateTime(2026, 2, 1), 20, 8), // net 18 + 35 = 53
      ];
      final stats = AnalysisStats.compute(exams, 'TYT');

      expect(stats.examCount, 2);
      expect(stats.averageNet, closeTo(58.5, 0.001));
      expect(stats.netSeries, [64, 53]); // oldest → newest
      expect(stats.weakest?.subject, 'Matematik');
    });

    test('diğer türü dışlar', () {
      final exams = [
        exam('tyt', DateTime(2026, 1, 1), 30, 4),
        PracticeExam(
          name: 'ayt',
          type: 'AYT',
          takenAt: DateTime(2026, 1, 2),
          subjects: const [
            ExamSubjectResult(subject: 'Matematik', correct: 10, wrong: 0, blank: 0),
          ],
        ),
      ];
      expect(AnalysisStats.compute(exams, 'TYT').examCount, 1);
      expect(AnalysisStats.compute(exams, 'AYT').examCount, 1);
    });
  });

  group('DashboardStats', () {
    test('bugünün çalışma süresi ve haftalık dağılım gerçek kayıtlardan gelir', () {
      final monday = DateTime(2026, 6, 29); // a Monday
      final today = monday;
      FocusSession session(DateTime start, int minutes) => FocusSession(
        subject: 'Matematik',
        startedAt: start,
        endedAt: start.add(Duration(minutes: minutes)),
      );

      final tasks = [
        StudyTask(
          subject: 'Matematik',
          title: 'Türev',
          scheduledDate: today,
          startMinutes: 540,
          endMinutes: 600,
          color: const Color(0xFF2563EB),
          status: TaskStatus.completed,
        ),
        StudyTask(
          subject: 'Fizik',
          title: 'Hareket',
          scheduledDate: today,
          startMinutes: 600,
          endMinutes: 660,
          color: const Color(0xFF0EA5E9),
        ),
      ];
      final sessions = [
        session(today.add(const Duration(hours: 9)), 25),
        session(today.add(const Duration(hours: 10)), 25),
        session(monday.add(const Duration(days: 2, hours: 9)), 50), // Wednesday
      ];

      final stats = DashboardStats.compute(
        tasks: tasks,
        sessions: sessions,
        today: today,
        weekStart: monday,
      );

      expect(stats.todayTotalTasks, 2);
      expect(stats.todayCompletedTasks, 1);
      expect(stats.todayCompletionRatio, 0.5);
      expect(stats.todayStudyMinutes, 50);
      expect(stats.todayFocusSessions, 2);
      expect(stats.weeklyStudyHours[0], closeTo(50 / 60, 0.001)); // Monday
      expect(stats.weeklyStudyHours[2], closeTo(50 / 60, 0.001)); // Wednesday
    });
  });

  group('model dönüşümleri', () {
    test('StudyTask saat etiketleri', () {
      final task = StudyTask(
        subject: 'Matematik',
        title: 'Türev',
        scheduledDate: DateTime(2026, 6, 29),
        startMinutes: 9 * 60,
        endMinutes: 10 * 60 + 30,
        color: const Color(0xFF2563EB),
      );
      expect(task.startLabel, '09:00');
      expect(task.endLabel, '10:30');
      expect(task.timeLabel, '09:00 - 10:30');
      expect(task.durationMinutes, 90);
    });

    test('UserProfile eski belgeye schemaVersion ekler ve onboarding kapalıdır', () {
      final profile = UserProfile.fromMap({'userName': 'Ada'});
      expect(profile.userName, 'Ada');
      expect(profile.schemaVersion, 1);
      expect(profile.onboardingCompleted, isFalse);
      expect(profile.reminderTime.hour, 19);
    });

    test('UserProfile round-trips through toMap', () {
      const profile = UserProfile(
        userName: 'Ada',
        grade: '12. Sınıf',
        onboardingCompleted: true,
        targetRank: 5000,
      );
      final restored = UserProfile.fromMap(
        Map<String, dynamic>.from(profile.toMap()),
      );
      expect(restored.userName, 'Ada');
      expect(restored.grade, '12. Sınıf');
      expect(restored.onboardingCompleted, isTrue);
      expect(restored.targetRank, 5000);
    });
  });
}
