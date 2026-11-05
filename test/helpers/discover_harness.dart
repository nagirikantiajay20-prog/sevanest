// Shared harness for requirement-builder widget tests: the real app + router with fake backends and
// a pre-built draft, opened straight on the step under test.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/core/config/app_config.dart';
import 'package:sevanest_customer/core/services/location_service.dart';
import 'package:sevanest_customer/features/addresses/domain/address.dart';
import 'package:sevanest_customer/features/addresses/presentation/providers/address_providers.dart';
import 'package:sevanest_customer/features/customer_profile/domain/customer_profile.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/providers/customer_profile_providers.dart';
import 'package:sevanest_customer/features/home/domain/home_data.dart';
import 'package:sevanest_customer/features/notifications/domain/notification.dart';
import 'package:sevanest_customer/features/notifications/domain/push_service.dart';
import 'package:sevanest_customer/features/service_discovery/domain/catalog.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/requirement_draft_provider.dart';
import 'package:sevanest_customer/features/support/domain/support.dart';

import 'fakes.dart';
import 'notification_fakes.dart';

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

  /// Types into the search-first service screen and waits out the debounce.
  Future<void> search(String text) async {
    await tester.enterText(
      find.byKey(const Key('discover_search_field')),
      text,
    );
    await tester.pump(const Duration(milliseconds: 400));
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
  NotificationRepository? notifications,
  SupportRepository? support,
  SafetyRepository? safety,
  PushService? push,
  AppConfig? config,
  CustomerProfileRepository? profiles,
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
      config: config,
      store: InMemorySessionStore((access: 'a', refresh: 'r')),
      repo: auth,
      home: FakeHomeRepository(const HomeData()),
      catalog: catalog,
      schedule: schedule,
      guidance: guidance,
      notifications: notifications,
      support: support,
      safety: safety,
      // A returning customer has already decided; no first-Home pre-prompt over the screens.
      push: push ?? FakePushService(state: PushPermission.granted),
      overrides: [
        ...overrides,
        addressRepositoryProvider.overrideWithValue(addr),
        locationServiceProvider.overrideWithValue(location),
        customerProfileRepositoryProvider.overrideWithValue(
          profiles ?? FakeProfileRepository(),
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
