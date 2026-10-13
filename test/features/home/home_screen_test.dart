// WIDGET tests: real app + router + Home, with fake repositories (docs/modules/03 HOME-01..10).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/features/addresses/domain/address.dart';
import 'package:sevanest_customer/features/addresses/presentation/providers/address_providers.dart';
import 'package:sevanest_customer/features/customer_profile/domain/customer_profile.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/providers/customer_profile_providers.dart';
import 'package:sevanest_customer/features/home/domain/home_data.dart';
import 'package:sevanest_customer/features/home/presentation/providers/home_providers.dart';
import 'package:sevanest_customer/features/home/presentation/screens/home_screen.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/requirement_draft_provider.dart';

import '../../helpers/fakes.dart';

const _addr = Address(
  id: 'h1',
  line: 'Flat 402',
  area: 'Madhapur',
  city: 'Hyderabad',
  pincode: '500081',
  isDefault: true,
);

final _returning = HomeData(
  activeBooking: const ActiveBookingSummary(
    id: 'bk_2048',
    reference: 'SN-2048',
    workerName: 'Lakshmi Devi',
    service: 'Cook',
    engagement: 'Full-time',
    startLabel: 'From 8 Oct',
    stage: BookingStage.trial,
  ),
  upcomingInterview: UpcomingInterview(
    id: 'iv_301',
    workerName: 'Sunita R.',
    startsAt: DateTime.now().add(const Duration(days: 1)),
  ),
  shortlist: const [
    ShortlistPreview(workerId: 'w_1', name: 'Anita K.', service: 'Cook'),
  ],
  unreadCount: 3,
);

