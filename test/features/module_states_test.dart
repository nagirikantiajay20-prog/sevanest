// QA gap closure: the loading / success / empty / error / retry states of Favourites, and the
// Workers search states that the other suites do not reach (no query yet, query change, filters
// that match nobody, clearing them). Notifications, Support, Transactions and Addresses already
// have these states in their own suites; see CUSTOMER_APP_MODULE_STATUS.md for where.
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/core/widgets/sn_states.dart';
import 'package:sevanest_customer/features/favourites/domain/favourites.dart';
import 'package:sevanest_customer/features/favourites/presentation/providers/favourites_providers.dart';
import 'package:sevanest_customer/features/service_discovery/domain/catalog.dart';
import 'package:sevanest_customer/features/worker_search/data/worker_search_repository_mock.dart';
import 'package:sevanest_customer/features/worker_search/domain/worker_search.dart';
import 'package:sevanest_customer/features/worker_search/presentation/providers/worker_search_providers.dart';

import '../helpers/discover_harness.dart';

Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 3; i++) {
    await t.pumpAndSettle();
    await t.pump(const Duration(seconds: 1));
  }
  await t.pumpAndSettle();
}

Finder k(String key) => find.byKey(Key(key));

/// A shortlist the test controls: rows, a failure, and a gate that holds the first answer back.
class _Favs implements FavouritesRepository {
  _Favs(this.rows);
  List<FavouriteEntry> rows;
  Object? listFails;
  Completer<void>? gate;
  var listCalls = 0;

  @override
  Future<FavouritesPage> list({String? cursor}) async {
    listCalls++;
    await gate?.future;
    final f = listFails;
    if (f != null) throw f;
    return FavouritesPage(rows, null);
  }

  @override
  Future<Set<String>> ids() async => {for (final r in rows) r.workerId};

  @override
  Future<void> add(String workerId) async {}

  @override
  Future<void> remove(String workerId) async {}
}

FavouriteEntry _entry(String id) =>
    FavouriteEntry(id, WorkerSearchRepositoryMock.byId(id));

/// Records every query; answers like the mock, but nobody matches once a filter is set.
class _SpySearch implements WorkerSearchRepository {
  _SpySearch(this.inner);
  final WorkerSearchRepositoryMock inner;
  final queries = <WorkerQuery>[];
  Completer<void>? gate;
  Object? fails;
  bool noOneMatchesFilters = false;

  @override
  Future<WorkerPage> search(
    WorkerQuery query, {
    String? cursor,
    CancelToken? cancel,
  }) async {
    queries.add(query);
    await gate?.future;
    final f = fails;
    if (f != null) throw f;
    if (noOneMatchesFilters && query.filters.count > 0) {
      return const WorkerPage([], null);
    }
    return inner.search(query, cursor: cursor, cancel: cancel);
  }

  @override
  Future<int> count(WorkerQuery query, {CancelToken? cancel}) =>
      inner.count(query, cancel: cancel);

  @override
  Future<WorkerSummary> detail(String id, {CancelToken? cancel}) =>
      inner.detail(id, cancel: cancel);
}

