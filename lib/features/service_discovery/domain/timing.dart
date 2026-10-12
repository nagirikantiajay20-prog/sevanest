import 'package:sevanest_customer/features/service_discovery/domain/catalog.dart';

/// "Preferred time of day" cards (design 09).
enum TimeWindow { earlyMorning, morning, afternoon, evening, night, flexible }

/// Which Timing layout an engagement uses. Live-in has no screen of its own: it reuses the
/// full-time shift layout (OPEN_QUESTIONS: live-in timing is not designed).
enum TimingVariant { partTime, daily, hourly, fullTime }

TimingVariant timingVariantFor(EngagementType e) => switch (e) {
  EngagementType.partTime => TimingVariant.partTime,
  EngagementType.daily => TimingVariant.daily,
  EngagementType.hourly => TimingVariant.hourly,
  EngagementType.fullTime || EngagementType.liveIn => TimingVariant.fullTime,
};

/// Whether a variant asks for days of the week. Hourly is a single dated visit instead.
bool variantUsesDays(TimingVariant v) => v != TimingVariant.hourly;

/// Default clock span of a window, minutes since midnight. Night crosses midnight (end < start).
class WindowSlot {
  const WindowSlot(this.start, this.end);
  final int start;
  final int end;
}

/// Schedule rules from the backend (`GET /catalog/time-slots`, docs/05). Durations are minutes.
class ScheduleConfig {
  const ScheduleConfig({
    required this.windows,
    required this.minDuration,
    required this.maxShiftMinutes,
    required this.shiftHours,
    required this.minLeadDays,
    required this.maxLeadDays,
  });

  final Map<TimeWindow, WindowSlot> windows;
  final Map<TimingVariant, int> minDuration;
  final int maxShiftMinutes;

  /// "Hours per day" chips of the full-time layout.
  final List<int> shiftHours;

  /// Earliest start = today + [minLeadDays] (design: today itself is not selectable).
  final int minLeadDays;

  /// Latest start = today + [maxLeadDays] (the 60-day limit).
  final int maxLeadDays;

  static const fallback = ScheduleConfig(
    windows: {
      TimeWindow.earlyMorning: WindowSlot(300, 480),
      TimeWindow.morning: WindowSlot(480, 720),
      TimeWindow.afternoon: WindowSlot(720, 960),
      TimeWindow.evening: WindowSlot(960, 1200),
      TimeWindow.night: WindowSlot(1200, 300),
    },
    minDuration: {
      TimingVariant.partTime: 120,
      TimingVariant.daily: 60,
      TimingVariant.hourly: 60,
      TimingVariant.fullTime: 360,
    },
    maxShiftMinutes: 720,
    shiftHours: [6, 8, 10, 12],
    minLeadDays: 1,
    maxLeadDays: 60,
  );
}

/// The "when" part of the draft. Times are minutes since midnight; [days] are ISO weekdays
/// (Mon = 1 ... Sun = 7). Hourly ignores [days]; its date is the draft's start date.
class Timing {
  const Timing({
    this.window,
    this.startMinutes,
    this.endMinutes,
    this.days = const {},
  });

  final TimeWindow? window;
  final int? startMinutes;
  final int? endMinutes;
  final Set<int> days;

  Timing copyWith({
    TimeWindow? window,
    int? startMinutes,
    int? endMinutes,
    Set<int>? days,
    bool clearTimes = false,
  }) => Timing(
    window: window ?? this.window,
    startMinutes: clearTimes ? null : startMinutes ?? this.startMinutes,
    endMinutes: clearTimes ? null : endMinutes ?? this.endMinutes,
    days: days ?? this.days,
  );

  /// Picking a window fills its default hours (Flexible has none).
  Timing withWindow(TimeWindow w, ScheduleConfig config) {
    final slot = config.windows[w];
    return Timing(
      window: w,
      startMinutes: slot?.start,
      endMinutes: slot?.end,
      days: days,
    );
  }

  Map<String, Object?> toJson() => {
    'window': window?.name,
    'start': startMinutes,
    'end': endMinutes,
    'days': days.toList()..sort(),
  };

  factory Timing.fromJson(Map<String, dynamic> j) => Timing(
    window: j['window'] == null
        ? null
        : TimeWindow.values.byName(j['window'] as String),
    startMinutes: j['start'] as int?,
    endMinutes: j['end'] as int?,
    days: {for (final d in (j['days'] as List<dynamic>? ?? [])) d as int},
  );
}

