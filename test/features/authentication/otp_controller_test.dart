// UNIT tests for the OTP state machine, token storage and logout (fake repository, no network).
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/core/config/app_config.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/session/auth_state.dart';
import 'package:sevanest_customer/core/storage/secure_session_store.dart';
import 'package:sevanest_customer/features/authentication/domain/auth_repository.dart';
import 'package:sevanest_customer/features/authentication/presentation/providers/auth_providers.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakeAuthRepository repo;
  late InMemorySessionStore store;
  late ProviderContainer container;

  OtpState state() => container.read(otpControllerProvider);
  OtpController ctl() => container.read(otpControllerProvider.notifier);

  setUp(() {
    repo = FakeAuthRepository();
    store = InMemorySessionStore();
    container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(AppConfig.dev),
        sessionStoreProvider.overrideWithValue(store),
        authRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);
  });

  Future<void> sent() async {
    await ctl().requestOtp('9876543210');
    expect(state().phase, OtpPhase.sent);
  }

  group('requestOtp', () {
    test('idle -> requesting -> sent, timings come from the server', () async {
      repo.onRequest = (_) async =>
          const OtpChallenge(expiresInSeconds: 300, resendAfterSeconds: 45);
      final phases = <OtpPhase>[];
      container.listen(otpControllerProvider, (_, n) => phases.add(n.phase));
      await ctl().requestOtp('9876543210');
      expect(phases.first, OtpPhase.requesting);
      expect(state().phase, OtpPhase.sent);
      expect(state().secondsLeft, 45);
      expect(state().expiresInSeconds, 300);
      expect(state().mobile, '9876543210');
      expect(state().canResend, isFalse);
    });

    testWidgets('resend cooldown counts down to zero then allows resend', (
      t,
    ) async {
      repo.onRequest = (_) async =>
          const OtpChallenge(expiresInSeconds: 300, resendAfterSeconds: 3);
      await sent();
      await t.pump(const Duration(seconds: 1));
      expect(state().secondsLeft, 2);
      await t.pump(const Duration(seconds: 2));
      expect(state().secondsLeft, 0);
      expect(state().canResend, isTrue);
      await t.pump(const Duration(seconds: 5));
      expect(state().secondsLeft, 0); // never negative
    });

    test(
      'AUTH-05: a second request while one is in flight is ignored',
      () async {
        final gate = Completer<OtpChallenge>();
        repo.onRequest = (_) => gate.future;
        final first = ctl().requestOtp('9876543210');
        await ctl().requestOtp('9876543210');
        expect(repo.requestCalls, 1);
        gate.complete(const OtpChallenge());
        await first;
        expect(state().phase, OtpPhase.sent);
      },
    );

    testWidgets(
      '429 honours Retry-After and blocks new requests until it passes',
      (t) async {
        repo.onRequest = (_) async =>
            throw const RateLimitedFailure('slow', 40);
        await ctl().requestOtp('9876543210');
        expect(state().phase, OtpPhase.rateLimited);
        expect(state().secondsLeft, 40);
        expect(state().requestBlocked, isTrue);
        await t.pump(const Duration(seconds: 39));
        expect(state().requestBlocked, isTrue);
        await t.pump(const Duration(seconds: 1));
        expect(state().requestBlocked, isFalse);
      },
    );

    test('429 without a hint falls back to a short wait', () async {
      repo.onRequest = (_) async => throw const RateLimitedFailure('slow');
      await ctl().requestOtp('9876543210');
      expect(state().secondsLeft, resendCooldownSeconds);
    });

    test(
      'network failure keeps the previous phase and exposes the failure',
      () async {
        repo.onRequest = (_) async => throw const NetworkFailure();
        await ctl().requestOtp('9876543210');
        expect(state().phase, OtpPhase.idle);
        expect(state().failure, isA<NetworkFailure>());
        expect(state().busy, isFalse);
      },
    );

    test('a retry clears the old failure', () async {
      repo.onRequest = (_) async => throw const ServerFailure();
      await ctl().requestOtp('9876543210');
      repo.onRequest = (_) async => const OtpChallenge();
      await ctl().requestOtp('9876543210');
      expect(state().failure, isNull);
      expect(state().phase, OtpPhase.sent);
    });
  });

  group('verify', () {
    test(
      'AUTH-11: success stores tokens in the session store and signs in',
      () async {
        repo.onProfile = () async => false;
        await sent();
        await ctl().verify('123456');
        expect(state().phase, OtpPhase.verified);
        expect(repo.lastOtp, '123456');
        // Tokens are written before the profile lookup (it needs the bearer token).
        expect(await store.read(), (access: 'access-1', refresh: 'refresh-1'));
        expect(container.read(authProvider), AuthStatus.authenticated);
        expect(container.read(profileCompleteProvider), isFalse);
      },
    );

    test(
      'success with a complete profile sets profileComplete = true',
      () async {
        repo.onProfile = () async => true;
        await sent();
        await ctl().verify('123456');
        expect(container.read(profileCompleteProvider), isTrue);
      },
    );

    test('AUTH-06: wrong code -> invalidOtp, can edit and retry', () async {
      repo.onVerify = (_, _) async => throw const OtpFailure(OtpError.invalid);
      await sent();
      await ctl().verify('000000');
      expect(state().phase, OtpPhase.invalidOtp);
      expect(await store.read(), isNull);
      expect(container.read(authProvider), AuthStatus.unknown);
      ctl().codeEdited();
      expect(state().phase, OtpPhase.sent);
      expect(state().canVerify, isTrue);
    });

    testWidgets('AUTH-07: expired -> resend becomes available immediately', (
      t,
    ) async {
      repo.onVerify = (_, _) async => throw const OtpFailure(OtpError.expired);
      await sent();
      expect(state().canResend, isFalse);
      await ctl().verify('123456');
      expect(state().phase, OtpPhase.expired);
      expect(state().canResend, isTrue);
      await t.pump(
        const Duration(seconds: 40),
      ); // timer was cancelled, nothing explodes
    });

    testWidgets('lock-out blocks verifying, then releases after the wait', (
      t,
    ) async {
      repo.onVerify = (_, _) async =>
          throw const RateLimitedFailure('too many', 60);
      await sent();
      await ctl().verify('123456');
      expect(state().phase, OtpPhase.locked);
      expect(state().isLocked, isTrue);
      expect(state().canVerify, isFalse);
      await ctl().verify('123456');
      expect(repo.verifyCalls, 1);
      await t.pump(const Duration(seconds: 60));
      expect(state().isLocked, isFalse);
      expect(state().canVerify, isTrue);
    });

    test('OtpFailure.locked without a wait uses the fallback', () async {
      repo.onVerify = (_, _) async =>
          throw const OtpFailure(OtpError.locked, 'Try later');
      await sent();
      await ctl().verify('123456');
      expect(state().secondsLeft, lockFallbackSeconds);
      expect(state().failure?.message, 'Try later');
    });

    test('duplicate verify taps call the backend once', () async {
      final gate = Completer<AuthTokens>();
      repo.onVerify = (_, _) => gate.future;
      await sent();
      final first = ctl().verify('123456');
      await ctl().verify('123456');
      expect(repo.verifyCalls, 1);
      gate.complete((access: 'a', refresh: 'r'));
      await first;
    });

    test(
      'network failure while verifying keeps the user on the screen',
      () async {
        repo.onVerify = (_, _) async => throw const NetworkFailure();
        await sent();
        await ctl().verify('123456');
        expect(state().phase, OtpPhase.sent);
        expect(state().failure, isA<NetworkFailure>());
        expect(await store.read(), isNull);
      },
    );

    test(
      'profile lookup failure after a good OTP retries WITHOUT re-verifying',
      () async {
        var attempts = 0;
        repo.onProfile = () async {
          if (attempts++ == 0) throw const NetworkFailure();
          return true;
        };
        await sent();
        await ctl().verify('123456');
        expect(state().failure, isA<NetworkFailure>());
        expect(await store.read(), isNull); // half-finished session is not kept
        await ctl().verify('123456');
        expect(repo.verifyCalls, 1); // the OTP is single-use
        expect(container.read(authProvider), AuthStatus.authenticated);
        expect(await store.read(), isNotNull);
      },
    );
  });

  group('logout', () {
    test(
      'AUTH-14: clears the session even when POST /auth/logout fails',
      () async {
        repo.onLogout = () async => throw const NetworkFailure();
        await sent();
        await ctl().verify('123456');
        expect(container.read(authProvider), AuthStatus.authenticated);

        await container.read(logoutProvider)();

        expect(repo.logoutCalls, 1);
        expect(await store.read(), isNull);
        expect(container.read(authProvider), AuthStatus.unauthenticated);
        expect(container.read(profileCompleteProvider), isNull);
        expect(container.read(otpControllerProvider).phase, OtpPhase.idle);
      },
    );
  });
}
