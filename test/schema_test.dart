import 'package:flutter_test/flutter_test.dart';
import 'package:yks_coach/services/schema.dart';

void main() {
  group('migrateUserData', () {
    test('stamps the current version on legacy documents without one', () {
      final migrated = migrateUserData({'userName': 'Ada'});
      expect(migrated['schemaVersion'], kCurrentSchemaVersion);
      expect(migrated['userName'], 'Ada');
    });

    test('leaves an already-current document at the current version', () {
      final migrated = migrateUserData({
        'schemaVersion': kCurrentSchemaVersion,
        'userName': 'Ada',
      });
      expect(migrated['schemaVersion'], kCurrentSchemaVersion);
    });

    test('does not mutate the input map', () {
      final input = <String, dynamic>{'userName': 'Ada'};
      migrateUserData(input);
      expect(input.containsKey('schemaVersion'), isFalse);
    });
  });
}
