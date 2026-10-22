import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/core/mock/dev_menu.dart';
import 'package:sevanest_customer/core/services/clock.dart';
import 'package:sevanest_customer/features/addresses/domain/address.dart';
import 'package:sevanest_customer/features/addresses/presentation/providers/address_providers.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_widgets.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/providers/customer_profile_providers.dart';
import 'package:sevanest_customer/features/home/domain/home_data.dart';
import 'package:sevanest_customer/features/home/presentation/home_widgets.dart';
import 'package:sevanest_customer/features/home/presentation/providers/home_providers.dart';
import 'package:sevanest_customer/features/payment/presentation/pending_payment_banner.dart';
import 'package:sevanest_customer/features/service_discovery/domain/draft_validation.dart';
import 'package:sevanest_customer/features/service_discovery/domain/timing.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/discover_navigation.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/engagement_labels.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/catalog_providers.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/requirement_draft_provider.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/schedule_providers.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// Service ids match module 4's catalogue (`cook`, `driver`, `maid`).
const _heroServices = [
  (id: 'cook', icon: Icons.soup_kitchen_outlined),
  (id: 'driver', icon: Icons.directions_car_outlined),
  (id: 'maid', icon: Icons.cleaning_services_outlined),
];

/// `/home` (screen 05): hero, "Find a worker" CTA, then Loading / Error / New user / Returning,
/// each with an offline-cache banner. Sections are hidden when the backend sends nothing for them.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _slide = 0;
  bool _paused = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Bring back a requirement left unfinished when the app was closed (shown as a Resume card).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(ref.read(requirementDraftProvider.notifier).restore());
      }
    });
    if (ref.read(heroAutoplayProvider)) {
      _timer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!_paused && mounted) {
          setState(() => _slide = (_slide + 1) % _heroServices.length);
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// "Find a worker" and the onboarding CTA: always a fresh draft (HOME-02).
  void _startHire() {
    ref.read(requirementDraftProvider.notifier).reset();
    context.push(Routes.discoverCategory);
  }

  /// Hero chip: fresh draft with the service preset; the service step is skipped (HOME-03).
  void _startWithService(String id) {
    ref.read(requirementDraftProvider.notifier).startWithService(id);
    context.push(Routes.discoverEngagement);
  }

  /// Re-open the requirement builder where it was left, with Back walking through earlier steps.
  void _resume(DiscoverStep target) {
    final draft = ref.read(requirementDraftProvider);
    for (final step in DiscoverStep.values) {
      if (step.index > target.index) break;
      if (step == DiscoverStep.startDate && draft.skipsStartDateStep) continue;
      unawaited(context.push<Object?>(routeForStep(step)));
    }
  }

  Future<void> _pickAddress(List<Address> list) async {
    if (list.isEmpty) {
      await context.push(Routes.addressNew);
      return;
    }
    final picked = await context.push<Address>(
      '${Routes.addresses}?select=true',
    );
    if (picked != null) ref.read(selectedAddressProvider.notifier).set(picked);
  }

  Future<void> _refresh() async {
    ref.invalidate(addressesProvider);
    ref.invalidate(profileProvider);
    await ref.read(homeProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final home = ref.watch(homeProvider);
    final addresses = ref.watch(addressesProvider);
    final name = ref.watch(profileProvider).value?.name.split(' ').first;
    final list = addresses.value ?? const <Address>[];
    final selected = ref.watch(selectedAddressProvider);
    final active =
        selected ??
        list.where((a) => a.isDefault).firstOrNull ??
        list.firstOrNull;

    final resumeDraft = ref.watch(requirementDraftProvider);
    final resumeGap = resumeDraft.serviceId == null
        ? null
        : firstIncompleteStep(
            resumeDraft,
            today: ref.watch(nowProvider)(),
            config:
                ref.watch(scheduleConfigProvider).value ??
                ScheduleConfig.fallback,
          );
    // Nothing missing = it was finished up to the last step; resume on Budget.
    final resumeTarget = resumeGap?.step ?? DiscoverStep.budget;

    final data = home.value;
    final loading = !home.hasValue && !home.hasError;
    final offline = data?.fromCache ?? false;
    final hero = _heroServices[_slide];
    final heroLabel = switch (hero.id) {
      'driver' => l10n.homeHeroDriver,
      'maid' => l10n.homeHeroMaid,
      _ => l10n.homeHeroCook,
    };

    return Scaffold(
      backgroundColor: AppColors.fieldBg,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: EdgeInsets.zero,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _Header(
              addressLabel: active == null
                  ? l10n.homeAddAddress
                  : '${active.area}, ${active.city}',
              unread: ref.watch(unreadCountProvider),
              greeting: name == null || name.isEmpty
                  ? l10n.homeGreetingNoName
                  : l10n.homeGreeting(name),
              heroLabel: heroLabel,
              heroId: hero.id,
              heroIcon: hero.icon,
              slide: _slide,
              slides: _heroServices.length,
              paused: _paused,
              ctaEnabled: !loading && !offline,
              onAddress: () => _pickAddress(list),
              onBell: () => context.push(Routes.notifications),
              onHeroTap: () => _startWithService(hero.id),
              onTogglePause: () => setState(() => _paused = !_paused),
              onTitleLongPress: () => showDevMenu(context, ref),
              onFind: _startHire,
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (offline) ...[
                    OfflineBanner(onRetry: _refresh),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  const PendingPaymentBanner(),
                  if (resumeGap != null || resumeDraft.serviceId != null) ...[
                    ResumeCard(
                      what: [
                        ?ref.watch(selectedCategoryProvider)?.name,
                        if (resumeDraft.engagement != null)
                          engagementLabels(l10n, resumeDraft.engagement!).name,
                      ].join(' · '),
                      step: stepNumber(resumeTarget),
                      onContinue: () => _resume(resumeTarget),
                      onDiscard: () =>
                          ref.read(requirementDraftProvider.notifier).reset(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  if (addresses.hasValue && list.isEmpty) ...[
                    const AddAddressBanner(),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  ..._content(home, data, loading),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _content(
    AsyncValue<HomeData> home,
    HomeData? data,
    bool loading,
  ) {
    if (loading) return const [HomeSkeleton()];
    if (data == null) return [HomeErrorCard(onRetry: _refresh)];
    if (data.isNewUser) return [OnboardingCard(onFind: _startHire)];
    return [
      if (data.activeBooking != null || data.upcomingInterview != null) ...[
        ActivityCard(
          booking: data.activeBooking,
          interview: data.upcomingInterview,
          now: DateTime.now(),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
      if (data.shortlist.isNotEmpty) ...[
        ShortlistPreviewCard(workers: data.shortlist),
        const SizedBox(height: AppSpacing.md),
      ],
      const SupportShortcut(),
    ];
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.addressLabel,
    required this.unread,
    required this.greeting,
    required this.heroLabel,
    required this.heroId,
    required this.heroIcon,
    required this.slide,
    required this.slides,
    required this.paused,
    required this.ctaEnabled,
    required this.onAddress,
    required this.onBell,
    required this.onHeroTap,
    required this.onTogglePause,
    required this.onTitleLongPress,
    required this.onFind,
  });

  final String addressLabel;
  final int unread;
  final String greeting;
  final String heroLabel;
  final String heroId;
  final IconData heroIcon;
  final int slide;
  final int slides;
  final bool paused;
  final bool ctaEnabled;
  final VoidCallback onAddress;
  final VoidCallback onBell;
  final VoidCallback onHeroTap;
  final VoidCallback onTogglePause;
  final VoidCallback onTitleLongPress;
  final VoidCallback onFind;

  static const _ctaHeight = 64.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final top = MediaQuery.paddingOf(context).top;

    // The CTA overlaps the header's bottom edge; the stack reserves its lower half so it stays tappable.
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: _ctaHeight / 2),
          child: Container(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              top + AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.md + _ctaHeight / 2,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.navyDeep, AppColors.tealDeep],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const LogoTile(size: 40),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Material(
                        color: Colors.white10,
                        shape: StadiumBorder(
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: .25),
                          ),
                        ),
                        child: InkWell(
                          key: const Key('home_address_chip'),
                          customBorder: const StadiumBorder(),
                          onTap: onAddress,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              minHeight: kMinTapTarget,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Flexible(
                                    child: Text(
                                      addressLabel,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: text.titleSmall?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.keyboard_arrow_down,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Semantics(
                      label: unread > 0
                          ? l10n.homeNotificationsUnread(unread)
                          : l10n.homeNotifications,
                      button: true,
                      child: Material(
                        color: Colors.white10,
                        shape: CircleBorder(
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: .25),
                          ),
                        ),
                        child: InkWell(
                          key: const Key('home_bell_btn'),
                          customBorder: const CircleBorder(),
                          onTap: onBell,
                          child: SizedBox(
                            width: kMinTapTarget,
                            height: kMinTapTarget,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                const Icon(
                                  Icons.notifications_none,
                                  color: Colors.white,
                                ),
                                if (unread > 0)
                                  const Positioned(
                                    top: 10,
                                    right: 12,
                                    child: CircleAvatar(
                                      key: Key('home_bell_badge'),
                                      radius: 5,
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
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Material(
                            color: Colors.white10,
                            shape: StadiumBorder(
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: .25),
                              ),
                            ),
                            child: InkWell(
                              key: Key('home_category_tile_$heroId'),
                              customBorder: const StadiumBorder(),
                              onTap: onHeroTap,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: kMinTapTarget,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.verified_user_outlined,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Flexible(
                                        child: Text(
                                          heroLabel,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          GestureDetector(
                            key: const Key('home_greeting'),
                            onLongPress: onTitleLongPress,
                            child: Text(
                              greeting,
                              style: text.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            l10n.homeSubtitle,
                            style: text.titleSmall?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Container(
                      width: 96,
                      height: 112,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .06),
                        border: Border.all(color: Colors.white24),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(48),
                          bottom: Radius.circular(12),
                        ),
                      ),
                      child: Icon(heroIcon, color: Colors.white60, size: 44),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    for (var i = 0; i < slides; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: AppSpacing.sm),
                        width: i == slide ? 36 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == slide ? Colors.white : Colors.white38,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    IconButton(
                      key: const Key('home_hero_toggle'),
                      tooltip: paused ? l10n.homePlay : l10n.homePause,
                      onPressed: onTogglePause,
                      color: Colors.white,
                      icon: Icon(paused ? Icons.play_arrow : Icons.pause),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Search-style CTA straddling the header's bottom edge.
        Positioned(
          left: AppSpacing.md,
          right: AppSpacing.md,
          bottom: 0,
          child: _FindCta(enabled: ctaEnabled, onTap: onFind),
        ),
      ],
    );
  }
}

class _FindCta extends StatelessWidget {
  const _FindCta({required this.enabled, required this.onTap});
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      elevation: 6,
      shadowColor: Colors.black26,
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        key: const Key('home_find_worker_btn'),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: enabled ? onTap : null,
        child: SizedBox(
          height: _Header._ctaHeight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 8, 8, 8),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: enabled ? AppColors.teal : AppColors.slate,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    l10n.homeFindWorkerCta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: enabled ? AppColors.teal : AppColors.hairline,
                    borderRadius: BorderRadius.circular(AppRadius.md + 2),
                  ),
                  child: Icon(
                    Icons.arrow_forward,
                    color: enabled ? Colors.white : AppColors.slate,
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
