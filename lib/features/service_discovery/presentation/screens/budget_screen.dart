import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/services/clock.dart';
import 'package:sevanest_customer/core/widgets/sn_button.dart';
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
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_scaffold.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/flow_chips.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// Live Indian digit grouping while typing: "600000" -> "6,00,000". Digits only, at most 7.
class RupeeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final capped = digits.length > 7 ? digits.substring(0, 7) : digits;
    final text = capped.isEmpty ? '' : groupIndian(int.parse(capped));
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

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
      areaId: areas.where((a) => a.name == d.address!.area).firstOrNull?.id,
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
    final text = Theme.of(context).textTheme;
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
        padding: const EdgeInsets.only(
          top: AppSpacing.md,
          bottom: AppSpacing.lg,
        ),
        children: [
          const FlowChips(),
          const SizedBox(height: AppSpacing.sm),
          StepHeading(heading: l10n.budgetHeading),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  period == BudgetPeriod.hourly
                      ? l10n.budgetSubHourly
                      : l10n.budgetSubMonthly,
                  style: text.bodyMedium?.copyWith(color: AppColors.ink),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.hairline.withValues(alpha: .6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  period == BudgetPeriod.hourly
                      ? l10n.budgetPerHour
                      : l10n.budgetPerMonth,
                  key: const Key('discover_period_chip'),
                  style: text.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // No published guidance (404) is not an error to show: the customer just types a range.
          if (guidanceAsync != null && guidanceAsync.error is! NotFoundFailure)
            _GuidanceCard(
              async: guidanceAsync,
              engagementName: engagement == null
                  ? ''
                  : engagementLabels(l10n, engagement).name.toLowerCase(),
              serviceName: category?.name.toLowerCase() ?? '',
              onUse: _useRange,
              onRetry: () => ref.invalidate(guidanceProvider(query!)),
            ),
          const SizedBox(height: AppSpacing.lg),
          _Readout(budget: budget, flexible: flexible),
          const SizedBox(height: AppSpacing.sm),
          _RangeBar(
            key: const Key('discover_budget_slider'),
            period: period,
            values: range,
            enabled: true,
            onChanged: (v) => _sliderChanged(v, period),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _AmountField(
                  fieldKey: const Key('discover_budget_min_field'),
                  label: l10n.budgetMinField,
                  controller: _min,
                  error: issue == BudgetIssue.minAboveMax,
                  onChanged: (_) => _typed(),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _AmountField(
                  fieldKey: const Key('discover_budget_max_field'),
                  label: l10n.budgetMaxField,
                  controller: _max,
                  error: issue == BudgetIssue.minAboveMax,
                  onChanged: (_) => _typed(),
                ),
              ),
            ],
          ),
          if (!flexible && issue != null && budget != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 18,
                  color: AppColors.danger,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    switch (issue) {
                      BudgetIssue.minAboveMax => l10n.budgetErrMinMax,
                      BudgetIssue.tooHigh => l10n.budgetErrHigh,
                      BudgetIssue.missing => l10n.budgetErrMissing,
                    },
                    key: const Key('discover_budget_error'),
                    style: text.bodyMedium?.copyWith(color: AppColors.danger),
                  ),
                ),
              ],
            ),
          ],
          if (status == BudgetStatus.lowWarning) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              key: const Key('discover_budget_low_warning'),
              padding: const EdgeInsets.all(AppSpacing.sm + 4),
              decoration: BoxDecoration(
                color: AppColors.warnBg,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.warn),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(l10n.budgetLow)),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Material(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              side: const BorderSide(color: AppColors.hairline),
            ),
            child: SwitchListTile(
              key: const Key('discover_flexible_switch'),
              value: flexible,
              onChanged: engagement == null
                  ? null
                  : (v) => _toggleFlexible(v, period, guidance),
              title: Text(
                l10n.budgetFlexibleLabel,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(l10n.budgetFlexibleBody),
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

class _GuidanceCard extends StatelessWidget {
  const _GuidanceCard({
    required this.async,
    required this.engagementName,
    required this.serviceName,
    required this.onUse,
    required this.onRetry,
  });

  final AsyncValue<Guidance> async;
  final String engagementName;
  final String serviceName;
  final ValueChanged<Guidance> onUse;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final g = async.value;

    if (g == null && async.hasError) {
      return Material(
        key: const Key('discover_guidance_error'),
        color: AppColors.surface,
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.dangerBg,
                child: Icon(Icons.error_outline, color: AppColors.danger),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.guidanceErrTitle,
                      style: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      l10n.guidanceErrBody,
                      style: text.bodyMedium?.copyWith(color: AppColors.slate),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: 160,
                      child: SnButton(
                        key: const Key('error_retry_btn'),
                        label: l10n.tryAgain,
                        icon: Icons.refresh,
                        variant: SnButtonVariant.secondary,
                        onPressed: onRetry,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    const tint = AppColors.tealWash;
    final border = Border.all(color: AppColors.teal.withValues(alpha: .25));
    if (g == null) {
      return Semantics(
        label: l10n.loading,
        child: Container(
          key: const Key('discover_guidance_loading'),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: border,
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.hairline,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final w in [180.0, 130.0, 100.0])
                      Container(
                        width: w,
                        height: 12,
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.hairline,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final range = '${formatRupees(g.min)} – ${formatRupees(g.max)}';
    return Container(
      key: const Key('discover_guidance_card'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: border,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white,
            child: Icon(Icons.trending_up, color: AppColors.teal),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.guidanceTypical(engagementName, serviceName, g.city),
                  style: text.bodyMedium,
                ),
                Text(
                  g.period == BudgetPeriod.hourly
                      ? l10n.budgetRangePerHour(range)
                      : l10n.budgetRangePerMonth(range),
                  key: const Key('discover_guidance_range'),
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      g.basis,
                      style: text.bodySmall?.copyWith(color: AppColors.slate),
                    ),
                    TextButton(
                      key: const Key('discover_use_range_btn'),
                      onPressed: () => onUse(g),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(kMinTapTarget, kMinTapTarget),
                        foregroundColor: AppColors.teal,
                      ),
                      child: Text(
                        l10n.guidanceUse,
                        style: const TextStyle(
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Readout extends StatelessWidget {
  const _Readout({required this.budget, required this.flexible});
  final Budget? budget;
  final bool flexible;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    if (flexible) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.budgetAny,
            key: const Key('discover_any_budget'),
            style: text.headlineMedium?.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(l10n.budgetAnyBody, style: text.bodySmall),
        ],
      );
    }
    String v(int? x) => x == null ? '–' : formatRupees(x);
    Widget col(String label, String value, Key k) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: text.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        // Scales down instead of overflowing at large text sizes or amounts like ₹4,00,000.
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            key: k,
            style: text.headlineMedium?.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: col(
            l10n.budgetMinimum,
            v(budget?.min),
            const Key('discover_readout_min'),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            '–',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
        ),
        Flexible(
          child: col(
            l10n.budgetMaximum,
            v(budget?.max),
            const Key('discover_readout_max'),
          ),
        ),
      ],
    );
  }
}

class _RangeBar extends StatelessWidget {
  const _RangeBar({
    required this.period,
    required this.values,
    required this.enabled,
    required this.onChanged,
    super.key,
  });

  final BudgetPeriod period;
  final RangeValues values;
  final bool enabled;
  final ValueChanged<RangeValues> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ceiling = budgetCeiling(period);
    final step = period == BudgetPeriod.hourly ? 25 : 500;
    final ticks = period == BudgetPeriod.hourly
        ? ['₹0', '₹250', '₹500', '₹750', '₹1k+']
        : ['₹0', '₹10k', '₹20k', '₹30k', '₹40k+'];
    final mid = ((values.start + values.end) / 2) / ceiling; // 0..1
    return Column(
      children: [
        Align(
          alignment: Alignment(mid * 2 - 1, 0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${formatRupees(values.start.round())}–${formatRupees(values.end.round())}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.tealDeep,
            inactiveTrackColor: AppColors.hairline,
            thumbColor: AppColors.surface,
            overlayColor: AppColors.teal.withValues(alpha: .12),
            rangeThumbShape: const RoundRangeSliderThumbShape(
              enabledThumbRadius: 12,
            ),
          ),
          child: Semantics(
            label: l10n.budgetSlider,
            child: RangeSlider(
              values: values,
              max: ceiling.toDouble(),
              divisions: ceiling ~/ step,
              onChanged: enabled ? onChanged : null,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final t in ticks)
              Text(
                t,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.slate),
              ),
          ],
        ),
      ],
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.fieldKey,
    required this.label,
    required this.controller,
    required this.error,
    required this.onChanged,
  });

  final Key fieldKey;
  final String label;
  final TextEditingController controller;
  final bool error;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final color = error ? AppColors.danger : AppColors.slate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        TextField(
          key: fieldKey,
          controller: controller,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          inputFormatters: [RupeeInputFormatter()],
          onChanged: onChanged,
          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            prefixText: '₹ ',
            filled: true,
            fillColor: AppColors.surface,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: color, width: error ? 2 : 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(
                color: error ? AppColors.danger : AppColors.teal,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
