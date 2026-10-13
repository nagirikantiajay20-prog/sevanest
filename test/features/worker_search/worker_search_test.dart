// Step 4.3 Search: DTO parsing, remote paging, cancel-on-re-search, and the Results screen states.
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/features/addresses/presentation/providers/address_providers.dart';
import 'package:sevanest_customer/features/service_discovery/domain/catalog.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/requirement_draft_provider.dart';
import 'package:sevanest_customer/features/worker_search/data/worker_search_repository_remote.dart';
import 'package:sevanest_customer/features/worker_search/domain/worker_search.dart';
import 'package:sevanest_customer/features/worker_search/presentation/providers/worker_search_providers.dart';

import '../../helpers/discover_harness.dart';
import '../../helpers/fakes.dart';

class _FakeRepo implements WorkerSearchRepository {
  final cursors = <String?>[];
  final tokens = <CancelToken?>[];
  Completer<WorkerPage>? gate;

  @override
  Future<WorkerPage> search(
    WorkerQuery query, {
    String? cursor,
    CancelToken? cancel,
  }) {
    cursors.add(cursor);
    tokens.add(cancel);
    return gate?.future ??
        Future.value(
          cursor == null
              ? const WorkerPage([WorkerSummary(id: 'a')], 'c2')
              : const WorkerPage([WorkerSummary(id: 'b')], null),
        );
  }
}

ProviderContainer _container(_FakeRepo repo) {
  final c = ProviderContainer(
    overrides: [
      workerSearchRepositoryProvider.overrideWithValue(repo),
      serviceAreasProvider.overrideWith((ref) async => const []),
    ],
  );
  addTearDown(c.dispose);
  c.read(requirementDraftProvider.notifier)
    ..setService('cook')
    ..setEngagement(EngagementType.fullTime)
    ..setAddress(testHome);
  return c;
}

/// pumpAndSettle ignores the mock's latency timer, so wait it out explicitly.
Future<void> settle(WidgetTester t) async {
  await t.pumpAndSettle();
  await t.pump(const Duration(seconds: 1));
  await t.pumpAndSettle();
}