void main() {
  late FakeHomeRepository home;
  late FakeAddressRepository addresses;

  Future<ProviderContainer> launch(
    WidgetTester t, {
    HomeData? data,
    List<Address> addrs = const [_addr],
  }) async {
    useTestPhone(t);
    home = FakeHomeRepository(data ?? _returning);
    addresses = FakeAddressRepository(addrs);
    final auth = FakeAuthRepository()..onProfile = () async => true;
    await t.pumpWidget(
      testRootApp(
        store: InMemorySessionStore((access: 'a', refresh: 'r')),
        repo: auth,
        home: home,
        overrides: [
          addressRepositoryProvider.overrideWithValue(addresses),
          customerProfileRepositoryProvider.overrideWithValue(
            FakeProfileRepository(
              const CustomerProfile(
                name: 'Priya Sharma',
                email: 'p@x.in',
                preferredLanguage: 'en',
              ),
            ),
          ),
        ],
      ),
    );
    await t.pumpAndSettle();
    return ProviderScope.containerOf(t.element(find.byType(HomeScreen)));
  }

  String location(WidgetTester t) => GoRouter.of(
    t.element(find.byType(Scaffold).first),
  ).routerDelegate.currentConfiguration.last.matchedLocation;

  Future<void> tapKey(WidgetTester t, String key) async {
    await t.ensureVisible(find.byKey(Key(key)));
    await t.pump();
    await t.tap(find.byKey(Key(key)));
    await t.pumpAndSettle();
  }

  group('header', () {
    testWidgets('greets by first name and shows the default address', (
      t,
    ) async {
      await launch(t);
      expect(find.text('Namaste, Priya'), findsOneWidget);
      expect(find.text('Madhapur, Hyderabad'), findsOneWidget);
    });

    testWidgets('HOME-05 bell shows unread and opens notifications', (t) async {
      await launch(t);
      expect(find.byKey(const Key('home_bell_badge')), findsOneWidget);
      await tapKey(t, 'home_bell_btn');
      expect(location(t), '/notifications');
    });

    testWidgets('no unread -> no badge', (t) async {
      await launch(t, data: const HomeData());
      expect(find.byKey(const Key('home_bell_badge')), findsNothing);
    });

    testWidgets('address chip opens the picker; the choice is kept', (t) async {
      const other = Address(
        id: 'o1',
        line: 'Plot 18',
        area: 'Gachibowli',
        city: 'Hyderabad',
        pincode: '500032',
      );
      final c = await launch(t, addrs: const [_addr, other]);
      await tapKey(t, 'home_address_chip');
      expect(location(t), '/addresses');
      await t.tap(find.byKey(const Key('address_card_o1')));
      await t.pumpAndSettle();
      expect(find.text('Gachibowli, Hyderabad'), findsOneWidget);
      expect(c.read(selectedAddressProvider)?.id, 'o1');
    });

    testWidgets('HOME-07 no address -> banner -> address form', (t) async {
      await launch(t, addrs: const []);
      expect(find.text('Add an address to find workers'), findsOneWidget);
      await tapKey(t, 'home_add_address_btn');
      expect(location(t), '/addresses/new');
    });

    testWidgets('hero pause toggles its label', (t) async {
      await launch(t);
      await tapKey(t, 'home_hero_toggle');
      expect(find.byTooltip('Play'), findsOneWidget);
    });
  });

  group('start hiring', () {
    testWidgets(
      'HOME-02 Find CTA resets the draft and opens the service step',
      (t) async {
        final c = await launch(t);
        c.read(requirementDraftProvider.notifier).startWithService('driver');
        await tapKey(t, 'home_find_worker_btn');
        expect(location(t), '/discover/category');
        expect(c.read(requirementDraftProvider).serviceId, isNull);
      },
    );

    testWidgets('HOME-03 hero service chip presets the draft and skips ahead', (
      t,
    ) async {
      final c = await launch(t);
      await tapKey(t, 'home_category_tile_cook');
      expect(location(t), '/discover/engagement');
      expect(c.read(requirementDraftProvider).serviceId, 'cook');
    });

    testWidgets('HOME-01 new user: onboarding only, CTA starts a fresh draft', (
      t,
    ) async {
      final c = await launch(t, data: const HomeData());
      expect(find.text('No bookings yet'), findsOneWidget);
      expect(find.text('Your activity'), findsNothing);
      expect(find.byKey(const Key('home_support_btn')), findsNothing);
      await tapKey(t, 'home_onboarding_cta');
      expect(location(t), '/discover/category');
      expect(c.read(requirementDraftProvider).serviceId, isNull);
    });
  });

  group('returning user', () {
    testWidgets('HOME-04 booking card opens that booking', (t) async {
      await launch(t);
      expect(find.text('Lakshmi Devi'), findsOneWidget);
      expect(find.text('Booking #SN-2048'), findsOneWidget);
      await tapKey(t, 'home_view_booking_btn');
      expect(location(t), '/bookings/bk_2048');
    });

    testWidgets('interview card opens that interview', (t) async {
      await launch(t);
      expect(find.text('Interview with Sunita R.'), findsOneWidget);
      await tapKey(t, 'home_interview_card');
      expect(location(t), '/interviews/iv_301');
    });

    testWidgets('sections the backend omits are hidden (no placeholders)', (
      t,
    ) async {
      await launch(
        t,
        data: const HomeData(
          shortlist: [
            ShortlistPreview(
              workerId: 'w_1',
              name: 'Anita K.',
              service: 'Cook',
            ),
          ],
        ),
      );
      expect(find.text('Your activity'), findsNothing);
      expect(find.text('Your shortlist'), findsOneWidget);
    });

    testWidgets('shortlist worker opens detail; View shortlist switches tab', (
      t,
    ) async {
      await launch(t);
      await tapKey(t, 'home_fav_worker_w_1');
      expect(location(t), '/workers/w_1');
      t.state<NavigatorState>(find.byType(Navigator).first).pop();
      await t.pumpAndSettle();
      await tapKey(t, 'home_view_favs_btn');
      expect(location(t), '/favourites');
    });

    testWidgets('support shortcut opens support', (t) async {
      await launch(t);
      await tapKey(t, 'home_support_btn');
      expect(location(t), '/support');
    });
  });

  group('states', () {
    testWidgets('loading skeleton, then content', (t) async {
      useTestPhone(t);
      home = FakeHomeRepository(_returning);
      final auth = FakeAuthRepository()..onProfile = () async => true;
      await t.pumpWidget(
        testRootApp(
          store: InMemorySessionStore((access: 'a', refresh: 'r')),
          repo: auth,
          home: home,
          overrides: [
            addressRepositoryProvider.overrideWithValue(
              FakeAddressRepository(const [_addr]),
            ),
            customerProfileRepositoryProvider.overrideWithValue(
              FakeProfileRepository(),
            ),
          ],
        ),
      );
      await t.pump();
      await t.pump();
      await t.pump(const Duration(milliseconds: 50));
      await t.pumpAndSettle();
      expect(find.text('Your activity'), findsOneWidget);
    });

    testWidgets('HOME-06 error -> Try again recovers', (t) async {
      useTestPhone(t);
      home = FakeHomeRepository(_returning)..failNext = const ServerFailure();
      final auth = FakeAuthRepository()..onProfile = () async => true;
      await t.pumpWidget(
        testRootApp(
          store: InMemorySessionStore((access: 'a', refresh: 'r')),
          repo: auth,
          home: home,
          overrides: [
            addressRepositoryProvider.overrideWithValue(
              FakeAddressRepository(const [_addr]),
            ),
            customerProfileRepositoryProvider.overrideWithValue(
              FakeProfileRepository(),
            ),
          ],
        ),
      );
      await t.pumpAndSettle();
      expect(find.text("We couldn't load your home"), findsOneWidget);
      // The hero and CTA stay usable.
      expect(find.byKey(const Key('home_find_worker_btn')), findsOneWidget);
      await tapKey(t, 'home_retry_btn');
      expect(home.fetchCalls, 2);
      expect(find.text('Your activity'), findsOneWidget);
    });

    testWidgets(
      'offline: banner over saved info, CTA disabled, Retry refetches',
      (t) async {
        await launch(t, data: _returning.asCached());
        expect(
          find.text("You're offline. Showing saved info."),
          findsOneWidget,
        );
        expect(find.text('Lakshmi Devi'), findsOneWidget);
        await tapKey(t, 'home_find_worker_btn');
        expect(location(t), '/home'); // disabled
        home.data = _returning;
        await tapKey(t, 'home_offline_retry');
        expect(find.text("You're offline. Showing saved info."), findsNothing);
      },
    );

    testWidgets('HOME-10 pull to refresh refetches', (t) async {
      await launch(t);
      expect(home.fetchCalls, 1);
      await t.fling(find.byType(ListView).first, const Offset(0, 400), 1000);
      await t.pumpAndSettle();
      expect(home.fetchCalls, 2);
    });
  });

  group('navigation shell', () {
    testWidgets('HOME-09 back on another tab returns to Home', (t) async {
      await launch(t);
      await t.tap(find.byKey(const Key('nav_bookings')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('home_find_worker_btn')), findsNothing);
      await t.binding.handlePopRoute();
      await t.pumpAndSettle();
      expect(find.byKey(const Key('home_find_worker_btn')), findsOneWidget);
    });
  });

  group('dev menu', () {
    testWidgets('long-press greeting flips the mock API behaviour', (t) async {
      final c = await launch(t);
      await t.longPress(find.byKey(const Key('home_greeting')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('dev_mode_offline')));
      await t.pump();
      expect(c.read(mockApiProvider).mode, MockMode.offline);
      await t.tap(find.byKey(const Key('dev_mode_loading')));
      await t.pump();
      expect(c.read(mockApiProvider).mode, MockMode.loading);
      await t.tap(find.byKey(const Key('dev_user_new')));
      await t.pump();
      expect(c.read(mockApiProvider).returningUser, isFalse);
      // Tests run as the dev flavor: mocks by default, the menu can switch to the live backend.
      expect(c.read(mockApiProvider).live, isFalse);
      await t.tap(find.byKey(const Key('dev_live_on')));
      await t.pump();
      expect(c.read(mockApiProvider).live, isTrue);
    });
  });
}
