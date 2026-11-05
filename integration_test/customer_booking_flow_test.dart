// Customer journey on the real app, router and widgets with deterministic fakes (no backend, SMS or
// payment): new customer login -> OTP -> profile setup -> service discovery -> worker selection ->
// interview request -> worker confirmation -> booking confirmation -> booking detail.
//
//   flutter test integration_test/customer_booking_flow_test.dart -d <android emulator id>
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sevanest_customer/features/addresses/presentation/providers/address_providers.dart';
import 'package:sevanest_customer/features/authentication/presentation/providers/auth_providers.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/providers/customer_profile_providers.dart';
import 'package:sevanest_customer/features/favourites/presentation/providers/favourites_providers.dart';
import 'package:sevanest_customer/features/home/domain/home_data.dart';
import 'package:sevanest_customer/features/notifications/domain/push_service.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/requirement_draft_provider.dart';

import '../test/helpers/fakes.dart';
import '../test/helpers/notification_fakes.dart';

Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 3; i++) {
    await t.pumpAndSettle();
    await t.pump(const Duration(seconds: 1));
  }
  await t.pumpAndSettle();
}

Finder k(String key) => find.byKey(Key(key));

Future<void> tapKey(WidgetTester t, String key) async {
  if (k(key).evaluate().isEmpty) {
    await t.scrollUntilVisible(
      k(key),
      300,
      scrollable: find.byType(Scrollable).last,
    );
  }
  await t.ensureVisible(k(key));
  await t.pump();
  await t.tap(k(key));
  await settle(t);
}

String where(WidgetTester t) => GoRouter.of(
  t.element(find.byType(Scaffold).first),
).routerDelegate.currentConfiguration.last.matchedLocation;

/// The shared helper also attaches a photo; the photo is optional, so this journey skips it.
Future<void> addAddressWithoutPhoto(WidgetTester t) async {
  Future<void> enter(String key, String text) async {
    await t.ensureVisible(k(key));
    await t.enterText(k(key), text);
    await t.pump();
  }

  await t.ensureVisible(k('profile_address_card'));
  await t.tap(k('profile_address_card'));
  await t.pumpAndSettle();
  await enter('address_line1_field', 'Flat 7B');
  await enter('address_line2_field', 'Lake View Apartments');
  await t.ensureVisible(k('address_area_field'));
  await t.tap(k('address_area_field'));
  await t.pumpAndSettle();
  await t.tap(k('area_option_Madhapur'));
  await t.pumpAndSettle();
  await enter('address_pincode_field', '500081');
  await t.ensureVisible(k('address_save_btn'));
  await t.tap(k('address_save_btn'));
  await t.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('new customer: login to booking confirmation', (t) async {
    // Tall virtual surface (as the widget tests use) so lazily built forms are fully present.
    useTestPhone(t);
    t.view.physicalSize = const Size(1170, 3 * 2400);
    final auth = FakeAuthRepository()..onProfile = () async => false;
    final profiles = FakeProfileRepository();
    final addresses = FakeAddressRepository();
    final store = InMemorySessionStore();
    await t.pumpWidget(
      testRootApp(
        store: store,
        repo: auth,
        home: FakeHomeRepository(const HomeData()),
        push: FakePushService(state: PushPermission.granted),
        overrides: [
          favouritesRepositoryProvider.overrideWithValue(
            FakeFavouritesRepository(),
          ),
          customerProfileRepositoryProvider.overrideWithValue(profiles),
          addressRepositoryProvider.overrideWithValue(addresses),
        ],
      ),
    );
    await t.pumpAndSettle();

    // Login: validation first (short number keeps the button disabled), then a valid number.
    await t.enterText(k('login_mobile_field'), '98765');
    await t.pump();
    await t.tap(k('login_get_otp_btn'), warnIfMissed: false);
    await t.pumpAndSettle();
    expect(auth.requestCalls, 0, reason: 'an invalid number is never sent');
    await t.enterText(k('login_mobile_field'), '9876543210');
    await t.pump();
    await t.tap(k('login_get_otp_btn'));
    await t.pumpAndSettle();
    expect(auth.requestCalls, 1);

    // OTP verification.
    expect(k('otp_input_field'), findsOneWidget);
    await t.enterText(k('otp_input_field'), '123456');
    await t.pump();
    await t.tap(k('otp_verify_btn'));
    await t.pump(verifiedHold);
    await t.pumpAndSettle();
    expect(auth.verifyCalls, 1);
    expect(await store.read(), isNotNull);

    // New customer: profile setup with a home address, then Home.
    expect(k('profile_continue_btn'), findsOneWidget);
    await t.enterText(k('profile_name_field'), 'Priya Sharma');
    await t.enterText(k('profile_email_field'), 'p@example.com');
    await t.pump();
    await addAddressWithoutPhoto(t);
    await t.tap(k('profile_continue_btn'));
    await t.pumpAndSettle();
    expect(profiles.createCalls, 1);
    expect(addresses.createCalls, 1);
    expect(k('home_find_worker_btn'), findsOneWidget);

    // Service discovery: search -> service -> engagement -> address -> timing -> start -> budget.
    await tapKey(t, 'home_find_worker_btn');
    await t.enterText(k('discover_search_field'), 'cook');
    await t.pump(const Duration(milliseconds: 400));
    await t.pumpAndSettle();
    await tapKey(t, 'discover_category_tile_cook');
    await tapKey(t, 'discover_next_btn');
    await tapKey(t, 'discover_engagement_partTime');
    await tapKey(t, 'discover_next_btn');
    await tapKey(t, 'discover_next_btn'); // address (default home)
    await tapKey(t, 'discover_window_morning');
    await tapKey(t, 'discover_next_btn');
    await tapKey(t, 'discover_shortcut_tomorrow');
    await tapKey(t, 'discover_next_btn');
    await tapKey(t, 'discover_next_btn'); // budget
    expect(where(t), '/discover/review');
    final container = ProviderScope.containerOf(
      t.element(k('discover_search_btn')),
    );
    final draft = container.read(requirementDraftProvider);
    expect(draft.serviceId, 'cook');
    expect(draft.startDate, isNotNull);

    // Worker selection.
    await tapKey(t, 'discover_search_btn');
    expect(where(t), '/workers');
    await tapKey(t, 'worker_card_cook-2');
    expect(where(t), '/workers/cook-2');

    // Booking details: the interview request carries the requirement.
    await tapKey(t, 'worker_request_interview_btn');
    expect(where(t), '/interviews/new');
    expect(k('interview_worker_mini'), findsOneWidget);

    // Booking confirmation: the matched seeded booking is confirmed and moves on to its detail.
    GoRouter.of(
      t.element(find.byType(Scaffold).first),
    ).go('/interviews/iv_302');
    await settle(t);
    await tapKey(t, 'interview_confirm_worker_btn');
    expect(where(t), '/bookings/confirm');
    expect(k('confirm_worker_card'), findsOneWidget);
    await tapKey(t, 'confirm_pay_btn');
    await tapKey(t, 'confirm_continue_btn');
    expect(where(t), '/bookings/iv_302');
  });
}
