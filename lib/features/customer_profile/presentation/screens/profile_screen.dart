import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/localization/failure_message.dart';
import 'package:sevanest_customer/core/widgets/async_value_view.dart';
import 'package:sevanest_customer/core/widgets/labeled_field.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart';
import 'package:sevanest_customer/features/customer_profile/domain/customer_profile.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/providers/customer_profile_providers.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/widgets/profile_photo_avatar.dart';
import 'package:sevanest_customer/features/interview_trial/presentation/widgets/interview_detail_parts.dart'
    show DashedRule;
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_page.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';
import 'package:sevanest_customer/shared/utils/validators.dart';

/// `/profile` (modules/02, screen 2.4; design: Find a Worker > My profile): read mode, with an
/// inline edit mode. The mobile number is the login identity and is never editable.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(profileProvider);
    final profile = value.value;
    if (profile != null) return _ProfileBody(profile: profile);
    final l10n = AppLocalizations.of(context);
    return FindGlassPage(
      title: l10n.profileTitle,
      backLabel: l10n.back,
      onBack: () => Navigator.of(context).maybePop(),
      body: AsyncValueView<CustomerProfile>(
        value: value,
        onRetry: () => ref.invalidate(profileProvider),
        data: (_) => const SizedBox.shrink(),
      ),
    );
  }
}

/// "+91 98765 43210" from whatever the backend stores.
String _displayMobile(String mobile) {
  final d = mobile.replaceAll(RegExp(r'\D'), '');
  if (d.length < 10) return mobile;
  final n = d.substring(d.length - 10);
  return '+91 ${n.substring(0, 5)} ${n.substring(5)}';
}

class _ProfileBody extends ConsumerStatefulWidget {
  const _ProfileBody({required this.profile});
  final CustomerProfile profile;

  @override
  ConsumerState<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends ConsumerState<_ProfileBody> {
  late final _name = TextEditingController(text: widget.profile.name);
  late final _email = TextEditingController(text: widget.profile.email);
  bool _editing = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  bool get _changed =>
      _name.text.trim() != widget.profile.name ||
      _email.text.trim() != widget.profile.email;

  bool get _valid => isValidName(_name.text) && isValidEmail(_email.text);

  Future<bool> _confirmDiscard() {
    final l10n = AppLocalizations.of(context);
    return showDiscoverDiscard(
      context,
      title: l10n.discardTitle,
      body: l10n.discardBody,
      keep: l10n.keepEditing,
      discard: l10n.discard,
      keepKey: const Key('dialog_cancel_btn'),
      discardKey: const Key('profile_discard_confirm_btn'),
    );
  }

  Future<void> _cancel() async {
    if (_changed && !await _confirmDiscard()) return;
    if (!mounted) return;
    setState(() {
      _name.text = widget.profile.name;
      _email.text = widget.profile.email;
      _editing = false;
    });
  }

  Future<void> _save() async {
    if (!_valid) return;
    final messenger = ScaffoldMessenger.of(context);
    final saved = AppLocalizations.of(context).profileUpdated;
    final updated = await ref
        .read(profileFormProvider.notifier)
        .submit(
          create: false,
          name: _name.text,
          email: _email.text,
          preferredLanguage: widget.profile.preferredLanguage,
        );
    if (updated == null || !mounted) return;
    // PATCH may not echo the mobile / verification fields: keep what we already know.
    ref
        .read(profileProvider.notifier)
        .replace(
          CustomerProfile(
            name: updated.name,
            email: updated.email,
            preferredLanguage: updated.preferredLanguage,
            mobile: updated.mobile ?? widget.profile.mobile,
            verificationStatus:
                updated.verificationStatus ?? widget.profile.verificationStatus,
          ),
        );
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(saved)));
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final form = ref.watch(profileFormProvider);
    final failure = form.failure;
    final fieldErrors = failure is ValidationFailure
        ? failure.fieldErrors
        : const <String, String>{};
    final general =
        failure != null &&
            !(failure is ValidationFailure && fieldErrors.isNotEmpty)
        ? failureMessage(l10n, failure)
        : null;
    final p = widget.profile;
    // While editing the header follows the draft, as in the design.
    final shownName = _editing ? _name.text.trim() : p.name;
    final language = profileLanguages
        .firstWhere(
          (l) => l.code == p.preferredLanguage,
          orElse: () => profileLanguages.first,
        )
        .label;
    // Live, as in the design: Save stays disabled while a field is invalid.
    final showErrors = _editing;

