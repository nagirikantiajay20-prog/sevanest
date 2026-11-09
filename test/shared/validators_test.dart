// UNIT tests (PROF-01): client-side validators.
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/shared/utils/validators.dart';

void main() {
  _extra();
  test('name: 2-60 letters, spaces and . \' -', () {
    expect(isValidName('Priya Sharma'), isTrue);
    expect(isValidName("D'Souza-Rao Jr."), isTrue);
    expect(isValidName('प्रिया शर्मा'), isTrue);
    expect(isValidName('A'), isFalse);
    expect(isValidName('  A '), isFalse);
    expect(isValidName(''), isFalse);
    expect(isValidName('Priya 123'), isFalse);
    expect(isValidName('a' * 61), isFalse);
    expect(isValidName('a' * 60), isTrue);
  });

  test('email: basic shape, trimmed', () {
    expect(isValidEmail('priya.sharma@gmail.com'), isTrue);
    expect(isValidEmail(' a@b.co '), isTrue);
    expect(isValidEmail('priya.sharma@gmail'), isFalse);
    expect(isValidEmail('priya sharma@gmail.com'), isFalse);
    expect(isValidEmail(''), isFalse);
  });

  test('pincode: exactly 6 digits, not starting with 0', () {
    expect(isValidPincode('500081'), isTrue);
    expect(isValidPincode('5000'), isFalse);
    expect(isValidPincode('5000811'), isFalse);
    expect(isValidPincode('050081'), isFalse);
    expect(isValidPincode('50008a'), isFalse);
  });
}

void _extra() {
  test('blank / max / otp / range helpers', () {
    expect(isBlank('   '), isTrue);
    expect(isBlank(null), isTrue);
    expect(isBlank(' a '), isFalse);
    expect(withinMax(' ${'a' * 300} ', 300), isTrue);
    expect(withinMax('a' * 301, 300), isFalse);
    expect(isValidOtp('123456', 6), isTrue);
    expect(isValidOtp('12345', 6), isFalse);
    expect(isValidOtp('12a456', 6), isFalse);
    expect(isValidRange(null, null), isTrue);
    expect(isValidRange(100, 100), isTrue);
    expect(isValidRange(500, 100), isFalse);
    expect(isValidRange(-1, 100), isFalse);
  });
}
