import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/services/clock.dart';
import 'package:sevanest_customer/features/addresses/domain/address.dart';
import 'package:sevanest_customer/features/addresses/presentation/providers/address_providers.dart';
import 'package:sevanest_customer/features/service_discovery/domain/budget.dart';
import 'package:sevanest_customer/features/service_discovery/domain/draft_validation.dart';
import 'package:sevanest_customer/features/service_discovery/domain/requirement_draft.dart';
import 'package:sevanest_customer/features/service_discovery/domain/timing.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/discover_navigation.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/engagement_labels.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/catalog_providers.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/requirement_draft_provider.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/schedule_providers.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/budget_widgets.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/choices_ticket.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_parts.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_scaffold.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/ticket_cells.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

export 'package:sevanest_customer/features/service_discovery/presentation/widgets/budget_widgets.dart'
    show RupeeInputFormatter;

int? _parse(String t) {
  final d = t.replaceAll(RegExp(r'[^0-9]'), '');
  return d.isEmpty ? null : int.parse(d);
}

/// `/discover/budget` (screen 11, step 6 of 6). A min-max range with market guidance for the
/// service + area + engagement, a slider, two amount fields and a Flexible ("Any budget") switch.
class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({this.edit = false, super.key});
  final bool edit;

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  final _min = TextEditingController();
  final _max = TextEditingController();
  bool _edited = false;
  bool _checked = false;
  bool _seeded = false;

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  GuidanceQuery? _query() {
    final d = ref.read(requirementDraftProvider);
    if (d.serviceId == null || d.engagement == null || d.address == null) {
      return null;
    }
    final areas = ref.read(serviceAreasProvider).asData?.value ?? const [];
    return GuidanceQuery(
      serviceId: d.serviceId!,
      engagement: d.engagement!,
      area: d.address!.area,
      city: d.address!.city,
      areaId: serviceAreaIdFor(areas, d.address!.area),
    );
  }

  void _setBudget(Budget b) =>
      ref.read(requirementDraftProvider.notifier).setBudget(b);

  /// Typing in a field: that choice replaces "Any budget".
  void _typed() {
    _edited = true;
    final p = budgetPeriodFor(ref.read(requirementDraftProvider).engagement!);
    _setBudget(
      Budget(min: _parse(_min.text), max: _parse(_max.text), period: p),
    );
  }

  void _sliderChanged(RangeValues v, BudgetPeriod p) {
    _edited = true;
    final step = p == BudgetPeriod.hourly ? 25 : 500;
    int snap(double x) => (x / step).round() * step;
    _setBudget(Budget(min: snap(v.start), max: snap(v.end), period: p));
  }

  void _useRange(Guidance g) {
    _edited = true;
    _setBudget(Budget(min: g.min, max: g.max, period: g.period));
  }

  void _toggleFlexible(bool on, BudgetPeriod p, Guidance? g) {
    _edited = true;
    if (on) {
      _setBudget(
        Budget(min: 0, max: budgetCeiling(p), flexible: true, period: p),
      );
    } else {
      final r = g == null ? fallbackBudgetRange(p) : (min: g.min, max: g.max);
      _setBudget(Budget(min: r.min, max: r.max, period: p));
    }
  }

  /// Keep the text fields in step with the draft (slider, "Use this range", Flexible) without
  /// fighting the user's typing.
  void _syncFields(Budget? b) {
    if (b == null) return;
    if (_parse(_min.text) != b.min) {
      _min.text = b.min == null ? '' : groupIndian(b.min!);
    }
    if (_parse(_max.text) != b.max) {
      _max.text = b.max == null ? '' : groupIndian(b.max!);
    }
  }

  Future<void> _continue(RequirementDraftBundle b) async {
    final gap = firstIncompleteStep(
      b.draft,
      today: ref.read(nowProvider)(),
      config: b.config,
      requiresBudget: b.requiresBudget,
    );
    if (gap != null) {
      await sendToGap(context, gap);
      return;
    }
    if (!mounted) return;
    if (widget.edit && context.canPop()) {
      context.pop();
    } else {
      await context.push<Object?>(Routes.discoverReview);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final draft = ref.watch(requirementDraftProvider);
    final category = ref.watch(selectedCategoryProvider);
    final config =
        ref.watch(scheduleConfigProvider).value ?? ScheduleConfig.fallback;
    final engagement = draft.engagement;

    if (!_checked) {
      _checked = true;
      if (engagement == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.pushReplacement(Routes.discoverEngagement);
        });
      }
    }

    final period = engagement == null
        ? BudgetPeriod.monthly
        : budgetPeriodFor(engagement);
    final query = _query();
    final guidanceAsync = query == null
        ? null
        : ref.watch(guidanceProvider(query));
    final guidance = guidanceAsync?.value;

    // Default range: guidance when we already have it, otherwise the design's defaults.
    final stale = draft.budget != null && draft.budget!.period != period;
    if (engagement != null && (draft.budget == null || stale) && !_seeded) {
      _seeded = true;
      final r = guidance == null
          ? fallbackBudgetRange(period)
          : (min: guidance.min, max: guidance.max);
      Future.microtask(
        () => _setBudget(Budget(min: r.min, max: r.max, period: period)),
      );
    }
    if (draft.budget != null && !stale) _seeded = false;

    if (query != null) {
      // Guidance that arrives after the defaults were shown replaces them, unless the user edited.
      ref.listen(guidanceProvider(query), (_, next) {
        final g = next.value;
        final b = ref.read(requirementDraftProvider).budget;
        if (g == null || b == null || _edited || b.flexible) return;
        final f = fallbackBudgetRange(period);
        if (b.min == f.min && b.max == f.max) {
          _setBudget(Budget(min: g.min, max: g.max, period: period));
        }
      });
    }

    final budget = draft.budget != null && !stale ? draft.budget : null;
    _syncFields(budget);
    final status = budgetStatus(budget, guidance);
    final issue = budgetIssue(budget);
    final flexible = budget?.flexible ?? false;
    final valid = engagement != null && budget != null && issue == null;

    final ceiling = budgetCeiling(period);
    final lo = ((budget?.min ?? 0).clamp(0, ceiling)).toDouble();
    final hi = ((budget?.max ?? ceiling).clamp(0, ceiling)).toDouble();
    final range = RangeValues(lo <= hi ? lo : hi, lo <= hi ? hi : lo);
    final typical = guidance == null
        ? null
        : (min: guidance.min, max: guidance.max);

    final summary = budget == null
        ? null
        : flexible
        ? l10n.budgetAny
        : issue != null
        ? null
        : _rangeLabel(l10n, budget, period);

    return DiscoverScaffold(
      step: 6,
      title: l10n.budgetTitle,
      summary: summary,
      inlineSummary: true,
      continueLabel: l10n.budgetReview,
      onContinue: valid
          ? () => _continue(
              RequirementDraftBundle(
                draft,
                config,
                category?.requiresBudget ?? true,
              ),
            )
          : null,
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.only(top: 18, bottom: 28),
        children: [
          DiscoverRise(
            delayMs: 0,
            child: ChoicesGrid(
              cells: flowTicketCells(
                context,
                ref,
                timing: true,
                startDate: true,
              ),
            ),
          ),
          const SizedBox(height: 16),
          DiscoverRise(
            delayMs: 80,
            child: StepHeading(heading: l10n.budgetHeading),
          ),
          const SizedBox(height: 8),
          DiscoverRise(
            delayMs: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    period == BudgetPeriod.hourly
                        ? l10n.budgetSubHourly
                        : l10n.budgetSubMonthly,
                    style: AppText.body.copyWith(
                      fontSize: 15,
                      height: 1.45,
                      color: dsText,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2EEEC),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    period == BudgetPeriod.hourly
                        ? l10n.budgetPerHour
                        : l10n.budgetPerMonth,
                    key: const Key('discover_period_chip'),
                    style: AppText.body.copyWith(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.actionDeepTeal,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // No published guidance (404) is not an error to show: the customer just types a range.
          if (guidanceAsync != null && guidanceAsync.error is! NotFoundFailure)
            DiscoverRise(
              delayMs: 200,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: GuidanceCard(
                  async: guidanceAsync,
                  engagementName: engagement == null
                      ? ''
                      : engagementLabels(l10n, engagement).name.toLowerCase(),
                  serviceName: category?.name.toLowerCase() ?? '',
                  onUse: _useRange,
                  onRetry: () => ref.invalidate(guidanceProvider(query!)),
                ),
              ),
            ),
          DiscoverRise(
            delayMs: 280,
            child: DiscoverGlass(
              radius: 28,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BudgetReadout(budget: budget, flexible: flexible),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 16, 14, 2),
                      child: PriceHistogram(
                        period: period,
                        low: range.start,
                        high: range.end,
                        typical: typical ?? fallbackBudgetRange(period),
                        showTypical: typical != null,
                        flexible: flexible,
                      ),
                    ),
                    BudgetSlider(
                      key: const Key('discover_budget_slider'),
                      period: period,
                      values: flexible
                          ? RangeValues(0, ceiling.toDouble())
                          : range,
                      enabled: !flexible,
                      typical: flexible ? null : typical,
                      onChanged: (v) => _sliderChanged(v, period),
                    ),
                    if (typical != null && !flexible)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 6,
                              decoration: BoxDecoration(
                                color: AppColors.amber.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              l10n.budgetTypicalBand,
                              style: AppText.body.copyWith(
                                fontSize: 12.5,
                                color: dsMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    DiscoverShake(
                      on: issue == BudgetIssue.minAboveMax,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (final f in [
                            (
                              const Key('discover_budget_min_field'),
                              l10n.budgetMinField,
                              _min,
                            ),
                            (
                              const Key('discover_budget_max_field'),
                              l10n.budgetMaxField,
                              _max,
                            ),
                          ])
                            SizedBox(
                              width: 124,
                              child: AmountField(
                                fieldKey: f.$1,
                                label: f.$2,
                                controller: f.$3,
                                dim: flexible,
                                error: !flexible && issue != null,
                                onChanged: (_) => _typed(),
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
          if (!flexible && issue != null && budget != null) ...[
            const SizedBox(height: 12),
            DiscoverInlineError(switch (issue) {
              BudgetIssue.minAboveMax => l10n.budgetErrMinMax,
              BudgetIssue.tooHigh => l10n.budgetErrHigh,
              BudgetIssue.missing => l10n.budgetErrMissing,
            }, fieldKey: const Key('discover_budget_error')),
          ],
          if (status == BudgetStatus.lowWarning) ...[
            const SizedBox(height: 12),
            KeyedSubtree(
              key: const Key('discover_budget_low_warning'),
              child: DiscoverWarn(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(
                        Icons.info_outline,
                        size: 22,
                        color: Color(0xFFB45309),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.budgetLow,
                        style: AppText.body.copyWith(
                          fontSize: 14,
                          height: 1.45,
                          color: const Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          DiscoverRise(
            delayMs: 340,
            child: FlexibleCard(
              value: flexible,
              onChanged: engagement == null
                  ? null
                  : (v) => _toggleFlexible(v, period, guidance),
            ),
          ),
        ],
      ),
    );
  }

  String _rangeLabel(AppLocalizations l10n, Budget b, BudgetPeriod p) {
    final r = '${formatRupees(b.min!)} – ${formatRupees(b.max!)}';
    return p == BudgetPeriod.hourly
        ? l10n.budgetRangePerHour(r)
        : l10n.budgetRangePerMonth(r);
  }
}

/// Everything Continue needs to validate the whole draft.
class RequirementDraftBundle {
  const RequirementDraftBundle(this.draft, this.config, this.requiresBudget);
  final RequirementDraft draft;
  final ScheduleConfig config;
  final bool requiresBudget;
}
