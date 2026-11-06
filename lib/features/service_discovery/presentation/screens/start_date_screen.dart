import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/core/services/clock.dart';
import 'package:sevanest_customer/features/service_discovery/domain/timing.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/requirement_draft_provider.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/schedule_providers.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/schedule_format.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/choices_ticket.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_scaffold.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/start_date_widgets.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/ticket_cells.dart';
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
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final draft = ref.watch(requirementDraftProvider);
    final configAsync = ref.watch(scheduleConfigProvider);
    final config = configAsync.value;
    final now = ref.watch(nowProvider)();
    final selected = draft.startDate;

    if (!_checked) {
      _checked = true;
      if (draft.skipsStartDateStep) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.pushReplacement(Routes.discoverTiming);
        });
      }
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
      body = const StartSkeleton();
    } else {
      final shortcuts = startDateShortcuts(now, config);
      final isShortcut = shortcuts.any((s) => s.date == selected);
      final last = lastStartDate(now, config);
      final lead = selected?.difference(istDate(now)).inDays;
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShortcutGrid(
            cards: [
              for (final s in shortcuts)
                ShortcutCard(
                  key: Key('discover_shortcut_${s.kind.name}'),
                  // ponytail: split "Tomorrow, Sat 10 Oct" at the comma; per-part strings when translating.
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
              ShortcutCard(
                key: const Key('discover_shortcut_other'),
                label: l10n.startPickAnother,
                trailing: Icons.chevron_right_rounded,
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
          const SizedBox(height: 16),
          DiscoverRise(
            delayMs: 400,
            child: KeyedSubtree(
              key: _calendarKey,
              child: GlassCalendar(
                firstDate: firstStartDate(now, config),
                lastDate: last,
                today: istDate(now),
                selected: selected,
                marked: usesDays && days.isNotEmpty
                    ? (d) => !isOnSelectedDays(d, days)
                    : null,
                onSelect: (d) =>
                    ref.read(requirementDraftProvider.notifier).setStartDate(d),
              ),
            ),
          ),
          const SizedBox(height: 10),
          DiscoverRise(
            delayMs: 460,
            child: Text(
              l10n.startLimitNote(config.maxLeadDays, formatDate(last, locale)),
              key: const Key('discover_limit_note'),
              style: AppText.body.copyWith(
                fontSize: 13.5,
                height: 1.4,
                color: dsMuted,
              ),
            ),
          ),
          if (selected != null && lead != null && lead > 0) ...[
            const SizedBox(height: 12),
            CountdownChip(
              text: lead == 1
                  ? l10n.startCountdownTomorrow(
                      formatShortcutDate(selected, locale),
                    )
                  : l10n.startCountdownDays(
                      lead,
                      formatShortcutDate(selected, locale),
                    ),
            ),
          ],
          if (outside) ...[
            const SizedBox(height: 14),
            OutsideDaysWarning(
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
        padding: const EdgeInsets.only(top: 18, bottom: 24),
        children: [
          DiscoverRise(
            delayMs: 0,
            child: ChoicesGrid(
              cells: flowTicketCells(context, ref, timing: true),
            ),
          ),
          const SizedBox(height: 16),
          DiscoverRise(
            delayMs: 80,
            child: StepHeading(heading: l10n.startHeading, sub: l10n.startSub),
          ),
          const SizedBox(height: 16),
          body,
        ],
      ),
    );
  }
}
