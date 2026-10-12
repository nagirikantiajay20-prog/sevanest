import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/core/services/clock.dart';
import 'package:sevanest_customer/core/widgets/sn_button.dart';
import 'package:sevanest_customer/core/widgets/sn_calendar.dart';
import 'package:sevanest_customer/features/service_discovery/domain/timing.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/requirement_draft_provider.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/schedule_providers.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/schedule_format.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/choice_pill.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_scaffold.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/flow_chips.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// `/discover/start-date` (screen 10, step 5 of 6): first day of work.
/// Shortcuts + calendar (today and earlier disabled, 60-day limit), and a warning when the chosen
/// day is not one of the selected days. Hourly skips this step: its date is picked on Timing.
class StartDateScreen extends ConsumerStatefulWidget {
  const StartDateScreen({this.edit = false, super.key});
  final bool edit;

  @override
  ConsumerState<StartDateScreen> createState() => _StartDateScreenState();
}

class _StartDateScreenState extends ConsumerState<StartDateScreen> {
  final _calendarKey = GlobalKey();
  bool _redirected = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final text = Theme.of(context).textTheme;
    final draft = ref.watch(requirementDraftProvider);
    final configAsync = ref.watch(scheduleConfigProvider);
    final config = configAsync.value;
    final now = ref.watch(nowProvider)();
    final selected = draft.startDate;

    if (draft.skipsStartDateStep && !_redirected) {
      _redirected = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.pushReplacement(Routes.discoverTiming);
      });
    }

    final days = draft.timing?.days ?? const <int>{};
    final usesDays = draft.variant != null && variantUsesDays(draft.variant!);
    final outside =
        selected != null && usesDays && !isOnSelectedDays(selected, days);
    final valid =
        config != null && validateStartDate(selected, now, config) == null;

    Widget body;
    if (configAsync.hasError && config == null) {
      body = StepErrorCard(
        title: l10n.startLoadFailedTitle,
        body: l10n.discoverLoadFailedBody,
        onRetry: () => ref.invalidate(scheduleConfigProvider),
      );
    } else if (config == null) {
      body = const _StartSkeleton();
    } else {
      final shortcuts = startDateShortcuts(now, config);
      final isShortcut = shortcuts.any((s) => s.date == selected);
      final last = lastStartDate(now, config);
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final s in shortcuts)
                ChoicePill(
                  key: Key('discover_shortcut_${s.kind.name}'),
                  label: switch (s.kind) {
                    ShortcutKind.tomorrow => l10n.startTomorrow(
                      formatShortcutDate(s.date, locale),
                    ),
                    ShortcutKind.inThreeDays => l10n.startInDays(
                      3,
                      formatShortcutDate(s.date, locale),
                    ),
                    ShortcutKind.nextMonday => l10n.startNextMonday(
                      formatDayMonth(s.date, locale),
                    ),
                  },
                  selected: s.date == selected,
                  onTap: () => ref
                      .read(requirementDraftProvider.notifier)
                      .setStartDate(s.date),
                ),
              ChoicePill(
                key: const Key('discover_shortcut_other'),
                label: l10n.startPickAnother,
                selected: selected != null && !isShortcut,
                onTap: () {
                  final ctx = _calendarKey.currentContext;
                  if (ctx != null) {
                    Scrollable.ensureVisible(
                      ctx,
                      duration: const Duration(milliseconds: 250),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          KeyedSubtree(
            key: _calendarKey,
            child: SnCalendar(
              firstDate: firstStartDate(now, config),
              lastDate: last,
              today: now,
              selected: selected,
              marked: usesDays && days.isNotEmpty
                  ? (d) => !isOnSelectedDays(d, days)
                  : null,
              onSelect: (d) =>
                  ref.read(requirementDraftProvider.notifier).setStartDate(d),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.startLimitNote(config.maxLeadDays, formatDate(last, locale)),
            key: const Key('discover_limit_note'),
            style: text.bodySmall?.copyWith(color: AppColors.slate),
          ),
          if (outside) ...[
            const SizedBox(height: AppSpacing.md),
            _OutsideDaysWarning(
              date: formatDate(selected, locale),
              days: formatDays(l10n, days, locale),
              onAdjust: () =>
                  context.push<Object?>('${Routes.discoverTiming}?edit=true'),
            ),
          ],
        ],
      );
    }

    return DiscoverScaffold(
      step: 5,
      title: l10n.startTitle,
      continueLabel: valid
          ? l10n.discoverContinueWith(formatDate(selected!, locale))
          : null,
      onContinue: valid
          ? () => discoverContinue(
              context,
              edit: widget.edit,
              next: Routes.discoverBudget,
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
          StepHeading(heading: l10n.startHeading, sub: l10n.startSub),
          const SizedBox(height: AppSpacing.md),
          body,
        ],
      ),
    );
  }
}

class _OutsideDaysWarning extends StatelessWidget {
  const _OutsideDaysWarning({
    required this.date,
    required this.days,
    required this.onAdjust,
  });

  final String date;
  final String days;
  final VoidCallback onAdjust;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Container(
      key: const Key('discover_outside_days_warning'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warnBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.amber.withValues(alpha: .4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.warn),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.startOutsideTitle(date),
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(l10n.startOutsideBody(days), style: text.bodyMedium),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: 180,
                  child: SnButton(
                    key: const Key('discover_adjust_days_btn'),
                    label: l10n.startAdjustDays,
                    variant: SnButtonVariant.secondary,
                    onPressed: onAdjust,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StartSkeleton extends StatelessWidget {
  const _StartSkeleton();

  Widget _pill(double w) => Container(
    width: w,
    height: 44,
    decoration: BoxDecoration(
      color: AppColors.hairline,
      borderRadius: BorderRadius.circular(24),
    ),
  );

  @override
  Widget build(BuildContext context) => Semantics(
    label: AppLocalizations.of(context).loading,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [_pill(160), _pill(120), _pill(100)],
        ),
        const SizedBox(height: AppSpacing.md),
        Material(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            side: const BorderSide(color: AppColors.hairline),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                for (var r = 0; r < 5; r++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (var c = 0; c < 7; c++)
                          const CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.hairline,
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
