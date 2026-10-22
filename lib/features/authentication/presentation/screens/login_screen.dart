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
import 'package:sevanest_customer/core/widgets/sn_bottom_sheet.dart';
import 'package:sevanest_customer/core/widgets/sn_button.dart';
import 'package:sevanest_customer/features/authentication/domain/auth_repository.dart';
import 'package:sevanest_customer/features/authentication/presentation/providers/auth_providers.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_widgets.dart';
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

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  late final TapGestureRecognizer _terms;
  late final TapGestureRecognizer _privacy;
  bool _showError = false;

  @override
  void initState() {
    super.initState();
    _terms = TapGestureRecognizer()
      ..onTap = () => _openLegal((c) => c.termsUrl);
    _privacy = TapGestureRecognizer()
      ..onTap = () => _openLegal((c) => c.privacyUrl);
    _focus.addListener(() {
      // Validate once the user leaves a non-empty field.
      if (!_focus.hasFocus && _controller.text.isNotEmpty) {
        setState(() => _showError = true);
      }
    });
  }

  @override
  void dispose() {
    _terms.dispose();
    _privacy.dispose();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  String get _digits => digitsOf(_controller.text);

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
      setState(() => _showError = true);
      return;
    }
    FocusScope.of(context).unfocus();
    await ref.read(otpControllerProvider.notifier).requestOtp(_digits);
  }

  Future<void> _chooseLanguage() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _LanguageSheet(),
    );
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
    final ready = _digits.length == 10 && !otp.busy && !otp.requestBlocked;

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
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
                        0,
                      ),
                      child: Row(
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
                          _LanguageChip(onTap: _chooseLanguage),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Semantics(
                              header: true,
                              child: Text(
                                l10n.loginHeadline,
                                style: AppText.display.copyWith(fontSize: 32),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.s12),
                            Text(l10n.loginSubhead, style: AppText.bodyLarge),
                            const SizedBox(height: AppSpacing.md),
                            const _HeroTrust(),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: AuthSheet(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Center(child: SnGrabber()),
                            const SizedBox(height: AppSpacing.md),
                            Semantics(
                              header: true,
                              child: Text(
                                l10n.loginHeading,
                                style: AppText.title,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              l10n.loginHelp(otpLength),
                              style: AppText.bodyLarge,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            _MobileField(
                              controller: _controller,
                              focusNode: _focus,
                              hasError: invalid,
                              enabled: !otp.busy,
                              onChanged: (_) => setState(() {}),
                              onSubmitted: (_) => _submit(),
                            ),
                            _Feedback(
                              invalid: invalid,
                              otp: otp,
                              invalidText: l10n.mobileInvalid,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            SnButton(
                              key: const Key('login_get_otp_btn'),
                              label: l10n.getOtp,
                              loadingLabel: l10n.sendingCode,
                              icon: Icons.arrow_forward_rounded,
                              isLoading: otp.phase == OtpPhase.requesting,
                              onPressed: ready ? _submit : null,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            const _PrivacyNote(),
                            const SizedBox(height: AppSpacing.md),
                            _LegalText(terms: _terms, privacy: _privacy),
                            const SizedBox(height: AppSpacing.md),
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
      ),
    );
  }
}

class _MobileField extends StatelessWidget {
  const _MobileField({
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.enabled,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final borderColor = hasError ? AppColors.danger : AppColors.hairline;
    const fieldText = TextStyle(
      fontFamily: AppFonts.body,
      color: AppColors.brandInk,
      fontSize: 18,
      fontWeight: FontWeight.w500,
    );
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        children: [
          const Text('+91', style: fieldText),
          Container(
            width: 1,
            height: 28,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
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
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Semantics(
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
                  invalidText,
                  key: const Key('login_mobile_error'),
                  style: AppText.bodyLarge.copyWith(color: AppColors.danger),
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
    padding: const EdgeInsets.only(top: AppSpacing.md),
    child: AuthNoticeCard(
      key: const Key('login_notice'),
      icon: icon,
      title: title,
      message: message,
    ),
  );
}

/// Hero rows: icon well, bold first word, muted rest (design 02).
class _HeroTrust extends StatelessWidget {
  const _HeroTrust();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget row(IconData icon, String label) {
      // ponytail: splits on the first space, fine for English-only V1; per-word strings when translating.
      final i = label.indexOf(' ');
      final head = i < 0 ? label : label.substring(0, i);
      final tail = i < 0 ? '' : label.substring(i + 1);
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.s12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.tileWell,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.teal, size: 20),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: head,
                      style: AppText.card.copyWith(fontSize: 15),
                    ),
                    if (tail.isNotEmpty)
                      TextSpan(text: '\n$tail', style: AppText.body),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        row(Icons.verified_user_outlined, l10n.loginTrustNearby),
        row(Icons.credit_card_outlined, l10n.trustSecurePayments),
        row(Icons.headset_mic_outlined, l10n.loginTrustSupport),
      ],
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: AppColors.tealMist,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.tileLine),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, color: AppColors.teal, size: 22),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.privateTitle, style: AppText.card),
                Text(l10n.privateBody, style: AppText.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalText extends StatelessWidget {
  const _LegalText({required this.terms, required this.privacy});
  final TapGestureRecognizer terms;
  final TapGestureRecognizer privacy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final base = AppText.body.copyWith(color: AppColors.slate);
    final link = base.copyWith(
      color: AppColors.teal,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.teal,
    );
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: l10n.legalPrefix),
          TextSpan(
            text: l10n.termsOfService,
            style: link,
            recognizer: terms,
            semanticsLabel: l10n.termsOfService,
          ),
          TextSpan(text: l10n.legalAnd),
          TextSpan(
            text: l10n.privacyPolicy,
            style: link,
            recognizer: privacy,
            semanticsLabel: l10n.privacyPolicy,
          ),
          const TextSpan(text: '.'),
        ],
      ),
      key: const Key('login_legal_text'),
      textAlign: TextAlign.center,
    );
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: AppLocalizations.of(context).languageButtonLabel,
      child: InkWell(
        key: const Key('login_language_btn'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          constraints: const BoxConstraints(minHeight: kMinTapTarget),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: AppColors.hairline),
            boxShadow: AppShadows.card,
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.language_rounded,
                color: AppColors.brandInk,
                size: 20,
              ),
              SizedBox(width: AppSpacing.xs),
              Text('EN', style: AppText.card),
              Icon(Icons.expand_more_rounded, color: AppColors.brandInk),
            ],
          ),
        ),
      ),
    );
  }
}

/// V1 ships English only (OPEN_QUESTIONS #16; `GET /app-config` lists `languages: ["en"]`).
/// The design's other languages are shown but not selectable until translations exist.
class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet();

  static const _languages = [
    ('English', 'English', true),
    ('हिन्दी', 'Hindi', false),
    ('తెలుగు', 'Telugu', false),
    ('தமிழ்', 'Tamil', false),
    ('ಕನ್ನಡ', 'Kannada', false),
    ('मराठी', 'Marathi', false),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: SnGrabber()),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Text(l10n.chooseLanguage, style: AppText.screenTitle),
                ),
                IconButton(
                  key: const Key('language_close_btn'),
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            Text(l10n.chooseLanguageHint, style: AppText.bodyLarge),
            const SizedBox(height: AppSpacing.sm),
            for (final (native, english, enabled) in _languages)
              ListTile(
                key: Key('language_$english'),
                contentPadding: EdgeInsets.zero,
                enabled: enabled,
                onTap: enabled ? () => Navigator.of(context).pop() : null,
                title: Text(
                  native,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(english),
                trailing: Icon(
                  enabled
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: enabled ? AppColors.teal : AppColors.slate,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
