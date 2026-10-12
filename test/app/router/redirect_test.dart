import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/app/router/redirect.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/core/session/auth_state.dart';

String? r(AuthStatus a, bool? p, String loc) =>
    resolveRedirect(auth: a, profileComplete: p, location: loc);

void main() {
  test('unknown auth parks on splash', () {
    expect(r(AuthStatus.unknown, null, Routes.home), Routes.splash);
    expect(r(AuthStatus.unknown, null, Routes.splash), isNull);
  });

  test('unauthenticated can only see login/otp', () {
    expect(r(AuthStatus.unauthenticated, null, Routes.splash), Routes.login);
    expect(r(AuthStatus.unauthenticated, null, Routes.bookings), Routes.login);
    expect(r(AuthStatus.unauthenticated, null, Routes.login), isNull);
    expect(r(AuthStatus.unauthenticated, null, Routes.otp), isNull);
  });

  test('authenticated + incomplete profile is forced to setup', () {
    expect(
      r(AuthStatus.authenticated, false, Routes.home),
      Routes.profileSetup,
    );
    expect(r(AuthStatus.authenticated, false, Routes.profileSetup), isNull);
    expect(r(AuthStatus.authenticated, false, Routes.addressNew), isNull);
  });

  test('authenticated + complete profile leaves auth screens', () {
    expect(r(AuthStatus.authenticated, true, Routes.splash), Routes.home);
    expect(r(AuthStatus.authenticated, true, Routes.login), Routes.home);
    expect(r(AuthStatus.authenticated, true, Routes.profileSetup), Routes.home);
    expect(r(AuthStatus.authenticated, true, Routes.bookings), isNull);
  });

  test('authenticated with unknown profile waits on splash', () {
    expect(r(AuthStatus.authenticated, null, Routes.splash), isNull);
  });

  test('dev routes are never redirected', () {
    expect(r(AuthStatus.unauthenticated, null, Routes.devGallery), isNull);
  });
}
