import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/gestures.dart';
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
import 'package:sevanest_customer/features/customer_profile/presentation/providers/account_providers.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// Digits only, max 10, shown as `98765 43210`.
class MobileNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final capped = digits.length > 10 ? digits.substring(0, 10) : digits;
    final text = capped.length > 5
        ? '${capped.substring(0, 5)} ${capped.substring(5)}'
        : capped;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

String digitsOf(String formatted) => formatted.replaceAll(RegExp(r'\D'), '');

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  late final TapGestureRecognizer _terms;
  late final TapGestureRecognizer _privacy;
  bool _showError = false;
  bool _focused = false;

  late final _clock = ScreenClock(
    this,
    motion: ref.read(splashHoldProvider) > Duration.zero,
  );
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );

  @override
  void initState() {
    super.initState();
    _terms = TapGestureRecognizer()
      ..onTap = () => _openLegal((c) => c.termsUrl);
    _privacy = TapGestureRecognizer()
      ..onTap = () => _openLegal((c) => c.privacyUrl);
    _focus.addListener(() {
      setState(() => _focused = _focus.hasFocus);
      // Validate once the user leaves a non-empty field.
      if (!_focus.hasFocus && _controller.text.isNotEmpty) _flagError();
    });
  }

  @override
  void dispose() {
    _clock.dispose();
    _shake.dispose();
    _terms.dispose();
    _privacy.dispose();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  String get _digits => digitsOf(_controller.text);

  /// Shows the validation error and shakes the field when the number is not valid.
  void _flagError() {
    setState(() => _showError = true);
    if (!isValidMobile(_digits)) _shake.forward(from: 0);
  }

  Future<void> _openLegal(String? Function(AccountConfig) pick) async {
    final messenger = ScaffoldMessenger.of(context);
    final unavailable = AppLocalizations.of(context).linkUnavailable;
    var opened = false;
    String? url;
    try {
      url = pick(await ref.read(accountConfigProvider.future));
    } on Object {
      url = null;
    }
    if (url != null) {
      try {
        opened = await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
      } on Object {
        opened = false;
      }
    }
    if (!opened) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(unavailable)));
    }
  }

  Future<void> _submit() async {
    final otp = ref.read(otpControllerProvider);
    if (otp.busy || otp.requestBlocked) return;
    if (!isValidMobile(_digits)) {
      _flagError();
      return;
    }
    FocusScope.of(context).unfocus();
    await ref.read(otpControllerProvider.notifier).requestOtp(_digits);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final otp = ref.watch(otpControllerProvider);

    ref.listen(otpControllerProvider, (prev, next) async {
      // Only the visible login screen reacts (a resend on the OTP screen also goes through `sent`).
      final onTop = ModalRoute.of(context)?.isCurrent ?? false;
      if (onTop &&
          prev?.phase == OtpPhase.requesting &&
          next.phase == OtpPhase.sent) {
        await context.push(Routes.otp);
        // Back / "Change number": forget the previous attempt (the typed number stays here).
        if (mounted) ref.invalidate(otpControllerProvider);
      }
    });

    final invalid = _showError && !isValidMobile(_digits);
    final loading = otp.phase == OtpPhase.requesting;
    final ready = _digits.length == 10 && !otp.busy && !otp.requestBlocked;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.ivory,
      body: Stack(
        children: [
          Positioned.fill(
            child: RoomBackdrop(clock: _clock, style: _backdropStyle),
          ),
          SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, box) => Column(
                children: [
                  Expanded(
                    // Spread over the room left above the sheet, not the whole screen.
                    child: LayoutBuilder(
                      builder: (context, top) => ClipRect(
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: top.maxHeight,
                            ),
                            child: IntrinsicHeight(child: _Hero(clock: _clock)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: box.maxHeight * 0.8),
                    child: _SheetIn(
                      clock: _clock,
                      child: _Sheet(
                        bottomInset: bottom,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Semantics(
                              header: true,
                              child: Text(
                                l10n.loginHeading,
                                style: authSerif(24, 1.2),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.loginHelp(otpLength),
                              style: AppText.body.copyWith(
                                fontSize: 14,
                                height: 1.45,
                                color: AppColors.slate700,
                              ),
                            ),
                            const SizedBox(height: 14),
                            AnimatedBuilder(
                              animation: _shake,
                              builder: (context, child) => Transform.translate(
                                offset: Offset(
                                  -5 * math.sin(2 * math.pi * _shake.value),
                                  0,
                                ),
                                child: child,
                              ),
                              child: _MobileField(
                                controller: _controller,
                                focusNode: _focus,
                                hasError: invalid,
                                focused: _focused,
                                enabled: !otp.busy,
                                onChanged: (_) => setState(() {}),
                                onSubmitted: (_) => _submit(),
                              ),
                            ),
                            _Feedback(
                              invalid: invalid,
                              otp: otp,
                              invalidText: l10n.mobileInvalid,
                            ),
                            const SizedBox(height: 14),
                            AuthCta(
                              key: const Key('login_get_otp_btn'),
                              clock: _clock,
                              breathe: true,
                              label: l10n.getOtp,
                              loadingLabel: l10n.sendingCode,
                              loading: loading,
                              onPressed: ready ? _submit : null,
                            ),
                            const SizedBox(height: 14),
                            _LegalText(terms: _terms, privacy: _privacy),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _fieldBorder = AppColors.slate400Light;

/// Room photo drifting under a wash from the left, plus three glows.
final _backdropStyle = RoomBackdropStyle(
  alignment: const Alignment(0.24, -0.1),
  washes: [
    LinearGradient(
      begin: const Alignment(-0.98, -0.17),
      end: const Alignment(0.98, 0.17),
      colors: [
        AppColors.ivory.withValues(alpha: 0.94),
        AppColors.ivory.withValues(alpha: 0.74),
        AppColors.ivory.withValues(alpha: 0.28),
      ],
      stops: const [0, 0.6, 1],
    ),
    LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppColors.ivory.withValues(alpha: 0),
        AppColors.ivory.withValues(alpha: 0.7),
      ],
      stops: const [0.55, 1],
    ),
  ],
  glows: const [
    AuthGlow(AppColors.teal0F766EA34, 260, top: -70, right: -80),
    AuthGlow(
      AppColors.orangeF59E0BA30,
      240,
      top: 300,
      left: -100,
      delayMs: 5000,
    ),
    AuthGlow(AppColors.cyan38BDF8A30, 260, top: 560, right: -90, delayMs: 9000),
  ],
);

/// Everything above the sheet: brand, headline, service marquee and the trust strip.
class _Hero extends StatelessWidget {
  const _Hero({required this.clock});
  final ValueListenable<double> clock;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const side = EdgeInsets.symmetric(horizontal: 20);
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: side,
            child: Rise(
              clock: clock,
              start: 100,
              duration: 700,
              child: _Brand(clock: clock),
            ),
          ),
          Padding(
            padding: side,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Headline(clock: clock, text: l10n.loginHeadline),
                Rise(
                  clock: clock,
                  start: 220,
                  duration: 700,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 70),
                      child: Text(
                        l10n.loginSubhead,
                        style: AppText.body.copyWith(
                          fontSize: 15,
                          height: 1.45,
                          color: AppColors.slate700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Rise(
            clock: clock,
            start: 340,
            duration: 700,
            child: _Marquee(clock: clock),
          ),
          Padding(
            padding: side,
            child: Rise(
              clock: clock,
              start: 460,
              duration: 700,
              child: const _TrustStrip(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Logo with its breathing halo, wordmark and caption.
class _Brand extends StatelessWidget {
  const _Brand({required this.clock});
  final ValueListenable<double> clock;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      label: l10n.appName,
      child: ExcludeSemantics(
        child: Row(
          children: [
            ValueListenableBuilder<double>(
              valueListenable: clock,
              builder: (context, t, child) {
                final k = Curves.easeInOut.transform(pingPong(t, 2600));
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity: 0.5 + 0.5 * k,
                      child: Transform.scale(
                        scale: 1 + 0.18 * k,
                        child: const SizedBox(
                          width: 84,
                          height: 84,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppColors.teal0F766EA34,
                                  AppColors.teal0F766EA0,
                                ],
                                stops: [0, 0.7],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    child!,
                  ],
                );
              },
              child: Image.asset('assets/login/logo.png', height: 52),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: const [
                        TextSpan(
                          text: 'Seva',
                          style: TextStyle(color: authNavy),
                        ),
                        TextSpan(
                          text: 'Nest',
                          style: TextStyle(color: AppColors.teal),
                        ),
                      ],
                      style: authSerif(25, 1.1),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    l10n.brandCaption,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body.copyWith(
                      fontSize: 10.5,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Headline whose words drop in one after another; "happier home" is teal italic.
class _Headline extends StatelessWidget {
  const _Headline({required this.clock, required this.text});
  final ValueListenable<double> clock;
  final String text;

  static const _accent = 'happier home';

  @override
  Widget build(BuildContext context) {
    final words = text.split(' ');
    final at = text.indexOf(_accent);
    final first = at < 0 ? -1 : text.substring(0, at).split(' ').length - 1;
    final count = _accent.split(' ').length;
    return Semantics(
      header: true,
      label: text,
      child: ExcludeSemantics(
        // Padding, not a width cap: it is the only wrapper whose intrinsic height tracks the narrower
        // width, which the hero's IntrinsicHeight needs.
        child: Padding(
          padding: const EdgeInsets.only(right: 30),
          child: ValueListenableBuilder<double>(
            valueListenable: clock,
            builder: (context, t, _) => Wrap(
              spacing: 9,
              children: [
                for (var i = 0; i < words.length; i++)
                  () {
                    final p = seg(t, 250 + 90.0 * i, 750, riseCurve);
                    final accent =
                        i >= first && i < first + count && first >= 0;
                    return Opacity(
                      opacity: p,
                      child: Transform.translate(
                        offset: Offset(0, 22 * (1 - p)),
                        child: Transform.rotate(
                          angle: 0.035 * (1 - p),
                          child: Text(
                            words[i],
                            style: authSerif(36, 1.13).copyWith(
                              color: accent ? AppColors.teal : authNavy,
                              fontStyle: accent
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  }(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ServiceCard {
  const _ServiceCard(this.label, this.asset, this.x, this.y);
  final String label;
  final String asset;

  /// Focal point of the photo, 0..1 (CSS `object-position`).
  final double x;
  final double y;
}

// ponytail: English-only labels like the rest of V1 copy here; the strip is decorative (hidden from
// screen readers). Move to l10n with the other catalogue names when translating.
const _cards = [
  _ServiceCard('House Maid', 'maid', 0.3, 0.25),
  _ServiceCard('Cook', 'cook', 0.5, 0.4),
  _ServiceCard('Babysitter', 'babysitter', 0.5, 0.4),
  _ServiceCard('Driver', 'driver', 0.5, 0.5),
  _ServiceCard('Elderly Care', 'elder', 0.5, 0.45),
  _ServiceCard('Cleaning Helper', 'cleaning', 0.6, 0.4),
];

const _cardW = 112.0;
const _cardGap = 10.0;

/// Endless strip of service photos sliding left, faded at both edges.
class _Marquee extends StatelessWidget {
  const _Marquee({required this.clock});
  final ValueListenable<double> clock;

  @override
  Widget build(BuildContext context) {
    // Two copies, so sliding one copy's width (+ its gaps) loops without a seam.
    const loop = (_cardW + _cardGap) * 6;
    final strip = Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < _cards.length * 2; i++) ...[
            if (i > 0) const SizedBox(width: _cardGap),
            _ServiceTile(_cards[i % _cards.length]),
          ],
        ],
      ),
    );
    return ExcludeSemantics(
      child: SizedBox(
        height: 154,
        child: ClipRect(
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (r) => const LinearGradient(
              colors: [
                AppColors.transparentBlack,
                AppColors.blackA100xFF,
                AppColors.blackA100xFF,
                AppColors.transparentBlack,
              ],
              stops: [0, 0.06, 0.94, 1],
            ).createShader(r),
            child: ValueListenableBuilder<double>(
              valueListenable: clock,
              child: strip,
              builder: (context, t, child) => OverflowBox(
                alignment: Alignment.topLeft,
                maxWidth: double.infinity,
                child: Transform.translate(
                  offset: Offset(20 - loop * ((t / 34000) % 1), 0),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile(this.card);
  final _ServiceCard card;

  @override
  Widget build(BuildContext context) => Container(
    width: _cardW,
    height: 136,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppColors.surface, width: 3),
      color: AppColors.tileWell,
      boxShadow: const [
        BoxShadow(
          color: AppColors.sky1B3354A22,
          blurRadius: 22,
          offset: Offset(0, 10),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(19),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/login/${card.asset}.jpg',
            fit: BoxFit.cover,
            alignment: Alignment(card.x * 2 - 1, card.y * 2 - 1),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.blue0F2340A0, AppColors.blue0F2340A55],
                stops: [0.5, 1],
              ),
            ),
          ),
          Positioned(
            left: 3,
            right: 3,
            bottom: 4,
            child: Text(
              card.label,
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(
                fontSize: 11,
                height: 1.2,
                fontWeight: FontWeight.w700,
                color: AppColors.surface,
                shadows: const [
                  Shadow(
                    color: AppColors.blackA40x66,
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Icon well, bold first word, muted rest (design 02); three items in one glass strip.
class _TrustStrip extends StatelessWidget {
  const _TrustStrip();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget item(IconData icon, String label, {bool first = false}) {
      // ponytail: splits on the first space, fine for English-only V1; per-word strings when translating.
      final i = label.indexOf(' ');
      final head = i < 0 ? label : label.substring(0, i);
      final tail = i < 0 ? '' : label.substring(i + 1);
      return Expanded(
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            border: first
                ? null
                : const Border(left: BorderSide(color: AppColors.hairline)),
          ),
          // Icon above the text: the full item width is kept for the words (no mid-word breaks).
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.tileWell,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.teal, size: 18),
              ),
              const SizedBox(height: 4),
              Flexible(
                // Scales down a little instead of breaking "professionals" at 1.3x text on 360 dp.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text.rich(
                    textAlign: TextAlign.center,
                    TextSpan(
                      children: [
                        TextSpan(
                          text: head,
                          style: AppText.body.copyWith(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: authNavy,
                          ),
                        ),
                        if (tail.isNotEmpty) TextSpan(text: '\n$tail'),
                      ],
                      style: AppText.body.copyWith(
                        fontSize: 11.5,
                        height: 1.2,
                        color: AppColors.slate600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AuthGlass(
      radius: BorderRadius.circular(22),
      blur: 16,
      tint: AppColors.whiteA62x9E,
      shadow: const [
        BoxShadow(
          color: AppColors.sky1B3354A12,
          blurRadius: 24,
          offset: Offset(0, 8),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              item(
                Icons.verified_user_outlined,
                l10n.loginTrustNearby,
                first: true,
              ),
              item(Icons.credit_card_outlined, l10n.trustSecurePayments),
              item(Icons.headset_mic_outlined, l10n.loginTrustSupport),
            ],
          ),
        ),
      ),
    );
  }
}

/// The sheet slides up and fades in once.
class _SheetIn extends StatelessWidget {
  const _SheetIn({required this.clock, required this.child});
  final ValueListenable<double> clock;
  final Widget child;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<double>(
    valueListenable: clock,
    child: child,
    builder: (context, t, c) {
      final p = seg(t, 300, 800, riseCurve);
      return Opacity(
        opacity: p,
        child: Transform.translate(offset: Offset(0, 60 * (1 - p)), child: c),
      );
    },
  );
}

/// Frosted bottom sheet that holds the form.
class _Sheet extends StatelessWidget {
  const _Sheet({required this.child, required this.bottomInset});
  final Widget child;
  final double bottomInset;

  @override
  Widget build(BuildContext context) => AuthGlass(
    radius: const BorderRadius.vertical(top: Radius.circular(32)),
    blur: 28,
    tint: AppColors.whiteA60x99,
    shadow: const [
      BoxShadow(
        color: AppColors.sky1B3354A20,
        blurRadius: 44,
        offset: Offset(0, -16),
      ),
    ],
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 10, 20, 24 + bottomInset),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.sky1B3354A22,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            child,
          ],
        ),
      ),
    ),
  );
}

class _MobileField extends StatelessWidget {
  const _MobileField({
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.focused,
    required this.enabled,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final bool focused;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final borderColor = hasError
        ? AppColors.danger
        : focused
        ? AppColors.teal
        : _fieldBorder;
    const fieldText = TextStyle(
      fontFamily: AppFonts.body,
      color: authNavy,
      fontSize: 18,
      fontWeight: FontWeight.w500,
    );
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.whiteA72xB8,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: focused && !hasError
            ? const [BoxShadow(color: AppColors.teal0F766EA16, spreadRadius: 4)]
            : null,
      ),
      child: Row(
        children: [
          const Text('+91', style: fieldText),
          Container(
            width: 1,
            height: 28,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: AppColors.hairline,
          ),
          Expanded(
            child: Semantics(
              label: l10n.mobileLabel,
              child: TextField(
                key: const Key('login_mobile_field'),
                controller: controller,
                focusNode: focusNode,
                enabled: enabled,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.telephoneNumberNational],
                inputFormatters: [MobileNumberFormatter()],
                style: fieldText,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  hintText: l10n.mobileHint,
                  hintStyle: fieldText.copyWith(color: AppColors.slate400),
                ),
                onChanged: onChanged,
                onSubmitted: onSubmitted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Inline validation error, or the "couldn't send" / rate-limit card (design: three states).
class _Feedback extends StatelessWidget {
  const _Feedback({
    required this.invalid,
    required this.otp,
    required this.invalidText,
  });

  final bool invalid;
  final OtpState otp;
  final String invalidText;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (invalid) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Semantics(
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
                  invalidText,
                  key: const Key('login_mobile_error'),
                  style: AppText.body.copyWith(
                    fontSize: 13.5,
                    color: AppColors.red700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final failure = otp.failure;
    if (otp.phase == OtpPhase.requesting || otp.phase == OtpPhase.sent) {
      return const SizedBox.shrink();
    }
    if (otp.requestBlocked) {
      return _card(
        icon: Icons.schedule_rounded,
        title: l10n.sendFailedTitle,
        message: l10n.rateLimitedWait(mmss(otp.secondsLeft)),
      );
    }
    if (failure == null) return const SizedBox.shrink();
    return _card(
      icon: failure is NetworkFailure
          ? Icons.wifi_off_rounded
          : Icons.error_outline,
      title: l10n.sendFailedTitle,
      message: failure is NetworkFailure
          ? l10n.sendFailedNetwork
          : failureMessage(l10n, failure),
    );
  }

  Widget _card({
    required IconData icon,
    required String title,
    required String message,
  }) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: AuthNoticeCard(
      key: const Key('login_notice'),
      icon: icon,
      title: title,
      message: message,
    ),
  );
}

/// An inline link with a key (module 01) that still taps through the shared recognizer.
InlineSpan _link(
  String key,
  String label,
  TextStyle style,
  TapGestureRecognizer r,
) => WidgetSpan(
  alignment: PlaceholderAlignment.baseline,
  baseline: TextBaseline.alphabetic,
  child: InkWell(
    key: Key(key),
    onTap: r.onTap,
    child: Text(label, style: style),
  ),
);

class _LegalText extends StatelessWidget {
  const _LegalText({required this.terms, required this.privacy});
  final TapGestureRecognizer terms;
  final TapGestureRecognizer privacy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final base = AppText.body.copyWith(
      fontSize: 12.5,
      height: 1.5,
      color: AppColors.slate600,
    );
    final link = base.copyWith(
      color: AppColors.teal,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.teal,
    );
    return SizedBox(
      width: double.infinity,
      child: Text.rich(
        TextSpan(
          style: base,
          children: [
            TextSpan(text: l10n.legalPrefix),
            _link('login_terms_link', l10n.termsOfService, link, terms),
            TextSpan(text: l10n.legalAnd),
            _link('login_privacy_link', l10n.privacyPolicy, link, privacy),
            const TextSpan(text: '.'),
          ],
        ),
        key: const Key('login_legal_text'),
        textAlign: TextAlign.center,
      ),
    );
  }
}
