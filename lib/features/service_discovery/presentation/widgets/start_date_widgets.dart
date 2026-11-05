import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart'
    show authSerif;
import 'package:sevanest_customer/features/authentication/presentation/widgets/motion.dart'
    show riseCurve;
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_parts.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// Glass pieces of the Start date step (design: Find a Worker 5).

String _ymd(DateTime d) =>
    '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

const _washNavy = [AppColors.grayE4E9F2A95, AppColors.whiteA72xB8];

/// Two cards per row, equal height (Tomorrow / In 3 days / Next Monday / Pick another).
class ShortcutGrid extends StatelessWidget {
  const ShortcutGrid({required this.cards, super.key});
  final List<Widget> cards;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var i = 0; i < cards.length; i += 2)
        Padding(
          padding: EdgeInsets.only(bottom: i + 2 < cards.length ? 12 : 0),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: DiscoverRise(delayMs: 200.0 + i * 70, child: cards[i]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: i + 1 < cards.length
                      ? DiscoverRise(
                          delayMs: 270.0 + i * 70,
                          child: cards[i + 1],
                        )
                      : const SizedBox(),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}

/// "Tomorrow / Sat 10 Oct": caption over value, a tick when chosen, a chevron on "Pick another".
class ShortcutCard extends StatelessWidget {
  const ShortcutCard({
    required this.label,
    required this.selected,
    required this.onTap,
    this.trailing,
    super.key,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? trailing;

  @override
  Widget build(BuildContext context) {
    final i = label.indexOf(', ');
    final head = i < 0 ? null : label.substring(0, i);
    final value = i < 0 ? label : label.substring(i + 2);
    return GlassChoice(
      selected: selected,
      onTap: onTap,
      selectedColor: dsNavy,
      selectedWash: _washNavy,
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (head != null)
                  Text(
                    head,
                    style: AppText.body.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: dsMuted,
                    ),
                  ),
                Text(
                  value,
                  style: AppText.body.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: dsNavy,
                  ),
                ),
              ],
            ),
          ),
          if (selected || trailing != null)
            DiscoverPop(
              active: selected,
              child: Icon(
                selected ? Icons.check_rounded : trailing,
                size: 20,
                color: dsNavy,
              ),
            ),
        ],
      ),
    );
  }
}

/// Month calendar on glass (Sunday first). Days outside [firstDate]..[lastDate] are greyed out,
/// [marked] days (outside the chosen weekdays) are amber, today has a teal dot and the chosen day
/// is navy. Each day has key `calendar_day_yyyymmdd`; marked days also `calendar_dot_yyyymmdd`.
class GlassCalendar extends StatefulWidget {
  const GlassCalendar({
    required this.firstDate,
    required this.lastDate,
    required this.today,
    required this.onSelect,
    this.selected,
    this.marked,
    super.key,
  });

  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime today;
  final DateTime? selected;
  final bool Function(DateTime day)? marked;
  final ValueChanged<DateTime> onSelect;

  @override
  State<GlassCalendar> createState() => _GlassCalendarState();
}

class _GlassCalendarState extends State<GlassCalendar> {
  late DateTime _month = _startMonth();
  int _dir = 1;

  DateTime _startMonth() {
    final d = widget.selected ?? widget.firstDate;
    return DateTime(d.year, d.month);
  }

  @override
  void didUpdateWidget(GlassCalendar old) {
    super.didUpdateWidget(old);
    // Jump to a newly selected date's month (e.g. a shortcut in another month).
    final s = widget.selected;
    if (s != null &&
        s != old.selected &&
        (s.month != _month.month || s.year != _month.year)) {
      _dir = DateTime(s.year, s.month).isAfter(_month) ? 1 : -1;
      _month = DateTime(s.year, s.month);
    }
  }

  void _go(int by) => setState(() {
    _dir = by;
    _month = DateTime(_month.year, _month.month + by);
  });

  bool _inRange(DateTime d) =>
      !d.isBefore(widget.firstDate) && !d.isAfter(widget.lastDate);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final firstMonth = DateTime(widget.firstDate.year, widget.firstDate.month);
    final lastMonth = DateTime(widget.lastDate.year, widget.lastDate.month);
    final canPrev = _month.isAfter(firstMonth);
    final canNext = _month.isBefore(lastMonth);
    final hasMarks =
        widget.marked != null &&
        [
          for (
            var d = widget.firstDate;
            !d.isAfter(widget.lastDate);
            d = d.add(const Duration(days: 1))
          )
            if (widget.marked!(d)) d,
        ].isNotEmpty;

