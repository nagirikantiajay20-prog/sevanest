import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/core/services/clock.dart';
import 'package:sevanest_customer/features/service_discovery/domain/timing.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/requirement_draft_provider.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/schedule_providers.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/schedule_format.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/choice_pill.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/date_sheet.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_scaffold.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/flow_chips.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/time_picker_sheet.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

const _windowIcons = {
  TimeWindow.earlyMorning: Icons.wb_twilight,
  TimeWindow.morning: Icons.wb_sunny_outlined,
  TimeWindow.afternoon: Icons.light_mode_outlined,
  TimeWindow.evening: Icons.wb_twilight,
  TimeWindow.night: Icons.nightlight_outlined,
  TimeWindow.flexible: Icons.schedule,
};

/// `/discover/timing` (screen 09, step 4 of 6). The engagement picks the layout:
/// Part-time / Daily / Hourly show a time-of-day window then exact hours; Full-time shows a shift.
/// Part-time and Daily add days of the week; Hourly adds a date (chosen in a bottom sheet).
class TimingScreen extends ConsumerStatefulWidget {
  const TimingScreen({this.edit = false, super.key});
  final bool edit;

  @override
  ConsumerState<TimingScreen> createState() => _TimingScreenState();
}

class _TimingScreenState extends ConsumerState<TimingScreen> {
  final _editorKey = GlobalKey();
  bool _checked = false;
  bool _seeded = false;

  void _update(Timing Function(Timing t) f) {
    final n = ref.read(requirementDraftProvider.notifier);
    n.setTiming(f(ref.read(requirementDraftProvider).timing ?? const Timing()));
  }

  Future<void> _pickTime({required bool start, required Timing t}) async {
    final l10n = AppLocalizations.of(context);
    final initial =
        (start ? t.startMinutes : t.endMinutes) ?? (start ? 8 * 60 : 12 * 60);
    final picked = await showTimePickerSheet(
      context,
      title: start ? l10n.timingStartTime : l10n.timingEndTime,
      initialMinutes: initial,
    );
    if (picked == null || !mounted) return;
    _update(
      (t) => start
          ? t.copyWith(startMinutes: picked)
          : t.copyWith(endMinutes: picked),
    );
  }

  Future<void> _pickDate(ScheduleConfig c) async {
    final now = ref.read(nowProvider)();
    final picked = await showDateSheet(
      context,
      firstDate: firstStartDate(now, c),
      lastDate: lastStartDate(now, c),
      today: now,
      selected: ref.read(requirementDraftProvider).startDate,
    );
    if (picked != null && mounted) {
      ref.read(requirementDraftProvider.notifier).setStartDate(picked);
    }
  }

  void _scrollToEditors() {
    final ctx = _editorKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 250),
        alignment: .1,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final draft = ref.watch(requirementDraftProvider);
    final configAsync = ref.watch(scheduleConfigProvider);
    final config = configAsync.value;
    final variant = draft.variant;

    // Resumed or deep-linked without an engagement: go choose one first.
    // Decided once on open, so discarding the draft later does not bounce this screen.
    if (!_checked) {
      _checked = true;
      if (variant == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.pushReplacement(Routes.discoverEngagement);
        });
      }
    }

    // First visit to a variant: preset its defaults (Full-time shift, Mon-Sat).
    if (variant != null && config != null && draft.timing == null && !_seeded) {
      _seeded = true;
      Future.microtask(
        () => ref
            .read(requirementDraftProvider.notifier)
            .setTiming(initialTiming(variant)),
      );
    }
    if (draft.timing != null) _seeded = false;

    final timing = draft.timing ?? const Timing();
    final issues = variant == null || config == null
        ? const <TimingIssue>[]
        : validateTiming(
            variant: variant,
            timing: draft.timing,
            date: draft.startDate,
            config: config,
          );
    final valid = variant != null && config != null && issues.isEmpty;

    Widget body;
    if (configAsync.hasError && config == null) {
      body = StepErrorCard(
        title: l10n.timingLoadFailedTitle,
        body: l10n.discoverLoadFailedBody,
        onRetry: () => ref.invalidate(scheduleConfigProvider),
      );
    } else if (config == null || variant == null) {
      body = const _TimingSkeleton();
    } else {
      body = _Editors(
        key: _editorKey,
        variant: variant,
        timing: timing,
        date: draft.startDate,
        config: config,
        issues: issues,
        locale: locale,
        onWindow: (w) => _update((t) => t.withWindow(w, config)),
        onTime: (start) => _pickTime(start: start, t: timing),
        onHours: (h) => _update(
          (t) => t.copyWith(
            endMinutes: ((t.startMinutes ?? 480) + h * 60) % 1440,
            startMinutes: t.startMinutes ?? 480,
          ),
        ),
        onDays: (d) => _update((t) => t.copyWith(days: d)),
        onDate: () => _pickDate(config),
      );
    }

    return DiscoverScaffold(
      step: 4,
      title: l10n.timingTitle,
      summary: valid
          ? timingSummary(
              l10n,
              variant: variant,
              timing: draft.timing,
              date: draft.startDate,
              locale: locale,
            )
          : null,
      onSummaryTap: _scrollToEditors,
      onContinue: valid
          ? () => discoverContinue(
              context,
              edit: widget.edit,
              // Hourly picks its date here, so it skips the Start date step.
              next: draft.skipsStartDateStep
                  ? Routes.discoverBudget
                  : Routes.discoverStartDate,
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.only(
          top: AppSpacing.md,
          bottom: AppSpacing.lg,
        ),
        children: [
          const FlowChips(),
          const SizedBox(height: AppSpacing.sm),
          StepHeading(heading: l10n.timingHeading, sub: l10n.timingSub),
          const SizedBox(height: AppSpacing.md),
          body,
        ],
      ),
    );
  }
}

