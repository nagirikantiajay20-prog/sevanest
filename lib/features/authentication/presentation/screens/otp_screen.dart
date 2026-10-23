import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/localization/failure_message.dart';
import 'package:sevanest_customer/core/widgets/sn_button.dart';
import 'package:sevanest_customer/core/widgets/sn_card.dart';
import 'package:sevanest_customer/core/widgets/sn_photo.dart';
import 'package:sevanest_customer/features/authentication/domain/auth_repository.dart';
import 'package:sevanest_customer/features/authentication/presentation/providers/auth_providers.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_widgets.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

enum _BoxStyle { normal, error, success, locked }

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
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
        otp.phase != OtpPhase.invalidOtp &&
        otp.phase != OtpPhase.expired;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.ivory,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.ivory, AppColors.surface],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 380,
              child: SnPhotoBackdrop(
                asset: AppPhotos.room,
                alignment: Alignment.topCenter,
              ),
            ),
            SafeArea(
              child: CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AuthBackButton(onPressed: _leave),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              Image.asset(
                                'assets/branding/logo_mark.png',
                                height: 44,
                                excludeFromSemantics: true,
                              ),
                              const SizedBox(width: AppSpacing.s12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.appName,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppText.screenTitle,
                                    ),
                                    Text(
                                      l10n.brandCaption,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppText.body.copyWith(
                                        fontSize: 10,
                                        letterSpacing: 1.2,
                                        color: AppColors.slate400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Semantics(
                            header: true,
                            child: Text(
                              l10n.otpTitle,
                              style: AppText.display.copyWith(fontSize: 32),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            l10n.otpEnterCode(otpLength),
                            style: AppText.bodyLarge,
                          ),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  '+91 ${_spaced(otp.mobile)}',
                                  key: const Key('otp_mobile_text'),
                                  style: AppText.title.copyWith(
                                    fontFamily: AppFonts.body,
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
                                onPressed: _leave,
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  color: AppColors.slate,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          SnCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _OtpBoxes(
                                  controller: _controller,
                                  focusNode: _focus,
                                  style: style,
                                  enabled: otp.canVerify,
                                  onChanged: (_) {
                                    ref
                                        .read(otpControllerProvider.notifier)
                                        .codeEdited();
                                    setState(() {});
                                  },
                                  onSubmitted: _verify,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                _Status(otp: otp, onResend: _resend),
                                const SizedBox(height: AppSpacing.md),
                                _VerifyButton(
                                  loading: otp.phase == OtpPhase.verifying,
                                  verified: isVerified,
                                  onPressed: canSubmit ? _verify : null,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.lock_outline,
                                      size: 20,
                                      color: AppColors.teal,
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Text(
                                        l10n.otpFooter(
                                          (otp.expiresInSeconds / 60).ceil(),
                                        ),
                                        style: AppText.body,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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

  static String _spaced(String d) =>
      d.length > 5 ? '${d.substring(0, 5)} ${d.substring(5)}' : d;
}

class _VerifyButton extends StatelessWidget {
  const _VerifyButton({
    required this.loading,
    required this.verified,
    required this.onPressed,
  });

  final bool loading;
  final bool verified;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (verified) {
      return FilledButton.icon(
        key: const Key('otp_verify_btn'),
        onPressed: null,
        style: FilledButton.styleFrom(
          disabledBackgroundColor: AppColors.teal,
          disabledForegroundColor: Colors.white,
        ),
        icon: const Icon(Icons.check_rounded),
        label: Text(l10n.verifiedLabel),
      );
    }
    return SnButton(
      key: const Key('otp_verify_btn'),
      label: l10n.verifyContinue,
      loadingLabel: l10n.verifying,
      isLoading: loading,
      onPressed: onPressed,
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
      return Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 22),
          const SizedBox(width: AppSpacing.sm),
          Text(
            l10n.numberVerified,
            key: const Key('otp_verified_text'),
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    if (otp.isLocked) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Consumer(
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
            TextSpan(
              style: const TextStyle(color: AppColors.slate, fontSize: 17),
              children: [
                TextSpan(text: countdown.substring(0, timeAt)),
                TextSpan(
                  text: time,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (error != null)
          Semantics(
            liveRegion: true,
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColors.danger,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    error,
                    key: const Key('otp_error_text'),
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        resendWidget,
        if (otp.secondsLeft == 0 && error == null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.otpDidntGet,
            style: const TextStyle(color: AppColors.slate, fontSize: 16),
          ),
        ],
      ],
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
    required this.controller,
    required this.focusNode,
    required this.style,
    required this.enabled,
    required this.onChanged,
    required this.onSubmitted,
  });

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
                    if (i > 0) const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _Box(
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
  const _Box({required this.char, required this.focused, required this.style});

  final String char;
  final bool focused;
  final _BoxStyle style;

  @override
  Widget build(BuildContext context) {
    final border = switch (style) {
      _BoxStyle.error => AppColors.danger,
      _BoxStyle.success => AppColors.success,
      _ when focused => AppColors.teal,
      _ => AppColors.hairline,
    };
    final fill = style == _BoxStyle.locked
        ? AppColors.navyMist
        : AppColors.surface;
    return AspectRatio(
      aspectRatio: 48 / 56,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: border, width: focused ? 2 : 1.5),
          boxShadow: focused
              ? [
                  BoxShadow(
                    color: AppColors.teal.withValues(alpha: 0.18),
                    spreadRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Text(
          char,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
