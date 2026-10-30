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
import 'package:sevanest_customer/features/addresses/domain/address.dart';
import 'package:sevanest_customer/features/addresses/presentation/providers/address_providers.dart';
import 'package:sevanest_customer/features/addresses/presentation/screens/address_form_screen.dart';
import 'package:sevanest_customer/features/authentication/presentation/screens/splash_screen.dart'
    show splashHoldProvider;
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/motion.dart';
import 'package:sevanest_customer/features/customer_profile/domain/customer_photo.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/providers/customer_photo_providers.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/providers/customer_profile_providers.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/widgets/language_chips.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/widgets/profile_photo_avatar.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/widgets/profile_setup_widgets.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';
import 'package:sevanest_customer/shared/utils/validators.dart';

/// Room photo under an ivory wash, with a teal glow top-right and an amber one lower left.
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
        AppColors.ivory.withValues(alpha: 0.74),
        AppColors.ivory.withValues(alpha: 0.42),
        AppColors.ivory.withValues(alpha: 0.8),
      ],
      stops: const [0, 0.35, 1],
    ),
  ],
  glows: const [
    AuthGlow(Color(0x520F766E), 260, top: -70, right: -80),
    AuthGlow(Color(0x4DF59E0B), 260, top: 560, left: -100, delayMs: 6000),
  ],
);