class _Editors extends StatelessWidget {
  const _Editors({
    required this.variant,
    required this.timing,
    required this.date,
    required this.config,
    required this.issues,
    required this.locale,
    required this.onWindow,
    required this.onTime,
    required this.onHours,
    required this.onDays,
    required this.onDate,
    super.key,
  });

  final TimingVariant variant;
  final Timing timing;
  final DateTime? date;
  final ScheduleConfig config;
  final List<TimingIssue> issues;
  final String locale;
  final ValueChanged<TimeWindow> onWindow;
  final ValueChanged<bool> onTime;
  final ValueChanged<int> onHours;
  final ValueChanged<Set<int>> onDays;
  final VoidCallback onDate;

  bool get _hasWindow => variant != TimingVariant.fullTime;
  bool get _showTimes =>
      !_hasWindow ||
      (timing.window != null && timing.window != TimeWindow.flexible);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final timeIssue = issues
        .where(
          (i) =>
              i == TimingIssue.endBeforeStart ||
              i == TimingIssue.tooShort ||
              i == TimingIssue.tooLong,
        )
        .firstOrNull;
    final s = timing.startMinutes;
    final e = timing.endMinutes;
    final dur = s != null && e != null
        ? durationMinutes(s, e, overnightOk: timing.window == TimeWindow.night)
        : 0;