    final lead = _month.weekday % 7; // blanks before the 1st (Sunday first)
    final daysInMonth = DateUtils.getDaysInMonth(_month.year, _month.month);
    final cells = <DateTime?>[
      for (var i = 0; i < lead; i++) null,
      for (var d = 1; d <= daysInMonth; d++)
        DateTime(_month.year, _month.month, d),
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    Widget nav(Key k, String tip, IconData icon, bool on, VoidCallback go) =>
        Opacity(
          opacity: on ? 1 : 0.35,
          child: SizedBox(
            width: 44,
            height: 44,
            child: DiscoverGlass(
              radius: 22,
              child: IconButton(
                key: k,
                tooltip: tip,
                padding: EdgeInsets.zero,
                onPressed: on ? go : null,
                icon: Icon(icon, size: 22, color: dsNavy),
              ),
            ),
          ),
        );

    return DiscoverGlass(
      radius: 28,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                nav(
                  const Key('calendar_prev'),
                  l10n.calPrev,
                  Icons.chevron_left_rounded,
                  canPrev,
                  () => _go(-1),
                ),
                Expanded(
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      DateFormat('MMMM yyyy', locale).format(_month),
                      key: const Key('calendar_month'),
                      textAlign: TextAlign.center,
                      style: authSerif(21, 1.2),
                    ),
                  ),
                ),
                nav(
                  const Key('calendar_next'),
                  l10n.calNext,
                  Icons.chevron_right_rounded,
                  canNext,
                  () => _go(1),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ExcludeSemantics(
              child: Row(
                children: [
                  for (var i = 0; i < 7; i++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Center(
                          child: Text(
                            // 7 Jan 2024 is a Sunday.
                            DateFormat.EEEEE(
                              locale,
                            ).format(DateTime(2024, 1, 7 + i)),
                            style: AppText.body.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: dsMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: riseCurve,
              transitionBuilder: (child, a) => FadeTransition(
                opacity: a,
                child: SlideTransition(
                  position: Tween(
                    begin: Offset(0.08 * _dir, 0),
                    end: Offset.zero,
                  ).animate(a),
                  child: child,
                ),
              ),
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.topCenter,
                children: [...previous, ?current],
              ),
              child: Column(
                key: ValueKey(_month),
                children: [
                  for (var w = 0; w < cells.length ~/ 7; w++)
                    Padding(
                      padding: EdgeInsets.only(top: w == 0 ? 0 : 4),
                      child: Row(
                        children: [
                          for (var c = 0; c < 7; c++)
                            Expanded(child: _cell(cells[w * 7 + c], locale)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            if (hasMarks)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
                child: Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.warnBg,
                        border: Border.all(color: AppColors.warn, width: 2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.startNotSelectedDays,
                        style: AppText.body.copyWith(
                          fontSize: 13,
                          color: dsMuted,
                        ),
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

  Widget _cell(DateTime? day, String locale) {
    if (day == null) return const SizedBox(height: 44);
    final enabled = _inRange(day);
    final isSelected =
        widget.selected != null && DateUtils.isSameDay(day, widget.selected);
    final isToday = DateUtils.isSameDay(day, widget.today);
    final marked =
        enabled && !isSelected && (widget.marked?.call(day) ?? false);
    final fg = isSelected
        ? AppColors.surface
        : !enabled
        ? AppColors.blueB6C0CE
        : marked
        ? AppColors.warnText
        : dsNavy;
    return Semantics(
      button: true,
      enabled: enabled,
      selected: isSelected,
      label: DateFormat('EEEE, d MMMM', locale).format(day),
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: DiscoverPop(
          active: isSelected,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: dsNavy.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Material(
              key: marked ? Key('calendar_dot_${_ymd(day)}') : null,
              color: isSelected
                  ? dsNavy
                  : marked
                  ? AppColors.warnBg
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                key: Key('calendar_day_${_ymd(day)}'),
                borderRadius: BorderRadius.circular(14),
                onTap: enabled ? () => widget.onSelect(day) : null,
                child: SizedBox(
                  height: 44,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '${day.day}',
                        style: AppText.body.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: fg,
                        ),
                      ),
                      if (isToday)
                        Positioned(
                          bottom: 4,
                          child: Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? AppColors.surface
                                  : AppColors.teal,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Starts in 3 days · Sat 10 Oct" pill under the calendar.
class CountdownChip extends StatelessWidget {
  const CountdownChip({required this.text, super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: DiscoverGlass(
      radius: 999,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.event_available_outlined,
              size: 18,
              color: AppColors.teal,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                key: const Key('discover_countdown'),
                style: AppText.body.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: dsNavy,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Amber notice when the chosen day is not one of the selected weekdays.
class OutsideDaysWarning extends StatelessWidget {
  const OutsideDaysWarning({
    required this.date,
    required this.days,
    required this.onAdjust,
    super.key,
  });
  final String date;
  final String days;
  final VoidCallback onAdjust;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return KeyedSubtree(
      key: const Key('discover_outside_days_warning'),
      child: DiscoverWarn(
        radius: 22,
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(
                Icons.info_outline,
                size: 24,
                color: AppColors.warnIcon,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.startOutsideTitle(date),
                    style: authSerif(
                      18,
                      1.25,
                    ).copyWith(color: AppColors.orange78350F),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    l10n.startOutsideBody(days),
                    style: AppText.body.copyWith(
                      fontSize: 14,
                      height: 1.45,
                      color: AppColors.warnText,
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    key: const Key('discover_adjust_days_btn'),
                    onPressed: onAdjust,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      foregroundColor: dsNavy,
                      backgroundColor: AppColors.surface.withValues(alpha: 0.7),
                      side: const BorderSide(color: dsNavy, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: AppText.body.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Text(l10n.startAdjustDays),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Loading placeholder: three shortcut pills and a calendar of grey circles.
class StartSkeleton extends StatelessWidget {
  const StartSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    label: AppLocalizations.of(context).loading,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            DiscoverShimmer(width: 160, height: 44, radius: 24),
            DiscoverShimmer(width: 120, height: 44, radius: 24),
            DiscoverShimmer(width: 100, height: 44, radius: 24),
          ],
        ),
        const SizedBox(height: 14),
        DiscoverGlass(
          radius: 28,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                for (var r = 0; r < 5; r++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (var c = 0; c < 7; c++)
                          const DiscoverShimmer(
                            width: 30,
                            height: 30,
                            radius: 15,
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
