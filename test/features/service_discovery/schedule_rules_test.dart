// UNIT tests: timing / start-date / budget rules, the days helper and the draft clearing rules.
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/features/addresses/domain/address.dart';
import 'package:sevanest_customer/features/booking/data/booking_repository_remote.dart';
import 'package:sevanest_customer/features/service_discovery/domain/budget.dart';
import 'package:sevanest_customer/features/service_discovery/domain/catalog.dart';
import 'package:sevanest_customer/features/service_discovery/domain/draft_validation.dart';
import 'package:sevanest_customer/features/service_discovery/domain/requirement_draft.dart';
import 'package:sevanest_customer/features/service_discovery/domain/timing.dart';

const _cfg = ScheduleConfig.fallback;
final _today = DateTime(2026, 10, 9); // Friday

const _addr = Address(
  id: 'a',
  line: 'x',
  area: 'Madhapur',
  city: 'Hyderabad',
  pincode: '500081',
);

List<TimingIssue> _check(TimingVariant v, Timing? t, {DateTime? date}) =>
    validateTiming(variant: v, timing: t, date: date, config: _cfg);

void main() {
  group('durationMinutes', () {
    test('plain span', () => expect(durationMinutes(480, 720), 240));
    test('end not after start is non-positive', () {
      expect(durationMinutes(480, 480), 0);
      expect(durationMinutes(600, 480), lessThan(0));
    });
    test('overnight spans wrap to the next day', () {
      expect(durationMinutes(1200, 300, overnightOk: true), 540);
    });
  });

  group('validateTiming', () {
    test('part-time needs a window first', () {
      expect(
        _check(TimingVariant.partTime, initialTiming(TimingVariant.partTime)),
        [TimingIssue.windowMissing],
      );
    });

    test('part-time: a window with its default hours and Mon-Sat is valid', () {
      final t = initialTiming(
        TimingVariant.partTime,
      ).withWindow(TimeWindow.morning, _cfg);
      expect(_check(TimingVariant.partTime, t), isEmpty);
    });

    test('end before start / equal to start is rejected', () {
      for (final end in [420, 480]) {
        final t = Timing(
          window: TimeWindow.morning,
          startMinutes: 480,
          endMinutes: end,
          days: const {1},
        );
        expect(_check(TimingVariant.partTime, t), [TimingIssue.endBeforeStart]);
      }
    });

    test('minimum duration per variant (part-time 2 h, daily 1 h)', () {
      const oneHour = Timing(
        window: TimeWindow.morning,
        startMinutes: 480,
        endMinutes: 540,
        days: {1},
      );
      expect(_check(TimingVariant.partTime, oneHour), [TimingIssue.tooShort]);
      expect(_check(TimingVariant.daily, oneHour), isEmpty);
    });

    test('night may run past midnight, other windows may not', () {
      const night = Timing(
        window: TimeWindow.night,
        startMinutes: 1200,
        endMinutes: 300,
        days: {1},
      );
      expect(_check(TimingVariant.partTime, night), isEmpty);
      expect(
        _check(
          TimingVariant.partTime,
          night.copyWith(window: TimeWindow.evening),
        ),
        [TimingIssue.endBeforeStart],
      );
    });

    test('flexible window needs no times', () {
      const t = Timing(window: TimeWindow.flexible, days: {2});
      expect(_check(TimingVariant.daily, t), isEmpty);
    });

    test('at least one day where the variant needs days', () {
      const t = Timing(
        window: TimeWindow.morning,
        startMinutes: 480,
        endMinutes: 720,
      );
      expect(_check(TimingVariant.daily, t), [TimingIssue.daysMissing]);
      expect(_check(TimingVariant.partTime, t), [TimingIssue.daysMissing]);
    });

    test('full-time: 6 to 12 hours, days required', () {
      Timing shift(int s, int e) =>
          Timing(startMinutes: s, endMinutes: e, days: const {1});
      expect(_check(TimingVariant.fullTime, shift(480, 960)), isEmpty);
      expect(_check(TimingVariant.fullTime, shift(480, 720)), [
        TimingIssue.tooShort,
      ]);
      expect(_check(TimingVariant.fullTime, shift(360, 1260)), [
        TimingIssue.tooLong,
      ]);
      expect(
        _check(TimingVariant.fullTime, initialTiming(TimingVariant.fullTime)),
        isEmpty,
      );
    });

    test('hourly: window, times and a date; no days', () {
      const t = Timing(
        window: TimeWindow.morning,
        startMinutes: 600,
        endMinutes: 780,
      );
      expect(_check(TimingVariant.hourly, t), [TimingIssue.dateMissing]);
      expect(
        _check(TimingVariant.hourly, t, date: DateTime(2026, 10, 10)),
        isEmpty,
      );
    });

    test('live-in reuses the full-time layout', () {
      expect(timingVariantFor(EngagementType.liveIn), TimingVariant.fullTime);
    });
  });

  group('start date', () {
    test('today is the first selectable day; tomorrow and later too', () {
      expect(firstStartDate(_today, _cfg), DateTime(2026, 10, 9));
      expect(validateStartDate(_today, _today, _cfg), isNull);
      expect(validateStartDate(DateTime(2026, 10, 10), _today, _cfg), isNull);
      expect(validateStartDate(DateTime(2026, 11, 20), _today, _cfg), isNull);
    });

    test('yesterday is rejected', () {
      expect(
        validateStartDate(DateTime(2026, 10, 8), _today, _cfg),
        StartDateIssue.tooSoon,
      );
    });

    test('a config with min lead 1 still disables today', () {
      const c = ScheduleConfig(
        windows: {},
        minDuration: {},
        maxShiftMinutes: 720,
        shiftHours: [8],
        minLeadDays: 1,
        maxLeadDays: 60,
      );
      expect(validateStartDate(_today, _today, c), StartDateIssue.tooSoon);
    });

    group('India calendar day (Asia/Kolkata, UTC+5:30)', () {
      // 18:30 UTC = 00:00 IST next day: the midnight boundary.
      final before = DateTime.utc(2026, 10, 9, 18, 29); // 23:59 IST on 9 Oct
      final after = DateTime.utc(2026, 10, 9, 18, 30); // 00:00 IST on 10 Oct

      test('istDate follows India midnight, not UTC midnight', () {
        expect(istDate(before), DateTime(2026, 10, 9));
        expect(istDate(after), DateTime(2026, 10, 10));
        expect(istDate(DateTime.utc(2026, 10, 9, 0, 1)), DateTime(2026, 10, 9));
      });

      test('9 Oct is selectable at 23:59 IST, rejected at 00:00 IST', () {
        final d = DateTime(2026, 10, 9);
        expect(validateStartDate(d, before, _cfg), isNull);
        expect(validateStartDate(d, after, _cfg), StartDateIssue.tooSoon);
        expect(validateStartDate(DateTime(2026, 10, 10), after, _cfg), isNull);
      });

      test('shortcuts roll over at India midnight', () {
        expect(
          startDateShortcuts(before, _cfg).first.date,
          DateTime(2026, 10, 10),
        );
        expect(
          startDateShortcuts(after, _cfg).first.date,
          DateTime(2026, 10, 11),
        );
      });

      test('a date-only value serializes as-is (no UTC shift)', () {
        expect(
          BookingRepositoryRemote.day(DateTime(2026, 10, 9)),
          '2026-10-09',
        );
        expect(BookingRepositoryRemote.day(DateTime(2026, 1, 5)), '2026-01-05');
      });
    });

    test('past dates are rejected', () {
      expect(
        validateStartDate(DateTime(2026, 10, 1), _today, _cfg),
        StartDateIssue.tooSoon,
      );
    });

    test('60 days out is allowed, 61 is not', () {
      expect(lastStartDate(_today, _cfg), DateTime(2026, 12, 8));
      expect(validateStartDate(DateTime(2026, 12, 8), _today, _cfg), isNull);
      expect(
        validateStartDate(DateTime(2026, 12, 9), _today, _cfg),
        StartDateIssue.tooFar,
      );
    });

    test('null is missing; time of day is ignored', () {
      expect(validateStartDate(null, _today, _cfg), StartDateIssue.missing);
      expect(
        validateStartDate(DateTime(2026, 10, 10, 23, 59), _today, _cfg),
        isNull,
      );
    });

    test('shortcuts match the design (Fri 9 Oct)', () {
      final s = startDateShortcuts(_today, _cfg);
      expect(s.map((e) => e.kind), [
        ShortcutKind.tomorrow,
        ShortcutKind.inThreeDays,
        ShortcutKind.nextMonday,
      ]);
      expect(s[0].date, DateTime(2026, 10, 10));
      expect(s[1].date, DateTime(2026, 10, 12));
      expect(s[2].date, DateTime(2026, 10, 19));
    });

    test('next Monday is a week later when today is a Monday', () {
      final s = startDateShortcuts(DateTime(2026, 10, 5), _cfg);
      expect(s.last.date, DateTime(2026, 10, 12));
    });

    test('duplicate shortcut dates are dropped', () {
      // Fri 9 Oct: tomorrow = Sat 10 Oct. On a Thursday, "in 3 days" = Sunday, no clash;
      // use a tiny window so far shortcuts fall out of range instead.
      const c = ScheduleConfig(
        windows: {},
        minDuration: {},
        maxShiftMinutes: 720,
        shiftHours: [8],
        minLeadDays: 1,
        maxLeadDays: 4,
      );
      final s = startDateShortcuts(_today, c);
      expect(s.map((e) => e.kind), [
        ShortcutKind.tomorrow,
        ShortcutKind.inThreeDays,
      ]);
    });
  });

  group('isOnSelectedDays', () {
    final sun = DateTime(2026, 10, 11);
    final sat = DateTime(2026, 10, 10);
    test('Mon-Sat excludes Sunday', () {
      const monSat = {1, 2, 3, 4, 5, 6};
      expect(isOnSelectedDays(sun, monSat), isFalse);
      expect(isOnSelectedDays(sat, monSat), isTrue);
    });
    test('no days selected = every day', () {
      expect(isOnSelectedDays(sun, const {}), isTrue);
    });
  });

  group('budget', () {
    const g = Guidance(
      min: 6000,
      max: 10000,
      period: BudgetPeriod.monthly,
      city: 'Hyderabad',
      basis: 'Based on recent bookings',
    );
    Budget b(int? min, int? max, {bool flexible = false}) => Budget(
      min: min,
      max: max,
      flexible: flexible,
      period: BudgetPeriod.monthly,
    );

    test('inside or above the range is ok', () {
      expect(budgetStatus(b(6000, 10000), g), BudgetStatus.ok);
      expect(budgetStatus(b(8000, 12000), g), BudgetStatus.ok);
      expect(budgetStatus(b(4000, 6000), g), BudgetStatus.ok);
    });

    test('entirely below the guidance warns but is not invalid', () {
      expect(budgetStatus(b(2000, 3000), g), BudgetStatus.lowWarning);
      expect(budgetIssue(b(2000, 3000)), isNull);
    });

    test('min above max is invalid', () {
      expect(budgetStatus(b(12000, 10000), g), BudgetStatus.invalid);
      expect(budgetIssue(b(12000, 10000)), BudgetIssue.minAboveMax);
    });

    test('missing amounts are invalid unless flexible', () {
      expect(budgetIssue(null), BudgetIssue.missing);
      expect(budgetIssue(b(null, 5000)), BudgetIssue.missing);
      expect(budgetIssue(b(1000, 0)), BudgetIssue.missing);
      expect(budgetStatus(b(null, null, flexible: true), g), BudgetStatus.ok);
    });

    test('absurd amounts are invalid', () {
      expect(budgetIssue(b(1000, 600000)), BudgetIssue.tooHigh);
    });

    test('no guidance (failed to load) never warns', () {
      expect(budgetStatus(b(2000, 3000), null), BudgetStatus.ok);
    });

    test('hourly period uses its own cap and defaults', () {
      expect(budgetPeriodFor(EngagementType.hourly), BudgetPeriod.hourly);
      expect(budgetPeriodFor(EngagementType.daily), BudgetPeriod.monthly);
      expect(fallbackBudgetRange(BudgetPeriod.hourly).max, 200);
    });

    test('Indian grouping', () {
      expect(formatRupees(0), '₹0');
      expect(formatRupees(999), '₹999');
      expect(formatRupees(6000), '₹6,000');
      expect(formatRupees(40000), '₹40,000');
      expect(formatRupees(100000), '₹1,00,000');
      expect(formatRupees(12345678), '₹1,23,45,678');
    });

    test('JSON round trip', () {
      final back = Budget.fromJson(b(6000, 10000).toJson());
      expect((back.min, back.max, back.flexible), (6000, 10000, false));
    });
  });

  group('draft clearing rules', () {
    RequirementDraft full(EngagementType e) => RequirementDraft(
      serviceId: 'cook',
      engagement: e,
      address: _addr,
      timing: initialTiming(timingVariantFor(e)),
      startDate: DateTime(2026, 10, 12),
      budget: Budget(min: 6000, max: 10000, period: budgetPeriodFor(e)),
    );

    test('a different service clears engagement, timing, date and budget', () {
      final d = full(EngagementType.partTime).withService('maid');
      expect(d.engagement, isNull);
      expect(d.timing, isNull);
      expect(d.startDate, isNull);
      expect(d.budget, isNull);
      expect(d.address, _addr);
    });

    test('same timing variant keeps timing but never the old budget', () {
      final d = full(
        EngagementType.fullTime,
      ).withEngagement(EngagementType.liveIn);
      expect(d.timing, isNotNull);
      expect(d.budget, isNull);
    });

    test('a different variant drops timing and budget, keeps the date', () {
      final d = full(
        EngagementType.partTime,
      ).withEngagement(EngagementType.hourly);
      expect(d.timing, isNull);
      expect(d.budget, isNull);
      expect(d.startDate, DateTime(2026, 10, 12));
    });

    test('re-picking the same engagement changes nothing', () {
      final before = full(EngagementType.partTime);
      expect(
        identical(before.withEngagement(EngagementType.partTime), before),
        isTrue,
      );
    });

    test('JSON round trip keeps everything', () {
      final back = RequirementDraft.fromJson(
        full(EngagementType.daily).toJson(),
      );
      expect(back.timing, isNotNull);
      expect(back.startDate, DateTime(2026, 10, 12));
      expect(back.budget?.period, BudgetPeriod.monthly);
      expect(back.engagement, EngagementType.daily);
    });
  });

  group('firstIncompleteStep', () {
    RequirementDraft ready() => RequirementDraft(
      serviceId: 'cook',
      engagement: EngagementType.partTime,
      address: _addr,
      timing: initialTiming(
        TimingVariant.partTime,
      ).withWindow(TimeWindow.morning, _cfg),
      startDate: DateTime(2026, 10, 12),
      budget: const Budget(min: 6000, max: 10000, period: BudgetPeriod.monthly),
    );
    DraftGap? gap(RequirementDraft d) =>
        firstIncompleteStep(d, today: _today, config: _cfg);

    test('a complete draft has no gap', () => expect(gap(ready()), isNull));

    test('walks the steps in order', () {
      expect(gap(const RequirementDraft())?.step, DiscoverStep.service);
      expect(
        gap(const RequirementDraft(serviceId: 'cook'))?.step,
        DiscoverStep.engagement,
      );
      expect(
        gap(
          const RequirementDraft(
            serviceId: 'cook',
            engagement: EngagementType.daily,
          ),
        )?.step,
        DiscoverStep.location,
      );
    });

    test('invalid timing, missing date, bad budget', () {
      expect(gap(ready().withTiming(null))?.step, DiscoverStep.timing);
      expect(
        gap(ready().withStartDate(null))?.reason,
        DraftGapReason.noStartDate,
      );
      expect(
        gap(ready().withStartDate(DateTime(2026, 10, 8)))?.reason,
        DraftGapReason.startDateOutOfRange,
      );
      expect(
        gap(
          ready().withBudget(
            const Budget(min: 9, max: 1, period: BudgetPeriod.monthly),
          ),
        )?.step,
        DiscoverStep.budget,
      );
      expect(
        gap(ready().withBudget(null))?.reason,
        DraftGapReason.budgetIncomplete,
      );
    });

    test('budget is skipped when the service does not need one', () {
      expect(
        firstIncompleteStep(
          ready().withBudget(null),
          today: _today,
          config: _cfg,
          requiresBudget: false,
        ),
        isNull,
      );
    });

    test('hourly: its missing date is reported on Timing', () {
      const d = RequirementDraft(
        serviceId: 'cook',
        engagement: EngagementType.hourly,
        address: _addr,
        timing: Timing(window: TimeWindow.flexible),
      );
      final g = gap(d);
      expect(g?.step, DiscoverStep.timing);
    });
  });
}
