// WIDGET tests: Review (module 04): rows, edit, the note for the worker, Find workers.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/features/service_discovery/domain/budget.dart';
import 'package:sevanest_customer/features/service_discovery/domain/catalog.dart';
import 'package:sevanest_customer/features/service_discovery/domain/timing.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/requirement_draft_provider.dart';

import '../../helpers/discover_harness.dart';

void main() {
  Future<DiscoverEnv> open(WidgetTester t) async {
    final env = await launchDiscover(t, height: 1600);
    env.stepsOneToThree(EngagementType.partTime);
    env.draftNotifier
      ..setTiming(
        const Timing(
          window: TimeWindow.morning,
          startMinutes: 480,
          endMinutes: 720,
          days: {1, 2, 3, 4, 5},
        ),
      )
      ..setStartDate(DateTime(2026, 10, 12))
      ..setBudget(
        const Budget(min: 6000, max: 10000, period: BudgetPeriod.monthly),
      );
    await env.go('/discover/review');
    return env;
  }

  testWidgets('lists every answer with an Edit button and "All steps done"', (
    t,
  ) async {
    await open(t);
    expect(find.text('All steps done'), findsOneWidget);
    expect(find.text('Check your requirement'), findsOneWidget);
    for (final f in [
      'service',
      'engagement',
      'address',
      'timing',
      'startDate',
      'budget',
    ]) {
      expect(find.byKey(Key('discover_review_row_$f')), findsOneWidget);
      expect(find.byKey(Key('discover_review_edit_$f')), findsOneWidget);
    }
    expect(find.text('₹6,000 – ₹10,000 per month'), findsOneWidget);
    expect(find.text('Search to see who matches'), findsOneWidget);
  });

  testWidgets('Edit opens the step in edit mode', (t) async {
    final env = await open(t);
    await env.tapKey('discover_review_edit_budget');
    expect(env.where, '/discover/budget');
  });

  testWidgets('the note is kept in the draft and cleared with it', (t) async {
    final env = await open(t);
    await t.enterText(
      find.byKey(const Key('discover_review_note')),
      '  Pets at home ',
    );
    expect(env.container.read(requirementNoteProvider), 'Pets at home');
    env.draftNotifier.reset();
    expect(env.container.read(requirementNoteProvider), isEmpty);
  });
}
