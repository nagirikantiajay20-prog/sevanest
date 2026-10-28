import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/core/config/app_config.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/session/auth_state.dart';
import 'package:sevanest_customer/core/storage/secure_session_store.dart';
import 'package:sevanest_customer/core/widgets/sn_button.dart';
import 'package:sevanest_customer/core/widgets/sn_card.dart';
import 'package:sevanest_customer/core/widgets/sn_photo.dart';
import 'package:sevanest_customer/features/authentication/presentation/providers/auth_providers.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_widgets.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/providers/account_providers.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shown as "slow" after this long (design: "Still loading. Your connection seems slow.").
const splashSlowAfter = Duration(seconds: 4);

/// Give up and offer retry after this long (modules/01_authentication.md: >8 s).
const splashTimeout = Duration(seconds: 8);

/// Minimum time the branded splash stays up, so it never flashes past on a fast start.
const splashMinHold = Duration(milliseconds: 1800);

/// Overridden to [Duration.zero] in tests.
final splashHoldProvider = Provider<Duration>((_) => splashMinHold);

/// Whether the customer / worker choice is shown after the splash. Tests that only need to get
/// past the splash override it to false, which proceeds as a customer straight away.
final splashChoiceProvider = Provider<bool>((_) => true);

enum _Splash { loading, slow, choose, failed }

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

  /// What "Proceed with Customer App" does once the session check is done (restore or sign out).
  Future<void> Function()? _enter;
  bool _entering = false;

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
    // The router leaves the splash as soon as authProvider resolves, so resolve it last:
    // check the session and profile first, hold the branded screen, then navigate once.
    final hold = Future<void>.delayed(ref.read(splashHoldProvider));
    try {
      if (await ref.read(sessionStoreProvider).read() != null) {
        final complete = await ref
            .read(authRepositoryProvider)
            .profileComplete()
            .timeout(splashTimeout);
        if (!mounted) return;
        ref.read(profileCompleteProvider.notifier).set(complete);
      }
      await hold;
      _offerChoice(ref.read(authProvider.notifier).restore);
    } on UnauthorizedFailure {
      await hold;
      _offerChoice(ref.read(authProvider.notifier).signOut);
    } on Object {
      // Network, timeout, 5xx...: keep the session, let the user retry or sign in again.
      if (mounted) setState(() => _state = _Splash.failed);
    } finally {
      _slowTimer?.cancel();
      _running = false;
    }
  }

  void _offerChoice(Future<void> Function() enter) {
    if (!mounted) return;
    _enter = enter;
    if (!ref.read(splashChoiceProvider)) {
      unawaited(_proceedCustomer());
      return;
    }
    setState(() => _state = _Splash.choose);
  }

  Future<void> _proceedCustomer() async {
    if (_entering) return;
    _entering = true;
    try {
      await _enter?.call();
    } finally {
      _entering = false;
    }
  }

  /// The worker app is a separate application: open its configured link, never a made-up one.
  Future<void> _openWorkerApp() async {
    final url = ref.read(appConfigProvider).workerAppUrl;
    final uri = url.isEmpty ? null : Uri.tryParse(url);
    var opened = false;
    if (uri != null) {
      try {
        opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } on Object {
        // falls through to the message below
      }
    }
    if (opened || !mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).workerAppUnavailable),
        ),
      );
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
                          _Reveal(
                            delay: 350,
                            child: Text(
                              l10n.splashTagline,
                              textAlign: TextAlign.center,
                              style: AppText.display,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          const _Reveal(delay: 650, child: _TrustRow()),
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
                          ] else if (_state == _Splash.choose)
                            _EntryButtons(
                              onCustomer: _proceedCustomer,
                              onWorker: _openWorkerApp,
                            )
                          else
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

/// Fade + rise-in, started [delay] ms after the screen appears.
class _Reveal extends StatelessWidget {
  const _Reveal({required this.delay, required this.child});
  final int delay;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const total = 700;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total + delay),
      curve: Interval(delay / (total + delay), 1, curve: Curves.easeOutCubic),
      builder: (context, v, c) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 16 * (1 - v)), child: c),
      ),
      child: child,
    );
  }
}

/// Soft teal glow that breathes behind the logo.
class _Halo extends StatefulWidget {
  const _Halo({required this.child});
  final Widget child;

  @override
  State<_Halo> createState() => _HaloState();
}

class _HaloState extends State<_Halo> with SingleTickerProviderStateMixin {
  late final _c =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2200),
      )..repeat(
        reverse: true,
        count: 4,
      ); // settles, so idle tests and the failed card are not animating forever

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, child) => DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.teal.withValues(alpha: 0.10 + 0.12 * _c.value),
            blurRadius: 40 + 24 * _c.value,
            spreadRadius: 4 + 8 * _c.value,
          ),
        ],
      ),
      child: child,
    ),
    child: widget.child,
  );
}

class _Caption extends StatelessWidget {
  const _Caption();

  @override
  Widget build(BuildContext context) => Text(
    AppLocalizations.of(context).brandCaption,
    style: AppText.body.copyWith(
      fontSize: 12,
      letterSpacing: 2,
      fontWeight: FontWeight.w600,
      color: AppColors.slate600,
    ),
  );
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      label: l10n.appName,
      child: ExcludeSemantics(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, v, child) => Opacity(
            opacity: v,
            child: Transform.scale(scale: 0.88 + 0.12 * v, child: child),
          ),
          child: const Column(
            children: [
              _Halo(
                child: Image(
                  image: AssetImage('assets/branding/logo_mark.png'),
                  height: 120,
                ),
              ),
              SizedBox(height: AppSpacing.sm),
              Text.rich(
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
              SizedBox(height: AppSpacing.xs),
              _Caption(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Two equal, side-by-side entry points once the session check is done.
class _EntryButtons extends StatelessWidget {
  const _EntryButtons({required this.onCustomer, required this.onWorker});
  final VoidCallback onCustomer;
  final VoidCallback onWorker;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SnButton(
              key: const Key('splash_customer_btn'),
              label: l10n.proceedCustomerApp,
              onPressed: onCustomer,
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: SnButton(
              key: const Key('splash_worker_btn'),
              label: l10n.moveToWorkerApp,
              variant: SnButtonVariant.secondary,
              onPressed: onWorker,
            ),
          ),
        ],
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
