import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/core/services/clock.dart';
import 'package:sevanest_customer/core/widgets/sn_photo.dart';
import 'package:sevanest_customer/features/addresses/domain/address.dart';
import 'package:sevanest_customer/features/addresses/presentation/providers/address_providers.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/providers/customer_profile_providers.dart';
import 'package:sevanest_customer/features/home/domain/home_data.dart';
import 'package:sevanest_customer/features/home/presentation/home_promo_carousel.dart';
import 'package:sevanest_customer/features/home/presentation/home_shortlist.dart';
import 'package:sevanest_customer/features/home/presentation/home_widgets.dart';
import 'package:sevanest_customer/features/home/presentation/providers/home_providers.dart';
import 'package:sevanest_customer/features/payment/presentation/pending_payment_banner.dart';
import 'package:sevanest_customer/features/service_discovery/domain/catalog.dart';
import 'package:sevanest_customer/features/service_discovery/domain/draft_validation.dart';
import 'package:sevanest_customer/features/service_discovery/domain/timing.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/discover_navigation.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/engagement_labels.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/catalog_providers.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/requirement_draft_provider.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/schedule_providers.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// Design shows eight service tiles; "See all" opens the full list.
const _maxServiceTiles = 8;

/// `/home` (screen 05): header, "Find a worker" CTA, service tiles, then Loading / Error / New user /
/// Returning, each with an offline-cache banner. Sections are hidden when the backend sends nothing.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Bring back a requirement left unfinished when the app was closed (shown as a Resume card).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(ref.read(requirementDraftProvider.notifier).restore());
      }
    });
  }

  /// "Find a worker" and the onboarding CTA: always a fresh draft (HOME-02).
  void _startHire() {
    ref.read(requirementDraftProvider.notifier).reset();
    context.push(Routes.discoverCategory);
  }

  /// Service tile: fresh draft with the service preset; the service step is skipped (HOME-03).
  void _startWithService(String id) {
    ref.read(requirementDraftProvider.notifier).startWithService(id);
    context.push(Routes.discoverEngagement);
  }

  /// Promo CTA: start with the matching service when the catalogue has one, else the full flow.
  void _promoCta(String? serviceId) {
    final has =
        ref.read(categoriesProvider).value?.any((c) => c.id == serviceId) ??
        false;
    if (has) {
      _startWithService(serviceId!);
    } else {
      _startHire();
    }
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
    ref.invalidate(categoriesProvider);
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
    final categories = ref.watch(categoriesProvider).value ?? const [];

    return Scaffold(
      backgroundColor: AppColors.canvasCool,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: EdgeInsets.zero,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _Header(
              addressTitle: active == null
                  ? l10n.homeAddAddress
                  : '${active.area}, ${active.city}',
              addressLine: active?.line,
              unread: ref.watch(unreadCountProvider),
              greeting: name == null || name.isEmpty
                  ? l10n.homeGreetingNoName
                  : l10n.homeGreeting(name),
              ctaEnabled: !loading && !offline,
              onAddress: () => _pickAddress(list),
              onBell: () => context.push(Routes.notifications),
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
                  PromoCarousel(onCta: _promoCta),
                  const SizedBox(height: AppSpacing.lg),
                  if (categories.isNotEmpty) ...[
                    _ExploreServices(
                      categories: categories.take(_maxServiceTiles).toList(),
                      onTile: _startWithService,
                      onSeeAll: _startHire,
                    ),
                    const SizedBox(height: AppSpacing.lg),
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
    required this.addressTitle,
    required this.addressLine,
    required this.unread,
    required this.greeting,
    required this.ctaEnabled,
    required this.onAddress,
    required this.onBell,
    required this.onFind,
  });

  final String addressTitle;
  final String? addressLine;
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
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.ivory, AppColors.canvasCool],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            width: MediaQuery.sizeOf(context).width * 0.55,
            child: ExcludeSemantics(
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (r) => const LinearGradient(
                  // Photo only fades in behind the right edge, never under the headline text.
                  colors: [Colors.transparent, Color(0x99000000)],
                  stops: [0.25, 1],
                ).createShader(r),
                child: Image.asset(
                  AppPhotos.room,
                  fit: BoxFit.cover,
                  alignment: Alignment.centerRight,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              top + AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        key: const Key('home_address_chip'),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        onTap: onAddress,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minHeight: kMinTapTarget,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: const BoxDecoration(
                                  color: AppColors.teal,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.location_on_outlined,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.s12),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            addressTitle,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppText.card,
                                          ),
                                        ),
                                        const Icon(
                                          Icons.keyboard_arrow_down,
                                          size: 20,
                                          color: AppColors.brandInk,
                                        ),
                                      ],
                                    ),
                                    if (addressLine != null)
                                      Text(
                                        addressLine!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppText.body.copyWith(
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
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
                        color: AppColors.surface,
                        elevation: 1,
                        shadowColor: AppColors.navy.withValues(alpha: 0.2),
                        shape: const CircleBorder(
                          side: BorderSide(color: AppColors.hairline),
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
                                  color: AppColors.brandInk,
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
                const SizedBox(height: AppSpacing.lg),
                Text(
                  greeting,
                  key: const Key('home_greeting'),
                  style: AppText.bodyLarge.copyWith(
                    fontSize: 17,
                    color: AppColors.brandInk,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Semantics(
                  header: true,
                  child: Text(
                    l10n.homeHeadline,
                    style: AppText.display.copyWith(fontSize: 32),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width * 0.7,
                  ),
                  child: Text(l10n.homeSubtitle, style: AppText.bodyLarge),
                ),
                const SizedBox(height: AppSpacing.lg),
                _FindCta(enabled: ctaEnabled, onTap: onFind),
              ],
            ),
          ),
        ],
      ),
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
      color: AppColors.surface,
      elevation: 2,
      shadowColor: AppColors.navy.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        side: const BorderSide(color: AppColors.hairline),
      ),
      child: InkWell(
        key: const Key('home_find_worker_btn'),
        borderRadius: BorderRadius.circular(AppRadius.button),
        onTap: enabled ? onTap : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: enabled ? AppColors.teal : AppColors.slate400,
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Text(
                    l10n.homeFindWorkerCta,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.card,
                  ),
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: enabled ? AppColors.teal : AppColors.hairline,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    Icons.arrow_forward,
                    color: enabled ? Colors.white : AppColors.slate400,
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

/// "Explore services": one tile per catalogue category (design 09-10, module 03 category row).
class _ExploreServices extends StatelessWidget {
  const _ExploreServices({
    required this.categories,
    required this.onTile,
    required this.onSeeAll,
  });

  final List<ServiceCategory> categories;
  final ValueChanged<String> onTile;
  final VoidCallback onSeeAll;

  static const _columns = 4;
  static const _gap = AppSpacing.sm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(l10n.homeExplore, style: AppText.title),
              ),
            ),
            TextButton.icon(
              key: const Key('home_see_all_btn'),
              onPressed: onSeeAll,
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: Text(l10n.homeSeeAll),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s12),
        LayoutBuilder(
          builder: (context, box) {
            final w = (box.maxWidth - _gap * (_columns - 1)) / _columns;
            return Wrap(
              spacing: _gap,
              runSpacing: AppSpacing.md,
              children: [
                for (final c in categories)
                  SizedBox(
                    width: w,
                    child: InkWell(
                      key: Key('home_category_tile_${c.id}'),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      onTap: () => onTile(c.id),
                      child: Column(
                        children: [
                          Container(
                            width: w,
                            height: w * 0.9,
                            decoration: BoxDecoration(
                              color: AppColors.tileWell,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.tileLine),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child:
                                AppPhotos.forService('${c.id} ${c.name}') ==
                                    null
                                ? Icon(c.icon, color: AppColors.teal)
                                : Image.asset(
                                    AppPhotos.forService('${c.id} ${c.name}')!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) =>
                                        Icon(c.icon, color: AppColors.teal),
                                  ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            c.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: AppText.card.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
