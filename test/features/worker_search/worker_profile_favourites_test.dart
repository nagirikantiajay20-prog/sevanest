// Steps 4.5-4.8: worker card, worker detail + reviews, favourites (heart, shortlist tab), empty state.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/features/favourites/domain/favourites.dart';
import 'package:sevanest_customer/features/favourites/presentation/providers/favourites_providers.dart';
import 'package:sevanest_customer/features/service_discovery/domain/budget.dart';
import 'package:sevanest_customer/features/service_discovery/domain/catalog.dart';
import 'package:sevanest_customer/features/service_discovery/domain/timing.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/requirement_draft_provider.dart';
import 'package:sevanest_customer/features/worker_profile/presentation/providers/worker_profile_providers.dart';
import 'package:sevanest_customer/features/worker_search/domain/worker_search.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/worker_card.dart';

import '../../helpers/discover_harness.dart';
import '../../helpers/fakes.dart';
import '../../helpers/favourites_repository_mock.dart';

/// pumpAndSettle ignores the mock's latency timer, so wait it out explicitly.
Future<void> settle(WidgetTester t) async {
  // Chained mock calls (screen, then hearts, then the shortlist) each need their own wait.
  for (var i = 0; i < 3; i++) {
    await t.pumpAndSettle();
    await t.pump(const Duration(seconds: 1));
  }
  await t.pumpAndSettle();
}

/// Mock shortlist that counts calls and can be made to fail or wait.
class _SpyFavourites implements FavouritesRepository {
  _SpyFavourites({bool returning = true})
    : _inner = FavouritesRepositoryMock(
        () => MockApiState(returningUser: returning),
      );
  final FavouritesRepositoryMock _inner;
  final added = <String>[];
  final removed = <String>[];
  Object? failWith;
  Completer<void>? gate;

  Future<void> _maybeFail() async {
    await gate?.future;
    if (failWith != null) throw failWith!;
  }

  @override
  Future<FavouritesPage> list({String? cursor}) => _inner.list(cursor: cursor);

  @override
  Future<Set<String>> ids() => _inner.ids();

  @override
  Future<void> add(String id) async {
    added.add(id);
    await _maybeFail();
    await _inner.add(id);
  }

  @override
  Future<void> remove(String id) async {
    removed.add(id);
    await _maybeFail();
    await _inner.remove(id);
  }
}

