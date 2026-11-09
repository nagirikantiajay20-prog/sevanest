import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/app/router/redirect.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/core/session/auth_state.dart';

String? go(
  String location, {
  AuthStatus auth = AuthStatus.authenticated,
  bool? profileComplete = true,
  bool allowDev = true,
}) => resolveRedirect(
  auth: auth,
  profileComplete: profileComplete,
  location: Uri.parse(location).path,
  uri: Uri.parse(location),
  allowDev: allowDev,
);

void main() {
  group('route parameters', () {
    test('plain backend ids pass', () {
      for (final l in [
        '/bookings/bk_2100',
        '/payments/new?bookingId=3f2c9a1e-7b44-4d0a-9c11-0a1b2c3d4e5f',
        '/payments/pay_123',
        '/workers/wrk-9/reviews',
        '/interviews/new?workerId=w1',
        '/payments/new?bookingId=',
      ]) {
        expect(go(l), isNull, reason: l);
      }
    });

    test('odd path segments or id values are sent Home', () {
      for (final l in [
        '/bookings/..%2Fadmin',
        '/bookings/a%20b',
        '/bookings/${'x' * 65}',
        '/payments/new?bookingId=1;DROP',
        '/payments/new?bookingId=http://evil.example',
        '/interviews/new?workerId=%3Cscript%3E',
      ]) {
        expect(go(l), Routes.home, reason: l);
      }
    });

    test('a bad id never bypasses the sign-in requirement', () {
      expect(
        go('/payments/new?bookingId=a%20b', auth: AuthStatus.unauthenticated),
        Routes.login,
      );
      expect(go('/payments/pay_1', auth: AuthStatus.unknown), Routes.splash);
    });

    test('signed-out users cannot open protected screens by link', () {
      for (final l in [
        '/payments/new?bookingId=b1',
        '/bookings/bk_1',
        '/transactions/t1',
        '/replacements/r1',
      ]) {
        expect(go(l, auth: AuthStatus.unauthenticated), Routes.login);
      }
    });
  });

  group('developer routes', () {
    test('open when the build allows them, closed otherwise', () {
      expect(go(Routes.devGallery), isNull);
      expect(go(Routes.devGallery, allowDev: false), Routes.home);
      expect(go(Routes.devPushDiagnostics, allowDev: false), Routes.home);
    });
  });

  test('hasUnsafeRouteParams', () {
    expect(hasUnsafeRouteParams(Uri.parse('/bookings/abc_1')), isFalse);
    expect(hasUnsafeRouteParams(Uri.parse('/bookings/a.b')), isTrue);
    expect(
      hasUnsafeRouteParams(Uri.parse('/x?note=any text allowed')),
      isFalse,
    );
  });
}
