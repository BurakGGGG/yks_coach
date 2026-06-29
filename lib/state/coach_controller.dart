import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/repositories.dart';
import '../models/coach_message.dart';

/// Owns the coach conversation (`users/{uid}/coachMessages`).
///
/// Until the server-side Gemini coach (Phase 4) lands, replies are produced by a
/// small local helper that gives generic study guidance and never fabricates
/// metrics. Phase 4 replaces [_localReply] with the `askCoach` callable.
class CoachController extends ChangeNotifier {
  CoachController(this._repository) {
    _subscription = _repository.watch().listen(_onMessages);
  }

  final CoachRepository _repository;
  late final StreamSubscription<List<CoachMessage>> _subscription;

  List<CoachMessage> _messages = const [];
  bool _typing = false;

  List<CoachMessage> get messages => _messages;
  bool get typing => _typing;

  void _onMessages(List<CoachMessage> messages) {
    _messages = messages;
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    final value = text.trim();
    if (value.isEmpty || _typing) return;
    await _repository.add(
      CoachMessage(text: value, fromUser: true, createdAt: DateTime.now()),
    );
    _typing = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 600));
    await _repository.add(
      CoachMessage(
        text: _localReply(value),
        fromUser: false,
        createdAt: DateTime.now(),
      ),
    );
    _typing = false;
    notifyListeners();
  }

  Future<void> clearHistory() => _repository.clear();

  String _localReply(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('program') || lower.contains('plan')) {
      return 'Programını Program sekmesinden oluşturabilirsin. Bugün için '
          'ulaşılabilir 2-3 oturum belirleyip ilkini Odak sekmesinden '
          'başlatmanı öneririm.';
    }
    if (lower.contains('motiv') || lower.contains('yorul')) {
      return 'Kısa bir mola ver ve yalnızca bir sonraki 25 dakikaya odaklan. '
          'Küçük, tamamlanabilir hedefler çalışma isteğini geri getirir.';
    }
    if (lower.contains('net') || lower.contains('deneme')) {
      return 'Denemelerini Analiz sekmesine ekledikçe ders bazında gelişimini '
          'birlikte yorumlayabiliriz. En çok yanlış yaptığın konuları '
          'önceliklendirmen faydalı olur.';
    }
    return 'Bunu birlikte çalışma planına çevirebiliriz. Hangi derse ve bugün '
        'ne kadar süre ayırabileceğini yazarsan net bir oturum önereyim.';
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
