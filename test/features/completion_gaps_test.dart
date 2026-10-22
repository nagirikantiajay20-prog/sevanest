import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/screens/account_deletion_screen.dart';
import 'package:sevanest_customer/features/interview_trial/domain/interview.dart';
import 'package:sevanest_customer/features/legal/legal_consent.dart';

void main() {
  group('DeletionRequest.parse', () {
    test('REQUESTED keeps the date', () {
      final r = DeletionRequest.parse({
        'status': 'REQUESTED',
        'requestedAt': '2026-10-15T10:00:00.000Z',
      });
      expect(r.status, DeletionStatus.requested);
      expect(r.requestedAt, isNotNull);
    });
    test('COMPLETED', () {
      expect(
        DeletionRequest.parse({'status': 'COMPLETED'}).status,
        DeletionStatus.completed,
      );
    });
    test('empty body, null and CANCELLED mean none', () {
      expect(DeletionRequest.parse(null).status, DeletionStatus.none);
      expect(DeletionRequest.parse('').status, DeletionStatus.none);
      expect(
        DeletionRequest.parse({'status': 'CANCELLED'}).status,
        DeletionStatus.none,
      );
    });
  });

  test('deletion is off unless ACCOUNT_DELETION is defined', () {
    expect(const bool.fromEnvironment('ACCOUNT_DELETION'), isFalse);
  });

  test('InterviewSlot end follows the server slot length', () {
    expect(const InterviewSlot('09:00').endMinutes, 9 * 60 + 60);
    expect(const InterviewSlot('09:00', minutes: 30).endMinutes, 9 * 60 + 30);
  });

  test('legal state is publishable only with both versions', () {
    expect(const LegalState(needsAcceptance: true).publishable, isFalse);
    expect(
      const LegalState(
        needsAcceptance: true,
        termsVersion: '1',
        privacyVersion: '1',
      ).publishable,
      isTrue,
    );
  });
}
