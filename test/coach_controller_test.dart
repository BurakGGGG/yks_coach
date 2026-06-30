import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yks_coach/data/repositories.dart';
import 'package:yks_coach/models/coach_message.dart';
import 'package:yks_coach/services/coach_service.dart';
import 'package:yks_coach/state/coach_controller.dart';

void main() {
  test('sunucu kotası controller durumuna yansır', () async {
    final repository = _FakeCoachRepository();
    final gateway = _FakeCoachGateway();
    final controller = CoachController(repository, gateway: gateway);
    addTearDown(() async {
      controller.dispose();
      await repository.close();
    });

    await controller.sendMessage('Bugün ne çalışmalıyım?');

    expect(gateway.lastMessage, 'Bugün ne çalışmalıyım?');
    expect(controller.remainingDailyQuota, 11);
    expect(controller.errorMessage, isNull);
    expect(controller.typing, isFalse);
  });

  test('günlük kota hatası kullanıcıya güvenli metinle gösterilir', () async {
    final repository = _FakeCoachRepository();
    final gateway = _FakeCoachGateway(quotaExceeded: true);
    final controller = CoachController(repository, gateway: gateway);
    addTearDown(() async {
      controller.dispose();
      await repository.close();
    });

    await controller.sendMessage('Bir soru daha');

    expect(
      controller.errorMessage,
      'Günlük 20 mesaj hakkını kullandın. Yarın tekrar deneyebilirsin.',
    );
    expect(controller.typing, isFalse);
    expect(repository.addCalls, 0);
  });
}

class _FakeCoachGateway implements CoachGateway {
  _FakeCoachGateway({this.quotaExceeded = false});

  final bool quotaExceeded;
  String? lastMessage;

  @override
  Future<CoachReply> ask({
    required String message,
    required String conversationId,
  }) async {
    lastMessage = message;
    if (quotaExceeded) {
      throw FirebaseFunctionsException(
        code: 'resource-exhausted',
        message: 'quota exceeded',
      );
    }
    return CoachReply(
      messageId: 'answer-1',
      answer: 'Yanıt',
      remainingDailyQuota: 11,
      createdAt: DateTime(2026, 6, 30),
    );
  }

  @override
  Future<void> clearHistory() async {}
}

class _FakeCoachRepository implements CoachRepository {
  final _messages = StreamController<List<CoachMessage>>.broadcast();
  int addCalls = 0;

  @override
  Stream<List<CoachMessage>> watch() => _messages.stream;

  @override
  Future<void> add(CoachMessage message) async {
    addCalls++;
  }

  @override
  Future<void> clear() async {}

  Future<void> close() => _messages.close();
}
