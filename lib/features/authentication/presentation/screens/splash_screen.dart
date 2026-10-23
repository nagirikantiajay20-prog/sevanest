import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/session/auth_state.dart';
import 'package:sevanest_customer/core/widgets/sn_button.dart';
import 'package:sevanest_customer/core/widgets/sn_card.dart';
import 'package:sevanest_customer/core/widgets/sn_photo.dart';
import 'package:sevanest_customer/features/authentication/presentation/providers/auth_providers.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_widgets.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/providers/account_providers.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// Shown as "slow" after this long (design: "Still loading. Your connection seems slow.").
const splashSlowAfter = Duration(seconds: 4);

/// Give up and offer retry after this long (modules/01_authentication.md: >8 s).
const splashTimeout = Duration(seconds: 8);

enum _Splash { loading, slow, failed }

/// Restores the stored session, validates it with `GET /customers/me`, then lets the router
/// redirect (login / profile setup / home). Never leaves the user on a blank screen.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  _Splash _state = _Splash.loading;
  Timer? _slowTimer;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_boot);
  }

  @override
  void dispose() {
    _slowTimer?.cancel();
    super.dispose();
  }

  Future<void> _boot() async {
    if (_running) return;
    _running = true;
    setState(() => _state = _Splash.loading);
    _slowTimer?.cancel();
    _slowTimer = Timer(splashSlowAfter, () {
      if (mounted && _state == _Splash.loading) {
        setState(() => _state = _Splash.slow);
      }
    });
    try {
      final auth = ref.read(authProvider.notifier);
      await auth.restore();
      if (!mounted || ref.read(authProvider) != AuthStatus.authenticated) {
        return;
      }
      final complete = await ref
          .read(authRepositoryProvider)
          .profileComplete()
          .timeout(splashTimeout);
      if (!mounted) return;
      ref.read(profileCompleteProvider.notifier).set(complete);
    } on UnauthorizedFailure {
      if (mounted) await ref.read(authProvider.notifier).signOut();
    } on Object {
      // Network, timeout, 5xx...: keep the session, let the user retry or sign in again.
      if (mounted) setState(() => _state = _Splash.failed);
    } finally {
      _slowTimer?.cancel();
      _running = false;
    }
  }

  Future<void> _signInAgain() => ref.read(authProvider.notifier).signOut();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final failed = _state == _Splash.failed;
    final version = ref.watch(appVersionProvider).value;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.surface, AppColors.surface, AppColors.ivory],
            stops: [0, 0.55, 1],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 320,
              child: SnPhotoBackdrop(
                asset: AppPhotos.splash,
                fadeFromBottom: false,
                alignment: Alignment.bottomCenter,
              ),
            ),
            SafeArea(
              child: CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: AppSpacing.xl),
                          const _Brand(),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            l10n.splashTagline,
                            textAlign: TextAlign.center,
                            style: AppText.display,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          const _TrustRow(),
                          const Spacer(),
                          if (failed) ...[
                            _FailedCard(
                              onRetry: _boot,
                              onSignInAgain: _signInAgain,
                            ),
                            AuthLink(
                              key: const Key('splash_support_link'),
                              label: l10n.contactSupport,
                              icon: Icons.headset_mic_outlined,
                              onTap: () => openSupport(context, ref),
                            ),
                          ] else
                            _Progress(slow: _state == _Splash.slow),
                          const SizedBox(height: AppSpacing.md),
                          if (version != null)
                            Text(
                              l10n.versionLabel(version),
                              style: AppText.body.copyWith(
                                color: AppColors.slate400,
                              ),
                            ),
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
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      label: l10n.appName,
      child: ExcludeSemantics(
        child: Column(
          children: [
            Image.asset('assets/branding/logo_mark.png', height: 120),
            const SizedBox(height: AppSpacing.sm),
            const Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Seva',
                    style: TextStyle(color: AppColors.brandInk),
                  ),
                  TextSpan(
                    text: 'Nest',
                    style: TextStyle(color: AppColors.teal),
                  ),
                ],
                style: TextStyle(
                  fontFamily: AppFonts.heading,
                  fontSize: 36,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.slow});
  final bool slow;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      liveRegion: true,
      label: slow ? l10n.splashSlow : l10n.splashLoading,
      child: ExcludeSemantics(
        child: Column(
          children: [
            SizedBox(
              width: 160,
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: slow ? 0.8 : 0.35),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOut,
                builder: (context, v, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    key: const Key('splash_progress'),
                    value: v,
                    minHeight: 4,
                    color: AppColors.teal,
                    backgroundColor: AppColors.hairline,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              slow ? l10n.splashSlow : l10n.splashLoading,
              textAlign: TextAlign.center,
              style: AppText.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _TrustRow extends StatelessWidget {
  const _TrustRow();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget item(IconData icon, String label) => Expanded(
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.tileWell,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.teal, size: 24),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppText.card.copyWith(fontSize: 13),
          ),
        ],
      ),
    );
    const divider = VerticalDivider(
      width: 1,
      thickness: 1,
      color: AppColors.hairline,
    );
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          item(Icons.verified_user_outlined, l10n.trustVerifiedWorkers),
          divider,
          item(Icons.credit_card_outlined, l10n.trustSecurePayments),
          divider,
          item(Icons.headset_mic_outlined, l10n.trustHelpSupport),
        ],
      ),
    );
  }
}

class _FailedCard extends StatelessWidget {
  const _FailedCard({required this.onRetry, required this.onSignInAgain});
  final VoidCallback onRetry;
  final VoidCallback onSignInAgain;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SnCard(
      child: Semantics(
        liveRegion: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.warnBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.warnIcon,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.splashFailedTitle,
              textAlign: TextAlign.center,
              style: AppText.screenTitle,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.splashFailedBody,
              textAlign: TextAlign.center,
              style: AppText.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            SnButton(
              key: const Key('splash_retry_btn'),
              label: l10n.tryAgain,
              icon: Icons.refresh_rounded,
              onPressed: onRetry,
            ),
            const SizedBox(height: AppSpacing.xs),
            TextButton(
              key: const Key('splash_login_btn'),
              onPressed: onSignInAgain,
              child: Text(l10n.signInAgain),
            ),
          ],
        ),
      ),
    );
  }
}