void main() {
  group('Worker card (4.5)', () {
    Widget card(WorkerSummary w, {double scale = 1}) => testApp(
      MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: SizedBox(
          width: 360,
          child: SingleChildScrollView(
            child: WorkerCard(worker: w, onTap: () {}),
          ),
        ),
      ),
    );

    testWidgets('SRCH-02 long text, no photo, no rating: no overflow at 200%', (
      t,
    ) async {
      await t.pumpWidget(
        card(
          const WorkerSummary(
            id: 'w',
            categories: [
              'A very long category name that will certainly not fit on one line',
              'Cooking',
              'Cleaning',
              'Driving',
              'Nanny',
              'Gardening',
            ],
            languages: ['te', 'hi', 'en', 'ta'],
            areas: ['Madhapur', 'Gachibowli', 'Kondapur', 'Hitech City'],
            availability: [AvailabilityWindow('08:00', '18:00')],
            verified: true,
          ),
          scale: 2,
        ),
      );
      expect(t.takeException(), isNull);
      expect(find.text('New'), findsOneWidget); // no rating
      expect(find.text('A'), findsOneWidget); // initials avatar
      expect(
        find.text('+2'),
        findsOneWidget,
      ); // 5 extra categories: 3 shown + "+2"
    });

    testWidgets('SRCH-03 badge only when the backend says VERIFIED', (t) async {
      await t.pumpWidget(card(const WorkerSummary(id: 'a', verified: true)));
      expect(find.text('Verified'), findsOneWidget);
      await t.pumpWidget(card(const WorkerSummary(id: 'a')));
      expect(find.text('Verified'), findsNothing);
    });

    testWidgets('missing optional rows are hidden', (t) async {
      await t.pumpWidget(card(const WorkerSummary(id: 'a')));
      expect(find.text('Experience not listed'), findsOneWidget);
      expect(find.textContaining('Available'), findsNothing);
    });
  });

  group('Flows', () {
    Future<DiscoverEnv> open(
      WidgetTester t, {
      _SpyFavourites? spy,
      bool withDraft = true,
      double? height,
    }) async {
      final env = await launchDiscover(
        t,
        height: height ?? 844,
        overrides: [
          if (spy != null) favouritesRepositoryProvider.overrideWithValue(spy),
        ],
      );
      if (withDraft) env.stepsOneToThree(EngagementType.fullTime);
      return env;
    }

    Future<void> tapKey(WidgetTester t, String key) async {
      // Result cards are tall, so a lower one may not be built yet: scroll to it first.
      if (find.byKey(Key(key)).evaluate().isEmpty) {
        await t.scrollUntilVisible(
          find.byKey(Key(key)),
          300,
          scrollable: find.byType(Scrollable).last,
        );
      }
      await t.ensureVisible(find.byKey(Key(key)));
      await t.pump();
      await t.tap(find.byKey(Key(key)));
      await settle(t);
    }

    Future<void> openResults(DiscoverEnv env, WidgetTester t) async {
      await env.go('/discover/review');
      await env.go('/workers');
      await settle(t);
    }

    bool isFav(DiscoverEnv env, String id) =>
        env.container.read(favouriteProvider).requireValue.ids.contains(id);

    Icon heartIcon(WidgetTester t, String key) => t.widget<Icon>(
      find.descendant(of: find.byKey(Key(key)), matching: find.byType(Icon)),
    );

    // ---- favourites ----

    testWidgets('FAV-01 tapping a heart fills it and calls add once', (
      t,
    ) async {
      final spy = _SpyFavourites(returning: false);
      final env = await open(t, spy: spy);
      await openResults(env, t);
      expect(isFav(env, 'cook-1'), isFalse);
      await tapKey(t, 'worker_card_fav_btn_cook-1');
      expect(spy.added, ['cook-1']);
      expect(isFav(env, 'cook-1'), isTrue);
      expect(heartIcon(t, 'worker_card_fav_btn_cook-1').icon, Icons.favorite);
    });

    testWidgets(
      'FAV-02 a failed add rolls back, shows a snackbar, re-enables',
      (t) async {
        final spy = _SpyFavourites(returning: false)
          ..failWith = const ServerFailure();
        final env = await open(t, spy: spy);
        await openResults(env, t);
        await tapKey(t, 'worker_card_fav_btn_cook-1');
        expect(isFav(env, 'cook-1'), isFalse);
        expect(
          find.text("Couldn't update favourites. Try again."),
          findsOneWidget,
        );
        final btn = t.widget<IconButton>(
          find.byKey(const Key('worker_card_fav_btn_cook-1')),
        );
        expect(btn.onPressed, isNotNull);
      },
    );

    testWidgets('FAV-03 rapid double tap sends one request', (t) async {
      final spy = _SpyFavourites(returning: false)..gate = Completer();
      final env = await open(t, spy: spy);
      await openResults(env, t);
      final heart = find.byKey(const Key('worker_card_fav_btn_cook-1'));
      await t.tap(heart);
      await t.pump();
      await t.tap(heart, warnIfMissed: false);
      await t.pump();
      expect(spy.added, ['cook-1']);
      spy.gate!.complete();
      await settle(t);
      expect(spy.added, ['cook-1']);
    });

    testWidgets('FAV-04 an added worker appears on the shortlist tab', (
      t,
    ) async {
      final spy = _SpyFavourites(returning: false);
      final env = await open(t, spy: spy);
      await openResults(env, t);
      await tapKey(t, 'worker_card_fav_btn_cook-2');
      GoRouter.of(t.element(find.byType(Scaffold).first)).go('/favourites');
      await settle(t);
      expect(find.byKey(const Key('worker_card_cook-2')), findsOneWidget);
    });

    testWidgets('FAV-05 remove hides the card; Undo brings it back via PUT', (
      t,
    ) async {
      final spy = _SpyFavourites();
      final env = await open(t, spy: spy);
      await tapKey(t, 'nav_favourites');
      expect(find.byKey(const Key('worker_card_cook-5')), findsOneWidget);

      await tapKey(t, 'worker_card_fav_btn_cook-5');
      expect(spy.removed, ['cook-5']);
      expect(find.byKey(const Key('worker_card_cook-5')), findsNothing);
      expect(find.text('Removed from favourites'), findsOneWidget);

      await tapKey(t, 'fav_undo_btn');
      expect(spy.added, ['cook-5']);
      expect(find.byKey(const Key('worker_card_cook-5')), findsOneWidget);
      expect(isFav(env, 'cook-5'), isTrue);
    });

    testWidgets('FAV-07 empty shortlist: CTA starts a search', (t) async {
      final env = await open(t, spy: _SpyFavourites(returning: false));
      await tapKey(t, 'nav_favourites');
      expect(find.text('No favourites yet'), findsOneWidget);
      await tapKey(t, 'favs_empty_find_btn');
      expect(env.where, '/discover/category');
    });

    testWidgets(
      'FAV-08 an unavailable worker is tagged; tap opens the gone state',
      (t) async {
        final env = await open(t, spy: _SpyFavourites());
        await tapKey(t, 'nav_favourites');
        expect(find.byKey(const Key('worker_unavailable_tag')), findsOneWidget);
        await tapKey(t, 'worker_card_cook-gone-1');
        expect(env.where, '/workers/cook-gone-1');
        expect(find.text('This worker is no longer available'), findsOneWidget);
      },
    );

    // ---- detail ----

    testWidgets(
      'detail shows the allow-listed profile and the verified sheet',
      (t) async {
        final env = await open(t);
        await openResults(env, t);
        await tapKey(t, 'worker_card_cook-2');
        expect(env.where, '/workers/cook-2');
        expect(find.text('Verified'), findsOneWidget);
        expect(find.text('Hindi'), findsOneWidget);
        expect(find.text('English'), findsOneWidget);
        // Nothing KYC-like is ever in the model, so nothing like it can render.
        expect(
          find.textContaining(RegExp('aadhaar', caseSensitive: false)),
          findsNothing,
        );

        await tapKey(t, 'worker_verified_info_btn');
        expect(find.text('What verified means'), findsOneWidget);
        await tapKey(t, 'worker_verified_sheet_close_btn');
        expect(find.text('What verified means'), findsNothing);
      },
    );

    testWidgets('FAV-06 the detail heart follows the list heart', (t) async {
      final env = await open(t, spy: _SpyFavourites(returning: false));
      await openResults(env, t);
      await tapKey(t, 'worker_card_fav_btn_cook-2');
      await tapKey(t, 'worker_card_cook-2');
      expect(heartIcon(t, 'worker_detail_fav_btn').icon, Icons.favorite);
      await tapKey(t, 'worker_detail_fav_btn');
      expect(isFav(env, 'cook-2'), isFalse);
    });

    testWidgets('SRCH-13 interview with no requirement prompts to search', (
      t,
    ) async {
      final env = await open(t, withDraft: false);
      await env.go('/workers/cook-2');
      await settle(t);
      await tapKey(t, 'worker_request_interview_btn');
      expect(find.text('Start a search first'), findsOneWidget);
      await tapKey(t, 'worker_start_search_btn');
      expect(env.where, '/discover/category');
    });

    testWidgets('SRCH-13 with a requirement it opens /interviews/new', (
      t,
    ) async {
      final env = await open(t);
      await env.go('/workers/cook-2');
      await settle(t);
      await tapKey(t, 'worker_request_interview_btn');
      expect(env.where, '/interviews/new');
    });

    testWidgets(
      'SRCH-14 a gone worker: unavailable state, Find another goes back',
      (t) async {
        final env = await open(t);
        await openResults(env, t);
        await env.go('/workers/cook-gone-9');
        await settle(t);
        expect(find.text('This worker is no longer available'), findsOneWidget);
        expect(
          find.byKey(const Key('worker_request_interview_btn')),
          findsNothing,
        );
        await tapKey(t, 'worker_find_another_btn');
        expect(env.where, '/workers');
      },
    );

    testWidgets('detail error shows Retry', (t) async {
      final env = await open(t);
      env.container
          .read(mockApiProvider.notifier)
          .set(const MockApiState(mode: MockMode.error));
      await env.go('/workers/cook-2');
      await settle(t);
      expect(find.byKey(const Key('error_retry_btn')), findsOneWidget);
    });

    testWidgets('reviews: preview, See all, paged list; unrated has none', (
      t,
    ) async {
      final env = await open(t);
      await env.go('/workers/cook-2'); // rated, 5 reviews
      await settle(t);
      expect(find.byKey(const Key('worker_reviews_all_btn')), findsOneWidget);
      await tapKey(t, 'worker_reviews_all_btn');
      expect(env.where, '/workers/cook-2/reviews');
      expect(find.textContaining('Anita'), findsWidgets);

      await env.go('/workers/cook-1'); // no rating ("New")
      await settle(t);
      expect(find.byKey(const Key('worker_reviews_all_btn')), findsNothing);
      expect(find.text('No reviews yet'), findsOneWidget);
    });

    testWidgets(
      'Flow B + C: Home -> Review -> Results -> Profile -> shortlist -> remove',
      (t) async {
        final env = await launchDiscover(
          t,
          height: 1600,
          overrides: [
            favouritesRepositoryProvider.overrideWithValue(
              _SpyFavourites(returning: false),
            ),
          ],
        );
        await env.tapKey('home_find_worker_btn');
        await env.search('cook');
        await env.tapKey('discover_category_tile_cook');
        await env.tapKey('discover_next_btn');
        await env.tapKey('discover_engagement_partTime');
        await env.tapKey('discover_next_btn');
        await env.tapKey('discover_next_btn');
        await env.tapKey('discover_window_morning');
        await env.tapKey('discover_next_btn');
        await env.tapKey('discover_shortcut_tomorrow');
        await env.tapKey('discover_next_btn');
        await env.tapKey('discover_next_btn');
        expect(env.where, '/discover/review');

        // Flow B: Search -> Results -> Profile.
        await tapKey(t, 'discover_search_btn');
        expect(env.where, '/workers');
        await tapKey(t, 'worker_card_cook-2');
        expect(env.where, '/workers/cook-2');

        // Flow C: shortlist it from the profile, find it on the tab, remove it.
        await tapKey(t, 'worker_detail_fav_btn');
        expect(isFav(env, 'cook-2'), isTrue);
        GoRouter.of(t.element(find.byType(Scaffold).first)).go('/favourites');
        await settle(t);
        expect(find.byKey(const Key('worker_card_cook-2')), findsOneWidget);
        await tapKey(t, 'worker_card_fav_btn_cook-2');
        expect(find.byKey(const Key('worker_card_cook-2')), findsNothing);
        expect(isFav(env, 'cook-2'), isFalse);
      },
    );

    testWidgets('reviews: a short first page pulls in the next one by itself', (
      t,
    ) async {
      final env = await open(t, height: 3000);
      await env.go('/workers/cook-43/reviews'); // 45 reviews, 10 per page
      await settle(t);
      final loaded = env.container
          .read(workerReviewsProvider('cook-43'))
          .requireValue
          .items
          .length;
      // 10 small rows do not fill the screen, so more were fetched without any scrolling.
      expect(loaded, greaterThan(10));
    });

    // ---- review screen ----

    testWidgets(
      'DISC-14 Review rows; Edit address returns with the rest kept',
      (t) async {
        final env = await open(t);
        env.draftNotifier
          ..setTiming(null)
          ..setStartDate(null);
        await env.go('/discover/review');
        expect(
          find.byKey(const Key('discover_review_row_service')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('discover_review_row_address')),
          findsOneWidget,
        );
        await tapKey(t, 'discover_review_edit_address');
        expect(env.where, '/discover/location');
        await tapKey(t, 'discover_next_btn');
        expect(env.where, '/discover/review');
        expect(env.container.read(requirementDraftProvider).serviceId, 'cook');
      },
    );

    testWidgets('DISC-15/16 Search opens Results once, even on a double tap', (
      t,
    ) async {
      final env = await open(t);
      env.draftNotifier
        ..setTiming(
          const Timing(
            startMinutes: 480,
            endMinutes: 960,
            days: {1, 2, 3, 4, 5, 6},
          ),
        )
        ..setStartDate(DateTime(2026, 10, 20))
        ..setBudget(
          const Budget(min: 15000, max: 20000, period: BudgetPeriod.monthly),
        );
      await env.go('/discover/review');
      final btn = find.byKey(const Key('discover_search_btn'));
      await t.tap(btn);
      await t.tap(btn, warnIfMissed: false);
      await settle(t);
      expect(env.where, '/workers');
    });
  });
}
