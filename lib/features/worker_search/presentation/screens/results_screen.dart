import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/core/localization/failure_message.dart';
import 'package:sevanest_customer/core/widgets/async_value_view.dart';
import 'package:sevanest_customer/core/widgets/sn_states.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/engagement_labels.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/catalog_providers.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/requirement_draft_provider.dart';
import 'package:sevanest_customer/features/worker_search/domain/worker_search.dart';
import 'package:sevanest_customer/features/worker_search/presentation/providers/worker_search_providers.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/filter_sheet.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/worker_card.dart';
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
    final filterCount = ref.watch(workerFiltersProvider.select((f) => f.count));
    final draft = ref.watch(requirementDraftProvider);
    final category = ref.watch(selectedCategoryProvider);
    final results = ref.watch(workerSearchProvider);
    final notifier = ref.read(workerSearchProvider.notifier);
    final area = draft.address?.area ?? '';

    final chips = <String>[
      ?category?.name,
      if (draft.engagement != null)
        engagementLabels(l10n, draft.engagement!).name,
      if (area.isNotEmpty) area,
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('app_back_btn'),
          tooltip: l10n.back,
          icon: const Icon(Icons.chevron_left, size: 32),
          onPressed: _editRequirement,
        ),
        title: Text(l10n.resultsTitle(category?.name ?? '', area)),
        actions: [
          Semantics(
            label: filterCount == 0
                ? l10n.filterButton
                : l10n.filterActiveSemantics(filterCount),
            child: IconButton(
              key: const Key('results_filter_btn'),
              tooltip: l10n.filterButton,
              onPressed: _openFilters,
              icon: Badge(
                key: const Key('results_filter_badge'),
                isLabelVisible: filterCount > 0,
                label: Text('$filterCount'),
                child: const Icon(Icons.tune),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (chips.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                itemCount: chips.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (_, i) => ActionChip(
                  key: const Key('results_summary_chip'),
                  label: Text(chips[i]),
                  onPressed: _editRequirement,
                ),
              ),
            ),
          Expanded(
            child: AsyncValueView<PagedState<WorkerSummary>>(
              value: results,
              onRetry: notifier.refresh,
              isEmpty: (p) => p.items.isEmpty,
              loading: const SnSkeletonList(count: 5),
              empty: _Empty(
                chips: chips,
                onEdit: _editRequirement,
                onRetry: notifier.refresh,
              ),
              data: (p) => RefreshIndicator(
                onRefresh: notifier.refresh,
                child: ListView.separated(
                  controller: _scroll,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: p.items.length + 1,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (_, i) {
                    if (i == p.items.length) return _Footer(p, notifier);
                    final w = p.items[i];
                    return KeyedSubtree(
                      key: Key('worker_card_${w.id}'),
                      child: WorkerCard(
                        worker: w,
                        onTap: () => context.push(
                          Routes.path(Routes.workerDetail, {'id': w.id}),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer(this.page, this.notifier);
  final PagedState<WorkerSummary> page;
  final WorkerSearchNotifier notifier;

  @override
  Widget build(BuildContext context) {
    if (page.loadMoreError != null) {
      final l10n = AppLocalizations.of(context);
      return Center(
        child: TextButton(
          key: const Key('results_load_more_retry_btn'),
          onPressed: notifier.loadMore,
          child: Text(
            '${l10n.resultsLoadMoreRetry}\n${failureMessage(l10n, page.loadMoreError!)}',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (page.isLoadingMore) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.sm),
          child: CircularProgressIndicator(key: Key('results_footer_loader')),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _Empty extends StatelessWidget {
  const _Empty({
    required this.chips,
    required this.onEdit,
    required this.onRetry,
  });
  final List<String> chips;
  final VoidCallback onEdit;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SnEmptyState(
          title: l10n.resultsEmptyTitle,
          message: l10n.resultsEmptyBody,
          actionLabel: l10n.resultsEditRequirement,
          actionKey: const Key('results_edit_requirement_btn'),
          onAction: onEdit,
        ),
        TextButton(
          key: const Key('results_retry_btn'),
          onPressed: onRetry,
          child: Text(l10n.retry),
        ),
      ],
    );
  }
}
