// Shared harness for requirement-builder widget tests: the real app + router with fake backends and
// a pre-built draft, opened straight on the step under test.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/core/services/location_service.dart';
import 'package:sevanest_customer/features/addresses/domain/address.dart';
import 'package:sevanest_customer/features/addresses/presentation/providers/address_providers.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/providers/customer_profile_providers.dart';
import 'package:sevanest_customer/features/home/domain/home_data.dart';
import 'package:sevanest_customer/features/service_discovery/domain/catalog.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/requirement_draft_provider.dart';

import 'fakes.dart';

const testHome = Address(
  id: 'h1',
  line: 'Flat 402, Sai Residency',
  area: 'Madhapur',
  city: 'Hyderabad',
  pincode: '500081',
  isDefault: true,
);

class DiscoverEnv {
  DiscoverEnv(this.tester, this.container);
  final WidgetTester tester;
  final ProviderContainer container;

  late FakeCatalogRepository catalog;
  late FakeScheduleRepository schedule;
  late FakeGuidanceRepository guidance;
  late FakeAddressRepository addresses;
  late FakeLocationService location;

  RequirementDraftNotifier get draftNotifier =>
      container.read(requirementDraftProvider.notifier);

  /// Where the router currently is (includes pushed routes, without the query string).
  String get where => GoRouter.of(
    tester.element(find.byType(Scaffold).first),
  ).routerDelegate.currentConfiguration.last.matchedLocation;

  Future<void> go(String route) async {
    unawaitedPush(route);
    await tester.pumpAndSettle();
  }

  void unawaitedPush(String route) {
    final ctx = tester.element(find.byType(Scaffold).first);
    // ignore: discarded_futures
    GoRouter.of(ctx).push<Object?>(route);
  }

  Future<void> tapKey(String key) async {
    await tester.ensureVisible(find.byKey(Key(key)));
    await tester.pump();
    await tester.tap(find.byKey(Key(key)));
    await tester.pumpAndSettle();
  }

  bool get nextEnabled {
    final b = find.descendant(
      of: find.byKey(const Key('discover_next_btn')),
      matching: find.byType(FilledButton),
    );
    return tester.widget<FilledButton>(b).onPressed != null;
  }

  /// Service + engagement + address in the draft (steps 1-3 done).
  void stepsOneToThree(EngagementType e) {
    draftNotifier
      ..setService('cook')
      ..setEngagement(e)
      ..setAddress(testHome);
  }
}

/// Starts the app on Home (returning customer, no activity) and returns the env.
Future<DiscoverEnv> launchDiscover(
  WidgetTester t, {
  List<Address> addresses = const [testHome],

  /// Logical height of the phone surface. Tall surfaces keep long forms fully built, so tests can
  /// read fields without scrolling.
  double height = 844,
  List<Override> overrides = const [],
}) async {
  useTestPhone(t);
  if (height != 844) {
    t.view.physicalSize = Size(1170, height * 3);
  }
  final catalog = FakeCatalogRepository();
  final schedule = FakeScheduleRepository();
  final guidance = FakeGuidanceRepository();
  final addr = FakeAddressRepository(addresses);
  final location = FakeLocationService();
  final auth = FakeAuthRepository()..onProfile = () async => true;
  await t.pumpWidget(
    testRootApp(
      store: InMemorySessionStore((access: 'a', refresh: 'r')),
      repo: auth,
      home: FakeHomeRepository(const HomeData()),
      catalog: catalog,
      schedule: schedule,
      guidance: guidance,
      overrides: [
        ...overrides,
        addressRepositoryProvider.overrideWithValue(addr),
        locationServiceProvider.overrideWithValue(location),
        customerProfileRepositoryProvider.overrideWithValue(
          FakeProfileRepository(),
        ),
      ],
    ),
  );
  await t.pumpAndSettle();
  final container = ProviderScope.containerOf(
    t.element(find.byKey(const Key('home_find_worker_btn'))),
  );
  return DiscoverEnv(t, container)
    ..catalog = catalog
    ..schedule = schedule
    ..guidance = guidance
    ..addresses = addr
    ..location = location;
}