void main() {
  group('WorkerSummary.fromJson', () {
    test('SRCH-01 every optional field missing/null gets a safe default', () {
      final w = WorkerSummary.fromJson({
        'workerId': 'w1',
        'experienceMonths': null,
        'rating': null,
        'photo': null,
      })!;
      expect(w.id, 'w1');
      expect(w.experienceMonths, isNull);
      expect(w.hasRating, isFalse);
      expect(w.categories, isEmpty);
      expect(w.languages, isEmpty);
      expect(w.availability, isEmpty);
      expect(w.verified, isFalse);
      expect(WorkerSummary.fromJson({'name': 'no id'}), isNull);
    });

    test('SRCH-03 verified only from the backend status', () {
      final w = WorkerSummary.fromJson({
        'workerId': 'w1',
        'verification': 'VERIFIED',
        'rating': {'average': 4.5, 'count': 10},
      })!;
      expect(w.verified, isTrue);
      expect(w.hasRating, isTrue);
      final pending = WorkerSummary.fromJson({
        'workerId': 'x',
        'verification': 'PENDING',
      })!;
      expect(pending.verified, isFalse);
    });
  });

  group('WorkerSearchRepositoryRemote', () {
    test('SRCH-06 pages by number, next cursor from meta.total', () async {
      final seen = <RequestOptions>[];
      final dio = Dio(BaseOptions(baseUrl: 'http://x'))
        ..httpClientAdapter = FakeAdapter((o) async {
          seen.add(o);
          return jsonBody(
            '{"data":[{"workerId":"w1"}],"meta":{"page":1,"limit":20,"total":25}}',
            200,
          );
        });
      final repo = WorkerSearchRepositoryRemote(dio);
      const q = WorkerQuery(
        category: 'HOUSE_MAID',
        areaId: 'a1',
        engagement: EngagementType.liveIn,
      );

      final first = await repo.search(q);
      expect(first.nextCursor, '2');
      expect(seen.single.path, '/search/workers');
      expect(seen.single.queryParameters, {
        'page': 1,
        'limit': 20,
        'category': 'HOUSE_MAID',
        'areaId': 'a1',
        'engagement': 'LIVE_IN',
      });
      final second = await repo.search(q, cursor: '2');
      expect(seen.last.queryParameters['page'], 2);
      expect(second.nextCursor, isNull);
    });
  });

  group('WorkerSearchNotifier', () {
    test('SRCH-06 next page uses the cursor the backend gave', () async {
      final repo = _FakeRepo();
      final c = _container(repo);
      await c.read(workerSearchProvider.future);
      await c.read(workerSearchProvider.notifier).loadMore();
      expect(repo.cursors, [null, 'c2']);
      final p = c.read(workerSearchProvider).requireValue;
      expect(p.items.map((w) => w.id), ['a', 'b']);
      expect(p.hasMore, isFalse);
      await c.read(workerSearchProvider.notifier).loadMore();
      expect(repo.cursors.length, 2);
    });

    test('SRCH-10 a changed query cancels the in-flight request', () async {
      final repo = _FakeRepo()..gate = Completer();
      final c = _container(repo);
      final sub = c.listen(workerSearchProvider, (_, _) {});
      addTearDown(sub.close);
      await Future<void>.delayed(Duration.zero);
      expect(repo.tokens, hasLength(1));
      expect(repo.tokens.first!.isCancelled, isFalse);

      c
          .read(requirementDraftProvider.notifier)
          .setEngagement(EngagementType.daily);
      await Future<void>.delayed(Duration.zero);
      expect(repo.tokens, hasLength(2));
      expect(repo.tokens.first!.isCancelled, isTrue);
      expect(repo.tokens.last!.isCancelled, isFalse);
    });
  });

  group('Results screen', () {
    Future<DiscoverEnv> open(WidgetTester t) async {
      final env = await launchDiscover(t);
      env.stepsOneToThree(EngagementType.fullTime);
      // Results opens on top of Review, as in the real flow.
      await env.go('/discover/review');
      await env.go('/workers');
      await settle(t);
      return env;
    }

    MockApiNotifier mock(DiscoverEnv e) =>
        e.container.read(mockApiProvider.notifier);

    Future<void> pullDown(WidgetTester t) async {
      await t.drag(find.byType(ListView).last, const Offset(0, 400));
      await settle(t);
    }

    Future<void> scrollToEnd(WidgetTester t) async {
      await t.drag(find.byType(ListView).last, const Offset(0, -20000));
      await settle(t);
    }

    testWidgets('SRCH-04/11 first page shows, tapping a card opens detail', (
      t,
    ) async {
      final env = await open(t);
      expect(find.byKey(const Key('worker_card_cook-1')), findsOneWidget);
      expect(find.text('Cook near Madhapur'), findsOneWidget);
      // Unrated workers read "New", never a made-up score.
      expect(find.text('New'), findsWidgets);

      await t.tap(find.byKey(const Key('worker_card_cook-1')));
      await t.pumpAndSettle();
      expect(env.where, '/workers/cook-1');
    });

    testWidgets('SRCH-04 scrolling to the end loads the next page', (t) async {
      await open(t);
      expect(find.byKey(const Key('worker_card_cook-21')), findsNothing);
      await scrollToEnd(t);
      expect(find.byKey(const Key('worker_card_cook-21')), findsOneWidget);
      expect(find.byKey(const Key('results_footer_loader')), findsNothing);
    });

    testWidgets('SRCH-05 footer error keeps the list; Retry loads the page', (
      t,
    ) async {
      final env = await open(t);
      mock(env).set(const MockApiState(mode: MockMode.error));
      await scrollToEnd(t);
      expect(
        find.byKey(const Key('results_load_more_retry_btn')),
        findsOneWidget,
      );
      mock(env).set(const MockApiState());
      await t.tap(find.byKey(const Key('results_load_more_retry_btn')));
      await settle(t);
      expect(
        find.byKey(const Key('results_load_more_retry_btn')),
        findsNothing,
      );
      final items = env.container.read(workerSearchProvider).requireValue.items;
      expect(items.length, greaterThanOrEqualTo(40));
    });

    testWidgets('SRCH-07 empty: message, chips, Retry re-searches, Edit', (
      t,
    ) async {
      final env = await open(t);
      mock(env).set(const MockApiState(mode: MockMode.empty));
      await pullDown(t);
      expect(find.text('No matching workers found'), findsOneWidget);
      expect(find.byKey(const Key('results_summary_chip')), findsWidgets);

      mock(env).set(const MockApiState());
      await t.tap(find.byKey(const Key('results_retry_btn')));
      await settle(t);
      expect(find.byKey(const Key('worker_card_cook-1')), findsOneWidget);

      mock(env).set(const MockApiState(mode: MockMode.empty));
      await pullDown(t);
      await t.tap(find.byKey(const Key('results_edit_requirement_btn')));
      await t.pumpAndSettle();
      expect(env.where, '/discover/review');
    });

    testWidgets('SRCH-15 failed refresh keeps the old list and a banner', (
      t,
    ) async {
      final env = await open(t);
      mock(env).set(const MockApiState(mode: MockMode.error));
      await pullDown(t);
      expect(find.byKey(const Key('worker_card_cook-1')), findsOneWidget);
      expect(find.textContaining('earlier'), findsOneWidget);
    });

    testWidgets('error with no earlier list shows Retry', (t) async {
      final env = await launchDiscover(t);
      env.stepsOneToThree(EngagementType.fullTime);
      mock(env).set(const MockApiState(mode: MockMode.error));
      await env.go('/workers');
      await settle(t);
      expect(find.byKey(const Key('error_retry_btn')), findsOneWidget);
      mock(env).set(const MockApiState());
      await t.tap(find.byKey(const Key('error_retry_btn')));
      await settle(t);
      expect(find.byKey(const Key('worker_card_cook-1')), findsOneWidget);
    });
  });
}
