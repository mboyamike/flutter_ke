import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/services/validator_service/validator_service.dart';

void main() {
  group('validator service tests ...', () {
    test('Empty email is not valid', () {
      expect(ValidatorService.emailFormatValidator(''), isNotNull);
    });
    test('various email formats', () {
      expect(ValidatorService.emailFormatValidator('user@gmail.com'), isNull);
      expect(ValidatorService.emailFormatValidator('user.name@gmail.com'), isNull);
      expect(ValidatorService.emailFormatValidator('user123.name@gmail.com'), isNull);
      expect(ValidatorService.emailFormatValidator('user123.name.21@gmail.com'), isNull);
    });
  });
}