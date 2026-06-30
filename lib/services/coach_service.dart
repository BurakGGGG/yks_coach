import 'package:cloud_functions/cloud_functions.dart';

class CoachReply {
  const CoachReply({
    required this.messageId,
    required this.answer,
    required this.remainingDailyQuota,
    required this.createdAt,
  });

  final String messageId;
  final String answer;
  final int remainingDailyQuota;
  final DateTime createdAt;
}

abstract interface class CoachGateway {
  Future<CoachReply> ask({
    required String message,
    required String conversationId,
  });
  Future<void> clearHistory();
}

/// Calls the App Check-protected `askCoach` v2 function. Authentication and
/// App Check tokens are attached by the Firebase callable SDK.
class FirebaseCoachGateway implements CoachGateway {
  FirebaseCoachGateway({FirebaseFunctions? functions})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1');

  final FirebaseFunctions _functions;

  @override
  Future<CoachReply> ask({
    required String message,
    required String conversationId,
  }) async {
    final callable = _functions.httpsCallable(
      'askCoach',
      options: HttpsCallableOptions(
        timeout: const Duration(seconds: 70),
        limitedUseAppCheckToken: true,
      ),
    );
    final response = await callable.call<Map<String, dynamic>>({
      'message': message,
      'conversationId': conversationId,
    });
    final data = response.data;
    final id = data['messageId'];
    final answer = data['answer'];
    final quota = data['remainingDailyQuota'];
    if (id is! String || answer is! String || quota is! num) {
      throw const FormatException('Geçersiz askCoach yanıtı');
    }
    return CoachReply(
      messageId: id,
      answer: answer,
      remainingDailyQuota: quota.toInt(),
      createdAt:
          DateTime.tryParse(data['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  @override
  Future<void> clearHistory() async {
    await _functions
        .httpsCallable(
          'clearCoachHistory',
          options: HttpsCallableOptions(limitedUseAppCheckToken: true),
        )
        .call<void>();
  }
}