/// Starting layout when a variant is opened for the first time (design: Full-time and Part-time
/// open with Mon-Sat; Full-time with 8 AM - 4 PM; Daily asks for explicit days).
Timing initialTiming(TimingVariant v) => switch (v) {
  TimingVariant.fullTime => const Timing(
    startMinutes: 480,
    endMinutes: 960,
    days: {1, 2, 3, 4, 5, 6},
  ),
  TimingVariant.partTime => const Timing(days: {1, 2, 3, 4, 5, 6}),
  TimingVariant.daily || TimingVariant.hourly => const Timing(),
};

enum TimingIssue {
  windowMissing,
  startMissing,
  endMissing,
  endBeforeStart,
  tooShort,
  tooLong,
  daysMissing,
  dateMissing,
}

/// Length of a span in minutes. Only [overnightOk] spans may end at or before their start (they
/// run into the next day); otherwise a non-positive result means the end is not after the start.
int durationMinutes(int start, int end, {bool overnightOk = false}) {
  if (end > start) return end - start;
  return overnightOk ? end + 1440 - start : end - start;
}

/// Everything that must be fixed before Timing can continue. Empty list = valid.
List<TimingIssue> validateTiming({
  required TimingVariant variant,
  required Timing? timing,
  required DateTime? date,
  required ScheduleConfig config,
}) {
  final t = timing ?? const Timing();
  final issues = <TimingIssue>[];
  final needsWindow = variant != TimingVariant.fullTime;
  final flexible = t.window == TimeWindow.flexible;

  if (needsWindow && t.window == null) {
    return [TimingIssue.windowMissing]; // nothing else is meaningful yet
  }
  if (!(needsWindow && flexible)) {
    final s = t.startMinutes;
    final e = t.endMinutes;
    if (s == null) issues.add(TimingIssue.startMissing);
    if (e == null) issues.add(TimingIssue.endMissing);
    if (s != null && e != null) {
      final overnight = t.window == TimeWindow.night;
      final d = durationMinutes(s, e, overnightOk: overnight);
      if (d <= 0) {
        issues.add(TimingIssue.endBeforeStart);
      } else if (d < (config.minDuration[variant] ?? 0)) {
        issues.add(TimingIssue.tooShort);
      } else if (variant == TimingVariant.fullTime &&
          d > config.maxShiftMinutes) {
        issues.add(TimingIssue.tooLong);
      }
    }
  }
  if (variantUsesDays(variant) && t.days.isEmpty) {
    issues.add(TimingIssue.daysMissing);
  }
  if (variant == TimingVariant.hourly && date == null) {
    issues.add(TimingIssue.dateMissing);
  }
  return issues;
}

enum StartDateIssue { missing, tooSoon, tooFar }

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Earliest and latest selectable start dates.
DateTime firstStartDate(DateTime today, ScheduleConfig c) =>
    dateOnly(today).add(Duration(days: c.minLeadDays));
DateTime lastStartDate(DateTime today, ScheduleConfig c) =>
    dateOnly(today).add(Duration(days: c.maxLeadDays));

StartDateIssue? validateStartDate(
  DateTime? date,
  DateTime today,
  ScheduleConfig config,
) {
  if (date == null) return StartDateIssue.missing;
  final d = dateOnly(date);
  if (d.isBefore(firstStartDate(today, config))) return StartDateIssue.tooSoon;
  if (d.isAfter(lastStartDate(today, config))) return StartDateIssue.tooFar;
  return null;
}

/// True when [date] falls on one of the selected [days] (no days selected = every day).
bool isOnSelectedDays(DateTime date, Set<int> days) =>
    days.isEmpty || days.contains(date.weekday);

/// Start-date shortcuts (design 10): tomorrow, in 3 days, and the "next Monday" = the first Monday
/// on or after today + 7 (Fri 9 Oct -> Mon 19 Oct). Duplicate dates are dropped.
List<({ShortcutKind kind, DateTime date})> startDateShortcuts(
  DateTime today,
  ScheduleConfig config,
) {
  final t = dateOnly(today);
  final next = t.add(const Duration(days: 7));
  final monday = next.add(Duration(days: (8 - next.weekday) % 7));
  final raw = [
    (kind: ShortcutKind.tomorrow, date: t.add(const Duration(days: 1))),
    (kind: ShortcutKind.inThreeDays, date: t.add(const Duration(days: 3))),
    (kind: ShortcutKind.nextMonday, date: monday),
  ];
  final seen = <DateTime>{};
  return [
    for (final s in raw)
      if (validateStartDate(s.date, today, config) == null && seen.add(s.date))
        s,
  ];
}

enum ShortcutKind { tomorrow, inThreeDays, nextMonday }