    Widget label(String t) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(t, style: AppText.heading),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_hasWindow) ...[
          label(l10n.timingWindowLabel),
          for (var i = 0; i < TimeWindow.values.length; i += 2)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s12),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final w in TimeWindow.values.skip(i).take(2)) ...[
                      if (w != TimeWindow.values[i])
                        const SizedBox(width: AppSpacing.s12),
                      Expanded(
                        child: _WindowCard(
                          window: w,
                          caption: windowCaption(l10n, w, config),
                          selected: timing.window == w,
                          onTap: () => onWindow(w),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (variant == TimingVariant.hourly) ...[
          label(l10n.timingDate),
          _DateRow(date: date, locale: locale, onTap: onDate),
          if (issues.contains(TimingIssue.dateMissing))
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                l10n.timingErrDate,
                key: const Key('discover_date_hint'),
                style: text.bodySmall?.copyWith(color: AppColors.slate),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (_showTimes) ...[
          label(_hasWindow ? l10n.timingExactHours : l10n.timingShiftHours),
          Row(
            children: [
              Expanded(
                child: _TimeField(
                  fieldKey: const Key('discover_time_start_btn'),
                  label: l10n.timingStartTime,
                  minutes: s,
                  error: timeIssue != null,
                  onTap: () => onTime(true),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _TimeField(
                  fieldKey: const Key('discover_time_end_btn'),
                  label: l10n.timingEndTime,
                  minutes: e,
                  error: timeIssue != null,
                  onTap: () => onTime(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (timeIssue != null)
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
                    timingIssueMessage(l10n, timeIssue, variant, config),
                    key: const Key('discover_timing_error'),
                    style: text.bodyMedium?.copyWith(color: AppColors.danger),
                  ),
                ),
              ],
            )
          else if (dur > 0)
            Row(
              children: [
                const Icon(
                  Icons.timer_outlined,
                  size: 18,
                  color: AppColors.teal,
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.timingHoursPerDay(formatDuration(l10n, dur)),
                  key: const Key('discover_duration'),
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          if (variant == TimingVariant.fullTime) ...[
            const SizedBox(height: AppSpacing.md),
            label(l10n.timingHoursPerDayLabel),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final h in config.shiftHours)
                  ChoicePill(
                    key: Key('discover_hours_$h'),
                    label: l10n.timingHoursChip(h),
                    selected: dur == h * 60,
                    onTap: () => onHours(h),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
        ],
        if (variantUsesDays(variant)) ...[
          label(l10n.timingDays),
          _DaysPicker(days: timing.days, onChanged: onDays, locale: locale),
          if (timing.days.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                l10n.timingErrDays,
                key: const Key('discover_days_hint'),
                style: text.bodySmall?.copyWith(color: AppColors.slate),
              ),
            ),
        ],
      ],
    );
  }
}

class _WindowCard extends StatelessWidget {
  const _WindowCard({
    required this.window,
    required this.caption,
    required this.selected,
    required this.onTap,
  });

  final TimeWindow window;
  final String caption;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.tealMist : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          side: BorderSide(
            color: selected ? AppColors.teal : AppColors.hairline,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          key: Key('discover_window_${window.name}'),
          borderRadius: BorderRadius.circular(AppRadius.button),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s12),
            child: Row(
              children: [
                Icon(
                  _windowIcons[window],
                  size: 26,
                  color: selected ? AppColors.teal : AppColors.slate400,
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        windowName(l10n, window),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.card,
                      ),
                      Text(caption, style: AppText.body.copyWith(fontSize: 12)),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(Icons.check, size: 20, color: AppColors.teal),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.fieldKey,
    required this.label,
    required this.minutes,
    required this.error,
    required this.onTap,
  });

  final Key fieldKey;
  final String label;
  final int? minutes;
  final bool error;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.body.copyWith(fontSize: 12)),
        const SizedBox(height: AppSpacing.xs),
        Material(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.field),
            side: BorderSide(
              color: error ? AppColors.danger : AppColors.hairline,
              width: error ? 2 : 1,
            ),
          ),
          child: InkWell(
            key: fieldKey,
            borderRadius: BorderRadius.circular(AppRadius.field),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: error ? AppColors.danger : AppColors.teal,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        minutes == null
                            ? l10n.timingPickTime
                            : formatTime(minutes!),
                        style: AppText.card.copyWith(
                          color: minutes == null
                              ? AppColors.slate400
                              : AppColors.brandInk,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.date,
    required this.locale,
    required this.onTap,
  });
  final DateTime? date;
  final String locale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
        side: const BorderSide(color: AppColors.hairline),
      ),
      child: InkWell(
        key: const Key('discover_date_btn'),
        borderRadius: BorderRadius.circular(AppRadius.field),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  color: AppColors.teal,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    date == null
                        ? l10n.timingChooseDate
                        : formatDate(date!, locale),
                    style: AppText.card.copyWith(
                      color: date == null
                          ? AppColors.slate400
                          : AppColors.brandInk,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.slate400),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DaysPicker extends StatelessWidget {
  const _DaysPicker({
    required this.days,
    required this.onChanged,
    required this.locale,
  });

  final Set<int> days;
  final ValueChanged<Set<int>> onChanged;
  final String locale;

  static const _all = {1, 2, 3, 4, 5, 6, 7};
  static const _weekdays = {1, 2, 3, 4, 5};
  static const _weekends = {6, 7};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    bool same(Set<int> a) => a.length == days.length && a.containsAll(days);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            ChoicePill(
              key: const Key('discover_days_every'),
              label: l10n.daysEvery,
              selected: same(_all),
              onTap: () => onChanged({..._all}),
            ),
            ChoicePill(
              key: const Key('discover_days_weekdays'),
              label: l10n.daysWeekdays,
              selected: same(_weekdays),
              onTap: () => onChanged({..._weekdays}),
            ),
            ChoicePill(
              key: const Key('discover_days_weekends'),
              label: l10n.daysWeekends,
              selected: same(_weekends),
              onTap: () => onChanged({..._weekends}),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var d = 1; d <= 7; d++)
              Semantics(
                selected: days.contains(d),
                button: true,
                label: dayShort(d, locale),
                excludeSemantics: true,
                child: InkResponse(
                  key: Key('discover_day_$d'),
                  onTap: () => onChanged(
                    days.contains(d) ? ({...days}..remove(d)) : {...days, d},
                  ),
                  child: Container(
                    width: 44,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      color: days.contains(d)
                          ? AppColors.teal
                          : AppColors.surface,
                      border: Border.all(
                        color: days.contains(d)
                            ? AppColors.teal
                            : AppColors.hairline,
                      ),
                    ),
                    child: Text(
                      dayShort(d, locale).substring(0, 1),
                      style: AppText.card.copyWith(
                        color: days.contains(d)
                            ? Colors.white
                            : AppColors.brandInk,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (days.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              l10n.timingDaysSelected(days.length),
              key: const Key('discover_days_count'),
              style: AppText.body,
            ),
          ),
      ],
    );
  }
}

class _TimingSkeleton extends StatelessWidget {
  const _TimingSkeleton();

  Widget _box({double? w, double h = 12}) => Container(
    width: w,
    height: h,
    decoration: BoxDecoration(
      color: AppColors.hairline,
      borderRadius: BorderRadius.circular(AppRadius.sm),
    ),
  );

  @override
  Widget build(BuildContext context) => Semantics(
    label: AppLocalizations.of(context).loading,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _box(w: 140, h: 14),
        const SizedBox(height: AppSpacing.md),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 2.2,
          children: [
            for (var i = 0; i < 6; i++)
              Material(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  side: const BorderSide(color: AppColors.hairline),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.hairline,
                      ),
                      const SizedBox(width: AppSpacing.s12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _box(w: 70),
                            const SizedBox(height: AppSpacing.xs),
                            _box(w: 50, h: 10),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    ),
  );
}
