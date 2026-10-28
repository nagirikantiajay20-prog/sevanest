import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/localization/failure_message.dart';
import 'package:sevanest_customer/core/widgets/async_value_view.dart';
import 'package:sevanest_customer/core/widgets/labeled_field.dart';
import 'package:sevanest_customer/core/widgets/sn_button.dart';
import 'package:sevanest_customer/core/widgets/sn_header.dart';
import 'package:sevanest_customer/features/customer_profile/domain/customer_profile.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/providers/customer_profile_providers.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/widgets/language_chips.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/widgets/profile_photo_avatar.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';
import 'package:sevanest_customer/shared/utils/validators.dart';

/// `/profile` (modules/02, screen 2.4): read mode, with an inline edit mode. The mobile number
/// is the login identity and is never editable.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.canvasCool,
      body: Column(
        children: [
          SnHeader(
            title: l10n.profileTitle,
            onBack: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: AsyncValueView<CustomerProfile>(
              value: ref.watch(profileProvider),
              onRetry: () => ref.invalidate(profileProvider),
              data: (p) => _ProfileBody(profile: p),
            ),
          ),
        ],
      ),
    );
  }
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
  late final _mobile = TextEditingController(text: widget.profile.mobile);
  late String _language = widget.profile.preferredLanguage;
  bool _editing = false;
  bool _attempted = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _mobile.dispose();
    super.dispose();
  }

  bool get _changed =>
      _name.text.trim() != widget.profile.name ||
      _email.text.trim() != widget.profile.email ||
      _language != widget.profile.preferredLanguage;

  void _resetFields() {
    _name.text = widget.profile.name;
    _email.text = widget.profile.email;
    _language = widget.profile.preferredLanguage;
    _attempted = false;
  }

  Future<bool> _confirmDiscard() {
    final l10n = AppLocalizations.of(context);
    return confirmDialog(
      context,
      title: l10n.discardTitle,
      body: l10n.discardBody,
      confirmLabel: l10n.discard,
      cancelLabel: l10n.keepEditing,
      confirmKey: const Key('profile_discard_confirm_btn'),
    );
  }

  Future<void> _cancel() async {
    if (_changed && !await _confirmDiscard()) return;
    if (!mounted) return;
    setState(() {
      _resetFields();
      _editing = false;
    });
  }

  Future<void> _save() async {
    setState(() => _attempted = true);
    if (!isValidName(_name.text) || !isValidEmail(_email.text)) return;
    final messenger = ScaffoldMessenger.of(context);
    final saved = AppLocalizations.of(context).profileUpdated;
    final updated = await ref
        .read(profileFormProvider.notifier)
        .submit(
          create: false,
          name: _name.text,
          email: _email.text,
          preferredLanguage: _language,
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
    final language = profileLanguages
        .firstWhere(
          (l) => l.code == p.preferredLanguage,
          orElse: () => profileLanguages.first,
        )
        .label;

    return PopScope(
      canPop: !(_editing && _changed),
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        if (await _confirmDiscard()) nav.pop();
      },
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Center(
            child: ProfilePhotoAvatar(
              radius: 48,
              initials: profileInitials(p.name),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          LabeledField(
            name: 'profile_name_field',
            label: l10n.fullNameLabel,
            controller: _name,
            readOnly: !_editing,
            enabled: !form.busy,
            error: _editing && _attempted && !isValidName(_name.text)
                ? l10n.nameInvalid
                : fieldErrors['name'],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.lg),
          LabeledField(
            name: 'profile_email_field',
            label: l10n.emailLabel,
            controller: _email,
            readOnly: !_editing,
            enabled: !form.busy,
            keyboardType: TextInputType.emailAddress,
            error: _editing && _attempted && !isValidEmail(_email.text)
                ? l10n.emailInvalid
                : fieldErrors['email'],
            onChanged: (_) => setState(() {}),
          ),
          if (p.mobile != null) ...[
            const SizedBox(height: AppSpacing.lg),
            LabeledField(
              name: 'profile_mobile_field',
              label: l10n.mobileLabel,
              controller: _mobile,
              readOnly: true,
              helper: l10n.profileMobileLocked,
              suffixIcon: const Icon(
                Icons.lock_outline,
                color: AppColors.slate,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.preferredLanguage,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_editing)
            LanguageChips(
              selected: _language,
              onSelected: form.busy
                  ? null
                  : (c) => setState(() => _language = c),
            )
          else
            Text(
              language,
              key: const Key('profile_language_value'),
              style: const TextStyle(color: AppColors.ink, fontSize: 18),
            ),
          if (p.verificationStatus != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.sm,
              children: [
                Text(
                  l10n.verificationLabel,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                // Backend-supplied status, shown as-is (AGENTS §27): never derived client-side.
                Chip(
                  key: const Key('profile_verification_chip'),
                  label: Text(p.verificationStatus!),
                ),
              ],
            ),
          ],
          if (general != null) ...[
            const SizedBox(height: AppSpacing.md),
            FormErrorBanner(general, key: const Key('profile_error_banner')),
          ],
          const SizedBox(height: AppSpacing.lg),
          if (_editing) ...[
            SnButton(
              key: const Key('profile_save_btn'),
              label: l10n.save,
              loadingLabel: l10n.saving,
              isLoading: form.busy,
              onPressed: _changed && !form.busy ? _save : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            SnButton(
              key: const Key('profile_cancel_btn'),
              label: l10n.cancel,
              variant: SnButtonVariant.secondary,
              onPressed: form.busy ? null : _cancel,
            ),
          ] else
            SnButton(
              key: const Key('profile_edit_btn'),
              label: l10n.edit,
              icon: Icons.edit_outlined,
              variant: SnButtonVariant.secondary,
              onPressed: () => setState(() => _editing = true),
            ),
        ],
      ),
    );
  }
}