void main() {
  group('Favourites states', () {
    late _Favs repo;
    setUp(() => repo = _Favs([_entry('cook-2'), _entry('cook-5')]));

    Future<DiscoverEnv> open(WidgetTester t, {bool settled = true}) async {
      final env = await launchDiscover(
        t,
        height: 1400,
        overrides: [favouritesRepositoryProvider.overrideWithValue(repo)],
      );
      env.unawaitedPush('/favourites');
      if (settled) await settle(t);
      return env;
    }

    testWidgets('loading: a skeleton while the shortlist is read, then rows', (
      t,
    ) async {
      repo.gate = Completer();
      await open(t, settled: false);
      await t.pump();
      await t.pump(const Duration(milliseconds: 500));
      expect(find.byType(SnSkeletonList), findsOneWidget);
      expect(k('worker_card_cook-2'), findsNothing);
      expect(k('error_retry_btn'), findsNothing);
      repo.gate!.complete();
      await settle(t);
      expect(find.byType(SnSkeletonList), findsNothing);
      expect(k('worker_card_cook-2'), findsOneWidget);
      expect(k('worker_card_cook-5'), findsOneWidget);
    });

    testWidgets('empty: the explanation and a way to start a search', (
      t,
    ) async {
      repo.rows = [];
      await open(t);
      expect(find.text('No favourites yet'), findsOneWidget);
      expect(k('favs_empty_find_btn'), findsOneWidget);
      expect(find.byType(SnSkeletonList), findsNothing);
    });

    testWidgets('error: a message, no raw exception, and Retry recovers', (
      t,
    ) async {
      repo.listFails = const ServerFailure();
      await open(t);
      expect(k('error_retry_btn'), findsOneWidget);
      expect(find.textContaining('Exception'), findsNothing);
      expect(k('worker_card_cook-2'), findsNothing);

      repo.listFails = null;
      final before = repo.listCalls;
      await t.tap(k('error_retry_btn'));
      await settle(t);
      expect(repo.listCalls, before + 1, reason: 'one request per Retry tap');
      expect(k('error_retry_btn'), findsNothing);
      expect(k('worker_card_cook-2'), findsOneWidget);
    });

    testWidgets('offline reads as offline, and Retry recovers', (t) async {
      repo.listFails = const NetworkFailure();
      await open(t);
      expect(
        find.textContaining(
          RegExp('offline|connection|internet', caseSensitive: false),
        ),
        findsWidgets,
      );
      repo.listFails = null;
      await t.tap(k('offline_retry_btn'));
      await settle(t);
      expect(k('worker_card_cook-5'), findsOneWidget);
    });

    testWidgets('a failed refresh keeps the rows and says they are old', (
      t,
    ) async {
      final env = await open(t);
      expect(k('worker_card_cook-2'), findsOneWidget);
      repo.listFails = const ServerFailure();
      await env.container.read(favouritesListProvider.notifier).refresh();
      await settle(t);
      expect(k('worker_card_cook-2'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('Workers search states', () {
    late _SpySearch spy;
    setUp(
      () => spy = _SpySearch(
        WorkerSearchRepositoryMock(
          () => const MockApiState(returningUser: true),
        ),
      ),
    );

    Future<DiscoverEnv> launch(WidgetTester t) => launchDiscover(
      t,
      overrides: [workerSearchRepositoryProvider.overrideWithValue(spy)],
    );

    Future<void> showResults(DiscoverEnv env, WidgetTester t) async {
      await env.go('/discover/review');
      await env.go('/workers');
      await settle(t);
    }

    testWidgets('initial: no requirement yet means no request is sent', (
      t,
    ) async {
      final env = await launch(t);
      // The provider is auto-disposed: hold it open while it answers.
      final sub = env.container.listen(workerSearchProvider, (_, _) {});
      addTearDown(sub.close);
      final results = await env.container.read(workerSearchProvider.future);
      expect(results.items, isEmpty);
      expect(results.hasMore, isFalse);
      expect(spy.queries, isEmpty);
    });

    testWidgets('loading: a skeleton, then the cards; one request', (t) async {
      final env = await launch(t);
      env.stepsOneToThree(EngagementType.fullTime);
      spy.gate = Completer();
      env.unawaitedPush('/workers');
      await t.pump();
      await t.pump(const Duration(milliseconds: 500));
      expect(find.bySemanticsLabel('Loading'), findsWidgets);
      expect(k('worker_card_cook-1'), findsNothing);
      expect(k('error_retry_btn'), findsNothing);
      expect(find.text('No matching workers found'), findsNothing);
      spy.gate!.complete();
      await settle(t);
      expect(k('worker_card_cook-1'), findsOneWidget);
      expect(spy.queries, hasLength(1));
    });

    testWidgets('error then Retry: the same query is sent again and recovers', (
      t,
    ) async {
      final env = await launch(t);
      env.stepsOneToThree(EngagementType.fullTime);
      spy.fails = const ServerFailure();
      await showResults(env, t);
      expect(k('error_retry_btn'), findsOneWidget);
      expect(find.textContaining('Exception'), findsNothing);
      final failed = spy.queries.last;

      spy.fails = null;
      await t.tap(k('error_retry_btn'));
      await settle(t);
      expect(spy.queries.last, failed);
      expect(k('worker_card_cook-1'), findsOneWidget);
    });

    testWidgets('query change: a new engagement searches again and replaces', (
      t,
    ) async {
      final env = await launch(t);
      env.stepsOneToThree(EngagementType.fullTime);
      await showResults(env, t);
      expect(spy.queries.last.engagement, EngagementType.fullTime);
      final count = spy.queries.length;

      env.draftNotifier.setEngagement(EngagementType.partTime);
      await settle(t);
      expect(spy.queries.length, greaterThan(count));
      expect(spy.queries.last.engagement, EngagementType.partTime);
      expect(spy.queries.last.category, 'cook');
      expect(
        env.container.read(workerSearchProvider).requireValue.items,
        isNotEmpty,
      );
    });

    testWidgets(
      'filters that match nobody show empty; Reset brings the list back',
      (t) async {
        final env = await launch(t);
        env.stepsOneToThree(EngagementType.fullTime);
        await showResults(env, t);
        expect(k('worker_card_cook-1'), findsOneWidget);

        spy.noOneMatchesFilters = true;
        await t.tap(k('results_filter_btn'));
        await settle(t);
        await t.tap(k('filter_language_ta'));
        await settle(t);
        await t.tap(k('filter_apply_btn'));
        await settle(t);
        expect(spy.queries.last.filters.count, 1);
        expect(find.text('No matching workers found'), findsOneWidget);
        expect(k('worker_card_cook-1'), findsNothing);

        await t.tap(k('results_filter_btn'));
        await settle(t);
        await t.tap(k('filter_reset_btn'));
        await settle(t);
        await t.tap(k('filter_apply_btn'));
        await settle(t);
        expect(spy.queries.last.filters.count, 0);
        expect(find.text('No matching workers found'), findsNothing);
        expect(k('worker_card_cook-1'), findsOneWidget);
      },
    );
  });
}
