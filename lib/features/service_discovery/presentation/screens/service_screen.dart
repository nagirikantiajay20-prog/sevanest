import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/core/widgets/sn_button.dart';
import 'package:sevanest_customer/features/service_discovery/domain/catalog.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/catalog_providers.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/requirement_draft_provider.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_scaffold.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// `/discover/category` (screen 06, step 1 of 6): pick the service.
/// States: loading skeleton, list, searching, no result, error, empty, selected.
class ServiceScreen extends ConsumerStatefulWidget {
  const ServiceScreen({this.edit = false, super.key});

  /// Opened from a "Change" chip / Review: Continue returns instead of moving on.
  final bool edit;

  @override
  ConsumerState<ServiceScreen> createState() => _ServiceScreenState();
}

class _ServiceScreenState extends ConsumerState<ServiceScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _setQuery(String q) => setState(() => _query = q);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final categories = ref.watch(categoriesProvider);
    final selectedId = ref.watch(requirementDraftProvider).serviceId;
    final selected = ref.watch(selectedCategoryProvider);

    final list = categories.value;
    Widget results;
    if (categories.hasError && list == null) {
      results = SliverToBoxAdapter(
        child: StepErrorCard(
          title: l10n.serviceLoadFailedTitle,
          body: l10n.discoverLoadFailedBody,
          onRetry: () => ref.invalidate(categoriesProvider),
        ),
      );
    } else if (list == null) {
      results = const SliverToBoxAdapter(child: _ServiceSkeleton());
    } else if (list.isEmpty) {
      results = SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xl),
          child: Text(
            l10n.serviceEmptyTitle,
            key: const Key('discover_empty'),
            textAlign: TextAlign.center,
            style: AppText.bodyLarge,
          ),
        ),
      );
    } else {
      final shown = list.where((c) => c.matches(_query)).toList();
      results = shown.isEmpty
          ? SliverToBoxAdapter(
              child: _NoResult(
                query: _query,
                onClear: () {
                  _search.clear();
                  _setQuery('');
                },
              ),
            )
          : SliverList.separated(
              itemCount: shown.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: AppColors.hairline),
              itemBuilder: (_, i) => _ServiceRow(
                category: shown[i],
                selected: shown[i].id == selectedId,
                onTap: () => ref
                    .read(requirementDraftProvider.notifier)
                    .setService(shown[i].id),
              ),
            );
    }

    return DiscoverScaffold(
      step: 1,
      title: l10n.discoverTitle,
      confirmBack: true,
      continueLabel: selected == null
          ? null
          : l10n.discoverContinueWith(selected.name),
      onContinue: selected == null
          ? null
          : () => discoverContinue(
              context,
              edit: widget.edit,
              next: Routes.discoverEngagement,
            ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.lg),
              child: StepHeading(
                heading: l10n.serviceHeading,
                sub: l10n.serviceSub,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: TextField(
                key: const Key('discover_search_field'),
                controller: _search,
                onChanged: _setQuery,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l10n.serviceSearchHint,
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.brandInk,
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          key: const Key('discover_search_clear'),
                          tooltip: l10n.serviceClearSearch,
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _search.clear();
                            _setQuery('');
                          },
                        ),
                ),
              ),
            ),
          ),
          results,
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
        ],
      ),
    );
  }
}

/// One service: icon well, name, description, optional "Popular" pill and a radio mark.
class _ServiceRow extends StatelessWidget {
  const _ServiceRow({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final ServiceCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      selected: selected,
      button: true,
      label: category.name,
      child: InkWell(
        key: Key('discover_category_tile_${category.id}'),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 88),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.tealWash : AppColors.canvasCool,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(category.icon, color: AppColors.teal),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(category.name, style: AppText.heading),
                      Text(
                        category.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.bodyLarge,
                      ),
                      if (category.popular) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.tealWash,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            l10n.servicePopular,
                            style: AppText.label.copyWith(
                              fontSize: 12,
                              color: AppColors.teal,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                selected
                    ? const Icon(
                        Icons.check_circle,
                        key: Key('discover_category_check'),
                        color: AppColors.teal,
                        size: 28,
                      )
                    : const Icon(
                        Icons.circle_outlined,
                        color: AppColors.slate300,
                        size: 28,
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ServiceSkeleton extends StatelessWidget {
  const _ServiceSkeleton();

  @override
  Widget build(BuildContext context) => Semantics(
    label: AppLocalizations.of(context).loading,
    child: Column(
      children: [
        for (var i = 0; i < 5; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.hairline,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 14,
                        width: 90,
                        color: AppColors.hairline,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Container(height: 12, color: AppColors.hairline),
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

class _NoResult extends StatelessWidget {
  const _NoResult({required this.query, required this.onClear});
  final String query;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        children: [
          const Icon(Icons.search, size: 48, color: AppColors.slate400),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.serviceNoMatch(query.trim()),
            key: const Key('discover_no_result'),
            textAlign: TextAlign.center,
            style: AppText.heading,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.serviceNoMatchBody,
            textAlign: TextAlign.center,
            style: AppText.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          SnButton(
            key: const Key('discover_clear_search_btn'),
            label: l10n.serviceClearSearch,
            variant: SnButtonVariant.secondary,
            onPressed: onClear,
          ),
        ],
      ),
    );
  }
}
