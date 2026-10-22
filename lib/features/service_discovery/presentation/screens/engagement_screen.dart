import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/features/service_discovery/domain/catalog.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/engagement_labels.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/catalog_providers.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/requirement_draft_provider.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_scaffold.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// `/discover/engagement` (screen 07, step 2 of 6). Options come from the chosen service only;
/// an option the service can't offer is shown disabled with its reason (Driver + Live-in).
class EngagementScreen extends ConsumerStatefulWidget {
  const EngagementScreen({this.edit = false, super.key});
  final bool edit;

  @override
  ConsumerState<EngagementScreen> createState() => _EngagementScreenState();
}

class _EngagementScreenState extends ConsumerState<EngagementScreen> {
  bool _checked = false;

  /// "Change" service: the draft may lose its engagement, which is then re-picked on this screen.
  Future<void> _changeService() async {
    await context.push<Object?>('${Routes.discoverCategory}?edit=true');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final categories = ref.watch(categoriesProvider);
    final category = ref.watch(selectedCategoryProvider);
    final draft = ref.watch(requirementDraftProvider);

    // Catalogue loaded but no service chosen (resumed draft / deep link): go pick one.
    // Decided once, when the catalogue first answers: later changes (e.g. a discarded draft)
    // must not bounce an already-open screen.
    if (!_checked && (categories.hasValue || categories.hasError)) {
      _checked = true;
      if (categories.hasValue && category == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.pushReplacement(Routes.discoverCategory);
        });
      }
    }

    // A single supported option is preselected (DISC-05).
    final available = category?.engagements.where((e) => e.available).toList();
    if (available != null &&
        available.length == 1 &&
        draft.engagement == null) {
      Future.microtask(
        () => ref
            .read(requirementDraftProvider.notifier)
            .setEngagement(available.single.type),
      );
    }

    final picked = draft.engagement == null
        ? null
        : engagementLabels(l10n, draft.engagement!).name;

    Widget content;
    if (categories.hasError && category == null) {
      content = StepErrorCard(
        title: l10n.engagementLoadFailedTitle,
        body: l10n.discoverLoadFailedBody,
        onRetry: () => ref.invalidate(categoriesProvider),
      );
    } else if (category == null) {
      content = const _EngagementSkeleton();
    } else {
      content = Column(
        children: [
          for (final o in category.engagements)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _EngagementCard(
                option: o,
                selected: draft.engagement == o.type,
                onTap: () => ref
                    .read(requirementDraftProvider.notifier)
                    .setEngagement(o.type),
              ),
            ),
        ],
      );
    }

    return DiscoverScaffold(
      step: 2,
      title: l10n.engagementTitle,
      continueLabel: picked == null ? null : l10n.discoverContinueWith(picked),
      onContinue: picked == null
          ? null
          : () => discoverContinue(
              context,
              edit: widget.edit,
              next: Routes.discoverLocation,
            ),
      body: ListView(
        padding: const EdgeInsets.only(
          top: AppSpacing.md,
          bottom: AppSpacing.lg,
        ),
        children: [
          if (category != null)
            Align(
              alignment: Alignment.centerLeft,
              child: SelectionChip(
                label: category.name,
                icon: category.icon,
                changeKey: const Key('discover_change_service'),
                onChange: _changeService,
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          StepHeading(heading: l10n.engagementHeading, sub: l10n.engagementSub),
          const SizedBox(height: AppSpacing.md),
          content,
        ],
      ),
    );
  }
}

class _EngagementCard extends StatelessWidget {
  const _EngagementCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final EngagementOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final labels = engagementLabels(l10n, option.type);
    final enabled = option.available;
    return Opacity(
      opacity: enabled ? 1 : .55,
      child: Semantics(
        selected: selected,
        enabled: enabled,
        inMutuallyExclusiveGroup: true,
        child: Material(
          color: selected ? AppColors.tealWash : AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            side: BorderSide(
              color: selected ? AppColors.teal : AppColors.slate,
              width: selected ? 2 : 1.2,
            ),
          ),
          child: InkWell(
            key: Key('discover_engagement_${option.type.name}'),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: enabled ? onTap : null,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: selected ? Colors.white : AppColors.tealWash,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(labels.icon, color: AppColors.teal),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          labels.name,
                          style: text.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          labels.description,
                          style: text.bodyMedium?.copyWith(
                            color: AppColors.slate,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            Icon(
                              enabled ? Icons.schedule : Icons.lock_outline,
                              size: 16,
                              color: AppColors.slate,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                option.unavailableReason ?? labels.meta,
                                key: enabled
                                    ? null
                                    : Key(
                                        'discover_engagement_reason_${option.type.name}',
                                      ),
                                style: text.bodySmall?.copyWith(
                                  color: AppColors.slate,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  selected
                      ? const CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.teal,
                          child: Icon(
                            Icons.check,
                            size: 18,
                            color: Colors.white,
                          ),
                        )
                      : Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.slate,
                              width: 1.5,
                            ),
                          ),
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

class _EngagementSkeleton extends StatelessWidget {
  const _EngagementSkeleton();

  @override
  Widget build(BuildContext context) => Semantics(
    label: AppLocalizations.of(context).loading,
    child: Column(
      children: [
        for (var i = 0; i < 4; i++)
          Container(
            height: 96,
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.hairline),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.hairline,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 10,
                        width: 80,
                        color: AppColors.hairline,
                      ),
                      const SizedBox(height: 8),
                      Container(height: 10, color: AppColors.hairline),
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
