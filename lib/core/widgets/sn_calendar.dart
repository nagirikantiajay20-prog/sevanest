import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

String _ymd(DateTime d) =>
    '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

/// Month calendar (Monday first). Days outside [firstDate]..[lastDate] are disabled; [today] gets a
/// ring; [marked] days carry a small dot (Start date uses it for days outside the selected ones).
/// Each day has key `calendar_day_yyyymmdd`.
class SnCalendar extends StatefulWidget {
  const SnCalendar({
    required this.firstDate,
    required this.lastDate,
    required this.today,
    required this.onSelect,
    this.selected,
    this.marked,
    this.initialMonth,
    super.key,
  });

  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime today;
  final DateTime? selected;
  final bool Function(DateTime day)? marked;
  final ValueChanged<DateTime> onSelect;

  /// Month to show first (defaults to the selection, else the first selectable month).
  final DateTime? initialMonth;

  @override
  State<SnCalendar> createState() => _SnCalendarState();
}

class _SnCalendarState extends State<SnCalendar> {
  late DateTime _month = _startMonth();

  DateTime _startMonth() {
    final d = widget.initialMonth ?? widget.selected ?? widget.firstDate;
    return DateTime(d.year, d.month);
  }

  @override
  void didUpdateWidget(SnCalendar old) {
    super.didUpdateWidget(old);
    // Jump to a newly selected date's month (e.g. a shortcut chip in another month).
    final s = widget.selected;
    if (s != null && s != old.selected) _month = DateTime(s.year, s.month);
  }

  bool _inRange(DateTime d) =>
      !d.isBefore(widget.firstDate) && !d.isAfter(widget.lastDate);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final text = Theme.of(context).textTheme;
    final firstMonth = DateTime(widget.firstDate.year, widget.firstDate.month);
    final lastMonth = DateTime(widget.lastDate.year, widget.lastDate.month);
    final canPrev = _month.isAfter(firstMonth);
    final canNext = _month.isBefore(lastMonth);

    final lead = _month.weekday - 1; // blanks before the 1st (Monday first)
    final daysInMonth = DateUtils.getDaysInMonth(_month.year, _month.month);
    final cells = <DateTime?>[
      for (var i = 0; i < lead; i++) null,
      for (var d = 1; d <= daysInMonth; d++)
        DateTime(_month.year, _month.month, d),
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  key: const Key('calendar_prev'),
                  tooltip: l10n.calPrev,
                  onPressed: canPrev
                      ? () => setState(
                          () =>
                              _month = DateTime(_month.year, _month.month - 1),
                        )
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    DateFormat('MMMM yyyy', locale).format(_month),
                    key: const Key('calendar_month'),
                    textAlign: TextAlign.center,
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('calendar_next'),
                  tooltip: l10n.calNext,
                  onPressed: canNext
                      ? () => setState(
                          () =>
                              _month = DateTime(_month.year, _month.month + 1),
                        )
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            Row(
              children: [
                for (var i = 1; i <= 7; i++)
                  Expanded(
                    child: Center(
                      child: Text(
                        DateFormat.EEEEE(locale).format(DateTime(2024, 1, i)),
                        style: text.bodySmall?.copyWith(
                          color: AppColors.slate,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            for (var w = 0; w < cells.length ~/ 7; w++)
              Row(
                children: [
                  for (var c = 0; c < 7; c++)
                    Expanded(child: _cell(context, cells[w * 7 + c], locale)),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _cell(BuildContext context, DateTime? day, String locale) {
    if (day == null) return const SizedBox(height: 46);
    final enabled = _inRange(day);
    final isSelected =
        widget.selected != null && DateUtils.isSameDay(day, widget.selected);
    final isToday = DateUtils.isSameDay(day, widget.today);
    final marked = enabled && (widget.marked?.call(day) ?? false);

    final Color? fill = isSelected
        ? AppColors.teal
        : enabled
        ? null
        : AppColors.navyMistAlt;
    final Color fg = isSelected
        ? AppColors.surface
        : enabled
        ? AppColors.ink
        : AppColors.slate;

    return Semantics(
      button: true,
      enabled: enabled,
      selected: isSelected,
      label: DateFormat('EEEE, d MMMM', locale).format(day),
      excludeSemantics: true,
      child: InkResponse(
        key: Key('calendar_day_${_ymd(day)}'),
        onTap: enabled ? () => widget.onSelect(day) : null,
        child: SizedBox(
          height: 46,
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: fill,
                border: isToday && !isSelected
                    ? Border.all(color: AppColors.slate, width: 1.4)
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      color: fg,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w500,
                    ),
                  ),
                  if (marked)
                    Container(
                      key: Key('calendar_dot_${_ymd(day)}'),
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.only(top: 1),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? AppColors.surface : AppColors.slate,
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
