import 'package:flutter_test/flutter_test.dart';
import 'package:yks_coach/data/memory_store.dart';
import 'package:yks_coach/state/focus_controller.dart';

void main() {
  test('sayaç başlar, duraklar ve sıfırlanır (duvar saatinden)', () {
    var now = DateTime(2026, 6, 29, 9);
    final focus = FocusController(
      InMemoryFocusRepository(),
      focusMinutes: 25,
      now: () => now,
    );
    addTearDown(focus.dispose);

    expect(focus.remainingSeconds, 25 * 60);

    focus.start();
    expect(focus.running, isTrue);

    now = now.add(const Duration(minutes: 1));
    expect(focus.remainingSeconds, 24 * 60);

    focus.pause();
    expect(focus.running, isFalse);
    expect(focus.remainingSeconds, 24 * 60); // frozen on pause

    focus.reset();
    expect(focus.remainingSeconds, 25 * 60);
  });

  test('arka planda geçen süre tamamlanınca oturum kaydedilir', () async {
    var now = DateTime(2026, 6, 29, 9);
    final focus = FocusController(
      InMemoryFocusRepository(),
      focusMinutes: 25,
      subject: 'Matematik',
      now: () => now,
    );
    addTearDown(focus.dispose);

    focus.start();
    now = now.add(const Duration(minutes: 25)); // elapsed while "backgrounded"
    focus.syncWithClock();
    await Future<void>.delayed(const Duration(milliseconds: 5));

    expect(focus.running, isFalse);
    expect(focus.sessions, hasLength(1));
    expect(focus.sessions.first.subject, 'Matematik');
    expect(focus.sessions.first.durationMinutes, 25);
  });

  test('mola modu oturum olarak kaydedilmez', () async {
    var now = DateTime(2026, 6, 29, 9);
    final focus = FocusController(
      InMemoryFocusRepository(),
      focusMinutes: 25,
      now: () => now,
    );
    addTearDown(focus.dispose);

    focus.setMode('shortBreak');
    expect(focus.remainingSeconds, 5 * 60);
    focus.start();
    now = now.add(const Duration(minutes: 5));
    focus.syncWithClock();
    await Future<void>.delayed(const Duration(milliseconds: 5));

    expect(focus.sessions, isEmpty);
  });
}
