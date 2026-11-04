// INTEGRATION-style widget tests: the whole requirement builder from Home to the Review placeholder,
// Back / Close behaviour, and kill-and-resume from the persisted draft (Flow B, first half).
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/features/service_discovery/domain/budget.dart';
import 'package:sevanest_customer/features/service_discovery/domain/catalog.dart';
import 'package:sevanest_customer/features/service_discovery/domain/requirement_draft.dart';
import 'package:sevanest_customer/features/service_discovery/domain/timing.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/requirement_draft_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/discover_harness.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Home -> ... -> Review: every step wires to the next', (t) async {
    final env = await launchDiscover(t, height: 1600);
    await env.tapKey('home_find_worker_btn');
    expect(env.where, '/discover/category');
    await env.search('cook');
    await env.tapKey('discover_category_tile_cook');
    await env.tapKey('discover_next_btn');
    expect(env.where, '/discover/engagement');
    await env.tapKey('discover_engagement_partTime');
    await env.tapKey('discover_next_btn');
    expect(env.where, '/discover/location');
    expect(find.text('Continue to Madhapur'), findsOneWidget);
    await env.tapKey('discover_next_btn');
    expect(env.where, '/discover/timing');
    await env.tapKey('discover_window_morning');
    await env.tapKey('discover_next_btn');
    expect(env.where, '/discover/start-date');
    await env.tapKey('discover_shortcut_tomorrow');
    await env.tapKey('discover_next_btn');
    expect(env.where, '/discover/budget');
    expect(find.text('Step 6 of 6'), findsOneWidget);
    await env.tapKey('discover_next_btn');
    expect(env.where, '/discover/review');

    final d = env.container.read(requirementDraftProvider);
    expect(d.serviceId, 'cook');
    expect(d.engagement, EngagementType.partTime);
    expect(d.address?.id, 'h1');
    expect(d.timing?.window, TimeWindow.morning);
    expect(d.startDate, DateTime(2026, 10, 10));
    expect((d.budget?.min, d.budget?.max), (6000, 10000));
  });

  testWidgets('Back walks the steps and keeps every value', (t) async {
    final env = await launchDiscover(t, height: 1600);
    await env.tapKey('home_find_worker_btn');
    await env.search('cook');
    await env.tapKey('discover_category_tile_cook');
    await env.tapKey('discover_next_btn');
    await env.tapKey('discover_engagement_daily');
    await env.tapKey('discover_next_btn');
    await env.tapKey('discover_next_btn');
    await env.tapKey('discover_window_evening');
    for (final d in [1, 3, 5]) {
      await env.tapKey('discover_day_$d');
    }
    await env.tapKey('discover_next_btn');
    await env.tapKey('discover_shortcut_nextMonday');
    await env.tapKey('discover_next_btn');
    expect(env.where, '/discover/budget');

    await env.tapKey('app_back_btn');
    expect(env.where, '/discover/start-date');
    expect(find.text('Continue with Mon, 19 Oct'), findsOneWidget);
    await env.tapKey('app_back_btn');
    expect(env.where, '/discover/timing');
    expect(find.textContaining('Evenings'), findsWidgets);
    expect(find.textContaining('Mon, Wed, Fri'), findsOneWidget);
    await env.tapKey('app_back_btn');
    expect(env.where, '/discover/location');
    await env.tapKey('app_back_btn');
    expect(env.where, '/discover/engagement');
    expect(find.text('Continue with Daily'), findsOneWidget);
  });

  testWidgets('Hourly skips the Start date step in both directions', (t) async {
    final env = await launchDiscover(t, height: 1600);
    await env.tapKey('home_find_worker_btn');
    await env.search('cook');
    await env.tapKey('discover_category_tile_cook');
    await env.tapKey('discover_next_btn');
    await env.tapKey('discover_engagement_hourly');
    await env.tapKey('discover_next_btn');
    await env.tapKey('discover_next_btn');
    expect(env.where, '/discover/timing');
    await env.tapKey('discover_window_morning');
    await env.tapKey('discover_date_btn');
    await env.tapKey('calendar_day_20261010');
    await env.tapKey('date_sheet_set_btn');
    await env.tapKey('discover_next_btn');
    expect(env.where, '/discover/budget');
    expect(find.text('₹ per hour'), findsOneWidget);
    await env.tapKey('app_back_btn');
    expect(env.where, '/discover/timing');
  });

  testWidgets('Close X on a late step: Keep editing stays, Discard clears', (
    t,
  ) async {
    final env = await launchDiscover(t, height: 1600);
    env.stepsOneToThree(EngagementType.partTime);
    await env.go('/discover/budget');
    await env.tapKey('discover_close_btn');
    expect(find.text('Discard this request?'), findsOneWidget);
    await env.tapKey('discover_discard_cancel_btn');
    expect(env.where, '/discover/budget');
    await env.tapKey('discover_close_btn');
    await env.tapKey('discover_discard_confirm_btn');
    expect(env.where, '/home');
    expect(env.container.read(requirementDraftProvider).isEmpty, isTrue);
  });

  testWidgets('preset flow: Home hero chip lands on step 2 of 6', (t) async {
    final env = await launchDiscover(t);
    await env.tapKey('home_category_tile_cook');
    expect(env.where, '/discover/engagement');
    expect(find.text('Step 2 of 6'), findsOneWidget);
  });

  group('kill and resume', () {
    RequirementDraft partial() => const RequirementDraft(
      serviceId: 'cook',
      engagement: EngagementType.partTime,
      address: testHome,
      timing: Timing(
        window: TimeWindow.morning,
        startMinutes: 480,
        endMinutes: 720,
        days: {1, 2, 3, 4, 5, 6},
      ),
    );

    Future<void> seedStored(RequirementDraft d) async =>
        SharedPreferences.setMockInitialValues({
          'requirement_draft_v1': jsonEncode(d.toJson()),
        });

    testWidgets('a stored draft shows the Resume card on the right step', (
      t,
    ) async {
      await seedStored(partial());
      final env = await launchDiscover(t);
      await t.pumpAndSettle();
      expect(find.byKey(const Key('home_resume_card')), findsOneWidget);
      expect(find.text('Cook · Part-time · Step 5 of 6'), findsOneWidget);
      await env.tapKey('home_resume_btn');
      expect(env.where, '/discover/start-date');
      // Back walks through the earlier steps, then Home.
      await env.tapKey('app_back_btn');
      expect(env.where, '/discover/timing');
      await env.tapKey('app_back_btn');
      expect(env.where, '/discover/location');
      await env.tapKey('app_back_btn');
      expect(env.where, '/discover/engagement');
      await env.tapKey('app_back_btn');
      expect(env.where, '/discover/category');
    });

    testWidgets('resuming a nearly finished draft lands on Budget', (t) async {
      await seedStored(
        partial()
            .withStartDate(DateTime(2026, 10, 12))
            .withBudget(
              const Budget(min: 6000, max: 10000, period: BudgetPeriod.monthly),
            ),
      );
      final env = await launchDiscover(t);
      await t.pumpAndSettle();
      expect(find.text('Cook · Part-time · Step 6 of 6'), findsOneWidget);
      await env.tapKey('home_resume_btn');
      expect(env.where, '/discover/budget');
    });

    testWidgets('an hourly draft resumes without the Start date step', (
      t,
    ) async {
      await seedStored(
        const RequirementDraft(
          serviceId: 'cook',
          engagement: EngagementType.hourly,
          address: testHome,
        ),
      );
      final env = await launchDiscover(t);
      await t.pumpAndSettle();
      expect(find.text('Cook · Hourly · Step 4 of 6'), findsOneWidget);
      await env.tapKey('home_resume_btn');
      expect(env.where, '/discover/timing');
      await env.tapKey('app_back_btn');
      expect(env.where, '/discover/location');
    });

    testWidgets('Start over forgets the stored draft', (t) async {
      await seedStored(partial());
      final env = await launchDiscover(t);
      await t.pumpAndSettle();
      await env.tapKey('home_resume_discard_btn');
      expect(find.byKey(const Key('home_resume_card')), findsNothing);
      expect(env.container.read(requirementDraftProvider).isEmpty, isTrue);
      expect(
        (await SharedPreferences.getInstance()).getString(
          'requirement_draft_v1',
        ),
        isNull,
      );
    });

    testWidgets('no stored draft: no Resume card', (t) async {
      await launchDiscover(t);
      await t.pumpAndSettle();
      expect(find.byKey(const Key('home_resume_card')), findsNothing);
    });

    testWidgets('Find a worker starts clean even with a stored draft', (
      t,
    ) async {
      await seedStored(partial());
      final env = await launchDiscover(t);
      await t.pumpAndSettle();
      await env.tapKey('home_find_worker_btn');
      expect(env.container.read(requirementDraftProvider).isEmpty, isTrue);
      expect(env.where, '/discover/category');
    });
  });
}
