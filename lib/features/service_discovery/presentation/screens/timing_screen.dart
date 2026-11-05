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
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/choices_ticket.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/date_sheet.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_parts.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_scaffold.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/ticket_cells.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/time_picker_sheet.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/timing_widgets.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

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
      body = const TimingSkeleton();
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
        padding: const EdgeInsets.only(top: 18, bottom: 24),
        children: [
          DiscoverRise(
            delayMs: 0,
            child: ChoicesTicket(cells: flowTicketCells(context, ref)),
          ),
          const SizedBox(height: 14),
          DiscoverRise(
            delayMs: 80,
            child: StepHeading(
              heading: l10n.timingHeading,
              sub: l10n.timingSub,
            ),
          ),
          const SizedBox(height: 18),
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
    final window = timing.window;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_hasWindow)
          DiscoverRise(
            delayMs: 200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DiscoverLabel(l10n.timingWindowLabel),
                SkyScene(
                  window: window,
                  slot: window == null ? null : config.windows[window],
                  label: window == null
                      ? l10n.timingSceneEmpty
                      : '${windowName(l10n, window)} · ${windowCaption(l10n, window, config)}',
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < TimeWindow.values.length; i += 2)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final w
                              in TimeWindow.values.skip(i).take(2)) ...[
                            if (w != TimeWindow.values[i])
                              const SizedBox(width: 12),
                            Expanded(
                              child: WindowCard(
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
              ],
            ),
          ),
        if (variant == TimingVariant.hourly)
          DiscoverRise(
            delayMs: 260,
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DiscoverLabel(l10n.timingDate),
                  DateField(
                    text: date == null
                        ? l10n.timingChooseDate
                        : formatDate(date!, locale),
                    filled: date != null,
                    onTap: onDate,
                  ),
                  if (issues.contains(TimingIssue.dateMissing))
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        l10n.timingErrDate,
                        key: const Key('discover_date_hint'),
                        style: AppText.body.copyWith(
                          fontSize: 13,
                          color: dsMuted,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        if (_showTimes)
          DiscoverRise(
            delayMs: 300,
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DiscoverLabel(
                    _hasWindow ? l10n.timingExactHours : l10n.timingShiftHours,
                  ),
                  DiscoverShake(
                    on: timeIssue != null,
                    child: Row(
                      children: [
                        Expanded(
                          child: TimeField(
                            fieldKey: const Key('discover_time_start_btn'),
                            label: l10n.timingStartTime,
                            minutes: s,
                            error: timeIssue != null,
                            onTap: () => onTime(true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TimeField(
                            fieldKey: const Key('discover_time_end_btn'),
                            label: l10n.timingEndTime,
                            minutes: e,
                            error: timeIssue != null,
                            onTap: () => onTime(false),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (timeIssue != null)
                    DiscoverInlineError(
                      timingIssueMessage(l10n, timeIssue, variant, config),
                      fieldKey: const Key('discover_timing_error'),
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
                          style: AppText.body.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: dsNavy,
                          ),
                        ),
                      ],
                    ),
                  if (variant == TimingVariant.fullTime) ...[
                    const SizedBox(height: 16),
                    DiscoverLabel(l10n.timingHoursPerDayLabel, size: 17),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final h in config.shiftHours)
                          DiscoverPill(
                            key: Key('discover_hours_$h'),
                            label: l10n.timingHoursChip(h),
                            selected: dur == h * 60,
                            accent: AppColors.teal,
                            selectedFill: AppColors.pillActive,
                            weight: FontWeight.w700,
                            onTap: () => onHours(h),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        if (variantUsesDays(variant))
          DiscoverRise(
            delayMs: 340,
            child: Padding(
              padding: const EdgeInsets.only(top: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DiscoverLabel(l10n.timingDays),
                  DaysPicker(
                    days: timing.days,
                    onChanged: onDays,
                    locale: locale,
                  ),
                  if (timing.days.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: DiscoverInlineError(
                        l10n.timingErrDays,
                        fieldKey: const Key('discover_days_hint'),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
