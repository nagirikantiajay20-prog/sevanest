import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/core/config/app_config.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/session/auth_state.dart';
import 'package:sevanest_customer/core/widgets/sn_button.dart';
import 'package:sevanest_customer/features/authentication/presentation/providers/auth_providers.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_widgets.dart';
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
    return Scaffold(
      body: AuthBackdrop(
        archAlignment: const Alignment(0, -0.05),
        archSize: const Size(315, 570),
        child: SafeArea(
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
                      const Spacer(flex: 5),
                      const LogoTile(size: 104),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        l10n.appName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        l10n.splashTagline,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 20,
                        ),
                      ),
                      Text(
                        l10n.splashTaglineHi,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 16,
                        ),
                      ),
                      if (failed) ...[
                        const Spacer(flex: 3),
                        _FailedCard(
                          onRetry: _boot,
                          onSignInAgain: _signInAgain,
                        ),
                        AuthLink(
                          key: const Key('splash_support_link'),
                          label: l10n.contactSupport,
                          icon: Icons.headset_mic_outlined,
                          onDark: true,
                          onTap: () => openSupport(context, ref),
                        ),
                      ] else ...[
                        const Spacer(flex: 5),
                        const _TrustRow(),
                        const Spacer(flex: 2),
                        _Progress(slow: _state == _Splash.slow),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        l10n.versionLabel(appVersionLabel),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 16,
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
      child: Column(
        children: [
          SizedBox(
            width: 160,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: slow ? 0.8 : 0.35),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOut,
              builder: (context, v, _) => ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  key: const Key('splash_progress'),
                  value: v,
                  minHeight: 4,
                  color: AppColors.amber,
                  backgroundColor: const Color(0xFF576C88),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            slow ? l10n.splashSlow : l10n.splashLoading,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 16,
            ),
          ),
        ],
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
          Icon(icon, color: Colors.white.withValues(alpha: 0.85), size: 28),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
    final divider = Container(
      width: 1,
      height: 56,
      color: Colors.white.withValues(alpha: 0.2),
    );
    return IntrinsicHeight(
      child: Row(
        children: [
          item(Icons.verified_user_outlined, l10n.trustVerifiedWorkers),
          divider,
          item(Icons.lock_outline, l10n.trustSecurePayments),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg + 4),
      ),
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
                color: AppColors.warn,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.splashFailedTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.splashFailedBody,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: AppColors.slate),
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
