import 'package:intl/intl.dart';
import 'package:sevanest_customer/features/service_discovery/domain/timing.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// "8 AM", "9:30 AM", "12 PM". [minutes] is minutes since midnight.
String formatTime(int minutes) {
  final h24 = (minutes ~/ 60) % 24;
  final m = minutes % 60;
  final h = h24 % 12 == 0 ? 12 : h24 % 12;
  final period = h24 < 12 ? 'AM' : 'PM';
  return m == 0 ? '$h $period' : '$h:${m.toString().padLeft(2, '0')} $period';
}

/// "8 AM – 12 PM" (spaced, used in summaries and time fields).
String formatTimeSpan(int start, int end) =>
    '${formatTime(start)} – ${formatTime(end)}';

/// Compact window caption on the cards: "5–8 AM", "8 AM–12 PM", "8 PM–5 AM".
String formatWindowRange(WindowSlot s) {
  String hm(int m) {
    final h24 = (m ~/ 60) % 24;
    final mm = m % 60;
    final h = h24 % 12 == 0 ? 12 : h24 % 12;
    return mm == 0 ? '$h' : '$h:${mm.toString().padLeft(2, '0')}';
  }

  String per(int m) => (m ~/ 60) % 24 < 12 ? 'AM' : 'PM';
  return per(s.start) == per(s.end)
      ? '${hm(s.start)}–${hm(s.end)} ${per(s.end)}'
      : '${hm(s.start)} ${per(s.start)}–${hm(s.end)} ${per(s.end)}';
}

String windowName(AppLocalizations l, TimeWindow w) => switch (w) {
  TimeWindow.earlyMorning => l.winEarlyMorning,
  TimeWindow.morning => l.winMorning,
  TimeWindow.afternoon => l.winAfternoon,
  TimeWindow.evening => l.winEvening,
  TimeWindow.night => l.winNight,
  TimeWindow.flexible => l.winFlexible,
};

String windowPlural(AppLocalizations l, TimeWindow w) => switch (w) {
  TimeWindow.earlyMorning => l.winEarlyMorningPlural,
  TimeWindow.morning => l.winMorningPlural,
  TimeWindow.afternoon => l.winAfternoonPlural,
  TimeWindow.evening => l.winEveningPlural,
  TimeWindow.night => l.winNightPlural,
  TimeWindow.flexible => l.winFlexible,
};

String windowCaption(AppLocalizations l, TimeWindow w, ScheduleConfig c) {
  final slot = c.windows[w];
  return slot == null ? l.winFlexibleRange : formatWindowRange(slot);
}

String dayShort(int isoDay, [String? locale]) => DateFormat.E(
  locale,
).format(DateTime(2024, 1, isoDay)); // 1 Jan 2024 is a Monday

/// "Every day", "Mon to Sat", "Mon, Wed, Fri".
String formatDays(AppLocalizations l, Set<int> days, [String? locale]) {
  final d = days.toList()..sort();
  if (d.length == 7) return l.daysEvery;
  if (d.isEmpty) return '';
  final contiguous = d.length >= 3 && d.last - d.first == d.length - 1;
  if (contiguous) {
    return l.daysRange(dayShort(d.first, locale), dayShort(d.last, locale));
  }
  return d.map((e) => dayShort(e, locale)).join(', ');
}

/// "3 hours", "1.5 hours", "1 hour", "45 min".
String formatDuration(AppLocalizations l, int minutes) {
  if (minutes < 60) return l.durMinutes(minutes);
  final h = minutes / 60;
  return l.durHours(h == h.roundToDouble() ? h.round() : h);
}

String formatDate(DateTime d, [String? locale]) =>
    DateFormat('EEE, d MMM', locale).format(d);

/// Shortcut chips: "Sat 10 Oct" (design 10 has no comma here).
String formatShortcutDate(DateTime d, [String? locale]) =>
    DateFormat('EEE d MMM', locale).format(d);

String formatDayMonth(DateTime d, [String? locale]) =>
    DateFormat('d MMM', locale).format(d);

/// One-line summary above Continue: "Mornings · 8 AM – 12 PM · Mon to Sat",
/// "8 AM – 4 PM · 8 hours · Mon to Sat", "Sat, 10 Oct · 10 AM – 1 PM · 3 hours".
String timingSummary(
  AppLocalizations l, {
  required TimingVariant variant,
  required Timing? timing,
  required DateTime? date,
  String? locale,
}) {
  final t = timing ?? const Timing();
  final parts = <String>[];
  final s = t.startMinutes;
  final e = t.endMinutes;
  final flexible = t.window == TimeWindow.flexible;
  final span = s != null && e != null && !flexible;
  final dur = span
      ? durationMinutes(s, e, overnightOk: t.window == TimeWindow.night)
      : 0;

  switch (variant) {
    case TimingVariant.fullTime:
      if (span) parts.add(formatTimeSpan(s, e));
      if (dur > 0) parts.add(formatDuration(l, dur));
    case TimingVariant.hourly:
      if (date != null) parts.add(formatDate(date, locale));
      if (span) parts.add(formatTimeSpan(s, e));
      if (flexible) parts.add(l.winFlexible);
      if (dur > 0) parts.add(formatDuration(l, dur));
    case TimingVariant.partTime || TimingVariant.daily:
      if (t.window != null) parts.add(windowPlural(l, t.window!));
      if (span) parts.add(formatTimeSpan(s, e));
  }
  if (variantUsesDays(variant) && t.days.isNotEmpty) {
    parts.add(formatDays(l, t.days, locale));
  }
  return parts.join(' · ');
}

String timingIssueMessage(
  AppLocalizations l,
  TimingIssue issue,
  TimingVariant variant,
  ScheduleConfig c,
) => switch (issue) {
  TimingIssue.endBeforeStart => l.timingErrEnd,
  TimingIssue.tooShort => l.timingErrShort(
    formatDuration(l, c.minDuration[variant] ?? 0),
  ),
  TimingIssue.tooLong => l.timingErrLong(formatDuration(l, c.maxShiftMinutes)),
  TimingIssue.daysMissing => l.timingErrDays,
  TimingIssue.dateMissing => l.timingErrDate,
  TimingIssue.windowMissing ||
  TimingIssue.startMissing ||
  TimingIssue.endMissing => '',
};
