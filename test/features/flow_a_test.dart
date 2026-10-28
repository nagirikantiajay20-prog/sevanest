// AGENTS §68 Flow A (AUTH-17): launch -> login -> OTP -> profile setup (with home address) -> Home,
// in one run on the real app + router with fake backends.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/features/addresses/presentation/providers/address_providers.dart';
import 'package:sevanest_customer/features/authentication/presentation/providers/auth_providers.dart';
import 'package:sevanest_customer/features/authentication/presentation/screens/otp_screen.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/providers/customer_profile_providers.dart';

import '../helpers/fakes.dart';

void main() {
  testWidgets('Flow A: new customer from launch to Home', (t) async {
    useTestPhone(t);
    final auth = FakeAuthRepository()..onProfile = () async => false;
    final profiles = FakeProfileRepository();
    final addresses = FakeAddressRepository();
    final store = InMemorySessionStore();
    await t.pumpWidget(
      testRootApp(
        store: store,
        repo: auth,
        overrides: [
          customerProfileRepositoryProvider.overrideWithValue(profiles),
          addressRepositoryProvider.overrideWithValue(addresses),
        ],
      ),
    );
    await t.pumpAndSettle();

    // Login
    await t.enterText(
      find.byKey(const Key('login_mobile_field')),
      '9876543210',
    );
    await t.pump();
    await t.tap(find.byKey(const Key('login_get_otp_btn')));
    await t.pumpAndSettle();
    expect(auth.requestCalls, 1);

    // OTP
    await t.enterText(find.byKey(const Key('otp_input_field')), '123456');
    await t.pump();
    await t.tap(find.byKey(const Key('otp_verify_btn')));
    await t.pump(verifiedHold);
    await t.pumpAndSettle();
    expect(auth.verifyCalls, 1);
    expect(await store.read(), isNotNull);

    // Profile setup: new customer, cannot go back to the OTP screen
    expect(find.byKey(const Key('profile_continue_btn')), findsOneWidget);
    expect(find.byType(OtpScreen), findsNothing);
    await t.enterText(
      find.byKey(const Key('profile_name_field')),
      'Priya Sharma',
    );
    await t.enterText(
      find.byKey(const Key('profile_email_field')),
      'p@example.com',
    );
    await t.pump();

    // Home address (typed here, saved with the profile), then Home
    await addHomeAddress(t);
    await t.tap(find.byKey(const Key('profile_continue_btn')));
    await t.pumpAndSettle();
    expect(profiles.createCalls, 1);
    expect(addresses.createCalls, 1);
    expect(find.byKey(const Key('nav_home')), findsOneWidget);
  });
}
