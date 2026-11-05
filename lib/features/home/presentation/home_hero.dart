import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// Rises and fades in once after [delayMs] (design: the `up` entrance, 0.75 s, staggered).
class HomeRise extends StatelessWidget {
  const HomeRise({required this.child, this.delayMs = 0, super.key});
  final Widget child;
  final int delayMs;

  static const _ms = 750;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: Duration(milliseconds: delayMs + _ms),
    curve: Interval(
      delayMs / (delayMs + _ms),
      1,
      curve: const Cubic(0.2, 0.7, 0.2, 1),
    ),
    child: child,
    builder: (_, v, c) => Opacity(
      opacity: v,
      child: Transform.translate(offset: Offset(0, 20 * (1 - v)), child: c),
    ),
  );
}

/// Navy frosted surface sitting on the hero photo (design `.gs`).
class NavyGlass extends StatelessWidget {
  const NavyGlass({
    required this.radius,
    required this.child,
    this.blur = 18,
    super.key,
  });
  final double radius;
  final double blur;
  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.navyDeep.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: AppColors.surface.withValues(alpha: 0.28)),
        ),
        child: child,
      ),
    ),
  );
}

/// Soft teal and amber glows behind the whole page (design `.aur`).
class HomeGlows extends StatelessWidget {
  const HomeGlows({super.key});

  Widget _glow(Color c, double size) => DecoratedBox(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [c, c.withValues(alpha: 0)]),
    ),
    child: SizedBox(width: size, height: size),
  );

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: 380,
            right: -150,
            child: _glow(AppColors.amber.withValues(alpha: 0.3), 380),
          ),
          Positioned(
            top: 700,
            left: -160,
            child: _glow(AppColors.teal.withValues(alpha: 0.25), 400),
          ),
        ],
      ),
    ),
  );
}

/// Full-bleed photo header: address and bell floating on top, greeting, headline and search at
/// the bottom (design: Home - Previous).
class HomeHero extends StatelessWidget {
  const HomeHero({
    required this.addressTitle,
    required this.unread,
    required this.greeting,
    required this.ctaEnabled,
    required this.onAddress,
    required this.onBell,
    required this.onFind,
    super.key,
  });

  final String addressTitle;
  final int unread;
  final String greeting;
  final bool ctaEnabled;
  final VoidCallback onAddress;
  final VoidCallback onBell;
  final VoidCallback onFind;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final top = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: 400 + top,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ExcludeSemantics(
              child: Image.asset(
                'assets/home/maid.jpg',
                fit: BoxFit.cover,
                alignment: const Alignment(-0.4, -0.6),
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.sky08182BA55,
                    AppColors.sky08182BA10,
                    AppColors.sky08182BA92,
                  ],
                  stops: [0, 0.35, 1],
                ),
              ),
            ),
            Positioned(
              top: top + 16,
              left: 16,
              right: 16,
              child: HomeRise(child: _topRow(l10n)),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HomeRise(
                    delayMs: 80,
                    child: Text(
                      greeting,
                      key: const Key('home_greeting'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.warnLine,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  HomeRise(
                    delayMs: 160,
                    child: Semantics(
                      header: true,
                      child: Text(
                        l10n.homeHeadline,
                        style: AppText.display.copyWith(
                          fontSize: 31,
                          height: 1.12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.surface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  HomeRise(delayMs: 240, child: _searchRow(l10n)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topRow(AppLocalizations l10n) => Row(
    children: [
      Expanded(
        child: NavyGlass(
          radius: 999,
          child: InkWell(
            key: const Key('home_address_chip'),
            borderRadius: BorderRadius.circular(999),
            onTap: onAddress,
            child: SizedBox(
              height: 48,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 14, 0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: AppColors.surface,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.homeDeliveringTo,
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.15,
                              letterSpacing: 1,
                              fontWeight: FontWeight.w600,
                              color: AppColors.slate300,
                            ),
                          ),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  addressTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.15,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.surface,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.keyboard_arrow_down,
                                size: 18,
                                color: AppColors.surface,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(width: 10),
      Semantics(
        label: unread > 0
            ? l10n.homeNotificationsUnread(unread)
            : l10n.homeNotifications,
        button: true,
        excludeSemantics: true,
        child: NavyGlass(
          radius: 24,
          child: InkWell(
            key: const Key('home_bell_btn'),
            customBorder: const CircleBorder(),
            onTap: onBell,
            child: SizedBox(
              width: 48,
              height: 48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.notifications_none,
                    color: AppColors.surface,
                  ),
                  if (unread > 0)
                    const Positioned(
                      top: 11,
                      right: 12,
                      child: CircleAvatar(
                        key: Key('home_bell_badge'),
                        radius: 4.5,
                        backgroundColor: AppColors.amber,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );

  Widget _searchRow(AppLocalizations l10n) => Row(
    children: [
      Expanded(
        child: NavyGlass(
          radius: 18,
          child: InkWell(
            key: const Key('home_find_worker_btn'),
            borderRadius: BorderRadius.circular(18),
            onTap: ctaEnabled ? onFind : null,
            child: Semantics(
              label: l10n.homeFindWorkerCta,
              button: true,
              excludeSemantics: true,
              child: SizedBox(
                height: 52,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search,
                        size: 20,
                        color: AppColors.hairline,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.homeSearchHint,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.hairline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(width: 10),
      // The search field beside it is the labelled control; this arrow repeats it.
      ExcludeSemantics(
        child: Material(
          color: ctaEnabled ? AppColors.navyDeep : AppColors.slate400,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: ctaEnabled ? onFind : null,
            child: const SizedBox(
              width: 52,
              height: 52,
              child: Icon(
                Icons.arrow_forward,
                color: AppColors.surface,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
