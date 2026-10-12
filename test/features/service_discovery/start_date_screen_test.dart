// WIDGET tests: Start date (screen 10, step 5 of 6). "Today" is Fri 9 Oct 2026 (the design date).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/features/service_discovery/domain/catalog.dart';
import 'package:sevanest_customer/features/service_discovery/domain/timing.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/requirement_draft_provider.dart';

import '../../helpers/discover_harness.dart';

void main() {
  /// Part-time, Mornings, Mon-Sat unless told otherwise.
  Future<DiscoverEnv> open(
    WidgetTester t, {
    EngagementType e = EngagementType.partTime,
    String route = '/discover/start-date',
  }) async {
    final env = await launchDiscover(t);
    env.stepsOneToThree(e);
    if (e != EngagementType.hourly) {
      env.draftNotifier.setTiming(
        const Timing(
          window: TimeWindow.morning,
          startMinutes: 480,
          endMinutes: 720,
          days: {1, 2, 3, 4, 5, 6},
        ),
      );
    }
    await env.go(route);
    return env;
  }

  DateTime? picked(DiscoverEnv env) =>
      env.container.read(requirementDraftProvider).startDate;

  testWidgets('default: shortcuts, calendar, Continue disabled', (t) async {
    final env = await open(t);
    expect(find.text('Step 5 of 6'), findsOneWidget);
    expect(find.text('When should they start?'), findsOneWidget);
    expect(find.text('Tomorrow, Sat 10 Oct'), findsOneWidget);
    expect(find.text('In 3 days, Mon 12 Oct'), findsOneWidget);
    expect(find.text('Next Monday, 19 Oct'), findsOneWidget);
    expect(find.text('Pick another date'), findsOneWidget);
    expect(find.text('October 2026'), findsOneWidget);
    expect(env.nextEnabled, isFalse);
  });

  testWidgets('past dates and today are disabled', (t) async {
    final env = await open(t);
    await t.tap(find.byKey(const Key('calendar_day_20261005')));
    await t.tap(find.byKey(const Key('calendar_day_20261009')));
    await t.pump();
    expect(picked(env), isNull);
  });

  testWidgets('a date selected: label, shortcut check, Continue to Budget', (
    t,
  ) async {
    final env = await open(t);
    await env.tapKey('calendar_day_20261010');
    expect(picked(env), DateTime(2026, 10, 10));
    expect(find.text('Continue with Sat, 10 Oct'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsWidgets);
    expect(
      find.byKey(const Key('discover_outside_days_warning')),
      findsNothing,
    );
    await env.tapKey('discover_next_btn');
    expect(env.where, '/discover/budget');
  });

  testWidgets('Next Monday shortcut selects 19 Oct', (t) async {
    final env = await open(t);
    await env.tapKey('discover_shortcut_nextMonday');
    expect(picked(env), DateTime(2026, 10, 19));
    expect(find.text('Continue with Mon, 19 Oct'), findsOneWidget);
  });

  testWidgets('Pick another date is highlighted for a custom date', (t) async {
    final env = await open(t);
    await env.tapKey('calendar_day_20261014');
    final chip = find.byKey(const Key('discover_shortcut_other'));
    expect(
      find.descendant(of: chip, matching: find.byIcon(Icons.check)),
      findsOneWidget,
    );
  });

  group('outside selected days', () {
    testWidgets('Sunday warns but still continues; days are dotted', (t) async {
      final env = await open(t);
      expect(find.byKey(const Key('calendar_dot_20261011')), findsOneWidget);
      expect(find.byKey(const Key('calendar_dot_20261010')), findsNothing);
      await env.tapKey('calendar_day_20261011');
      expect(
        find.byKey(const Key('discover_outside_days_warning')),
        findsOneWidget,
      );
      expect(
        find.text("Sun, 11 Oct isn't one of your selected days"),
        findsOneWidget,
      );
      expect(find.text('Continue with Sun, 11 Oct'), findsOneWidget);
      expect(env.nextEnabled, isTrue);
      await env.tapKey('discover_next_btn');
      expect(env.where, '/discover/budget');
    });

    testWidgets('Adjust days opens Timing in edit mode and returns', (t) async {
      final env = await open(t);
      await env.tapKey('calendar_day_20261011');
      await env.tapKey('discover_adjust_days_btn');
      expect(env.where, '/discover/timing');
      await env.tapKey('discover_days_every');
      await env.tapKey('discover_next_btn');
      expect(env.where, '/discover/start-date');
      expect(
        find.byKey(const Key('discover_outside_days_warning')),
        findsNothing,
      );
    });
  });

  group('60-day limit', () {
    testWidgets('day 60 is selectable, day 61 is not; note explains', (
      t,
    ) async {
      final env = await open(t);
      expect(
        find.text('You can start up to 60 days from today (by Tue, 8 Dec).'),
        findsOneWidget,
      );
      await env.tapKey('calendar_next');
      await env.tapKey('calendar_next');
      expect(find.text('December 2026'), findsOneWidget);
      await env.tapKey('calendar_day_20261208');
      expect(picked(env), DateTime(2026, 12, 8));
      await t.tap(find.byKey(const Key('calendar_day_20261209')));
      await t.pump();
      expect(picked(env), DateTime(2026, 12, 8)); // unchanged
      final next = t.widget<IconButton>(find.byKey(const Key('calendar_next')));
      expect(next.onPressed, isNull); // no months beyond the limit
    });

    testWidgets('cannot browse before the first selectable month', (t) async {
      await open(t);
      final prev = t.widget<IconButton>(find.byKey(const Key('calendar_prev')));
      expect(prev.onPressed, isNull);
    });
  });

  group('loading, error, wiring', () {
    testWidgets('loading skeleton', (t) async {
      final env = await launchDiscover(t);
      final gate = Completer<void>();
      env.schedule.gate = gate.future;
      env.stepsOneToThree(EngagementType.partTime);
      env.unawaitedPush('/discover/start-date');
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
      expect(env.nextEnabled, isFalse);
      gate.complete();
      await t.pumpAndSettle();
      expect(find.text('Pick another date'), findsOneWidget);
    });

    testWidgets('error card -> Try again', (t) async {
      final env = await launchDiscover(t);
      env.schedule.failNext = const NetworkFailure();
      env.stepsOneToThree(EngagementType.partTime);
      await env.go('/discover/start-date');
      expect(find.text("We couldn't load available dates"), findsOneWidget);
      await env.tapKey('error_retry_btn');
      expect(find.text('Pick another date'), findsOneWidget);
    });

    testWidgets('edit mode: Continue returns to the screen that opened it', (
      t,
    ) async {
      final env = await open(t, route: '/discover/budget');
      await env.go('/discover/start-date?edit=true');
      await env.tapKey('discover_shortcut_tomorrow');
      await env.tapKey('discover_next_btn');
      expect(env.where, '/discover/budget');
      expect(picked(env), DateTime(2026, 10, 10));
    });

    testWidgets('a selected date is restored when coming back to the step', (
      t,
    ) async {
      final env = await open(t);
      await env.tapKey('discover_shortcut_inThreeDays');
      await env.tapKey('discover_next_btn');
      await env.tapKey('app_back_btn');
      expect(env.where, '/discover/start-date');
      expect(find.text('Continue with Mon, 12 Oct'), findsOneWidget);
    });

    testWidgets('hourly never lands here: it is sent to Timing', (t) async {
      final env = await open(t, e: EngagementType.hourly);
      expect(env.where, '/discover/timing');
    });
  });
}
