import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
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
          : SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: .86,
              ),
              itemCount: shown.length,
              itemBuilder: (_, i) => _ServiceTile(
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
              padding: const EdgeInsets.only(top: AppSpacing.md),
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
                  prefixIcon: const Icon(Icons.search),
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

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
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
    final text = Theme.of(context).textTheme;
    return Semantics(
      selected: selected,
      button: true,
      label: category.name,
      child: Material(
        color: selected ? const Color(0xFFEAF8F5) : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(
            color: selected ? AppColors.teal : AppColors.slate,
            width: selected ? 2 : 1.2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('discover_category_tile_${category.id}'),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: selected
                          ? const [AppColors.tealDeep, AppColors.teal]
                          : const [AppColors.navy, AppColors.tealDeep],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: 12,
                        bottom: 8,
                        child: Icon(
                          category.icon,
                          size: 52,
                          color: Colors.white70,
                        ),
                      ),
                      if (category.popular)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.trending_up,
                                  size: 14,
                                  color: AppColors.tealDeep,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  l10n.servicePopular,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (selected)
                        const Positioned(
                          top: 6,
                          right: 6,
                          child: CircleAvatar(
                            key: Key('discover_category_check'),
                            radius: 13,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.check,
                              size: 18,
                              color: AppColors.teal,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm + 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        category.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall?.copyWith(color: AppColors.slate),
                      ),
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

class _ServiceSkeleton extends StatelessWidget {
  const _ServiceSkeleton();

  @override
  Widget build(BuildContext context) => Semantics(
    label: AppLocalizations.of(context).loading,
    child: GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: .86,
      children: [
        for (var i = 0; i < 6; i++)
          Material(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              side: const BorderSide(color: AppColors.hairline),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.hairline,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(height: 12, width: 70, color: AppColors.hairline),
                  const SizedBox(height: AppSpacing.sm),
                  Container(height: 10, color: AppColors.hairline),
                ],
              ),
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
    final text = Theme.of(context).textTheme;
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            const Icon(Icons.search, size: 48, color: AppColors.navy),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.serviceNoMatch(query.trim()),
              key: const Key('discover_no_result'),
              textAlign: TextAlign.center,
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.serviceNoMatchBody,
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: AppColors.slate),
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
      ),
    );
  }
}
