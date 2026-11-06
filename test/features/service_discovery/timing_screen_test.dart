// WIDGET tests: Timing (screen 09, step 4 of 6): every variant and state in the design.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/features/service_discovery/domain/catalog.dart';
import 'package:sevanest_customer/features/service_discovery/domain/timing.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/requirement_draft_provider.dart';

import '../../helpers/discover_harness.dart';

void main() {
  Future<DiscoverEnv> open(
    WidgetTester t,
    EngagementType e, {
    String route = '/discover/timing',
  }) async {
    final env = await launchDiscover(t);
    env.stepsOneToThree(e);
    await env.go(route);
    return env;
  }

  group('Part-time (default)', () {
    testWidgets('six windows, nothing chosen: Continue disabled, no summary', (
      t,
    ) async {
      final env = await open(t, EngagementType.partTime);
      expect(find.text('Step 4 of 6'), findsOneWidget);
      expect(find.text('When do you need them?'), findsOneWidget);
      for (final w in TimeWindow.values) {
        expect(find.byKey(Key('discover_window_${w.name}')), findsOneWidget);
      }
      expect(find.text('5–8 AM'), findsOneWidget);
      expect(find.text('8 AM–12 PM'), findsOneWidget);
      expect(find.text('8 PM–5 AM'), findsOneWidget);
      expect(find.text('Any time'), findsOneWidget);
      expect(env.nextEnabled, isFalse);
      expect(find.byKey(const Key('discover_summary')), findsNothing);
    });

    testWidgets('chips row shows service, engagement and area with Change', (
      t,
    ) async {
      await open(t, EngagementType.partTime);
      expect(find.text('Cook'), findsOneWidget);
      expect(find.text('Part-time'), findsOneWidget);
      expect(find.text('Madhapur'), findsOneWidget);
      for (final k in [
        'discover_change_service',
        'discover_change_engagement',
        'discover_change_address',
      ]) {
        expect(find.byKey(Key(k)), findsOneWidget);
      }
    });

    testWidgets('Morning (filled): hours default, Mon-Sat, summary, Continue', (
      t,
    ) async {
      final env = await open(t, EngagementType.partTime);
      await env.tapKey('discover_window_morning');
      expect(env.nextEnabled, isTrue);
      expect(find.text('Mornings · 8 AM – 12 PM · Mon to Sat'), findsOneWidget);
      final timing = env.container.read(requirementDraftProvider).timing;
      expect(timing?.window, TimeWindow.morning);
      expect((timing?.startMinutes, timing?.endMinutes), (480, 720));
      await env.tapKey('discover_next_btn');
      expect(env.where, '/discover/start-date');
    });

    testWidgets('Flexible needs no exact hours', (t) async {
      final env = await open(t, EngagementType.partTime);
      await env.tapKey('discover_window_flexible');
      expect(find.byKey(const Key('discover_time_start_btn')), findsNothing);
      expect(env.nextEnabled, isTrue);
      expect(find.text('Flexible · Mon to Sat'), findsOneWidget);
    });

    testWidgets('time error: end before start keeps Continue disabled', (
      t,
    ) async {
      final env = await open(t, EngagementType.partTime);
      await env.tapKey('discover_window_morning');
      env.draftNotifier.setTiming(
        const Timing(
          window: TimeWindow.morning,
          startMinutes: 720,
          endMinutes: 480,
          days: {1, 2, 3},
        ),
      );
      await t.pumpAndSettle();
      expect(
        find.text('End time must be after the start time.'),
        findsOneWidget,
      );
      expect(env.nextEnabled, isFalse);
      expect(find.byKey(const Key('discover_summary')), findsNothing);
    });

    testWidgets('time error: too-short span names the minimum', (t) async {
      final env = await open(t, EngagementType.partTime);
      await env.tapKey('discover_window_morning');
      env.draftNotifier.setTiming(
        const Timing(
          window: TimeWindow.morning,
          startMinutes: 480,
          endMinutes: 540,
          days: {1},
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('Choose at least 2 hours.'), findsOneWidget);
      expect(env.nextEnabled, isFalse);
    });

    testWidgets('clearing every day blocks Continue with a hint', (t) async {
      final env = await open(t, EngagementType.partTime);
      await env.tapKey('discover_window_morning');
      env.draftNotifier.setTiming(
        env.container.read(requirementDraftProvider).timing!.copyWith(days: {}),
      );
      await t.pumpAndSettle();
      expect(find.byKey(const Key('discover_days_hint')), findsOneWidget);
      expect(env.nextEnabled, isFalse);
    });
  });

  group('time picker sheet', () {
    testWidgets('open, cancel leaves the time alone', (t) async {
      final env = await open(t, EngagementType.partTime);
      await env.tapKey('discover_window_morning');
      await env.tapKey('discover_time_start_btn');
      expect(find.text('Start time'), findsWidgets);
      await env.tapKey('time_picker_cancel_btn');
      expect(find.byKey(const Key('time_picker_set_btn')), findsNothing);
      expect(
        env.container.read(requirementDraftProvider).timing?.startMinutes,
        480,
      );
    });

    testWidgets('select a time and confirm', (t) async {
      final env = await open(t, EngagementType.partTime);
      await env.tapKey('discover_window_morning');
      await env.tapKey('discover_time_start_btn');
      // Hour wheel: 8 -> 9; minute wheel: 00 -> 15.
      await t.drag(
        find.byKey(const Key('time_picker_hour')),
        const Offset(0, -44),
      );
      await t.pumpAndSettle();
      await t.drag(
        find.byKey(const Key('time_picker_minute')),
        const Offset(0, -44),
      );
      await t.pumpAndSettle();
      await env.tapKey('time_picker_set_btn');
      expect(
        env.container.read(requirementDraftProvider).timing?.startMinutes,
        9 * 60 + 15,
      );
      expect(find.textContaining('9:15 AM – 12 PM'), findsOneWidget);
    });

    testWidgets('the end time sheet is titled End time', (t) async {
      final env = await open(t, EngagementType.partTime);
      await env.tapKey('discover_window_morning');
      await env.tapKey('discover_time_end_btn');
      expect(
        t.widget<Text>(find.byKey(const Key('time_sheet_title'))).data,
        'End time',
      );
    });
  });

  group('Daily', () {
    testWidgets('days start empty and must be chosen', (t) async {
      final env = await open(t, EngagementType.daily);
      await env.tapKey('discover_window_morning');
      expect(find.byKey(const Key('discover_days_hint')), findsOneWidget);
      expect(env.nextEnabled, isFalse);
      for (final d in [1, 3, 5]) {
        await env.tapKey('discover_day_$d');
      }
      expect(env.nextEnabled, isTrue);
      expect(
        find.text('Mornings · 8 AM – 12 PM · Mon, Wed, Fri'),
        findsOneWidget,
      );
    });

    testWidgets('Weekdays and Weekends shortcuts', (t) async {
      final env = await open(t, EngagementType.daily);
      await env.tapKey('discover_window_evening');
      await env.tapKey('discover_days_weekdays');
      expect(find.textContaining('Mon to Fri'), findsOneWidget);
      await env.tapKey('discover_days_weekends');
      expect(find.textContaining('Sat, Sun'), findsOneWidget);
      await env.tapKey('discover_days_every');
      expect(find.text('Evenings · 4 PM – 8 PM · Every day'), findsOneWidget);
    });
  });

  group('Full-time', () {
    testWidgets('opens with 8 AM - 4 PM, 8 hours and Mon-Sat', (t) async {
      final env = await open(t, EngagementType.fullTime);
      expect(find.text('Shift hours'), findsOneWidget);
      expect(find.byKey(const Key('discover_window_morning')), findsNothing);
      expect(find.text('8 AM'), findsOneWidget);
      expect(find.text('4 PM'), findsOneWidget);
      expect(find.text('8 hours per day'), findsOneWidget);
      expect(find.text('8 AM – 4 PM · 8 hours · Mon to Sat'), findsOneWidget);
      expect(env.nextEnabled, isTrue);
    });

    testWidgets('hours chips move the end time', (t) async {
      final env = await open(t, EngagementType.fullTime);
      await env.tapKey('discover_hours_6');
      expect(find.text('2 PM'), findsOneWidget);
      expect(find.text('8 AM – 2 PM · 6 hours · Mon to Sat'), findsOneWidget);
      await env.tapKey('discover_hours_12');
      expect(find.text('8 PM'), findsOneWidget);
    });

    testWidgets('a shift shorter than 6 hours is rejected', (t) async {
      final env = await open(t, EngagementType.fullTime);
      env.draftNotifier.setTiming(
        const Timing(startMinutes: 480, endMinutes: 720, days: {1}),
      );
      await t.pumpAndSettle();
      expect(find.text('Choose at least 6 hours.'), findsOneWidget);
      expect(env.nextEnabled, isFalse);
    });

    testWidgets('Live-in reuses the full-time layout', (t) async {
      await open(t, EngagementType.liveIn);
      expect(find.text('Shift hours'), findsOneWidget);
    });
  });

  group('Hourly', () {
    testWidgets('needs a window, a date and valid hours; skips Start date', (
      t,
    ) async {
      final env = await open(t, EngagementType.hourly);
      expect(find.text('Date'), findsOneWidget);
      expect(
        find.byKey(const Key('discover_day_1')),
        findsNothing,
      ); // no weekdays
      await env.tapKey('discover_window_morning');
      expect(env.nextEnabled, isFalse);
      expect(find.byKey(const Key('discover_date_hint')), findsOneWidget);

      await env.tapKey('discover_date_btn');
      expect(find.text('Select date'), findsOneWidget);
      expect(
        find.text('Select a date'),
        findsOneWidget,
      ); // Set is disabled until picked
      await env.tapKey('calendar_day_20261010');
      expect(find.text('Set date: Sat, 10 Oct'), findsOneWidget);
      await env.tapKey('date_sheet_set_btn');
      expect(find.text('Sat, 10 Oct'), findsWidgets);

      env.draftNotifier.setTiming(
        const Timing(
          window: TimeWindow.morning,
          startMinutes: 600,
          endMinutes: 780,
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('Sat, 10 Oct · 10 AM – 1 PM · 3 hours'), findsOneWidget);
      expect(env.nextEnabled, isTrue);
      await env.tapKey('discover_next_btn');
      expect(env.where, '/discover/budget');
    });

    testWidgets(
      'date sheet: yesterday is disabled, closing keeps the old date',
      (t) async {
        final env = await open(t, EngagementType.hourly);
        await env.tapKey('discover_date_btn');
        await t.tap(find.byKey(const Key('calendar_day_20261008')));
        await t.pumpAndSettle();
        expect(find.text('Select a date'), findsOneWidget);
        await env.tapKey('date_sheet_close');
        expect(env.container.read(requirementDraftProvider).startDate, isNull);
      },
    );

    testWidgets('date sheet: today is selectable', (t) async {
      final env = await open(t, EngagementType.hourly);
      await env.tapKey('discover_date_btn');
      await env.tapKey('calendar_day_20261009');
      await env.tapKey('date_sheet_set_btn');
      expect(
        env.container.read(requirementDraftProvider).startDate,
        DateTime(2026, 10, 9),
      );
    });
  });

  group('loading, error, wiring', () {
    testWidgets('loading skeleton while the schedule rules load', (t) async {
      final env = await launchDiscover(t);
      final gate = Completer<void>();
      env.schedule.gate = gate.future;
      env.stepsOneToThree(EngagementType.partTime);
      env.unawaitedPush('/discover/timing');
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
      expect(find.byKey(const Key('discover_window_morning')), findsNothing);
      expect(env.nextEnabled, isFalse);
      gate.complete();
      await t.pumpAndSettle();
      expect(find.byKey(const Key('discover_window_morning')), findsOneWidget);
    });

    testWidgets('error card -> Try again', (t) async {
      final env = await launchDiscover(t);
      env.schedule.failNext = const NetworkFailure();
      env.stepsOneToThree(EngagementType.partTime);
      await env.go('/discover/timing');
      expect(find.text("We couldn't load timing options"), findsOneWidget);
      await env.tapKey('error_retry_btn');
      expect(find.byKey(const Key('discover_window_morning')), findsOneWidget);
    });

    testWidgets('edit mode: Continue returns to the previous screen', (
      t,
    ) async {
      final env = await open(
        t,
        EngagementType.partTime,
        route: '/discover/budget',
      );
      await env.go('/discover/timing?edit=true');
      expect(env.where, '/discover/timing');
      await env.tapKey('discover_window_afternoon');
      await env.tapKey('discover_next_btn');
      expect(env.where, '/discover/budget');
    });

    testWidgets('Change engagement to another variant clears the timing', (
      t,
    ) async {
      final env = await open(t, EngagementType.partTime);
      await env.tapKey('discover_window_morning');
      await t.drag(find.byType(ListView).first, const Offset(0, 800));
      await t.pumpAndSettle();
      await env.tapKey('discover_change_engagement');
      expect(env.where, '/discover/engagement');
      await env.tapKey('discover_engagement_fullTime');
      await env.tapKey('discover_next_btn'); // edit mode: back to Timing
      expect(env.where, '/discover/timing');
      // Full-time layout, with its own defaults rather than the part-time window.
      expect(find.text('Shift hours'), findsOneWidget);
      expect(find.text('8 AM – 4 PM · 8 hours · Mon to Sat'), findsOneWidget);
    });

    testWidgets('resumed without an engagement: sent to pick one', (t) async {
      final env = await launchDiscover(t);
      env.draftNotifier.setService('cook');
      await env.go('/discover/timing');
      expect(env.where, '/discover/engagement');
    });
  });
}
