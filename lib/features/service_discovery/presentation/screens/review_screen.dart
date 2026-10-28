import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/core/services/clock.dart';
import 'package:sevanest_customer/features/service_discovery/domain/budget.dart';
import 'package:sevanest_customer/features/service_discovery/domain/draft_validation.dart';
import 'package:sevanest_customer/features/service_discovery/domain/timing.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/discover_navigation.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/engagement_labels.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/catalog_providers.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/requirement_draft_provider.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/schedule_providers.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/schedule_format.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_scaffold.dart';
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

    return DiscoverScaffold(
      step: kDiscoverSteps,
      title: l10n.reviewTitle,
      stepLabel: l10n.reviewAllDone,
      nextKey: const Key('discover_search_btn'),
      continueLabel: l10n.reviewSearch,
      onContinue: _search,
      body: ListView(
        padding: const EdgeInsets.only(
          top: AppSpacing.lg,
          bottom: AppSpacing.lg,
        ),
        children: [
          StepHeading(heading: l10n.reviewHeading, sub: l10n.reviewSub),
          const SizedBox(height: AppSpacing.md),
          for (final r in rows) ...[
            const Divider(height: 1, color: AppColors.hairline),
            Padding(
              key: Key('discover_review_row_${r.field}'),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.label.toUpperCase(),
                          style: AppText.body.copyWith(
                            fontSize: 12,
                            letterSpacing: 0.8,
                            color: AppColors.slate400,
                          ),
                        ),
                        Text(
                          r.value,
                          style: AppText.heading.copyWith(fontSize: 17),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  OutlinedButton(
                    key: Key('discover_review_edit_${r.field}'),
                    onPressed: () => _edit(r.step),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(64, kMinTapTarget),
                      shape: const StadiumBorder(),
                      side: const BorderSide(color: AppColors.hairline),
                      foregroundColor: AppColors.teal,
                    ),
                    child: Semantics(
                      label: l10n.reviewEditSemantics(r.label),
                      excludeSemantics: true,
                      child: Text(l10n.reviewEdit),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Divider(height: 1, color: AppColors.hairline),
        ],
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
