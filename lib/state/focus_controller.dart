import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/repositories.dart';
import '../models/focus_session.dart';

const _breakMinutes = {'shortBreak': 5, 'longBreak': 15};

/// Drives the Pomodoro timer from the real wall clock rather than a ticking
/// counter, so the remaining time stays correct after the app is backgrounded.
/// Completed focus blocks are persisted to `users/{uid}/focusSessions`.
class FocusController extends ChangeNotifier {
  FocusController(
    this._repository, {
    required int focusMinutes,
    String? subject,
    this.onFocusMinutesChanged,
    DateTime Function()? now,
  }) : _subject = subject ?? '',
       _now = now ?? DateTime.now {
    _focusMinutes = focusMinutes;
    _remaining = _modeSeconds;
    _subscription = _repository.watch().listen(_onSessions);
  }

  final FocusRepository _repository;
  final ValueChanged<int>? onFocusMinutesChanged;
  final DateTime Function() _now;
  late final StreamSubscription<List<FocusSession>> _subscription;

  late int _focusMinutes;
  String _subject;
  String _mode = 'focus';
  bool _running = false;
  DateTime? _endAt;
  int _remaining = 0;
  Timer? _ticker;
  List<FocusSession> _sessions = const [];

  int get focusMinutes => _focusMinutes;
  String get subject => _subject;
  String get mode => _mode;
  bool get running => _running;
  List<FocusSession> get sessions => _sessions;

  int get _modeMinutes => _breakMinutes[_mode] ?? _focusMinutes;
  int get _modeSeconds => _modeMinutes * 60;
  int get totalSeconds => _modeSeconds;

  int get remainingSeconds {
    if (_running && _endAt != null) {
      final left = _endAt!.difference(_now()).inSeconds;
      return left < 0 ? 0 : left;
    }
    return _remaining;
  }

  int get todaySessionCount {
    final now = _now();
    return _sessions.where((s) => _sameDay(s.startedAt, now)).length;
  }

  int get todayMinutes {
    final now = _now();
    return _sessions
        .where((s) => _sameDay(s.startedAt, now))
        .fold(0, (sum, s) => sum + s.durationMinutes);
  }

  void _onSessions(List<FocusSession> sessions) {
    _sessions = sessions;
    notifyListeners();
  }

  void selectSubject(String subject) {
    _subject = subject;
    notifyListeners();
  }

  void setMode(String mode) {
    _mode = mode;
    _running = false;
    _endAt = null;
    _remaining = _modeSeconds;
    _stopTicker();
    notifyListeners();
  }

  /// Applies the user's saved focus-length preference without persisting it
  /// back (used to sync from the profile). No-op while a timer is running.
  void applyPreferredMinutes(int minutes) {
    if (_running || minutes == _focusMinutes) return;
    _focusMinutes = minutes;
    if (_mode == 'focus') _remaining = _modeSeconds;
    notifyListeners();
  }

  void setFocusMinutes(int minutes) {
    _focusMinutes = minutes;
    _mode = 'focus';
    _running = false;
    _endAt = null;
    _remaining = _modeSeconds;
    _stopTicker();
    notifyListeners();
    onFocusMinutesChanged?.call(minutes);
  }

  void toggleTimer() => _running ? pause() : start();

  void start() {
    if (_running) return;
    if (_remaining <= 0) _remaining = _modeSeconds;
    _running = true;
    _endAt = _now().add(Duration(seconds: _remaining));
    _startTicker();
    notifyListeners();
  }

  void pause() {
    if (!_running) return;
    _remaining = remainingSeconds;
    _running = false;
    _endAt = null;
    _stopTicker();
    notifyListeners();
  }

  void reset() {
    _running = false;
    _endAt = null;
    _remaining = _modeSeconds;
    _stopTicker();
    notifyListeners();
  }

  /// Re-checks the clock (call on app resume) and finalises a session that
  /// elapsed while the app was backgrounded.
  void syncWithClock() {
    if (_running && remainingSeconds <= 0) {
      _complete();
    } else {
      notifyListeners();
    }
  }

  void _tick() {
    if (!_running) return;
    if (remainingSeconds <= 0) {
      _complete();
    } else {
      notifyListeners();
    }
  }

  void _complete() {
    final wasFocus = _mode == 'focus';
    _running = false;
    _endAt = null;
    _remaining = _modeSeconds;
    _stopTicker();
    if (wasFocus) {
      final ended = _now();
      final started = ended.subtract(Duration(minutes: _focusMinutes));
      unawaited(
        _repository.add(
          FocusSession(subject: _subject, startedAt: started, endedAt: ended),
        ),
      );
    }
    notifyListeners();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  void dispose() {
    _stopTicker();
    _subscription.cancel();
    super.dispose();
  }
}
