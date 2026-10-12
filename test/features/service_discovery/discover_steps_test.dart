// WIDGET tests: requirement builder steps 1-3 (docs/modules/04 DISC-01..10, screens 06-08).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/services/location_service.dart';
import 'package:sevanest_customer/features/addresses/domain/address.dart';
import 'package:sevanest_customer/features/addresses/presentation/providers/address_providers.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/providers/customer_profile_providers.dart';
import 'package:sevanest_customer/features/home/domain/home_data.dart';
import 'package:sevanest_customer/features/service_discovery/domain/catalog.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/requirement_draft_provider.dart';

import '../../helpers/fakes.dart';

const _home = Address(
  id: 'h1',
  line: 'Flat 402, Sai Residency',
  area: 'Madhapur',
  city: 'Hyderabad',
  pincode: '500081',
  isDefault: true,
);
const _office = Address(
  id: 'o1',
  line: 'Plot 18, HITEC City',
  area: 'Gachibowli',
  city: 'Hyderabad',
  pincode: '500032',
);

void main() {
  late FakeCatalogRepository catalog;
  late FakeAddressRepository addresses;
  late FakeLocationService location;
  late ProviderContainer container;

  Future<void> launch(
    WidgetTester t, {
    List<Address>? addrs,
    bool failAddresses = false,
  }) async {
    useTestPhone(t);
    catalog = FakeCatalogRepository();
    addresses = FakeAddressRepository(addrs ?? [_home, _office]);
    location = FakeLocationService();
    if (failAddresses) addresses.failList = const NetworkFailure();
    final auth = FakeAuthRepository()..onProfile = () async => true;
    await t.pumpWidget(
      testRootApp(
        store: InMemorySessionStore((access: 'a', refresh: 'r')),
        repo: auth,
        home: FakeHomeRepository(const HomeData()),
        catalog: catalog,
        overrides: [
          addressRepositoryProvider.overrideWithValue(addresses),
          locationServiceProvider.overrideWithValue(location),
          customerProfileRepositoryProvider.overrideWithValue(
            FakeProfileRepository(),
          ),
        ],
      ),
    );
    await t.pumpAndSettle();
    container = ProviderScope.containerOf(
      t.element(find.byKey(const Key('home_find_worker_btn'))),
    );
  }

  Future<void> start(WidgetTester t) async {
    await t.tap(find.byKey(const Key('home_find_worker_btn')));
    await t.pumpAndSettle();
  }

  String where(WidgetTester t) => GoRouter.of(
    t.element(find.byType(Scaffold).first),
  ).routerDelegate.currentConfiguration.last.matchedLocation;

  Future<void> tapKey(WidgetTester t, String key) async {
    await t.ensureVisible(find.byKey(Key(key)));
    await t.pump();
    await t.tap(find.byKey(Key(key)));
    await t.pumpAndSettle();
  }

  bool nextEnabled(WidgetTester t) {
    final b = find.descendant(
      of: find.byKey(const Key('discover_next_btn')),
      matching: find.byType(FilledButton),
    );
    return t.widget<FilledButton>(b).onPressed != null;
  }

  Future<void> toEngagement(WidgetTester t, {String service = 'cook'}) async {
    await start(t);
    await tapKey(t, 'discover_category_tile_$service');
    await tapKey(t, 'discover_next_btn');
  }

  Future<void> toLocation(WidgetTester t) async {
    await toEngagement(t);
    await tapKey(t, 'discover_engagement_partTime');
    await tapKey(t, 'discover_next_btn');
  }

  group('step 1 - service', () {
    testWidgets('DISC-01 loading skeleton, then the grid', (t) async {
      useTestPhone(t);
      final gate = Completer<void>();
      catalog = FakeCatalogRepository()..gate = gate.future;
      final auth = FakeAuthRepository()..onProfile = () async => true;
      await t.pumpWidget(
        testRootApp(
          store: InMemorySessionStore((access: 'a', refresh: 'r')),
          repo: auth,
          home: FakeHomeRepository(const HomeData()),
          catalog: catalog,
          overrides: [
            addressRepositoryProvider.overrideWithValue(
              FakeAddressRepository(),
            ),
            customerProfileRepositoryProvider.overrideWithValue(
              FakeProfileRepository(),
            ),
          ],
        ),
      );
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('home_find_worker_btn')));
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
      expect(nextEnabled(t), isFalse);
      gate.complete();
      await t.pumpAndSettle();
      expect(
        find.byKey(const Key('discover_category_tile_cook')),
        findsOneWidget,
      );
    });

    testWidgets('DISC-01 error -> Try again refetches', (t) async {
      await launch(t);
      catalog.failNext = const NetworkFailure();
      await start(t);
      expect(find.text("We couldn't load services"), findsOneWidget);
      await tapKey(t, 'error_retry_btn');
      expect(catalog.calls, 2);
      expect(
        find.byKey(const Key('discover_category_tile_maid')),
        findsOneWidget,
      );
    });

    testWidgets('DISC-01 empty catalogue shows a message', (t) async {
      await launch(t);
      catalog.items = const [];
      await start(t);
      expect(find.text('No services available right now'), findsOneWidget);
    });

    testWidgets(
      'DISC-02 Continue disabled until chosen, label names the pick',
      (t) async {
        await launch(t);
        await start(t);
        expect(find.text('Step 1 of 6'), findsOneWidget);
        expect(nextEnabled(t), isFalse);
        await tapKey(t, 'discover_category_tile_cook');
        expect(
          find.byKey(const Key('discover_category_check')),
          findsOneWidget,
        );
        expect(find.text('Continue with Cook'), findsOneWidget);
        await tapKey(t, 'discover_next_btn');
        expect(where(t), '/discover/engagement');
      },
    );

    testWidgets('search filters, no-result offers Clear search', (t) async {
      await launch(t);
      await start(t);
      await t.enterText(find.byKey(const Key('discover_search_field')), 'dri');
      await t.pump();
      expect(
        find.byKey(const Key('discover_category_tile_driver')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('discover_category_tile_cook')),
        findsNothing,
      );
      await t.enterText(find.byKey(const Key('discover_search_field')), 'xyz');
      await t.pump();
      expect(find.text('No services match “xyz”'), findsOneWidget);
      await tapKey(t, 'discover_clear_search_btn');
      expect(
        find.byKey(const Key('discover_category_tile_cook')),
        findsOneWidget,
      );
    });

    testWidgets(
      'DISC-07 close asks, cancel stays, confirm clears and goes Home',
      (t) async {
        await launch(t);
        await start(t);
        await tapKey(t, 'discover_category_tile_cook');
        await tapKey(t, 'discover_close_btn');
        expect(find.text('Discard this request?'), findsOneWidget);
        await tapKey(t, 'discover_discard_cancel_btn');
        expect(where(t), '/discover/category');
        await tapKey(t, 'discover_close_btn');
        await tapKey(t, 'discover_discard_confirm_btn');
        expect(where(t), '/home');
        expect(container.read(requirementDraftProvider).isEmpty, isTrue);
      },
    );

    testWidgets('back with nothing chosen leaves without a prompt', (t) async {
      await launch(t);
      await start(t);
      await tapKey(t, 'app_back_btn');
      expect(where(t), '/home');
    });

    testWidgets('back after choosing asks to discard', (t) async {
      await launch(t);
      await start(t);
      await tapKey(t, 'discover_category_tile_cook');
      await tapKey(t, 'app_back_btn');
      expect(find.text('Discard this request?'), findsOneWidget);
    });
  });

  group('step 2 - engagement', () {
    testWidgets(
      'DISC-04 lists the service options; selecting enables Continue',
      (t) async {
        await launch(t);
        await toEngagement(t);
        expect(find.text('Step 2 of 6'), findsOneWidget);
        expect(
          find.byKey(const Key('discover_engagement_fullTime')),
          findsOneWidget,
        );
        expect(nextEnabled(t), isFalse);
        await tapKey(t, 'discover_engagement_partTime');
        expect(find.text('Continue with Part-time'), findsOneWidget);
        await tapKey(t, 'discover_next_btn');
        expect(where(t), '/discover/location');
      },
    );

    testWidgets(
      'Driver: Live-in is disabled with its reason and cannot be picked',
      (t) async {
        await launch(t);
        await toEngagement(t, service: 'driver');
        expect(
          find.byKey(const Key('discover_engagement_reason_liveIn')),
          findsOneWidget,
        );
        await t.ensureVisible(
          find.byKey(const Key('discover_engagement_liveIn')),
        );
        await t.tap(find.byKey(const Key('discover_engagement_liveIn')));
        await t.pump();
        expect(container.read(requirementDraftProvider).engagement, isNull);
        expect(nextEnabled(t), isFalse);
      },
    );

    testWidgets('DISC-05 a single supported option is preselected', (t) async {
      await launch(t);
      catalog.items = const [
        ServiceCategory(
          id: 'cook',
          name: 'Cook',
          description: 'x',
          icon: Icons.soup_kitchen,
          engagements: [EngagementOption(EngagementType.daily)],
        ),
      ];
      await toEngagement(t);
      expect(
        container.read(requirementDraftProvider).engagement,
        EngagementType.daily,
      );
      expect(nextEnabled(t), isTrue);
    });

    testWidgets('DISC-03 changing the service clears the engagement', (
      t,
    ) async {
      await launch(t);
      await toEngagement(t);
      await tapKey(t, 'discover_engagement_partTime');
      await t.drag(find.byType(ListView), const Offset(0, 600));
      await t.pumpAndSettle();
      await tapKey(t, 'discover_change_service');
      expect(where(t), '/discover/category');
      await tapKey(t, 'discover_category_tile_maid');
      expect(container.read(requirementDraftProvider).engagement, isNull);
      await tapKey(
        t,
        'discover_next_btn',
      ); // edit mode: returns instead of pushing
      expect(where(t), '/discover/engagement');
      expect(find.text('Cook'), findsNothing);
      expect(find.text('Maid'), findsOneWidget);
    });

    testWidgets('DISC-06 back keeps the choice', (t) async {
      await launch(t);
      await toEngagement(t);
      await tapKey(t, 'discover_engagement_daily');
      await tapKey(t, 'app_back_btn');
      expect(where(t), '/discover/category');
      await tapKey(t, 'discover_next_btn');
      expect(
        container.read(requirementDraftProvider).engagement,
        EngagementType.daily,
      );
      expect(find.text('Continue with Daily'), findsOneWidget);
    });

    testWidgets('error state (resumed draft, catalogue down) -> Try again', (
      t,
    ) async {
      await launch(t);
      catalog.failNext = const NetworkFailure();
      await tapKey(t, 'home_category_tile_cook'); // straight to step 2
      expect(find.text("We couldn't load options"), findsOneWidget);
      await tapKey(t, 'error_retry_btn');
      expect(
        find.byKey(const Key('discover_engagement_fullTime')),
        findsOneWidget,
      );
    });
  });

  group('step 3 - location', () {
    testWidgets('DISC-08 default address preselected, label names the area', (
      t,
    ) async {
      await launch(t);
      await toLocation(t);
      expect(find.text('Step 3 of 6'), findsOneWidget);
      expect(find.byKey(const Key('discover_default_tag_h1')), findsOneWidget);
      expect(find.text('Continue to Madhapur'), findsOneWidget);
      expect(container.read(requirementDraftProvider).address?.id, 'h1');
    });

    testWidgets('picking Office updates the label and the draft', (t) async {
      await launch(t);
      await toLocation(t);
      await tapKey(t, 'discover_address_o1');
      expect(find.text('Continue to Gachibowli'), findsOneWidget);
      expect(container.read(requirementDraftProvider).address?.id, 'o1');
      await tapKey(t, 'discover_next_btn');
      expect(where(t), '/discover/timing');
    });

    testWidgets('no saved addresses: empty card, Add address opens the form', (
      t,
    ) async {
      await launch(t, addrs: const []);
      await toLocation(t);
      expect(find.text('Add your first address'), findsOneWidget);
      expect(nextEnabled(t), isFalse);
      await tapKey(t, 'discover_empty_add_address_btn');
      expect(where(t), '/addresses/new');
    });

    testWidgets('DISC-08 a newly saved address is auto-selected', (t) async {
      await launch(t, addrs: const [_home]);
      await toLocation(t);
      container
          .read(requirementDraftProvider.notifier)
          .setAddress(_home); // baseline
      await tapKey(t, 'discover_add_address_btn');
      expect(where(t), '/addresses/new');
    });

    testWidgets('error -> Try again', (t) async {
      await launch(t, failAddresses: true);
      await toEngagement(t);
      await tapKey(t, 'discover_engagement_partTime');
      await tapKey(t, 'discover_next_btn');
      expect(find.text("We couldn't load your addresses"), findsOneWidget);
      addresses.failList = null;
      await tapKey(t, 'error_retry_btn');
      expect(find.byKey(const Key('discover_address_h1')), findsOneWidget);
    });

    testWidgets(
      'DISC-10 permission denied shows the card; settings + saved work',
      (t) async {
        await launch(t);
        await toLocation(t);
        location.result = const LocationResult(LocationOutcome.deniedForever);
        await tapKey(t, 'discover_use_location_btn');
        expect(find.byKey(const Key('discover_location_off')), findsOneWidget);
        await tapKey(t, 'discover_open_settings_btn');
        expect(location.settingsCalls, 1);
        await tapKey(t, 'discover_choose_saved_btn');
        expect(find.byKey(const Key('discover_location_off')), findsNothing);
        expect(
          nextEnabled(t),
          isTrue,
        ); // the flow continues with a saved address
      },
    );

    testWidgets(
      'finding location shows progress; a result opens a prefilled form',
      (t) async {
        await launch(t);
        await toLocation(t);
        final gate = Completer<void>();
        location
          ..gate = gate.future
          ..result = const LocationResult(
            LocationOutcome.found,
            AddressInput(
              line: '',
              area: 'Kondapur',
              city: 'Hyderabad',
              pincode: '500084',
            ),
          );
        await t.tap(find.byKey(const Key('discover_use_location_btn')));
        await t.pump();
        expect(find.text('Finding your location...'), findsOneWidget);
        gate.complete();
        await t.pumpAndSettle();
        expect(where(t), '/addresses/new');
        expect(find.widgetWithText(TextField, 'Kondapur'), findsOneWidget);
        expect(find.widgetWithText(TextField, '500084'), findsOneWidget);
      },
    );

    testWidgets('location unavailable -> snackbar, flow continues', (t) async {
      await launch(t);
      await toLocation(t);
      location.result = const LocationResult(LocationOutcome.unavailable);
      await tapKey(t, 'discover_use_location_btn');
      expect(find.textContaining("Couldn't get your location"), findsOneWidget);
      expect(where(t), '/discover/location');
    });

    testWidgets('Change engagement opens edit mode and Continue returns', (
      t,
    ) async {
      await launch(t);
      await toLocation(t);
      await tapKey(t, 'discover_change_engagement');
      expect(where(t), '/discover/engagement');
      await tapKey(t, 'discover_engagement_daily');
      await tapKey(t, 'discover_next_btn');
      expect(where(t), '/discover/location');
      expect(find.text('Daily'), findsOneWidget);
    });
  });
}
