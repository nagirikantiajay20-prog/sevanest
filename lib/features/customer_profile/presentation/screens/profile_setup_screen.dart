import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/localization/failure_message.dart';
import 'package:sevanest_customer/core/session/auth_state.dart';
import 'package:sevanest_customer/core/widgets/labeled_field.dart';
import 'package:sevanest_customer/core/widgets/sn_button.dart';
import 'package:sevanest_customer/core/widgets/sn_header.dart';
import 'package:sevanest_customer/core/widgets/sn_photo.dart';
import 'package:sevanest_customer/features/addresses/domain/address.dart';
import 'package:sevanest_customer/features/addresses/presentation/providers/address_providers.dart';
import 'package:sevanest_customer/features/addresses/presentation/screens/address_form_screen.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_widgets.dart';
import 'package:sevanest_customer/features/customer_profile/domain/customer_photo.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/providers/customer_photo_providers.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/providers/customer_profile_providers.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/widgets/language_chips.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/widgets/profile_photo_avatar.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';
import 'package:sevanest_customer/shared/utils/validators.dart';

/// Shown once after the first login (modules/02, screen 2.1). Back is disabled: the profile is mandatory.
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  String _language = 'en';
  bool _nameTouched = false;
  bool _emailTouched = false;

  /// Home address typed on this screen; saved right after the profile (it needs the profile first).
  AddressInput? _address;
  bool _addressTouched = false;
  bool _profileSaved = false;

  /// Photo chosen on this screen; uploaded after the profile is saved.
  PickedPhoto? _photo;
  bool _saving = false;
  AppFailure? _addressFailure;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _pickAddress() async {
    final picked = await showCollectAddressSheet(context, initial: _address);
    if (picked != null && mounted) {
      setState(() {
        _address = picked;
        _addressFailure = null;
      });
    }
  }

  Future<void> _submit() async {
    if (_saving) return;
    setState(() {
      _nameTouched = true;
      _emailTouched = true;
      _addressTouched = true;
    });
    final address = _address;
    if (!isValidName(_name.text) ||
        !isValidEmail(_email.text) ||
        address == null) {
      return;
    }
    setState(() {
      _saving = true;
      _addressFailure = null;
    });
    // Profile first (the address belongs to it); a retry after an address failure skips this.
    if (!_profileSaved) {
      final saved = await ref
          .read(profileFormProvider.notifier)
          .submit(
            create: true,
            name: _name.text,
            email: _email.text,
            preferredLanguage: _language,
          );
      final exists = ref.read(profileFormProvider).failure is ConflictFailure;
      // 409: a profile already exists for this account (e.g. created on another device).
      if (saved == null && !exists) {
        if (mounted) setState(() => _saving = false);
        return;
      }
      _profileSaved = true;
    }
    try {
      await ref.read(addressRepositoryProvider).create(address);
    } on AppFailure catch (f) {
      if (mounted) {
        setState(() {
          _saving = false;
          _addressFailure = f;
        });
      }
      return;
    }
    // The photo needs the profile to exist. Best effort: a failure must not block sign-up; the
    // photo can be added again from Account.
    final photo = _photo;
    if (photo != null) {
      try {
        await ref.read(customerPhotoRepositoryProvider).upload(photo);
      } on AppFailure {
        // ignored on purpose
      }
    }
    if (!mounted) return;
    ref.invalidate(addressesProvider);
    setState(() => _saving = false);
    // Navigate first: flipping profileComplete would otherwise race the redirect.
    context.go(Routes.home);
    ref.read(profileCompleteProvider.notifier).set(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final form = ref.watch(profileFormProvider);
    final failure = form.failure;
    final fieldErrors = failure is ValidationFailure
        ? failure.fieldErrors
        : const <String, String>{};
    final nameError = _nameTouched && !isValidName(_name.text)
        ? l10n.nameInvalid
        : fieldErrors['name'];
    final emailError = _emailTouched && !isValidEmail(_email.text)
        ? l10n.emailInvalid
        : fieldErrors['email'];
    final busy = form.busy || _saving;
    final addressFailure = _addressFailure;
    final generalError = addressFailure != null
        ? failureMessage(l10n, addressFailure)
        : failure != null &&
              !(failure is ValidationFailure && fieldErrors.isNotEmpty) &&
              failure is! ConflictFailure
        ? failureMessage(l10n, failure)
        : null;

    return PopScope(
      canPop: false,
      child: Scaffold(
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
                bottom: false,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
                        AppSpacing.lg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SnStepBar(step: 3, total: 4),
                          const SizedBox(height: AppSpacing.lg),
                          Semantics(
                            header: true,
                            child: Text(
                              l10n.profileSetupTitle,
                              style: AppText.display,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            l10n.profileSetupSubtitle,
                            style: AppText.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: AuthSheet(
                        child: Column(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Center(
                                      child: ProfilePhotoAvatar(
                                        radius: 44,
                                        initials: profileInitials(_name.text),
                                        localBytes: _photo?.bytes,
                                        onPicked: (p) {
                                          if (!busy) setState(() => _photo = p);
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.lg),
                                    LabeledField(
                                      name: 'profile_name_field',
                                      controller: _name,
                                      label: l10n.fullNameLabel,
                                      hint: l10n.fullNameHint,
                                      helper: l10n.fullNameHelp,
                                      error: nameError,
                                      enabled: !busy,
                                      prefixIcon: Icons.person_outline,
                                      textInputAction: TextInputAction.next,
                                      autofillHints: const [AutofillHints.name],
                                      onChanged: (_) => setState(() {}),
                                    ),
                                    const SizedBox(height: AppSpacing.lg),
                                    LabeledField(
                                      name: 'profile_email_field',
                                      controller: _email,
                                      label: l10n.emailLabel,
                                      hint: l10n.emailHint,
                                      helper: l10n.emailHelp,
                                      error: emailError,
                                      enabled: !busy,
                                      prefixIcon: Icons.mail_outline,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.done,
                                      autofillHints: const [
                                        AutofillHints.email,
                                      ],
                                      onChanged: (_) => setState(() {}),
                                      onSubmitted: (_) => _submit(),
                                    ),
                                    const SizedBox(height: AppSpacing.lg),
                                    Text(
                                      l10n.preferredLanguage,
                                      style: AppText.label.copyWith(
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    LanguageChips(
                                      selected: _language,
                                      onSelected: busy
                                          ? null
                                          : (c) =>
                                                setState(() => _language = c),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Text(
                                      l10n.chooseLanguageHint,
                                      style: AppText.body,
                                    ),
                                    const SizedBox(height: AppSpacing.lg),
                                    _AddressCard(
                                      address: _address,
                                      showError:
                                          _addressTouched && _address == null,
                                      onTap: busy ? null : _pickAddress,
                                    ),
                                    if (generalError != null) ...[
                                      const SizedBox(height: AppSpacing.md),
                                      FormErrorBanner(
                                        generalError,
                                        key: const Key('profile_error_banner'),
                                      ),
                                    ],
                                    const SizedBox(height: AppSpacing.md),
                                  ],
                                ),
                              ),
                            ),
                            SnButton(
                              key: const Key('profile_continue_btn'),
                              label: l10n.continueLabel,
                              loadingLabel: l10n.saving,
                              icon: Icons.arrow_forward_rounded,
                              isLoading: busy,
                              onPressed: isValidName(_name.text) && !busy
                                  ? _submit
                                  : null,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              l10n.ageConfirm,
                              textAlign: TextAlign.center,
                              style: AppText.body.copyWith(
                                color: AppColors.slate400,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
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

/// Design 04: the "Add your home address" card; shows the address once it is typed.
class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.showError,
    required this.onTap,
  });

  final AddressInput? address;
  final bool showError;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final a = address;
    final title = a == null
        ? l10n.profileAddAddressTitle
        : '${(a.label ?? '').trim().isEmpty ? 'Home' : a.label!.trim()} \u00b7 ${a.area}';
    final sub = a == null
        ? l10n.profileAddAddressSub
        : [
            a.line,
            a.line2,
            '${a.city} ${a.pincode}',
          ].where((s) => s != null && s.isNotEmpty).join(', ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          child: InkWell(
            key: const Key('profile_address_card'),
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.s12),
              decoration: BoxDecoration(
                color: a == null ? AppColors.tealMist : AppColors.successBg,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(
                  color: showError ? AppColors.danger : AppColors.successLine,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(
                      Icons.home_outlined,
                      color: AppColors.teal,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppText.card),
                        Text(
                          sub,
                          key: const Key('profile_address_summary'),
                          style: AppText.body,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.slate),
                ],
              ),
            ),
          ),
        ),
        if (showError)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              l10n.profileAddressRequired,
              key: const Key('profile_address_error'),
              style: AppText.body.copyWith(color: AppColors.danger),
            ),
          ),
      ],
    );
  }
}
