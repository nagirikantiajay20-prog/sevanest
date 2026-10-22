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
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_widgets.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/providers/customer_profile_providers.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/widgets/language_chips.dart';
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

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _nameTouched = true;
      _emailTouched = true;
    });
    if (!isValidName(_name.text) || !isValidEmail(_email.text)) return;
    final controller = ref.read(profileFormProvider.notifier);
    final saved = await controller.submit(
      create: true,
      name: _name.text,
      email: _email.text,
      preferredLanguage: _language,
    );
    if (!mounted) return;
    final complete = ref.read(profileCompleteProvider.notifier);
    if (saved != null) {
      // Navigate first: flipping profileComplete would otherwise redirect /profile/setup to /home.
      context.go('${Routes.addressNew}?firstTime=true');
      complete.set(true);
    } else if (ref.read(profileFormProvider).failure is ConflictFailure) {
      // 409: a profile already exists for this account (e.g. created on another device).
      complete.set(true);
    }
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
    final generalError =
        failure != null &&
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
          child: SafeArea(
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
                      Text(l10n.profileSetupSubtitle, style: AppText.bodyLarge),
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
                                LabeledField(
                                  name: 'profile_name_field',
                                  controller: _name,
                                  label: l10n.fullNameLabel,
                                  hint: l10n.fullNameHint,
                                  helper: l10n.fullNameHelp,
                                  error: nameError,
                                  enabled: !form.busy,
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
                                  enabled: !form.busy,
                                  prefixIcon: Icons.mail_outline,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.done,
                                  autofillHints: const [AutofillHints.email],
                                  onChanged: (_) => setState(() {}),
                                  onSubmitted: (_) => _submit(),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                Text(
                                  l10n.preferredLanguage,
                                  style: AppText.label.copyWith(fontSize: 15),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                LanguageChips(
                                  selected: _language,
                                  onSelected: form.busy
                                      ? null
                                      : (c) => setState(() => _language = c),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  l10n.chooseLanguageHint,
                                  style: AppText.body,
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
                          isLoading: form.busy,
                          onPressed: isValidName(_name.text) && !form.busy
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
        ),
      ),
    );
  }
}
