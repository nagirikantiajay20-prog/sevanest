// Step 4.4 Filters: the sheet (apply / reset / close), the badge, and what reaches the search.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/features/service_discovery/domain/catalog.dart';
import 'package:sevanest_customer/features/worker_search/data/worker_search_repository_remote.dart';
import 'package:sevanest_customer/features/worker_search/domain/worker_search.dart';
import 'package:sevanest_customer/features/worker_search/presentation/providers/worker_search_providers.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/filter_sheet.dart';

import '../../helpers/discover_harness.dart';
import '../../helpers/fakes.dart';

/// pumpAndSettle ignores the mock's latency timer, so wait it out explicitly.
Future<void> settle(WidgetTester t) async {
  await t.pumpAndSettle();
  await t.pump(const Duration(seconds: 1));
  await t.pumpAndSettle();
}

void main() {
  test('WorkerFilters: count and equality', () {
    expect(const WorkerFilters().count, 0);
    const f = WorkerFilters(
      availability: AvailabilityFilter.morning,
      language: 'hi',
    );
    expect(f.count, 2);
    expect(
      f,
      const WorkerFilters(
        availability: AvailabilityFilter.morning,
        language: 'hi',
      ),
    );
    expect(
      const WorkerQuery(category: 'c', areaId: 'a'),
      isNot(const WorkerQuery(category: 'c', areaId: 'a', filters: f)),
    );
  });

  test('remote sends only the filters that are set', () async {
    final seen = <RequestOptions>[];
    final dio = Dio(BaseOptions(baseUrl: 'http://x'))
      ..httpClientAdapter = FakeAdapter((o) async {
        seen.add(o);
        return jsonBody('{"data":[],"meta":{"total":0}}', 200);
      });
    final repo = WorkerSearchRepositoryRemote(dio);
    await repo.search(const WorkerQuery(category: 'C', areaId: 'a'));
    expect(seen.last.queryParameters.keys, isNot(contains('language')));
    expect(seen.last.queryParameters.keys, isNot(contains('availableFrom')));

    await repo.search(
      const WorkerQuery(
        category: 'C',
        areaId: 'a',
        filters: WorkerFilters(
          availability: AvailabilityFilter.afternoon,
          language: 'hi',
          minExperienceMonths: 36,
        ),
      ),
    );
    final q = seen.last.queryParameters;
    expect(q['availableFrom'], '12:00');
    expect(q['availableTo'], '17:00');
    expect(q['language'], 'hi');
    expect(q['minExperienceMonths'], 36);
  });

  group('Filter sheet', () {
    Future<DiscoverEnv> open(WidgetTester t) async {
      final env = await launchDiscover(t);
      env.stepsOneToThree(EngagementType.fullTime);
      await env.go('/discover/review');
      await env.go('/workers');
      await settle(t);
      return env;
    }

    WorkerFilters filters(DiscoverEnv e) =>
        e.container.read(workerQueryProvider)!.filters;

    Future<void> tapKey(WidgetTester t, String key) async {
      await t.tap(find.byKey(Key(key)));
      await settle(t);
    }

    testWidgets('SRCH-08 Apply re-searches from page 1, requirement kept', (
      t,
    ) async {
      final env = await open(t);
      await t.drag(find.byType(ListView).last, const Offset(0, -20000));
      await settle(t);
      expect(
        env.container.read(workerSearchProvider).requireValue.items.length,
        greaterThan(20),
      );

      await tapKey(t, 'results_filter_btn');
      await tapKey(t, 'filter_language_ta');
      await tapKey(t, 'filter_experience_36');
      await tapKey(t, 'filter_apply_btn');

      final q = env.container.read(workerQueryProvider)!;
      expect(q.category, 'cook');
      expect(q.engagement, EngagementType.fullTime);
      expect(q.filters.language, 'ta');
      expect(q.filters.minExperienceMonths, 36);
      // List replaced by page 1 of the filtered search, and every row matches.
      final items = env.container.read(workerSearchProvider).requireValue.items;
      expect(items, isNotEmpty);
      expect(
        items.every(
          (w) => w.languages.contains('ta') && (w.experienceMonths ?? 0) >= 36,
        ),
        isTrue,
      );
      expect(find.byKey(const Key('results_filter_badge')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('results_filter_badge')),
          matching: find.text('2'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('SRCH-09 Reset clears the chips; Apply drops the badge', (
      t,
    ) async {
      final env = await open(t);
      await tapKey(t, 'results_filter_btn');
      await tapKey(t, 'filter_availability_morning');
      await tapKey(t, 'filter_apply_btn');
      expect(filters(env).count, 1);

      await tapKey(t, 'results_filter_btn');
      await tapKey(t, 'filter_reset_btn');
      await tapKey(t, 'filter_apply_btn');
      expect(filters(env).count, 0);
      expect(
        t
            .widget<Badge>(find.byKey(const Key('results_filter_badge')))
            .isLabelVisible,
        isFalse,
      );
    });

    testWidgets('Close discards unsaved edits', (t) async {
      final env = await open(t);
      await tapKey(t, 'results_filter_btn');
      await tapKey(t, 'filter_language_hi');
      await tapKey(t, 'filter_close_btn');
      expect(filters(env).count, 0);
      expect(find.byKey(const Key('filter_apply_btn')), findsNothing);
    });

    testWidgets('sheet reopens with the applied choices selected', (t) async {
      await open(t);
      await tapKey(t, 'results_filter_btn');
      await tapKey(t, 'filter_language_hi');
      await tapKey(t, 'filter_apply_btn');
      await tapKey(t, 'results_filter_btn');
      final chip = t.widget<FilterChoice>(
        find.byKey(const Key('filter_language_hi')),
      );
      expect(chip.selected, isTrue);
    });
  });
}
