import 'package:flutter_test/flutter_test.dart';
import 'package:yks_coach/services/crash_reporting_service.dart';

void main() {
  test(
    'crash description excludes raw exception content and personal data',
    () {
      final description = sanitizedCrashDescription(
        StateError('user@example.com token=secret-token sohbet=kişisel mesaj'),
      );

      expect(description, contains('StateError'));
      expect(description, isNot(contains('user@example.com')));
      expect(description, isNot(contains('secret-token')));
      expect(description, isNot(contains('kişisel mesaj')));
    },
  );
}
