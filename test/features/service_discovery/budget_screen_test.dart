// WIDGET tests: Budget (screen 11, step 6 of 6) and the whole-draft check on Continue.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/features/service_discovery/domain/budget.dart';
import 'package:sevanest_customer/features/service_discovery/domain/catalog.dart';
import 'package:sevanest_customer/features/service_discovery/domain/timing.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/requirement_draft_provider.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/screens/budget_screen.dart';

import '../../helpers/discover_harness.dart';

void main() {
  /// A complete part-time draft up to the Budget step.
  Future<DiscoverEnv> open(
    WidgetTester t, {
    EngagementType e = EngagementType.partTime,
    bool complete = true,
    String route = '/discover/budget',
    void Function(DiscoverEnv env)? beforeOpen,
  }) async {
    final env = await launchDiscover(t, height: 1600);
    beforeOpen?.call(env);
    env.stepsOneToThree(e);
    if (complete) {
      env.draftNotifier
        ..setTiming(
          e == EngagementType.hourly
              ? const Timing(
                  window: TimeWindow.morning,
                  startMinutes: 600,
                  endMinutes: 780,
                )
              : const Timing(
                  window: TimeWindow.morning,
                  startMinutes: 480,
                  endMinutes: 720,
                  days: {1, 2, 3, 4, 5, 6},
                ),
        )
        ..setStartDate(DateTime(2026, 10, 12));
    }
    await env.go(route);
    return env;
  }

  Budget? budget(DiscoverEnv env) =>
      env.container.read(requirementDraftProvider).budget;

  String text(WidgetTester t, String key) =>
      t.widget<Text>(find.byKey(Key(key))).data!;

  String field(WidgetTester t, String key) =>
      t.widget<TextField>(find.byKey(Key(key))).controller!.text;

  Future<void> type(WidgetTester t, String key, String value) async {
    await t.ensureVisible(find.byKey(Key(key)));
    await t.enterText(find.byKey(Key(key)), value);
    await t.pumpAndSettle();
  }

  group('default (monthly)', () {
    testWidgets('guidance card, defaults from the range, summary, CTA', (
      t,
    ) async {
      final env = await open(t);
      expect(find.text('Step 6 of 6'), findsOneWidget);
      expect(find.text("What's your budget?"), findsOneWidget);
      expect(find.byKey(const Key('discover_period_chip')), findsOneWidget);
      expect(text(t, 'discover_period_chip'), '₹ per month');
      expect(
        find.text('Typical for a part-time cook in Hyderabad'),
        findsOneWidget,
      );
      expect(text(t, 'discover_guidance_range'), '₹6,000 – ₹10,000 per month');
      expect(find.text('Based on recent bookings'), findsOneWidget);
      expect(text(t, 'discover_readout_min'), '₹6,000');
      expect(text(t, 'discover_readout_max'), '₹10,000');
      expect(field(t, 'discover_budget_min_field'), '6,000');
      expect(field(t, 'discover_budget_max_field'), '10,000');
      expect(
        find.text('₹6,000 – ₹10,000 per month'),
        findsNWidgets(2),
      ); // summary
      expect(find.text('Review requirement'), findsOneWidget);
      expect(env.nextEnabled, isTrue);
      expect(
        find.byKey(const Key('discover_budget_low_warning')),
        findsNothing,
      );
    });

    testWidgets('Use this range restores the guidance after editing', (
      t,
    ) async {
      final env = await open(t);
      await type(t, 'discover_budget_max_field', '15000');
      expect(budget(env)?.max, 15000);
      await env.tapKey('discover_use_range_btn');
      expect((budget(env)?.min, budget(env)?.max), (6000, 10000));
      expect(field(t, 'discover_budget_max_field'), '10,000');
    });

    testWidgets('slider moves both ends and the fields follow', (t) async {
      final env = await open(t);
      final slider = find.byKey(const Key('discover_budget_slider'));
      await t.ensureVisible(slider);
      await t.drag(find.byType(RangeSlider), const Offset(120, 0));
      await t.pumpAndSettle();
      final b = budget(env)!;
      expect(b.min! >= 0 && b.max! >= b.min!, isTrue);
      expect(
        field(t, 'discover_budget_min_field'),
        b.min == 0 ? '0' : groupIndian(b.min!),
      );
    });
  });

  group('hourly variant', () {
    testWidgets('per-hour copy, guidance and defaults', (t) async {
      final env = await open(t, e: EngagementType.hourly);
      expect(text(t, 'discover_period_chip'), '₹ per hour');
      expect(
        find.text('Typical for a hourly cook in Hyderabad'),
        findsOneWidget,
      );
      expect(text(t, 'discover_guidance_range'), '₹100 – ₹200 per hour');
      expect(field(t, 'discover_budget_min_field'), '100');
      expect(find.text('₹100 – ₹200 per hour'), findsWidgets);
      expect(budget(env)?.period, BudgetPeriod.hourly);
      expect(
        find.text('₹250'),
        findsOneWidget,
      ); // hourly scale under the slider
    });
  });

  group('guidance states', () {
    testWidgets('loading: skeleton card, defaults already usable', (t) async {
      final env = await launchDiscover(t, height: 1600);
      final gate = Completer<void>();
      env.guidance.gate = gate.future;
      env.stepsOneToThree(EngagementType.partTime);
      env.draftNotifier
        ..setTiming(
          const Timing(
            window: TimeWindow.morning,
            startMinutes: 480,
            endMinutes: 720,
            days: {1},
          ),
        )
        ..setStartDate(DateTime(2026, 10, 12));
      env.unawaitedPush('/discover/budget');
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      expect(
        find.byKey(const Key('discover_guidance_loading')),
        findsOneWidget,
      );
      expect(field(t, 'discover_budget_min_field'), '6,000');
      expect(env.nextEnabled, isTrue);
      gate.complete();
      await t.pumpAndSettle();
      expect(find.byKey(const Key('discover_guidance_card')), findsOneWidget);
    });

    testWidgets('error: card with Try again, the budget can still be typed', (
      t,
    ) async {
      final env = await open(
        t,
        beforeOpen: (e) => e.guidance.failNext = const NetworkFailure(),
      );
      expect(find.text("We couldn't load price guidance"), findsOneWidget);
      expect(find.text('You can still enter a range below.'), findsOneWidget);
      await type(t, 'discover_budget_max_field', '12000');
      expect(budget(env)?.max, 12000);
      expect(env.nextEnabled, isTrue);
      await env.tapKey('error_retry_btn');
      expect(find.byKey(const Key('discover_guidance_card')), findsOneWidget);
    });

    testWidgets('guidance is fetched per service + area + engagement', (
      t,
    ) async {
      final env = await open(t);
      expect(env.guidance.queries.last.engagement, EngagementType.partTime);
      env.draftNotifier.setEngagement(EngagementType.hourly);
      await t.pumpAndSettle();
      expect(env.guidance.queries.last.engagement, EngagementType.hourly);
      expect(env.guidance.queries.last.area, 'Madhapur');
      // The old monthly budget is gone: the screen re-seeds for the new period.
      expect(budget(env)?.period, BudgetPeriod.hourly);
      expect(text(t, 'discover_period_chip'), '₹ per hour');
    });
  });

  group('typing', () {
    testWidgets('digits only, Indian grouping, ₹ prefix', (t) async {
      final env = await open(t);
      await type(t, 'discover_budget_max_field', '100000');
      expect(field(t, 'discover_budget_max_field'), '1,00,000');
      await type(t, 'discover_budget_max_field', '12ab3');
      expect(field(t, 'discover_budget_max_field'), '123');
      expect(budget(env)?.max, 123);
      expect(find.text('₹ '), findsWidgets);
    });

    testWidgets('invalid: minimum above maximum disables Continue', (t) async {
      final env = await open(t);
      await type(t, 'discover_budget_min_field', '12000');
      await type(t, 'discover_budget_max_field', '10000');
      expect(
        find.text('Maximum must be at least the minimum.'),
        findsOneWidget,
      );
      expect(env.nextEnabled, isFalse);
      expect(find.byKey(const Key('discover_summary')), findsNothing);
    });

    testWidgets('invalid: an empty field is incomplete', (t) async {
      final env = await open(t);
      await type(t, 'discover_budget_min_field', '');
      expect(find.text('Enter a minimum and a maximum.'), findsOneWidget);
      expect(env.nextEnabled, isFalse);
    });

    testWidgets('low budget warns but does not block', (t) async {
      final env = await open(t);
      await type(t, 'discover_budget_min_field', '2000');
      await type(t, 'discover_budget_max_field', '3000');
      expect(
        find.byKey(const Key('discover_budget_low_warning')),
        findsOneWidget,
      );
      expect(env.nextEnabled, isTrue);
      expect(find.text('₹2,000 – ₹3,000 per month'), findsOneWidget);
    });

    testWidgets('a range overlapping the guidance does not warn', (t) async {
      await open(t);
      await type(t, 'discover_budget_min_field', '4000');
      await type(t, 'discover_budget_max_field', '7000');
      expect(
        find.byKey(const Key('discover_budget_low_warning')),
        findsNothing,
      );
    });
  });

  group('flexible', () {
    testWidgets('Any budget: no amounts required, Review shows Flexible data', (
      t,
    ) async {
      final env = await open(t);
      await env.tapKey('discover_flexible_switch');
      expect(find.byKey(const Key('discover_any_budget')), findsOneWidget);
      expect(
        find.text("You'll see workers at every price. Adjust anytime."),
        findsOneWidget,
      );
      expect(budget(env)?.flexible, isTrue);
      expect(field(t, 'discover_budget_min_field'), '0');
      expect(field(t, 'discover_budget_max_field'), '40,000');
      expect(find.text('Any budget'), findsWidgets);
      expect(env.nextEnabled, isTrue);
      await env.tapKey('discover_next_btn');
      expect(env.where, '/discover/review');
    });

    testWidgets('typing an amount turns Flexible off', (t) async {
      final env = await open(t);
      await env.tapKey('discover_flexible_switch');
      await type(t, 'discover_budget_max_field', '20000');
      expect(budget(env)?.flexible, isFalse);
      expect(find.byKey(const Key('discover_any_budget')), findsNothing);
    });

    testWidgets('switching Flexible off goes back to the guidance range', (
      t,
    ) async {
      final env = await open(t);
      await env.tapKey('discover_flexible_switch');
      await env.tapKey('discover_flexible_switch');
      expect(budget(env)?.flexible, isFalse);
      expect((budget(env)?.min, budget(env)?.max), (6000, 10000));
    });
  });

  group('whole-draft check on Continue', () {
    testWidgets('complete draft opens Review', (t) async {
      final env = await open(t);
      await env.tapKey('discover_next_btn');
      expect(env.where, '/discover/review');
    });

    testWidgets('missing timing: says why and opens Timing in edit mode', (
      t,
    ) async {
      final env = await open(t, complete: false);
      env.draftNotifier.setStartDate(DateTime(2026, 10, 12));
      await env.tapKey('discover_next_btn');
      expect(find.text('Complete the timing details.'), findsOneWidget);
      expect(env.where, '/discover/timing');
      // Finishing the step returns to Budget (edit mode), where Continue now succeeds.
      await env.tapKey('discover_window_morning');
      await env.tapKey('discover_next_btn');
      expect(env.where, '/discover/budget');
      await env.tapKey('discover_next_btn');
      expect(env.where, '/discover/review');
    });

    testWidgets('missing start date routes to the Start date step', (t) async {
      final env = await open(t, complete: false);
      env.draftNotifier.setTiming(
        const Timing(
          window: TimeWindow.morning,
          startMinutes: 480,
          endMinutes: 720,
          days: {1},
        ),
      );
      await env.tapKey('discover_next_btn');
      expect(find.text('Choose a start date.'), findsOneWidget);
      expect(env.where, '/discover/start-date');
    });

    testWidgets('hourly: a missing date is reported on Timing', (t) async {
      final env = await open(t, e: EngagementType.hourly);
      env.draftNotifier.setStartDate(null);
      await t.pumpAndSettle();
      await env.tapKey('discover_next_btn');
      expect(env.where, '/discover/timing');
    });

    testWidgets('edit mode returns to the caller instead of opening Review', (
      t,
    ) async {
      final env = await open(t, route: '/discover/timing');
      await env.go('/discover/budget?edit=true');
      await env.tapKey('discover_next_btn');
      expect(env.where, '/discover/timing');
    });
  });

  group('RupeeInputFormatter', () {
    final f = RupeeInputFormatter();
    String fmt(String s) => f
        .formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: s))
        .text;
    test('groups the Indian way and caps at 7 digits', () {
      expect(fmt('6000'), '6,000');
      expect(fmt('1234567'), '12,34,567');
      expect(fmt('123456789'), '12,34,567');
      expect(fmt('₹ 1,2'), '12');
      expect(fmt(''), '');
    });
  });
}