/// Shown once after the first login (modules/02, screen 2.1). Back is disabled: the profile is mandatory.
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen>
    with TickerProviderStateMixin {
  final _name = TextEditingController();
  final _email = TextEditingController();
  late final _clock = ScreenClock(
    this,
    motion: ref.read(splashHoldProvider) > Duration.zero,
  );
  late final _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  final _addressKey = GlobalKey();
  Offset _burstOrigin = Offset.zero;
  String _language = 'en';
  bool _nameTouched = false;
  bool _emailTouched = false;

  /// Home address typed on this screen; saved right after the profile (it needs the profile first).
  AddressInput? _address;
  PickedPhoto? _homePhoto;
  bool _addressTouched = false;
  bool _profileSaved = false;

  /// Photo chosen on this screen; uploaded after the profile is saved.
  PickedPhoto? _photo;
  bool _saving = false;
  AppFailure? _addressFailure;

  @override
  void dispose() {
    _burst.dispose();
    _clock.dispose();
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _pickAddress() async {
    final picked = await showCollectAddressSheet(
      context,
      initial: _address,
      initialPhoto: _homePhoto,
    );
    if (picked != null && mounted) {
      setState(() {
        _address = picked.input;
        _homePhoto = picked.photo;
        _addressFailure = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _celebrate());
    }
  }

  /// Confetti from the address card (skipped when the system asks for no animations).
  void _celebrate() {
    final card = _addressKey.currentContext?.findRenderObject();
    final me = context.findRenderObject();
    if (!mounted ||
        !_clock.animating ||
        card is! RenderBox ||
        me is! RenderBox) {
      return;
    }
    _burstOrigin = me.globalToLocal(
      card.localToGlobal(card.size.center(Offset.zero)),
    );
    _burst.forward(from: 0);
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
    final Address created;
    try {
      created = await ref.read(addressRepositoryProvider).create(address);
    } on AppFailure catch (f) {
      if (mounted) {
        setState(() {
          _saving = false;
          _addressFailure = f;
        });
      }
      return;
    }
    // Home photo: best effort too; it can be added again by editing the address.
    final homePhoto = _homePhoto;
    if (homePhoto != null) {
      try {
        await ref
            .read(addressRepositoryProvider)
            .uploadPhoto(created.id, homePhoto);
      } on AppFailure {
        // ignored on purpose
      }
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
    final nameOk = isValidName(_name.text);
    final emailOk = isValidEmail(_email.text);
    final nameError = _nameTouched && !nameOk
        ? l10n.nameInvalid
        : fieldErrors['name'];
    final emailError = _emailTouched && !emailOk
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
    final filledEmail = _email.text.trim().isNotEmpty && emailOk;
    final percent = profileProgress(
      nameOk: nameOk,
      emailOk: filledEmail,
      hasAddress: _address != null,
      hasPhoto: _photo != null,
    );
    final hint = !nameOk
        ? l10n.profileHintName
        : _address == null
        ? l10n.profileHintAddress
        : !filledEmail
        ? l10n.profileHintEmail
        : l10n.profileHintDone;

    return PopScope(
      canPop: false,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: AppColors.ivory,
        body: Stack(
          children: [
            Positioned.fill(
              child: RoomBackdrop(clock: _clock, style: _backdropStyle),
            ),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Rise(
                          clock: _clock,
                          start: 100,
                          duration: 700,
                          child: ProfileProgressPill(
                            percent: percent,
                            hint: hint,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Rise(
                          clock: _clock,
                          start: 220,
                          duration: 700,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Semantics(
                                      header: true,
                                      child: Text(
                                        l10n.profileSetupTitle,
                                        style: authSerif(35, 1.1),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      l10n.profileSetupSubtitle,
                                      style: AppText.bodyLarge.copyWith(
                                        color: AppColors.slate700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ProfileAvatarHalo(
                                clock: _clock,
                                child: ProfilePhotoAvatar(
                                  radius: 50,
                                  initials: profileInitials(_name.text),
                                  localBytes: _photo?.bytes,
                                  onPicked: (p) {
                                    if (!busy) setState(() => _photo = p);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Rise(
                      clock: _clock,
                      start: 250,
                      duration: 850,
                      child: AuthGlass(
                        radius: const BorderRadius.vertical(
                          top: Radius.circular(32),
                        ),
                        blur: 28,
                        gradient: const LinearGradient(
                          begin: Alignment(-0.5, -1),
                          end: Alignment(0.5, 1),
                          colors: [Color(0xE6FFFFFF), Color(0xB8FFFFFF)],
                        ),
                        border: setupGlassBorder,
                        shadow: setupGlassShadow,
                        child: SizedBox(
                          width: double.infinity,
                          child: _form(
                            l10n,
                            busy: busy,
                            nameOk: nameOk,
                            nameError: nameError,
                            emailError: emailError,
                            generalError: generalError,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: ConfettiBurst(progress: _burst, origin: _burstOrigin),
            ),
          ],
        ),
      ),
    );
  }

  Widget _form(
    AppLocalizations l10n, {
    required bool busy,
    required bool nameOk,
    required String? nameError,
    required String? emailError,
    required String? generalError,
  }) {
    final fill = Colors.white.withValues(alpha: 0.8);
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
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
                  enabled: !busy,
                  fill: fill,
                  prefixIcon: Icons.person_outline,
                  suffixIcon: nameOk
                      ? const Icon(Icons.check_circle, color: Color(0xFF16A34A))
                      : null,
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
                  fill: fill,
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
                  threeColumns: true,
                  selected: _language,
                  onSelected: busy
                      ? null
                      : (c) => setState(() => _language = c),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(l10n.chooseLanguageHint, style: AppText.body),
                const SizedBox(height: AppSpacing.lg),
                KeyedSubtree(
                  key: _addressKey,
                  child: ProfileAddressCard(
                    address: _address,
                    showError: _addressTouched && _address == null,
                    onTap: busy ? null : _pickAddress,
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
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            border: Border(
              top: BorderSide(color: authNavy.withValues(alpha: 0.08)),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AuthCta(
                    key: const Key('profile_continue_btn'),
                    clock: _clock,
                    breathe: true,
                    radius: 17,
                    label: l10n.continueLabel,
                    loadingLabel: l10n.saving,
                    loading: busy,
                    onPressed: nameOk && !busy ? _submit : null,
                  ),
                  const SizedBox(height: 9),
                  Text(
                    l10n.ageConfirm,
                    textAlign: TextAlign.center,
                    style: AppText.body.copyWith(
                      fontSize: 12.5,
                      color: AppColors.slate700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
