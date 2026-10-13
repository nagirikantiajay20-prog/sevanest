import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/core/services/clock.dart';
import 'package:sevanest_customer/core/widgets/sn_button.dart';
import 'package:sevanest_customer/features/service_discovery/domain/budget.dart';
import 'package:sevanest_customer/features/service_discovery/domain/draft_validation.dart';
import 'package:sevanest_customer/features/service_discovery/domain/timing.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/discover_navigation.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/engagement_labels.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/catalog_providers.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/requirement_draft_provider.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/schedule_providers.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/schedule_format.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// `/discover/review` (module 04, step 7): the requirement in one card, each row editable, then
/// Search opens the results.
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  bool _searching = false;

  Future<void> _search() async {
    if (_searching) return; // double tap opens Results once
    _searching = true;
    try {
      final draft = ref.read(requirementDraftProvider);
      final gap = firstIncompleteStep(
        draft,
        today: ref.read(nowProvider)(),
        config:
            ref.read(scheduleConfigProvider).value ?? ScheduleConfig.fallback,
        requiresBudget:
            ref.read(selectedCategoryProvider)?.requiresBudget ?? true,
      );
      if (gap != null) {
        await sendToGap(context, gap);
        return;
      }
      if (mounted) await context.push<Object?>(Routes.workers);
    } finally {
      _searching = false;
    }
  }

  /// Edit pushes the step in edit mode: its Continue pops straight back here, later values kept.
  void _edit(DiscoverStep step) =>
      context.push<Object?>('${routeForStep(step)}?edit=true');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toString();
    final d = ref.watch(requirementDraftProvider);
    final category = ref.watch(selectedCategoryProvider);

    final address = d.address;
    final budget = d.budget;
    final rows = <({String field, DiscoverStep step, String label, String value})>[
      (
        field: 'service',
        step: DiscoverStep.service,
        label: l10n.reviewRowService,
        value: category?.name ?? d.serviceId ?? '',
      ),
      if (d.engagement != null)
        (
          field: 'engagement',
          step: DiscoverStep.engagement,
          label: l10n.reviewRowEngagement,
          value: engagementLabels(l10n, d.engagement!).name,
        ),
      if (address != null)
        (
          field: 'address',
          step: DiscoverStep.location,
          label: l10n.reviewRowAddress,
          value:
              '${address.fullLine}, ${address.area}, ${address.city} ${address.pincode}',
        ),
      if (d.engagement != null && d.timing != null)
        (
          field: 'timing',
          step: DiscoverStep.timing,
          label: l10n.reviewRowTiming,
          value: timingSummary(
            l10n,
            variant: timingVariantFor(d.engagement!),
            timing: d.timing,
            // Hourly's date is part of its timing line.
            date: d.skipsStartDateStep ? d.startDate : null,
            locale: locale,
          ),
        ),
      if (d.startDate != null && !d.skipsStartDateStep)
        (
          field: 'startDate',
          step: DiscoverStep.startDate,
          label: l10n.reviewRowStartDate,
          value: formatDate(d.startDate!, locale),
        ),
      if (budget != null && (category?.requiresBudget ?? true))
        (
          field: 'budget',
          step: DiscoverStep.budget,
          label: l10n.reviewRowBudget,
          value: budget.flexible || budget.min == null || budget.max == null
              ? l10n.budgetAny
              : _range(l10n, budget),
        ),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('app_back_btn'),
          tooltip: l10n.back,
          icon: const Icon(Icons.chevron_left, size: 32),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(Routes.home),
        ),
        title: Text(l10n.reviewTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(l10n.reviewHeading, style: text.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.reviewSub, style: text.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                for (final r in rows)
                  ListTile(
                    key: Key('discover_review_row_${r.field}'),
                    title: Text(r.label, style: text.bodySmall),
                    subtitle: Text(r.value, style: text.bodyLarge),
                    trailing: TextButton(
                      key: Key('discover_review_edit_${r.field}'),
                      onPressed: () => _edit(r.step),
                      child: Semantics(
                        label: l10n.reviewEditSemantics(r.label),
                        excludeSemantics: true,
                        child: Text(l10n.reviewEdit),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: SnButton(
            key: const Key('discover_search_btn'),
            label: l10n.reviewSearch,
            onPressed: _search,
          ),
        ),
      ),
    );
  }

  String _range(AppLocalizations l10n, Budget b) {
    final r = '${formatRupees(b.min!)} – ${formatRupees(b.max!)}';
    return b.period == BudgetPeriod.hourly
        ? l10n.budgetRangePerHour(r)
        : l10n.budgetRangePerMonth(r);
  }
}
