import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/localization/failure_message.dart';
import 'package:sevanest_customer/features/authentication/domain/auth_repository.dart';
import 'package:sevanest_customer/features/authentication/presentation/providers/auth_providers.dart';
import 'package:sevanest_customer/features/authentication/presentation/screens/splash_screen.dart'
    show splashHoldProvider;
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_widgets.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/motion.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

enum _BoxStyle { normal, error, success, locked }

const _slate700 = AppColors.slate700;

/// Photo under a vertical wash, with a teal glow top-left and an amber one lower right.
final _backdropStyle = RoomBackdropStyle(
  alignment: const Alignment(0.24, -0.2),
  zoomFrom: 1.06,
  driftMs: 22000,
  drift: const Offset(-6, -4),
  glowTravel: const Offset(30, 40),
  glowZoom: 0.12,
  glowMs: 12000,
  washes: [
    LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppColors.ivory.withValues(alpha: 0.9),
        AppColors.ivory.withValues(alpha: 0.72),
        AppColors.ivory.withValues(alpha: 0.82),
      ],
      stops: const [0, 0.45, 1],
    ),
  ],
  glows: const [
    AuthGlow(Color(0x520F766E), 260, top: -60, left: -80),
    AuthGlow(Color(0x4DF59E0B), 260, top: 520, right: -90, delayMs: 6000),
  ],
);

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen>
    with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  late final _clock = ScreenClock(
    this,
    motion: ref.read(splashHoldProvider) > Duration.zero,
  );
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  @override
  void dispose() {
    _clock.dispose();
    _shake.dispose();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.login);
    }
  }

  Future<void> _verify() async {
    final otp = _controller.text;
    if (otp.length != otpLength) return;
    await ref.read(otpControllerProvider.notifier).verify(otp);
  }

  Future<void> _resend() async {
    final notifier = ref.read(otpControllerProvider.notifier);
    final mobile = ref.read(otpControllerProvider).mobile;
    await notifier.requestOtp(mobile);
  }

  static bool _isWrong(OtpPhase p) =>
      p == OtpPhase.invalidOtp || p == OtpPhase.expired;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final otp = ref.watch(otpControllerProvider);

    ref.listen(otpControllerProvider, (prev, next) {
      // A resend produced a new code: start from an empty field.
      if (prev?.phase == OtpPhase.requesting && next.phase == OtpPhase.sent) {
        _controller.clear();
        _focus.requestFocus();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.otpSentAgain)));
      }
      if (_isWrong(next.phase) && !_isWrong(prev?.phase ?? OtpPhase.idle)) {
        _shake.forward(from: 0);
      }
    });

    final style = switch (otp.phase) {
      OtpPhase.verified => _BoxStyle.success,
      OtpPhase.invalidOtp || OtpPhase.expired => _BoxStyle.error,
      _ when otp.isLocked => _BoxStyle.locked,
      _ => _BoxStyle.normal,
    };
    final isVerified = otp.phase == OtpPhase.verified;
    // After a wrong/expired code the design keeps Verify disabled until the code is edited.
    final canSubmit =
        _controller.text.length == otpLength &&
        otp.canVerify &&
        !_isWrong(otp.phase);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.ivory,
      body: Stack(
        children: [
          Positioned.fill(
            child: RoomBackdrop(clock: _clock, style: _backdropStyle),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, box) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: box.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Rise(
                            clock: _clock,
                            start: 100,
                            duration: 700,
                            child: _Header(onBack: _leave),
                          ),
                          Rise(
                            clock: _clock,
                            start: 240,
                            duration: 700,
                            child: _Intro(
                              clock: _clock,
                              otp: otp,
                              onChangeNumber: _leave,
                            ),
                          ),
                          Rise(
                            clock: _clock,
                            start: 380,
                            duration: 700,
                            child: AuthGlass(
                              radius: BorderRadius.circular(30),
                              blur: 22,
                              gradient: _glassGradient,
                              border: _glassBorder,
                              shadow: _glassShadow,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  18,
                                  16,
                                  14,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AnimatedBuilder(
                                      animation: _shake,
                                      builder: (context, child) =>
                                          Transform.translate(
                                            offset: Offset(
                                              _shakeOffset(_shake.value),
                                              0,
                                            ),
                                            child: child,
                                          ),
                                      child: _OtpBoxes(
                                        clock: _clock,
                                        controller: _controller,
                                        focusNode: _focus,
                                        style: style,
                                        enabled: otp.canVerify,
                                        onChanged: (_) {
                                          ref
                                              .read(
                                                otpControllerProvider.notifier,
                                              )
                                              .codeEdited();
                                          setState(() {});
                                        },
                                        onSubmitted: _verify,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    _Status(otp: otp, onResend: _resend),
                                    const SizedBox(height: 4),
                                    AuthCta(
                                      key: const Key('otp_verify_btn'),
                                      clock: _clock,
                                      radius: 17,
                                      label: isVerified
                                          ? l10n.verifiedLabel
                                          : l10n.verifyContinue,
                                      loadingLabel: l10n.verifying,
                                      loading: otp.phase == OtpPhase.verifying,
                                      done: isVerified,
                                      onPressed: canSubmit ? _verify : null,
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.only(top: 1),
                                          child: Icon(
                                            Icons.shield_outlined,
                                            size: 18,
                                            color: _slate700,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            l10n.otpFooter(
                                              (otp.expiresInSeconds / 60)
                                                  .ceil(),
                                            ),
                                            style: AppText.body.copyWith(
                                              fontSize: 12.5,
                                              height: 1.45,
                                              color: _slate700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (otp.demoOtp != null)
                            _DemoOtpCard(clock: _clock, code: otp.demoOtp!),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Horizontal shake: left, right, back (400 ms).
  static double _shakeOffset(double t) => t < 0.2
      ? -6 * t / 0.2
      : t < 0.6
      ? -6 + 12 * (t - 0.2) / 0.4
      : 6 * (1 - (t - 0.6) / 0.4);
}

const _glassGradient = LinearGradient(
  begin: Alignment(-0.64, -0.77),
  end: Alignment(0.64, 0.77),
  colors: [Color(0x9EFFFFFF), Color(0x57FFFFFF)],
);
const _glassBorder = Border.fromBorderSide(
  BorderSide(color: Color(0xD9FFFFFF)),
);
const _glassShadow = [
  BoxShadow(color: Color(0x2E1B3354), blurRadius: 44, offset: Offset(0, 18)),
];

/// Back button, logo and wordmark.
class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        AuthGlass(
          radius: BorderRadius.circular(22),
          blur: 22,
          gradient: _glassGradient,
          border: _glassBorder,
          shadow: _glassShadow,
          child: IconButton(
            key: const Key('app_back_btn'),
            tooltip: l10n.back,
            constraints: const BoxConstraints.tightFor(width: 44, height: 44),
            padding: EdgeInsets.zero,
            onPressed: onBack,
            icon: const Icon(Icons.chevron_left_rounded, color: authNavy),
          ),
        ),
        const SizedBox(width: 12),
        Image.asset(
          'assets/login/logo.png',
          height: 42,
          excludeFromSemantics: true,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                const TextSpan(
                  text: 'Seva',
                  children: [
                    TextSpan(
                      text: 'Nest',
                      style: TextStyle(color: AppColors.teal),
                    ),
                  ],
                ),
                semanticsLabel: l10n.appName,
                overflow: TextOverflow.ellipsis,
                style: authSerif(23, 1.1),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.brandCaption,
                overflow: TextOverflow.ellipsis,
                style: AppText.body.copyWith(
                  fontSize: 11,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                  color: _slate700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Resend countdown ring, title and the number the code went to.
class _Intro extends StatelessWidget {
  const _Intro({
    required this.clock,
    required this.otp,
    required this.onChangeNumber,
  });
  final ScreenClock clock;
  final OtpState otp;
  final VoidCallback onChangeNumber;

  static String _spaced(String d) =>
      d.length > 5 ? '${d.substring(0, 5)} ${d.substring(5)}' : d;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        _TimerRing(clock: clock, secondsLeft: otp.secondsLeft),
        const SizedBox(height: 14),
        Semantics(
          header: true,
          child: Text(
            l10n.otpTitle,
            textAlign: TextAlign.center,
            style: authSerif(32, 1.1),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.otpEnterCode(otpLength),
          textAlign: TextAlign.center,
          style: AppText.body.copyWith(
            fontSize: 15,
            height: 1.4,
            color: _slate700,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                '+91 ${_spaced(otp.mobile)}',
                key: const Key('otp_mobile_text'),
                style: AppText.body.copyWith(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                  color: authNavy,
                ),
              ),
            ),
            IconButton(
              key: const Key('otp_change_number_btn'),
              tooltip: l10n.changeNumber,
              constraints: const BoxConstraints.tightFor(
                width: kMinTapTarget,
                height: kMinTapTarget,
              ),
              onPressed: onChangeNumber,
              icon: const Icon(
                Icons.edit_outlined,
                color: AppColors.slate600,
                size: 20,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Draining ring around the time left to resend, with a pulsing glow and ping.
class _TimerRing extends StatelessWidget {
  const _TimerRing({required this.clock, required this.secondsLeft});
  final ScreenClock clock;
  final int secondsLeft;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final time = mmss(secondsLeft);
    final fraction = (secondsLeft / resendCooldownSeconds).clamp(0.0, 1.0);
    return Semantics(
      label: secondsLeft > 0 ? l10n.resendIn(time) : l10n.resendCode,
      child: ExcludeSemantics(
        child: SizedBox(
          width: 128,
          height: 128,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              ValueListenableBuilder<double>(
                valueListenable: clock,
                builder: (context, t, _) {
                  final k = Curves.easeInOut.transform(pingPong(t, 2800));
                  final ping = ((t / 2400) % 1);
                  return Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Opacity(
                        opacity: 0.55 + 0.45 * k,
                        child: Transform.scale(
                          scale: 1 + 0.14 * k,
                          child: const SizedBox(
                            width: 156,
                            height: 156,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Color(0x5C0F766E),
                                    Color(0x000F766E),
                                  ],
                                  stops: [0, 0.68],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Opacity(
                        opacity: 0.7 * (1 - Curves.easeOut.transform(ping)),
                        child: Transform.scale(
                          scale: 0.9 + 0.6 * Curves.easeOut.transform(ping),
                          child: Container(
                            width: 116,
                            height: 116,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0x660F766E),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              if (clock.animating)
                // Glides between seconds; when frozen it just jumps (a glide would never settle).
                TweenAnimationBuilder<double>(
                  tween: Tween(end: fraction),
                  duration: const Duration(seconds: 1),
                  builder: (context, f, _) => CustomPaint(
                    size: const Size.square(128),
                    painter: _RingPainter(f),
                  ),
                )
              else
                CustomPaint(
                  size: const Size.square(128),
                  painter: _RingPainter(fraction),
                ),
              AuthGlass(
                radius: BorderRadius.circular(46),
                blur: 22,
                gradient: _glassGradient,
                border: _glassBorder,
                shadow: _glassShadow,
                child: SizedBox(
                  width: 92,
                  height: 92,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.mobile_friendly_rounded,
                        color: AppColors.teal,
                        size: 22,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        time,
                        style: AppText.body.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: authNavy,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter(this.fraction);
  final double fraction;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final arc = rect.deflate(7 / 2 + 8); // r = 56 on the 128 box
    canvas.drawArc(
      arc,
      0,
      2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..color = const Color(0x1F1B3354),
    );
    canvas.drawArc(
      arc,
      -math.pi / 2,
      2 * math.pi * fraction,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.teal, Color(0xFF38BDF8)],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.fraction != fraction;
}

/// Test mode: the generated code, with a copy button (the backend does not send SMS).
class _DemoOtpCard extends StatelessWidget {
  const _DemoOtpCard({required this.clock, required this.code});
  final ValueListenable<double> clock;
  final String code;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ValueListenableBuilder<double>(
      valueListenable: clock,
      // Drops in from above with a little overshoot once the rest has settled.
      builder: (context, t, child) {
        final p = seg(t, 900, 900, const Cubic(.3, 1.3, .5, 1));
        return Opacity(
          opacity: seg(t, 900, 540, Curves.easeOut),
          child: Transform.translate(
            offset: Offset(0, -46 * (1 - p)),
            child: Transform.scale(scale: 0.96 + 0.04 * p, child: child),
          ),
        );
      },
      child: AuthGlass(
        key: const Key('otp_demo_card'),
        radius: BorderRadius.circular(22),
        blur: 22,
        gradient: _glassGradient,
        border: _glassBorder,
        shadow: _glassShadow,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x241B3354),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/login/logo.png',
                  width: 36,
                  excludeFromSemantics: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.demoOtpLabel,
                      style: AppText.body.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _slate700,
                      ),
                    ),
                    Text(
                      code,
                      key: const Key('otp_demo_code'),
                      style: AppText.body.copyWith(
                        fontSize: 21,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4,
                        color: authNavy,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                key: const Key('otp_demo_copy_btn'),
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  backgroundColor: AppColors.teal.withValues(alpha: 0.12),
                  foregroundColor: AppColors.teal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: AppText.body.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final copied = l10n.demoOtpCopied;
                  await Clipboard.setData(ClipboardData(text: code));
                  messenger
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(content: Text(copied)));
                },
                icon: const Icon(Icons.copy_rounded, size: 17),
                label: Text(l10n.demoOtpCopy),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wrong-code / expired / failure message, countdown or resend link, lock-out card.
class _Status extends StatelessWidget {
  const _Status({required this.otp, required this.onResend});

  final OtpState otp;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (otp.phase == OtpPhase.verified) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 22),
            const SizedBox(width: 8),
            Text(
              l10n.numberVerified,
              key: const Key('otp_verified_text'),
              style: AppText.body.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      );
    }

    if (otp.isLocked) {
      return Consumer(
        builder: (context, ref, _) => AuthNoticeCard(
          key: const Key('otp_locked_card'),
          icon: Icons.schedule_rounded,
          title: l10n.tooManyAttempts,
          message: l10n.tooManyWait((otp.secondsLeft / 60).ceil()),
          action: AuthLink(
            key: const Key('otp_support_link'),
            label: l10n.contactSupport,
            onTap: () => openSupport(context, ref),
          ),
        ),
      );
    }

    final error = switch (otp.phase) {
      OtpPhase.invalidOtp => l10n.otpWrong,
      OtpPhase.expired => l10n.otpExpired,
      _ => switch (otp.failure) {
        final AppFailure f when otp.phase != OtpPhase.requesting =>
          _failureText(l10n, f),
        _ => null,
      },
    };

    final time = mmss(otp.secondsLeft);
    final countdown = l10n.resendIn(time);
    final timeAt = countdown.lastIndexOf(time);
    final resendWidget = otp.secondsLeft > 0
        ? Text.rich(
            key: const Key('otp_countdown_text'),
            textAlign: TextAlign.center,
            TextSpan(
              style: AppText.body.copyWith(fontSize: 15, color: _slate700),
              children: [
                TextSpan(text: countdown.substring(0, timeAt)),
                TextSpan(
                  text: time,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                TextSpan(text: countdown.substring(timeAt + time.length)),
              ],
            ),
          )
        : AuthLink(
            key: const Key('otp_resend_btn'),
            label: l10n.resendCode,
            icon: Icons.refresh_rounded,
            onTap: otp.canResend ? onResend : null,
          );

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 46),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (error != null)
            Semantics(
              liveRegion: true,
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.danger,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      error,
                      key: const Key('otp_error_text'),
                      style: AppText.body.copyWith(
                        fontSize: 14,
                        color: const Color(0xFFB91C1C),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (error != null) const SizedBox(height: 4),
          Center(child: resendWidget),
          if (otp.secondsLeft == 0 && error == null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l10n.otpDidntGet,
                textAlign: TextAlign.center,
                style: AppText.body.copyWith(fontSize: 14, color: _slate700),
              ),
            ),
        ],
      ),
    );
  }

  String _failureText(AppLocalizations l10n, AppFailure f) {
    if (f is RateLimitedFailure) {
      return l10n.rateLimitedWait(mmss(otp.secondsLeft));
    }
    return failureMessage(l10n, f);
  }
}

/// Six boxes over one real (invisible) TextField, so paste, SMS autofill (`oneTimeCode`) and the
/// platform keyboard all work.
class _OtpBoxes extends StatelessWidget {
  const _OtpBoxes({
    required this.clock,
    required this.controller,
    required this.focusNode,
    required this.style,
    required this.enabled,
    required this.onChanged,
    required this.onSubmitted,
  });

  final ValueListenable<double> clock;
  final TextEditingController controller;
  final FocusNode focusNode;
  final _BoxStyle style;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? focusNode.requestFocus : null,
      child: Stack(
        children: [
          ListenableBuilder(
            listenable: Listenable.merge([controller, focusNode]),
            builder: (context, _) {
              final text = controller.text;
              return Row(
                children: [
                  for (var i = 0; i < otpLength; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: _Box(
                        clock: clock,
                        char: i < text.length ? text[i] : '',
                        focused:
                            enabled &&
                            focusNode.hasFocus &&
                            i == text.length.clamp(0, otpLength - 1),
                        style: style,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              alwaysIncludeSemantics: true,
              child: AutofillGroup(
                child: TextField(
                  key: const Key('otp_input_field'),
                  controller: controller,
                  focusNode: focusNode,
                  enabled: enabled,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  enableInteractiveSelection: false,
                  showCursor: false,
                  maxLength: otpLength,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    semanticCounterText: l10n.otpEnterCode(otpLength),
                  ),
                  onChanged: onChanged,
                  onSubmitted: (_) => onSubmitted(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({
    required this.clock,
    required this.char,
    required this.focused,
    required this.style,
  });

  final ValueListenable<double> clock;
  final String char;
  final bool focused;
  final _BoxStyle style;

  @override
  Widget build(BuildContext context) {
    final border = switch (style) {
      _BoxStyle.error => AppColors.danger,
      _BoxStyle.success => AppColors.success,
      _ when focused => AppColors.teal,
      _ => const Color(0xF2FFFFFF),
    };
    final fill = style == _BoxStyle.locked
        ? const Color(0xB3E2E8F0)
        : const Color(0x9EFFFFFF);
    return AspectRatio(
      aspectRatio: 48 / 56,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: border, width: focused ? 2 : 1.5),
          boxShadow: focused
              ? [
                  BoxShadow(
                    color: AppColors.teal.withValues(alpha: 0.2),
                    spreadRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // A new digit pops in (keyed on the digit, so only a changed box replays).
            TweenAnimationBuilder<double>(
              key: ValueKey(char),
              tween: Tween(begin: char.isEmpty ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 350),
              curve: const Cubic(.34, 1.56, .64, 1),
              builder: (context, p, child) => Opacity(
                opacity: p.clamp(0.0, 1.0),
                child: Transform.scale(scale: 0.4 + 0.6 * p, child: child),
              ),
              child: Text(
                char,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (focused && char.isEmpty)
              ValueListenableBuilder<double>(
                valueListenable: clock,
                builder: (context, t, _) => Opacity(
                  opacity: (t / 1000) % 1 < 0.5 ? 1 : 0,
                  child: Container(
                    width: 2,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.teal,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
