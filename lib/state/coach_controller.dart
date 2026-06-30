import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '../data/repositories.dart';
import '../models/coach_message.dart';
import '../services/coach_service.dart';

/// Owns the coach conversation (`users/{uid}/coachMessages`).
///
class CoachController extends ChangeNotifier {
  CoachController(this._repository, {this._gateway}) {
    _subscription = _repository.watch().listen(_onMessages);
  }

  final CoachRepository _repository;
  final CoachGateway? _gateway;
  late final StreamSubscription<List<CoachMessage>> _subscription;

  List<CoachMessage> _messages = const [];
  bool _typing = false;
  String? _errorMessage;
  int? _remainingDailyQuota;

  List<CoachMessage> get messages => _messages;
  bool get typing => _typing;
  String? get errorMessage => _errorMessage;
  int? get remainingDailyQuota => _remainingDailyQuota;

  void _onMessages(List<CoachMessage> messages) {
    _messages = messages;
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    final value = text.trim();
    if (value.isEmpty || _typing) return;
    _errorMessage = null;
    _typing = true;
    notifyListeners();
    try {
      if (_gateway != null) {
        final reply = await _gateway.ask(
          message: value,
          conversationId: 'main',
        );
        _remainingDailyQuota = reply.remainingDailyQuota;
      } else {
        // Deterministic offline adapter for widget/unit tests. Production always
        // injects [FirebaseCoachGateway], so client code never fabricates AI
        // answers or writes assistant messages to Firestore.
        await _repository.add(
          CoachMessage(text: value, fromUser: true, createdAt: DateTime.now()),
        );
        await Future<void>.delayed(const Duration(milliseconds: 600));
        await _repository.add(
          CoachMessage(
            text: _localReply(value),
            fromUser: false,
            createdAt: DateTime.now(),
          ),
        );
      }
    } on Object catch (error) {
      _errorMessage = _messageFor(error);
    } finally {
      _typing = false;
      notifyListeners();
    }
  }

  Future<bool> clearHistory() async {
    _errorMessage = null;
    try {
      if (_gateway != null) {
        await _gateway.clearHistory();
      } else {
        await _repository.clear();
      }
      return true;
    } on Object catch (error) {
      _errorMessage = _messageFor(error);
      notifyListeners();
      return false;
    }
  }

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

  String _messageFor(Object error) {
    if (error is FirebaseFunctionsException) {
      return switch (error.code) {
        'resource-exhausted' =>
          'Günlük 20 mesaj hakkını kullandın. Yarın tekrar deneyebilirsin.',
        'unauthenticated' || 'permission-denied' =>
          'Güvenli oturum doğrulanamadı. Çıkış yapıp tekrar giriş yap.',
        'failed-precondition' =>
          error.message ?? 'Bu mesaja güvenli bir yanıt üretilemedi.',
        'invalid-argument' => 'Mesaj 1-2000 karakter olmalı.',
        'deadline-exceeded' => 'Koç yanıtı zaman aşımına uğradı. Tekrar dene.',
        _ => 'Koç şu anda yanıt veremiyor. Biraz sonra tekrar dene.',
      };
    }
    return 'Koç şu anda yanıt veremiyor. İnternet bağlantını kontrol et.';
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
