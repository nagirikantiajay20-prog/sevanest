import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/network/dio_provider.dart';
import 'package:sevanest_customer/core/session/auth_state.dart';
import 'package:sevanest_customer/core/storage/device_id_store.dart';
import 'package:sevanest_customer/core/storage/secure_session_store.dart';
import 'package:sevanest_customer/features/authentication/data/auth_repository_remote.dart';
import 'package:sevanest_customer/features/authentication/domain/auth_repository.dart';

/// Used only when a 429 gives no Retry-After. Cosmetic: the backend enforces the real limits.
const resendCooldownSeconds = 30;

/// Shown when the server locks verification without telling us how long (design: "5 minutes").
const lockFallbackSeconds = 300;

/// How long the "Verified" state stays visible before the router moves on.
const verifiedHold = Duration(milliseconds: 700);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryRemote(
    ref.watch(dioProvider),
    ref.watch(deviceIdStoreProvider),
  ),
);

/// POST /auth/logout (failure ignored) -> clear tokens + profile state; the router sends the user
/// to /login. FCM token unregister joins in step 10.3.
final logoutProvider = Provider<Future<void> Function()>(
  (ref) => () async {
    try {
      await ref.read(authRepositoryProvider).logout();
    } on Object {
      // best effort: the local session is cleared regardless
    }
    ref.invalidate(otpControllerProvider);
    await ref.read(authProvider.notifier).signOut();
  },
);

enum OtpPhase {
  idle,
  requesting,
  sent,
  verifying,
  verified,
  invalidOtp,
  expired,
  locked,
  rateLimited,
  failed,
}

class OtpState {
  const OtpState({
    this.phase = OtpPhase.idle,
    this.mobile = '',
    this.secondsLeft = 0,
    this.expiresInSeconds = 300,
    this.failure,
  });

  final OtpPhase phase;

  /// 10 digits, no prefix.
  final String mobile;

  /// Resend cooldown, or the Retry-After wait while [OtpPhase.rateLimited] / [OtpPhase.locked].
  final int secondsLeft;

  /// OTP validity from the server, for the footer copy.
  final int expiresInSeconds;

  /// Set for request failures and non-OTP verify failures; cleared on every other transition.
  final AppFailure? failure;

  bool get busy => phase == OtpPhase.requesting || phase == OtpPhase.verifying;
  bool get isLocked => phase == OtpPhase.locked && secondsLeft > 0;

  /// Login screen: the server asked us to wait before another OTP request.
  bool get requestBlocked => phase == OtpPhase.rateLimited && secondsLeft > 0;
  bool get canResend => secondsLeft == 0 && !busy && phase != OtpPhase.verified;
  bool get canVerify => !busy && !isLocked && phase != OtpPhase.verified;

  OtpState copyWith({
    OtpPhase? phase,
    String? mobile,
    int? secondsLeft,
    int? expiresInSeconds,
    AppFailure? failure,
  }) => OtpState(
    phase: phase ?? this.phase,
    mobile: mobile ?? this.mobile,
    secondsLeft: secondsLeft ?? this.secondsLeft,
    expiresInSeconds: expiresInSeconds ?? this.expiresInSeconds,
    failure: failure,
  );
}

/// idle -> requesting -> sent -> verifying -> verified
///                          \-> invalidOtp | expired | locked | failed (-> sent again)
/// A 429 on request moves to rateLimited (wait = Retry-After).
class OtpController extends Notifier<OtpState> {
  Timer? _timer;

  /// Verified OTP whose profile lookup failed: retry only that step, the OTP is single-use.
  AuthTokens? _pending;

  @override
  OtpState build() {
    ref.onDispose(() => _timer?.cancel());
    return const OtpState();
  }

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  /// No automatic retries (an OTP request sends an SMS). A second call while one is in flight is
  /// ignored.
  Future<void> requestOtp(String mobile) async {
    if (state.busy) return;
    final prev = state.phase == OtpPhase.requesting
        ? OtpPhase.idle
        : state.phase;
    state = state.copyWith(phase: OtpPhase.requesting, mobile: mobile);
    try {
      final c = await _repo.requestOtp(mobile);
      _pending = null;
      state = state.copyWith(
        phase: OtpPhase.sent,
        expiresInSeconds: c.expiresInSeconds,
      );
      _startCountdown(c.resendAfterSeconds);
    } on RateLimitedFailure catch (f) {
      final wait = f.retryAfterSeconds ?? resendCooldownSeconds;
      state = state.copyWith(phase: OtpPhase.rateLimited, failure: f);
      _startCountdown(wait);
    } on AppFailure catch (f) {
      state = state.copyWith(phase: prev, failure: f);
    }
  }

  Future<void> verify(String otp) async {
    if (!state.canVerify) return;
    final phaseBefore = state.phase;
    state = state.copyWith(phase: OtpPhase.verifying);
    try {
      final tokens = _pending ??= await _repo.verifyOtp(state.mobile, otp);
      // Store first: GET /customers/me needs the bearer token.
      await ref
          .read(sessionStoreProvider)
          .write(access: tokens.access, refresh: tokens.refresh);
      final complete = await _repo.profileComplete();
      _pending = null;
      _timer?.cancel();
      state = state.copyWith(phase: OtpPhase.verified);
      await Future<void>.delayed(verifiedHold);
      ref.read(profileCompleteProvider.notifier).set(complete);
      await ref
          .read(authProvider.notifier)
          .signIn(access: tokens.access, refresh: tokens.refresh);
    } on OtpFailure catch (f) {
      switch (f.error) {
        case OtpError.invalid:
          state = state.copyWith(phase: OtpPhase.invalidOtp);
        case OtpError.expired:
          _timer?.cancel();
          state = state.copyWith(phase: OtpPhase.expired, secondsLeft: 0);
        case OtpError.locked:
          state = state.copyWith(phase: OtpPhase.locked, failure: f);
          _startCountdown(lockFallbackSeconds);
      }
    } on RateLimitedFailure catch (f) {
      state = state.copyWith(phase: OtpPhase.locked, failure: f);
      _startCountdown(f.retryAfterSeconds ?? lockFallbackSeconds);
    } on AppFailure catch (f) {
      if (f is UnauthorizedFailure) _pending = null;
      await ref.read(sessionStoreProvider).clear();
      state = state.copyWith(
        phase: phaseBefore == OtpPhase.verifying ? OtpPhase.sent : phaseBefore,
        failure: f,
      );
    }
  }

  /// The user edited the code after a wrong/expired/failed attempt: drop the error styling.
  void codeEdited() {
    const clearable = {OtpPhase.invalidOtp, OtpPhase.expired};
    if (clearable.contains(state.phase) || state.failure != null) {
      if (state.phase == OtpPhase.locked || state.busy) return;
      state = state.copyWith(
        phase: state.phase == OtpPhase.rateLimited
            ? OtpPhase.rateLimited
            : OtpPhase.sent,
      );
    }
  }

  void _startCountdown(int seconds) {
    _timer?.cancel();
    state = state.copyWith(
      secondsLeft: seconds,
      phase: state.phase,
      failure: state.failure,
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      final next = state.secondsLeft - 1;
      if (next <= 0) t.cancel();
      state = state.copyWith(
        secondsLeft: next < 0 ? 0 : next,
        phase: state.phase,
        failure: state.failure,
      );
    });
  }
}

final otpControllerProvider = NotifierProvider<OtpController, OtpState>(
  OtpController.new,
);
