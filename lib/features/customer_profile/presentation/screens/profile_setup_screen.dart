import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/localization/failure_message.dart';
import 'package:sevanest_customer/core/session/auth_state.dart';
import 'package:sevanest_customer/core/widgets/labeled_field.dart';
import 'package:sevanest_customer/core/widgets/sn_button.dart';
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
        body: AuthBackdrop(
          archAlignment: const Alignment(0.8, -0.7),
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
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Semantics(
                              header: true,
                              child: Text(
                                l10n.profileSetupTitle,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              l10n.profileSetupSubtitle,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          l10n.profileStep,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
                                LabeledField(
                                  name: 'profile_name_field',
                                  controller: _name,
                                  label: l10n.fullNameLabel,
                                  hint: l10n.fullNameHint,
                                  helper: l10n.fullNameHelp,
                                  error: nameError,
                                  enabled: !form.busy,
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
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.done,
                                  autofillHints: const [AutofillHints.email],
                                  onChanged: (_) => setState(() {}),
                                  onSubmitted: (_) => _submit(),
                                ),
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
                                LanguageChips(
                                  selected: _language,
                                  onSelected: form.busy
                                      ? null
                                      : (c) => setState(() => _language = c),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  l10n.chooseLanguageHint,
                                  style: const TextStyle(
                                    color: AppColors.slate,
                                    fontSize: 15,
                                  ),
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
                          isLoading: form.busy,
                          onPressed: isValidName(_name.text) && !form.busy
                              ? _submit
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          l10n.ageConfirm,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.slate,
                            fontSize: 15,
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