    return PopScope(
      canPop: !(_editing && _changed),
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        if (await _confirmDiscard()) nav.pop();
      },
      child: FindGlassPage(
        title: l10n.profileTitle,
        backLabel: l10n.back,
        onBack: () => Navigator.of(context).maybePop(),
        bottom: _editing
            ? Row(
                children: [
                  _OutlineButton(
                    key: const Key('profile_cancel_btn'),
                    label: l10n.cancel,
                    onPressed: form.busy ? null : _cancel,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Builder(
                      builder: (ctx) => AuthCta(
                        key: const Key('profile_save_btn'),
                        clock: DiscoverClock.of(ctx),
                        label: l10n.profileSaveChanges,
                        loadingLabel: l10n.saving,
                        loading: form.busy,
                        breathe: true,
                        showArrow: false,
                        radius: 18,
                        height: 58,
                        onPressed: _changed && _valid && !form.busy
                            ? _save
                            : null,
                      ),
                    ),
                  ),
                ],
              )
            : null,
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          children: [
            DiscoverRise(
              delayMs: 0,
              child: Column(
                children: [
                  ProfilePhotoAvatar(
                    radius: 42,
                    initials: profileInitials(shownName),
                    gradient: const [AppColors.teal, dsSky],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    shownName,
                    key: const Key('profile_name_heading'),
                    textAlign: TextAlign.center,
                    style: authSerif(26, 1.2),
                  ),
                  if (p.mobile != null) ...[
                    const SizedBox(height: 10),
                    _Pill(
                      icon: Icons.check_rounded,
                      label: l10n.profileMobileVerified,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            DiscoverRise(
              delayMs: 80,
              child: DiscoverGlass(
                radius: 26,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Row(
                        label: l10n.fullNameLabel,
                        child: _editing
                            ? _Input(
                                name: 'profile_name_field',
                                controller: _name,
                                enabled: !form.busy,
                                autofill: AutofillHints.name,
                                error: showErrors && !isValidName(_name.text)
                                    ? l10n.nameInvalid
                                    : fieldErrors['name'],
                                onChanged: (_) => setState(() {}),
                              )
                            : _Value(
                                p.name,
                                key: const Key('profile_name_value'),
                              ),
                      ),
                      const DashedRule(),
                      _Row(
                        label: l10n.emailLabel,
                        child: _editing
                            ? _Input(
                                name: 'profile_email_field',
                                controller: _email,
                                enabled: !form.busy,
                                autofill: AutofillHints.email,
                                keyboardType: TextInputType.emailAddress,
                                error: showErrors && !isValidEmail(_email.text)
                                    ? l10n.emailInvalid
                                    : fieldErrors['email'],
                                onChanged: (_) => setState(() {}),
                              )
                            : _Value(
                                p.email,
                                key: const Key('profile_email_value'),
                              ),
                      ),
                      if (p.mobile != null) ...[
                        const DashedRule(),
                        _Row(
                          label: l10n.profileMobileFixed,
                          icon: Icons.lock_outline,
                          child: _Value(
                            _displayMobile(p.mobile!),
                            key: const Key('profile_mobile_value'),
                          ),
                        ),
                      ],
                      const DashedRule(),
                      _Row(
                        label: l10n.languageLabel,
                        child: _Value(
                          language,
                          key: const Key('profile_language_value'),
                        ),
                      ),
                      if (p.verificationStatus != null) ...[
                        const DashedRule(),
                        // Backend-supplied status, shown as-is (AGENTS §27): never derived.
                        _Row(
                          label: l10n.verificationLabel,
                          child: _Value(
                            p.verificationStatus!,
                            key: const Key('profile_verification_chip'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (general != null) ...[
              const SizedBox(height: AppSpacing.md),
              FormErrorBanner(general, key: const Key('profile_error_banner')),
            ],
            if (!_editing) ...[
              const SizedBox(height: 18),
              DiscoverRise(
                delayMs: 140,
                child: Center(
                  child: _EditPill(
                    label: l10n.profileEditBtn,
                    onPressed: () => setState(() => _editing = true),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One `.fd` line of the glass card: small muted label over a value or an input.
class _Row extends StatelessWidget {
  const _Row({required this.label, required this.child, this.icon});
  final String label;
  final IconData? icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: dsMuted),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                style: AppText.body.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: dsMuted,
                ),
              ),
            ),
          ],
        ),
        child,
      ],
    ),
  );
}

class _Value extends StatelessWidget {
  const _Value(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text(
      text,
      style: AppText.body.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: dsNavy,
      ),
    ),
  );
}

/// White 48 px input of the edit mode; the error line is keyed `${name}_error`.
class _Input extends StatelessWidget {
  const _Input({
    required this.name,
    required this.controller,
    required this.enabled,
    required this.onChanged,
    required this.autofill,
    this.error,
    this.keyboardType,
  });

  final String name;
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final String autofill;
  final String? error;
  final TextInputType? keyboardType;

  static const _danger = AppColors.rose700;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder edge(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: c, width: 1.5),
    );
    final idle = error != null ? _danger : dsNavy.withValues(alpha: 0.2);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            key: Key(name),
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            autofillHints: [autofill],
            onChanged: onChanged,
            style: AppText.body.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: dsNavy,
            ),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              enabledBorder: edge(idle),
              disabledBorder: edge(idle),
              focusedBorder: edge(error != null ? _danger : AppColors.teal),
            ),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                error!,
                key: Key('${name}_error'),
                style: AppText.body.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _danger,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Mint "Mobile verified" chip under the name.
class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.tealD6EFEA,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.teal0B5A53),
        const SizedBox(width: 5),
        Text(
          label,
          style: AppText.body.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.teal0B5A53,
          ),
        ),
      ],
    ),
  );
}

/// Teal-outlined "Edit profile" pill.
class _EditPill extends StatelessWidget {
  const _EditPill({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    key: const Key('profile_edit_btn'),
    onPressed: onPressed,
    icon: const Icon(Icons.edit_outlined, size: 16),
    label: Text(label),
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(0, 44),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      foregroundColor: AppColors.teal,
      backgroundColor: AppColors.surface.withValues(alpha: 0.8),
      shape: const StadiumBorder(),
      side: BorderSide(
        color: AppColors.teal.withValues(alpha: 0.45),
        width: 1.5,
      ),
      textStyle: AppText.body.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

/// White, navy-outlined secondary button of the bottom bar (Cancel).
class _OutlineButton extends StatelessWidget {
  const _OutlineButton({
    required this.label,
    required this.onPressed,
    super.key,
  });
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(0, 58),
      padding: const EdgeInsets.symmetric(horizontal: 22),
      foregroundColor: dsNavy,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      side: BorderSide(color: dsNavy.withValues(alpha: 0.25), width: 1.5),
      textStyle: AppText.body.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    ),
    child: Text(label),
  );
}
