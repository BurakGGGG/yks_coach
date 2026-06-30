import 'package:cloud_functions/cloud_functions.dart';

abstract interface class AccountGateway {
  Future<void> deleteAccount();
}

class FirebaseAccountGateway implements AccountGateway {
  FirebaseAccountGateway({FirebaseFunctions? functions})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1');

  final FirebaseFunctions _functions;

  @override
  Future<void> deleteAccount() async {
    final result = await _functions
        .httpsCallable(
          'deleteAccount',
          options: HttpsCallableOptions(
            timeout: const Duration(minutes: 6),
            limitedUseAppCheckToken: true,
          ),
        )
        .call<Map<String, dynamic>>();
    if (result.data['deleted'] != true) {
      throw const FormatException('Geçersiz deleteAccount yanıtı');
    }
  }
}
