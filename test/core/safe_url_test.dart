// UNIT tests: only approved schemes may be handed to the operating system (audit follow-up).
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/core/security/safe_url.dart';

void main() {
  group('web links (https only)', () {
    test('accepts a well-formed https URL and trims it', () {
      expect(
        parseAllowedUri('  https://sevanest.in/terms?lang=en ')?.toString(),
        'https://sevanest.in/terms?lang=en',
      );
      expect(parseAllowedUri('HTTPS://sevanest.in/p')?.scheme, 'https');
    });

    test('rejects other schemes, even though they have a scheme', () {
      for (final bad in [
        'http://sevanest.in/terms',
        'intent://scan/#Intent;scheme=zxing;end',
        'file:///data/data/com.sevanest.customer/shared_prefs/x.xml',
        'javascript:alert(1)',
        'data:text/html;base64,PGgxPmhpPC9oMT4=',
        'sevanest://payments/new?bookingId=b1',
        'market://details?id=com.sevanest.customer',
        'tel:+911234567890',
        'content://media/external/images/1',
      ]) {
        expect(parseAllowedUri(bad), isNull, reason: bad);
      }
    });

    test('rejects malformed, relative and unsafe input', () {
      for (final bad in [
        null,
        '',
        '   ',
        'sevanest.in/terms',
        '/terms',
        'https://',
        'https:///path-without-host',
        'https://user:pw@sevanest.in/',
        'https://sevanest.in/a b',
        'https://sevanest.in/a\nb',
        'https://sevanest.in/\u0000',
        'https://[not-a-host/',
        'https://sevanest.in/${'a' * 3000}',
      ]) {
        expect(parseAllowedUri(bad), isNull, reason: '$bad');
      }
    });
  });

  group('store links (https or market)', () {
    test('accepts the https listing and the Play Store app link', () {
      expect(
        parseAllowedUri(
          'https://play.google.com/store/apps/details?id=com.sevanest.customer',
          schemes: storeSchemes,
        ),
        isNotNull,
      );
      expect(
        parseAllowedUri(
          'market://details?id=com.sevanest.customer',
          schemes: storeSchemes,
        ),
        isNotNull,
      );
    });

    test('still rejects intent:, http: and custom app schemes', () {
      for (final bad in [
        'intent://details?id=x#Intent;scheme=market;end',
        'http://play.google.com/store',
        'sevanest://update',
        'file:///sdcard/x.apk',
      ]) {
        expect(
          parseAllowedUri(bad, schemes: storeSchemes),
          isNull,
          reason: bad,
        );
      }
    });
  });

  group('contact links (tel / mailto built by the app)', () {
    test('allows tel and mailto with a value', () {
      expect(
        isAllowedUri(
          Uri(scheme: 'tel', path: '+911234567890'),
          schemes: contactSchemes,
        ),
        isTrue,
      );
      expect(
        isAllowedUri(
          Uri(scheme: 'mailto', path: 'help@sevanest.in'),
          schemes: contactSchemes,
        ),
        isTrue,
      );
    });

    test('refuses an empty value or any other scheme', () {
      expect(
        isAllowedUri(Uri(scheme: 'tel'), schemes: contactSchemes),
        isFalse,
      );
      expect(
        isAllowedUri(Uri.parse('sms:+911234567890'), schemes: contactSchemes),
        isFalse,
      );
      expect(
        isAllowedUri(Uri.parse('https://sevanest.in'), schemes: contactSchemes),
        isFalse,
      );
    });
  });
}
