import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/core/widgets/async_value_view.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart'
    show authSerif;
import 'package:sevanest_customer/features/favourites/presentation/providers/favourites_providers.dart';
import 'package:sevanest_customer/features/favourites/presentation/widgets/favourite_button.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/engagement_labels.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/catalog_providers.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/requirement_draft_provider.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/schedule_format.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/features/worker_profile/presentation/screens/worker_detail_screen.dart'
    show requestInterviewFor;
import 'package:sevanest_customer/features/worker_search/domain/worker_search.dart';
import 'package:sevanest_customer/features/worker_search/presentation/providers/worker_search_providers.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/filter_sheet.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_page.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/paged_footer.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/result_worker_card.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';
import 'package:sevanest_customer/shared/models/paged_state.dart';

/// `/workers`: verified workers matching the requirement (module 05, screen 5.1).
class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({super.key});

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 300) {
        ref.read(workerSearchProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Back to the Review step (draft intact); the Review route is the fallback when opened cold.
  void _editRequirement() =>
      context.canPop() ? context.pop() : context.go(Routes.discoverReview);

  /// A summary chip reopens its own step in edit mode; Continue there returns to the results.
  void _editStep(String route) => context.push<Object?>('$route?edit=true');

  Future<void> _openFilters() async {
    final current = ref.read(workerFiltersProvider);
    final picked = await showFilterSheet(context, current);
    // Closing the sheet leaves the filters alone; Apply re-searches from page 1 (the query
    // changes, which cancels any request still running).
    if (picked != null) ref.read(workerFiltersProvider.notifier).set(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filters = ref.watch(workerFiltersProvider);
    final draft = ref.watch(requirementDraftProvider);
    final category = ref.watch(selectedCategoryProvider);
    final results = ref.watch(workerSearchProvider);
    final notifier = ref.read(workerSearchProvider.notifier);
    final saved = ref.watch(favouriteProvider).value?.ids.length ?? 0;
    final area = draft.address?.area ?? '';
    final locale = Localizations.localeOf(context).toString();

    final chips = <(String, String)>[
      if (category != null) (category.name, Routes.discoverCategory),
      if (draft.engagement != null)
        (
          engagementLabels(l10n, draft.engagement!).name,
          Routes.discoverEngagement,
        ),
      if (area.isNotEmpty) (area, Routes.discoverLocation),
      if (draft.startDate != null)
        (formatDate(draft.startDate!, locale), Routes.discoverStartDate),
    ];

    return FindGlassPage(
      title: l10n.resultsTitle(category?.name ?? '', area),
      backLabel: l10n.back,
      onBack: _editRequirement,
      trailing: GlassCircleButton(
        key: const Key('results_shortlist_btn'),
        icon: Icons.favorite_border_rounded,
        tooltip: l10n.resultsShortlistCount(saved),
        badge: saved,
        onPressed: () => context.go(Routes.favourites),
      ),
      headerBottom: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          itemCount: chips.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (_, i) => _RequirementChip(
            key: i == 0
                ? const Key('results_summary_chip')
                : Key('results_summary_chip_$i'),
            label: chips[i].$1,
            onTap: () => _editStep(chips[i].$2),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: DiscoverRise(
              delayMs: 0,
              child: Row(
                children: [
                  Expanded(
                    child: _SortSegments(
                      sort: filters.sort,
                      onChanged: (s) => ref
                          .read(workerFiltersProvider.notifier)
                          .set(filters.copyWith(sort: s)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _FilterButton(count: filters.count, onPressed: _openFilters),
                ],
              ),
            ),
          ),
          Expanded(
            child: AsyncValueView<PagedState<WorkerSummary>>(
              value: results,
              onRetry: notifier.refresh,
              isEmpty: (p) => p.items.isEmpty,
              loading: Semantics(
                label: l10n.loading,
                child: const _SkeletonCards(),
              ),
              empty: _Empty(
                onEdit: _editRequirement,
                onRetry: notifier.refresh,
              ),
              data: (p) {
                loadMoreIfShort(_scroll, p, notifier.loadMore);
                final items = p.items;
                // The true total from the count endpoint; the loaded count until it answers.
                final query = ref.watch(workerQueryProvider);
                final total = query == null
                    ? null
                    : ref.watch(workerCountProvider(query)).value;
                return RefreshIndicator(
                  onRefresh: notifier.refresh,
                  child: ListView(
                    controller: _scroll,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      DiscoverRise(
                        delayMs: 80,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(2, 14, 2, 12),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.verified_user_outlined,
                                size: 16,
                                color: AppColors.teal,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  l10n.resultsMatchCount(total ?? items.length),
                                  style: AppText.body.copyWith(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: dsText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      for (final (i, w) in items.indexed) ...[
                        KeyedSubtree(
                          key: Key('worker_card_${w.id}'),
                          child: DiscoverRise(
                            delayMs: 120.0 + 100 * i.clamp(0, 5),
                            child: ResultWorkerCard(
                              worker: w,
                              bestMatch:
                                  i == 0 &&
                                  (filters.sort == null ||
                                      filters.sort == WorkerSort.bestMatch),
                              trailing: SizedBox(
                                width: 48,
                                height: 48,
                                child: FavouriteButton(
                                  workerId: w.id,
                                  keyName: 'worker_card_fav_btn_${w.id}',
                                ),
                              ),
                              onView: () => context.push(
                                Routes.path(Routes.workerDetail, {'id': w.id}),
                              ),
                              onInterview: w.canRequestInterview
                                  ? () =>
                                        requestInterviewFor(context, ref, w.id)
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      PagedFooter(page: p, onRetry: notifier.loadMore),
                    ],
                  ),
                );
              },
            ),
          ),
          if (results.value?.items.isNotEmpty ?? false)
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                4,
                16,
                18 + MediaQuery.paddingOf(context).bottom,
              ),
              child: DiscoverRise(
                delayMs: 500,
                child: _EditFooter(onEdit: _editRequirement),
              ),
            ),
        ],
      ),
    );
  }
}

class _RequirementChip extends StatelessWidget {
  const _RequirementChip({required this.label, required this.onTap, super.key});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    excludeSemantics: true,
    child: Material(
      color: const Color(0xC7FFFFFF),
      shape: StadiumBorder(
        side: BorderSide(
          color: AppColors.teal.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 36),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppText.body.copyWith(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.teal,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.edit_rounded, size: 12, color: AppColors.teal),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Best match / Rating / Experience as one frosted track with a navy thumb that slides.
class _SortSegments extends StatelessWidget {
  const _SortSegments({required this.sort, required this.onChanged});
  final WorkerSort? sort;
  final ValueChanged<WorkerSort> onChanged;

  static const _order = [
    WorkerSort.bestMatch,
    WorkerSort.highestRated,
    WorkerSort.mostExperienced,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = [
      l10n.resultsSortBest,
      l10n.resultsSortRating,
      l10n.resultsSortExperience,
    ];
    final selected = sort == null ? 0 : _order.indexOf(sort!);
    return DiscoverGlass(
      radius: 18,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: SizedBox(
          height: 44,
          child: Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 400),
                curve: const Cubic(.34, 1.4, .64, 1),
                alignment: Alignment(-1 + selected.toDouble(), 0),
                child: FractionallySizedBox(
                  widthFactor: 1 / 3,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [dsNavy, AppColors.actionDeepTeal],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: dsNavy.withValues(alpha: 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Semantics(
                container: true,
                label: l10n.resultsSortLabel,
                child: Row(
                  children: [
                    for (var i = 0; i < 3; i++)
                      Expanded(
                        child: Semantics(
                          button: true,
                          selected: selected == i,
                          child: InkWell(
                            key: Key('results_sort_${_order[i].name}'),
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => onChanged(_order[i]),
                            child: Center(
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 250),
                                style: AppText.body.copyWith(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: selected == i ? Colors.white : dsText,
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(labels[i]),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.count, required this.onPressed});
  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: count == 0 ? l10n.filterButton : l10n.filterActiveSemantics(count),
      excludeSemantics: true,
      child: SizedBox(
        width: 52,
        height: 52,
        child: DiscoverGlass(
          radius: 18,
          child: InkWell(
            key: const Key('results_filter_btn'),
            borderRadius: BorderRadius.circular(18),
            onTap: onPressed,
            child: Center(
              child: Badge(
                key: const Key('results_filter_badge'),
                isLabelVisible: count > 0,
                label: Text('$count'),
                backgroundColor: AppColors.teal,
                child: const Icon(Icons.tune_rounded, size: 22, color: dsNavy),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Floating "Not the right fit?" card over the list.
class _EditFooter extends StatelessWidget {
  const _EditFooter({required this.onEdit});
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DiscoverGlass(
      radius: 22,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
        child: Row(
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: '${l10n.resultsNotFit}\n',
                  style: AppText.body.copyWith(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                    color: dsText,
                  ),
                  children: [
                    TextSpan(
                      text: l10n.resultsChangeRequirement,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: dsMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              flex: 0,
              child: FilledButton(
                key: const Key('results_edit_link'),
                onPressed: onEdit,
                style: FilledButton.styleFrom(
                  backgroundColor: dsNavy,
                  minimumSize: const Size(0, kMinTapTarget),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: AppText.body.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Text(
                  l10n.resultsEditRequirement,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmering glass placeholders while the first page loads.
class _SkeletonCards extends StatelessWidget {
  const _SkeletonCards();

  @override
  Widget build(BuildContext context) => ListView(
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
    children: [
      for (var i = 0; i < 3; i++) ...[
        DiscoverGlass(
          radius: 28,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 34,
                  backgroundColor: Color(0x401B3354),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _bar(120, 12, 0x401B3354),
                      const SizedBox(height: 10),
                      _bar(170, 9, 0x241B3354),
                      const SizedBox(height: 10),
                      _bar(90, 9, 0x241B3354),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    ],
  );

  static Widget _bar(double w, double h, int argb) => Container(
    width: w,
    height: h,
    decoration: BoxDecoration(
      color: Color(argb),
      borderRadius: BorderRadius.circular(6),
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onEdit, required this.onRetry});
  final VoidCallback onEdit;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: DiscoverRise(
          delayMs: 0,
          child: DiscoverGlass(
            radius: 28,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFFE2EEEC), Colors.white],
                      ),
                    ),
                    child: const Icon(
                      Icons.search_off_rounded,
                      size: 40,
                      color: AppColors.teal,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    l10n.resultsEmptyTitle,
                    textAlign: TextAlign.center,
                    style: authSerif(24, 1.2),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.resultsEmptyBody,
                    textAlign: TextAlign.center,
                    style: AppText.body.copyWith(
                      fontSize: 15,
                      height: 1.45,
                      color: dsText,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      key: const Key('results_edit_requirement_btn'),
                      onPressed: onEdit,
                      style: FilledButton.styleFrom(
                        backgroundColor: dsNavy,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        textStyle: AppText.body.copyWith(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: Text(l10n.resultsEditRequirement),
                    ),
                  ),
                  TextButton(
                    key: const Key('results_retry_btn'),
                    onPressed: onRetry,
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
