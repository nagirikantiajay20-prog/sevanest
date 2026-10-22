// WIDGET tests: the real app + router + screens, with a fake repository (no network).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/features/authentication/domain/auth_repository.dart';
import 'package:sevanest_customer/features/authentication/presentation/providers/auth_providers.dart';
import 'package:sevanest_customer/features/authentication/presentation/screens/login_screen.dart';
import 'package:sevanest_customer/features/authentication/presentation/screens/splash_screen.dart';

import '../../helpers/fakes.dart';

const _mobileField = Key('login_mobile_field');
const _getOtp = Key('login_get_otp_btn');
const _otpField = Key('otp_input_field');
const _verify = Key('otp_verify_btn');

/// The FilledButton behind a key that sits on an SnButton wrapper (or on the button itself).
FilledButton fb(WidgetTester t, Key key) {
  final inner = find.descendant(
    of: find.byKey(key),
    matching: find.byType(FilledButton),
  );
  return t.widget<FilledButton>(
    inner.evaluate().isNotEmpty ? inner : find.byKey(key),
  );
}

void main() {
  late FakeAuthRepository repo;
  late InMemorySessionStore store;

  Future<void> launch(WidgetTester t, {bool withSession = false}) async {
    useTestPhone(t);
    store = withSession
        ? InMemorySessionStore((access: 'a', refresh: 'r'))
        : InMemorySessionStore();
    await t.pumpWidget(testRootApp(store: store, repo: repo));
    await t.pumpAndSettle();
  }

  Future<void> typeMobile(WidgetTester t, String digits) async {
    await t.enterText(find.byKey(_mobileField), digits);
    await t.pump();
  }

  Future<void> requestOtp(
    WidgetTester t, {
    String digits = '9876543210',
  }) async {
    await typeMobile(t, digits);
    await t.tap(find.byKey(_getOtp));
    await t.pumpAndSettle();
  }

  setUp(() => repo = FakeAuthRepository());

  group('Splash (AUTH-12)', () {
    testWidgets('no session -> login', (t) async {
      await launch(t);
      expect(find.byKey(_mobileField), findsOneWidget);
      expect(repo.profileCalls, 0); // nothing to validate without a session
    });

    testWidgets('valid session + complete profile -> home', (t) async {
      repo.onProfile = () async => true;
      await launch(t, withSession: true);
      expect(find.byKey(const Key('home_find_worker_btn')), findsOneWidget);
    });

    testWidgets('valid session + incomplete profile -> profile setup', (
      t,
    ) async {
      repo.onProfile = () async => false;
      await launch(t, withSession: true);
      expect(find.byKey(const Key('profile_continue_btn')), findsOneWidget);
    });

    testWidgets('expired session (401) -> login and tokens cleared', (t) async {
      repo.onProfile = () async => throw const UnauthorizedFailure();
      await launch(t, withSession: true);
      expect(find.byKey(_mobileField), findsOneWidget);
      expect(await store.read(), isNull);
    });

    testWidgets('network failure -> retry card; retry recovers', (t) async {
      repo.onProfile = () async => throw const NetworkFailure();
      await launch(t, withSession: true);
      expect(find.text("Can't connect right now"), findsOneWidget);
      expect(find.byKey(const Key('splash_retry_btn')), findsOneWidget);
      expect(await store.read(), isNotNull); // session kept for a retry

      repo.onProfile = () async => true;
      await t.tap(find.byKey(const Key('splash_retry_btn')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('home_find_worker_btn')), findsOneWidget);
    });

    testWidgets('"Sign in again" clears the session and opens login', (
      t,
    ) async {
      repo.onProfile = () async => throw const ServerFailure();
      await launch(t, withSession: true);
      await t.tap(find.byKey(const Key('splash_login_btn')));
      await t.pumpAndSettle();
      expect(find.byKey(_mobileField), findsOneWidget);
      expect(await store.read(), isNull);
    });

    testWidgets('hanging request: loading -> slow -> failed (never blank)', (
      t,
    ) async {
      final never = Completer<bool>();
      repo.onProfile = () => never.future;
      useTestPhone(t);
      store = InMemorySessionStore((access: 'a', refresh: 'r'));
      await t.pumpWidget(testRootApp(store: store, repo: repo));
      await t.pump();
      expect(find.text('Getting things ready...'), findsOneWidget);

      await t.pump(splashSlowAfter + const Duration(milliseconds: 100));
      expect(
        find.text('Still loading. Your connection seems slow.'),
        findsOneWidget,
      );

      await t.pump(splashTimeout);
      await t.pumpAndSettle();
      expect(find.text("Can't connect right now"), findsOneWidget);
    });
  });

  group('Login', () {
    testWidgets('AUTH-02: Get OTP needs 10 digits; invalid shows error on tap', (
      t,
    ) async {
      await launch(t);
      expect(fb(t, _getOtp).onPressed, isNull);
      await typeMobile(t, '98765');
      expect(fb(t, _getOtp).onPressed, isNull);

      // Starts with 1: enabled (design), but rejected with an inline error and no request.
      await typeMobile(t, '1234567890');
      expect(fb(t, _getOtp).onPressed, isNotNull);
      await t.tap(find.byKey(_getOtp));
      await t.pump();
      expect(find.text('Enter a valid 10-digit mobile number'), findsOneWidget);
      expect(repo.requestCalls, 0);

      await typeMobile(t, '9876543210');
      expect(find.text('Enter a valid 10-digit mobile number'), findsNothing);
    });

    testWidgets('mobile field only accepts digits, caps at 10, groups 5+5', (
      t,
    ) async {
      await launch(t);
      await typeMobile(t, '98a76-54 32109999');
      expect(
        t.widget<TextField>(find.byKey(_mobileField)).controller!.text,
        '98765 43210',
      );
      expect(digitsOf('98765 43210'), '9876543210');
    });

    testWidgets(
      'AUTH-03: valid number -> request -> OTP screen with masked-free number',
      (t) async {
        await launch(t);
        await requestOtp(t);
        expect(repo.requestCalls, 1);
        expect(repo.lastMobile, '9876543210'); // digits only, no +91 / spaces
        expect(find.text('Verify your number'), findsOneWidget);
        expect(find.byKey(const Key('otp_mobile_text')), findsOneWidget);
        expect(find.text('+91 98765 43210'), findsOneWidget);
      },
    );

    testWidgets(
      'sending state: button shows "Sending code..." and ignores taps',
      (t) async {
        final gate = Completer<OtpChallenge>();
        repo.onRequest = (_) => gate.future;
        await launch(t);
        await typeMobile(t, '9876543210');
        await t.tap(find.byKey(_getOtp));
        await t.pump();
        expect(find.text('Sending code...'), findsOneWidget);
        await t.tap(find.byKey(_getOtp), warnIfMissed: false);
        await t.tap(find.byKey(_getOtp), warnIfMissed: false);
        await t.pump();
        expect(repo.requestCalls, 1);
        gate.complete(const OtpChallenge());
        await t.pumpAndSettle();
        expect(find.text('Verify your number'), findsOneWidget);
      },
    );

    testWidgets(
      'AUTH-04: 429 -> notice with the server wait, stays on login, then re-enables',
      (t) async {
        repo.onRequest = (_) async =>
            throw const RateLimitedFailure('slow', 45);
        await launch(t);
        await requestOtp(t);
        expect(find.byKey(_mobileField), findsOneWidget);
        expect(find.text("Couldn't send the code"), findsOneWidget);
        expect(
          find.text('Too many requests. Please try again in 00:45.'),
          findsOneWidget,
        );
        expect(fb(t, _getOtp).onPressed, isNull);

        await t.pump(const Duration(seconds: 45));
        expect(fb(t, _getOtp).onPressed, isNotNull);
      },
    );

    testWidgets('network failure -> design card, number kept, can retry', (
      t,
    ) async {
      repo.onRequest = (_) async => throw const NetworkFailure();
      await launch(t);
      await requestOtp(t);
      expect(find.text("Couldn't send the code"), findsOneWidget);
      expect(
        find.text('Check your internet connection and tap Get OTP again.'),
        findsOneWidget,
      );
      expect(
        t.widget<TextField>(find.byKey(_mobileField)).controller!.text,
        '98765 43210',
      );
      expect(fb(t, _getOtp).onPressed, isNotNull);
    });

    testWidgets(
      'backend message is shown for business errors (account type mismatch)',
      (t) async {
        repo.onRequest = (_) async => throw const ConflictFailure(
          'This mobile number is registered for a different type of account',
        );
        await launch(t);
        await requestOtp(t);
        expect(
          find.text(
            'This mobile number is registered for a different type of account',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'language sheet: English selected, other languages not selectable',
      (t) async {
        await launch(t);
        await t.tap(find.byKey(const Key('login_language_btn')));
        await t.pumpAndSettle();
        expect(find.text('Choose your language'), findsOneWidget);
        for (final l in [
          'English',
          'Hindi',
          'Telugu',
          'Tamil',
          'Kannada',
          'Marathi',
        ]) {
          expect(find.byKey(Key('language_$l')), findsOneWidget);
        }
        expect(
          t.widget<ListTile>(find.byKey(const Key('language_Hindi'))).enabled,
          isFalse,
        );
        await t.tap(find.byKey(const Key('language_close_btn')));
        await t.pumpAndSettle();
        expect(find.text('Choose your language'), findsNothing);
      },
    );

    testWidgets(
      'legal links: no URL defined yet -> friendly message, no crash',
      (t) async {
        await launch(t);
        final rich = t.widget<Text>(find.byKey(const Key('login_legal_text')));
        final spans = (rich.textSpan! as TextSpan).children!.cast<TextSpan>();
        final terms = spans.firstWhere((s) => s.text == 'Terms of service');
        (terms.recognizer! as dynamic).onTap();
        await t.pump();
        await t.pump(const Duration(milliseconds: 100));
        expect(find.text("This link isn't available yet."), findsOneWidget);
      },
    );
  });

  group('OTP', () {
    testWidgets(
      'countdown starts at the server value and ticks; resend after it ends',
      (t) async {
        repo.onRequest = (_) async =>
            const OtpChallenge(expiresInSeconds: 300, resendAfterSeconds: 30);
        await launch(t);
        await requestOtp(t);
        expect(find.byKey(const Key('otp_countdown_text')), findsOneWidget);
        expect(
          find.textContaining('00:30', findRichText: true),
          findsOneWidget,
        );
        expect(find.byKey(const Key('otp_resend_btn')), findsNothing);

        await t.pump(const Duration(seconds: 10));
        expect(
          find.textContaining('00:20', findRichText: true),
          findsOneWidget,
        );

        await t.pump(const Duration(seconds: 20));
        expect(find.byKey(const Key('otp_resend_btn')), findsOneWidget);
        expect(
          find.text("Didn't get it? Check your number or try again."),
          findsOneWidget,
        );
        expect(
          find.text(
            'We never share your number. This code expires in 5 minutes.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('Verify enables only with 6 digits; digits only', (t) async {
      await launch(t);
      await requestOtp(t);
      expect(fb(t, _verify).onPressed, isNull);
      await t.enterText(find.byKey(_otpField), '48a29');
      await t.pump();
      expect(fb(t, _verify).onPressed, isNull);
      await t.enterText(find.byKey(_otpField), '482913');
      await t.pump();
      expect(fb(t, _verify).onPressed, isNotNull);
    });

    testWidgets(
      'AUTH-09: verified + incomplete profile -> setup; OTP cannot be reached by back',
      (t) async {
        repo.onProfile = () async => false;
        await launch(t);
        await requestOtp(t);
        await t.enterText(find.byKey(_otpField), '123456');
        await t.pump();
        await t.tap(find.byKey(_verify));
        await t.pump();
        await t.pump();
        expect(
          find.text('Number verified'),
          findsOneWidget,
        ); // design "Verified" state
        await t.pump(verifiedHold);
        await t.pumpAndSettle();

        expect(find.byKey(const Key('profile_continue_btn')), findsOneWidget);
        expect(find.text('Verify your number'), findsNothing);
        expect(repo.lastOtp, '123456');
        expect(await store.read(), isNotNull);
        final navigator = t.state<NavigatorState>(find.byType(Navigator).first);
        expect(navigator.canPop(), isFalse);
      },
    );

    testWidgets('AUTH-10: verified + complete profile -> home', (t) async {
      repo.onProfile = () async => true;
      await launch(t);
      await requestOtp(t);
      await t.enterText(find.byKey(_otpField), '123456');
      await t.pump();
      await t.tap(find.byKey(_verify));
      await t.pump();
      await t.pump(verifiedHold);
      await t.pumpAndSettle();
      expect(find.byKey(const Key('home_find_worker_btn')), findsOneWidget);
    });

    testWidgets(
      'verifying state shows "Verifying..." and duplicate taps verify once',
      (t) async {
        final gate = Completer<AuthTokens>();
        repo.onVerify = (_, _) => gate.future;
        await launch(t);
        await requestOtp(t);
        await t.enterText(find.byKey(_otpField), '123456');
        await t.pump();
        await t.tap(find.byKey(_verify));
        await t.pump();
        expect(find.text('Verifying...'), findsOneWidget);
        await t.tap(find.byKey(_verify), warnIfMissed: false);
        await t.pump();
        expect(repo.verifyCalls, 1);
        gate.complete((access: 'a', refresh: 'r'));
        await t.pump(verifiedHold);
        await t.pumpAndSettle();
      },
    );

    testWidgets(
      'AUTH-06: wrong code -> inline error, stays on OTP, can retype',
      (t) async {
        repo.onVerify = (_, _) async =>
            throw const OtpFailure(OtpError.invalid);
        await launch(t);
        await requestOtp(t);
        await t.enterText(find.byKey(_otpField), '482193');
        await t.pump();
        await t.tap(find.byKey(_verify));
        await t.pumpAndSettle();
        expect(
          find.text("That code isn't correct. Please try again."),
          findsOneWidget,
        );
        expect(find.text('Verify your number'), findsOneWidget);
        expect(await store.read(), isNull);
        // Design: Verify stays disabled until the code is edited.
        expect(fb(t, _verify).onPressed, isNull);

        await t.enterText(find.byKey(_otpField), '48219');
        await t.pump();
        expect(
          find.text("That code isn't correct. Please try again."),
          findsNothing,
        );
      },
    );

    testWidgets('AUTH-07: expired code -> message and Resend enabled at once', (
      t,
    ) async {
      repo.onVerify = (_, _) async => throw const OtpFailure(OtpError.expired);
      await launch(t);
      await requestOtp(t);
      await t.enterText(find.byKey(_otpField), '123456');
      await t.pump();
      await t.tap(find.byKey(_verify));
      await t.pumpAndSettle();
      expect(
        find.text('This code has expired. Request a new one.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('otp_resend_btn')), findsOneWidget);
    });

    testWidgets(
      'too many attempts (429) -> design card, field locked, Verify disabled',
      (t) async {
        repo.onVerify = (_, _) async =>
            throw const RateLimitedFailure('x', 300);
        await launch(t);
        await requestOtp(t);
        await t.enterText(find.byKey(_otpField), '123456');
        await t.pump();
        await t.tap(find.byKey(_verify));
        await t.pumpAndSettle();
        expect(find.text('Too many attempts'), findsOneWidget);
        expect(
          find.text('Please wait 5 minutes or contact support.'),
          findsOneWidget,
        );
        expect(find.byKey(const Key('otp_support_link')), findsOneWidget);
        expect(fb(t, _verify).onPressed, isNull);
        expect(t.widget<TextField>(find.byKey(_otpField)).enabled, isFalse);
      },
    );

    testWidgets('network error while verifying keeps the typed code', (
      t,
    ) async {
      repo.onVerify = (_, _) async => throw const NetworkFailure();
      await launch(t);
      await requestOtp(t);
      await t.enterText(find.byKey(_otpField), '123456');
      await t.pump();
      await t.tap(find.byKey(_verify));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('otp_error_text')), findsOneWidget);
      expect(
        t.widget<TextField>(find.byKey(_otpField)).controller!.text,
        '123456',
      );
      expect(fb(t, _verify).onPressed, isNotNull);
    });

    testWidgets('resend: calls the backend again, clears the field, confirms', (
      t,
    ) async {
      await launch(t);
      await requestOtp(t);
      await t.enterText(find.byKey(_otpField), '123');
      await t.pump(const Duration(seconds: 31));
      await t.tap(find.byKey(const Key('otp_resend_btn')));
      await t.pumpAndSettle();
      expect(repo.requestCalls, 2);
      expect(find.text('Code sent again'), findsOneWidget);
      expect(
        t.widget<TextField>(find.byKey(_otpField)).controller!.text,
        isEmpty,
      );
      expect(
        find.text('Verify your number'),
        findsOneWidget,
      ); // no second OTP route pushed
      final navigator = t.state<NavigatorState>(find.byType(Navigator).first);
      navigator.pop();
      await t.pumpAndSettle();
      expect(
        find.byKey(_mobileField),
        findsOneWidget,
      ); // exactly one level above: login
    });

    testWidgets('Change number / back return to login with the number kept', (
      t,
    ) async {
      await launch(t);
      await requestOtp(t);
      await t.tap(find.byKey(const Key('otp_change_number_btn')));
      await t.pumpAndSettle();
      expect(find.byKey(_mobileField), findsOneWidget);
      expect(
        t.widget<TextField>(find.byKey(_mobileField)).controller!.text,
        '98765 43210',
      );
      // The old attempt is forgotten.
      await requestOtp(t);
      await t.tap(find.byKey(const Key('app_back_btn')));
      await t.pumpAndSettle();
      expect(find.byKey(_mobileField), findsOneWidget);
      expect(repo.requestCalls, 2);
    });
  });

  test('provider is overridable and OTP length is the design default', () {
    expect(otpLength, 6);
    expect(isValidMobile('9876543210'), isTrue);
    for (final bad in [
      '1234567890',
      '98765',
      'abcdefghij',
      '',
      '98765432101',
    ]) {
      expect(isValidMobile(bad), isFalse, reason: bad);
    }
  });
}
