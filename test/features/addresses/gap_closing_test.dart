// Gap-closing: Log out (2.4), "Use my current location" in the address form (3.2), and the
// live/mock switch for the repositories that now have a backend contract.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/core/config/app_config.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/core/services/location_service.dart';
import 'package:sevanest_customer/features/addresses/data/address_repository_remote.dart';
import 'package:sevanest_customer/features/addresses/domain/address.dart';
import 'package:sevanest_customer/features/favourites/data/favourites_repository_mock.dart';
import 'package:sevanest_customer/features/favourites/data/favourites_repository_remote.dart';
import 'package:sevanest_customer/features/favourites/presentation/providers/favourites_providers.dart';
import 'package:sevanest_customer/features/home/data/home_repository_remote.dart';
import 'package:sevanest_customer/features/home/presentation/providers/home_providers.dart';
import 'package:sevanest_customer/features/service_discovery/data/catalog_repository_mock.dart';
import 'package:sevanest_customer/features/service_discovery/data/catalog_repository_remote.dart';
import 'package:sevanest_customer/features/service_discovery/data/guidance_repository_remote.dart';
import 'package:sevanest_customer/features/service_discovery/domain/budget.dart';
import 'package:sevanest_customer/features/service_discovery/domain/catalog.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/catalog_providers.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/schedule_providers.dart';
import 'package:sevanest_customer/features/worker_search/data/worker_search_repository_mock.dart';
import 'package:sevanest_customer/features/worker_search/data/worker_search_repository_remote.dart';
import 'package:sevanest_customer/features/worker_search/presentation/providers/worker_search_providers.dart';

import '../../helpers/discover_harness.dart';
import '../../helpers/fakes.dart';

Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 3; i++) {
    await t.pumpAndSettle();
    await t.pump(const Duration(seconds: 1));
  }
  await t.pumpAndSettle();
}

ProviderContainer _container(AppEnv env, {bool? live}) {
  final c = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(switch (env) {
        AppEnv.dev => AppConfig.dev,
        AppEnv.stg => AppConfig.stg,
        AppEnv.prod => AppConfig.prod,
      }),
    ],
  );
  addTearDown(c.dispose);
  if (live != null) {
    c
        .read(mockApiProvider.notifier)
        .set(c.read(mockApiProvider).copyWith(live: live));
  }
  return c;
}

