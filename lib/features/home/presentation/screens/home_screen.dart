import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/core/services/clock.dart';
import 'package:sevanest_customer/features/addresses/domain/address.dart';
import 'package:sevanest_customer/features/addresses/presentation/providers/address_providers.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/providers/customer_profile_providers.dart';
import 'package:sevanest_customer/features/home/domain/home_data.dart';
import 'package:sevanest_customer/features/home/presentation/home_attendance.dart';
import 'package:sevanest_customer/features/home/presentation/home_book_again.dart';
import 'package:sevanest_customer/features/home/presentation/home_hero.dart';
import 'package:sevanest_customer/features/home/presentation/home_info_sections.dart';
import 'package:sevanest_customer/features/home/presentation/home_promo_carousel.dart';
import 'package:sevanest_customer/features/home/presentation/home_services_grid.dart';
import 'package:sevanest_customer/features/home/presentation/home_shortlist.dart';
import 'package:sevanest_customer/features/home/presentation/home_top_rated.dart';
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

/// Design shows eight service tiles; "See all" opens the full list.
const _maxServiceTiles = 8;

/// `/home` (screen 05): photo hero with search, service mosaic, then Loading / Error / New user /
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

  /// Home search bar: same fresh draft, but the service step opens empty with the keyboard up.
  void _startSearch() {
    ref.read(requirementDraftProvider.notifier).reset();
    context.push('${Routes.discoverCategory}?search=true');
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
    final returning = data != null && !data.isNewUser;

    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: Stack(
        children: [
          const Positioned.fill(child: HomeGlows()),
          RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: EdgeInsets.zero,
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                HomeHero(
                  addressTitle: active == null
                      ? l10n.homeAddAddress
                      : '${active.area}, ${active.city}',
                  unread: ref.watch(unreadCountProvider),
                  greeting: name == null || name.isEmpty
                      ? l10n.homeGreetingNoName
                      : l10n.homeGreeting(name),
                  ctaEnabled: !loading && !offline,
                  onAddress: () => _pickAddress(list),
                  onBell: () => context.push(Routes.notifications),
                  onFind: _startSearch,
                ),
                Padding(
                  // Bottom: clear of the floating nav pill (Scaffold extendBody).
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (offline) ...[
                        OfflineBanner(onRetry: _refresh),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      const PendingPaymentBanner(),
                      if (resumeGap != null ||
                          resumeDraft.serviceId != null) ...[
                        HomeRise(
                          delayMs: 160,
                          child: ResumeCard(
                            what: [
                              ?ref.watch(selectedCategoryProvider)?.name,
                              if (resumeDraft.engagement != null)
                                engagementLabels(
                                  l10n,
                                  resumeDraft.engagement!,
                                ).name,
                            ].join(' · '),
                            step: stepNumber(resumeTarget),
                            onContinue: () => _resume(resumeTarget),
                            onDiscard: () => ref
                                .read(requirementDraftProvider.notifier)
                                .reset(),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      if (addresses.hasValue && list.isEmpty) ...[
                        const HomeRise(delayMs: 240, child: AddAddressBanner()),
                        const SizedBox(height: 24),
                      ],
                      if (categories.isNotEmpty) ...[
                        HomeRise(
                          delayMs: 320,
                          child: HomeServicesGrid(
                            categories: categories
                                .take(_maxServiceTiles)
                                .toList(),
                            onTile: _startWithService,
                            onSeeAll: _startHire,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      if (returning) const HomeBookAgain(),
                      ..._content(home, data, loading),
                      if (data != null) HomeTopRated(workers: data.topRated),
                      const HomeFeaturedHeading(),
                      PromoCarousel(onCta: _promoCta),
                      const SizedBox(height: 24),
                      const WhyFamiliesBanner(),
                      const SizedBox(height: 24),
                      const HowItWorks(),
                      const SizedBox(height: 24),
                      const SupportShortcut(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _content(
    AsyncValue<HomeData> home,
    HomeData? data,
    bool loading,
  ) {
    if (loading) {
      return const [HomeSkeleton(), SizedBox(height: 24)];
    }
    if (data == null) {
      return [HomeErrorCard(onRetry: _refresh), const SizedBox(height: 24)];
    }
    if (data.isNewUser) {
      return [OnboardingCard(onFind: _startHire), const SizedBox(height: 24)];
    }
    return [
      HomeAttendance(attendance: data.todayAttendance),
      if (data.activeBooking != null || data.upcomingInterview != null) ...[
        ActivityCard(
          booking: data.activeBooking,
          interview: data.upcomingInterview,
          now: DateTime.now(),
        ),
        const SizedBox(height: 24),
      ],
      if (data.shortlist.isNotEmpty) ...[
        ShortlistPreviewCard(workers: data.shortlist),
        const SizedBox(height: 24),
      ],
    ];
  }
}