void main() {
  group('Log out (2.4)', () {
    testWidgets(
      'Cancel keeps the session; Confirm calls logout and signs out',
      (t) async {
        useTestPhone(t);
        final auth = FakeAuthRepository()..onProfile = () async => true;
        await t.pumpWidget(
          testRootApp(
            store: InMemorySessionStore((access: 'a', refresh: 'r')),
            repo: auth,
          ),
        );
        await t.pumpAndSettle();
        await t.tap(find.byKey(const Key('nav_account')));
        await t.pumpAndSettle();

        await t.tap(find.byKey(const Key('account_logout_btn')));
        await t.pumpAndSettle();
        await t.tap(find.byKey(const Key('dialog_cancel_btn')));
        await t.pumpAndSettle();
        expect(auth.logoutCalls, 0);
        expect(find.byKey(const Key('account_logout_btn')), findsOneWidget);

        await t.tap(find.byKey(const Key('account_logout_btn')));
        await t.pumpAndSettle();
        await t.tap(find.byKey(const Key('logout_confirm_btn')));
        await t.pumpAndSettle();
        expect(auth.logoutCalls, 1);
        expect(find.byKey(const Key('login_mobile_field')), findsOneWidget);
      },
    );
  });

  group('Use my current location (3.2)', () {
    Future<DiscoverEnv> open(WidgetTester t) async {
      final env = await launchDiscover(t);
      await env.go('/addresses/new');
      await settle(t);
      return env;
    }

    testWidgets('fills area, city, pincode and keeps the coordinates', (
      t,
    ) async {
      final env = await open(t);
      env.location.result = const LocationResult(
        LocationOutcome.found,
        AddressInput(
          line: '',
          area: 'madhapur', // geocoder casing differs from the service area
          city: 'Hyderabad',
          pincode: '500081',
          latitude: 17.44,
          longitude: 78.39,
        ),
      );
      await t.tap(find.byKey(const Key('address_use_location_btn')));
      await settle(t);
      String field(String k) =>
          t.widget<TextField>(find.byKey(Key(k))).controller!.text;
      expect(field('address_area_field'), 'Madhapur');
      expect(field('address_pincode_field'), '500081');

      await t.enterText(find.byKey(const Key('address_line1_field')), '7B');
      await t.enterText(find.byKey(const Key('address_line2_field')), 'Lake');
      await t.pump();
      await t.ensureVisible(find.byKey(const Key('address_save_btn')));
      await t.tap(find.byKey(const Key('address_save_btn')));
      await settle(t);
      expect(env.addresses.lastInput?.latitude, 17.44);
      expect(env.addresses.lastInput?.longitude, 78.39);
    });

    testWidgets('an area outside the service list is left for the picker', (
      t,
    ) async {
      final env = await open(t);
      env.location.result = const LocationResult(
        LocationOutcome.found,
        AddressInput(
          line: '',
          area: 'Nowhere',
          city: 'Hyderabad',
          pincode: '500001',
        ),
      );
      await t.tap(find.byKey(const Key('address_use_location_btn')));
      await settle(t);
      expect(
        t
            .widget<TextField>(find.byKey(const Key('address_area_field')))
            .controller!
            .text,
        '',
      );
    });

    testWidgets('permission denied: message, form still usable', (t) async {
      await open(t);
      await t.tap(find.byKey(const Key('address_use_location_btn')));
      await settle(t);
      expect(find.byKey(const Key('address_location_error')), findsOneWidget);
      expect(find.byKey(const Key('address_line1_field')), findsOneWidget);
    });
  });

  test(
    'remote create sends latitude and longitude only when both are known',
    () async {
      final seen = <RequestOptions>[];
      final dio = Dio(BaseOptions(baseUrl: 'http://x'))
        ..httpClientAdapter = FakeAdapter((o) async {
          seen.add(o);
          return jsonBody(
            '{"id":"a1","line":"l","area":"Madhapur","city":"Hyderabad","pincode":"500081"}',
            201,
          );
        });
      final repo = AddressRepositoryRemote(dio);
      await repo.create(
        const AddressInput(
          line: 'l',
          area: 'Madhapur',
          city: 'Hyderabad',
          pincode: '500081',
          latitude: 17.4,
          longitude: 78.3,
        ),
      );
      expect((seen.last.data as Map)['latitude'], 17.4);
      await repo.create(
        const AddressInput(
          line: 'l',
          area: 'Madhapur',
          city: 'Hyderabad',
          pincode: '500081',
        ),
      );
      expect((seen.last.data as Map).containsKey('latitude'), isFalse);
    },
  );

  group('live vs mock repositories', () {
    test('dev flavor starts on mocks; stg and prod start live', () {
      expect(_container(AppEnv.dev).read(mockApiProvider).live, isFalse);
      expect(_container(AppEnv.stg).read(mockApiProvider).live, isTrue);
      expect(_container(AppEnv.prod).read(mockApiProvider).live, isTrue);
    });

    test('live picks the real repositories, mock picks the seeded ones', () {
      final live = _container(AppEnv.prod);
      expect(
        live.read(catalogRepositoryProvider),
        isA<CatalogRepositoryRemote>(),
      );
      expect(
        live.read(workerSearchRepositoryProvider),
        isA<WorkerSearchRepositoryRemote>(),
      );
      expect(
        live.read(favouritesRepositoryProvider),
        isA<FavouritesRepositoryRemote>(),
      );
      expect(
        live.read(guidanceRepositoryProvider),
        isA<GuidanceRepositoryRemote>(),
      );
      expect(live.read(homeRepositoryProvider), isA<HomeRepositoryRemote>());

      final mock = _container(AppEnv.dev);
      expect(
        mock.read(catalogRepositoryProvider),
        isA<CatalogRepositoryMock>(),
      );
      expect(
        mock.read(workerSearchRepositoryProvider),
        isA<WorkerSearchRepositoryMock>(),
      );
      expect(
        mock.read(favouritesRepositoryProvider),
        isA<FavouritesRepositoryMock>(),
      );
    });

    test('live Home and guidance never invent data', () async {
      expect((await const HomeRepositoryRemote().fetch()).isNewUser, isTrue);
      expect(
        const GuidanceRepositoryRemote().guidance(
          const GuidanceQuery(
            serviceId: 'COOK',
            engagement: EngagementType.fullTime,
            area: 'Madhapur',
            city: 'Hyderabad',
          ),
        ),
        throwsA(isA<NotFoundFailure>()),
      );
    });

    test('catalogue maps /service-categories codes to ids', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://x'))
        ..httpClientAdapter = FakeAdapter(
          (o) async => jsonBody(
            '{"data":[{"code":"HOUSE_MAID","name":"House maid","description":"Cleaning"},'
            '{"code":"COOK","name":"Cook"},{"name":"no code"}],"meta":{"total":3}}',
            200,
          ),
        );
      final list = await CatalogRepositoryRemote(dio).categories();
      expect(list.map((c) => c.id), ['HOUSE_MAID', 'COOK']);
      expect(list.first.name, 'House maid');
      expect(list.first.engagements.every((e) => e.available), isTrue);
      expect(list.first.engagements.map((e) => e.type), EngagementType.values);
    });
  });
}
