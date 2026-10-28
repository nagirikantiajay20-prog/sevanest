import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/features/authentication/data/auth_repository_demo.dart';
import 'package:sevanest_customer/features/authentication/presentation/providers/auth_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fakes.dart';

const _mobile = Key('login_mobile_field');
const _getOtp = Key('login_get_otp_btn');
const _otpField = Key('otp_input_field');
const _verify = Key('otp_verify_btn');
const _demoCode = Key('otp_demo_code');

void main() {
  late InMemorySessionStore store;

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> launchAndRequest(WidgetTester t, String number) async {
    useTestPhone(t);
    store = InMemorySessionStore();
    await t.pumpWidget(testRootApp(store: store, repo: AuthRepositoryDemo()));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(_mobile), number);
    await t.pump();
    await t.tap(find.byKey(_getOtp));
    await t.pumpAndSettle();
  }

  String shownCode(WidgetTester t) =>
      t.widget<Text>(find.byKey(_demoCode)).data!;

  Future<void> verifyWith(WidgetTester t, String code) async {
    await t.enterText(find.byKey(_otpField), code);
    await t.pump();
    await t.tap(find.byKey(_verify));
    await t.pump();
    await t.pump(verifiedHold);
    await t.pumpAndSettle();
  }

  testWidgets('random 6-digit code is shown on the OTP screen', (t) async {
    await launchAndRequest(t, '9876543210');
    expect(shownCode(t), matches(RegExp(r'^\d{6}$')));
  });

  testWidgets('wrong code -> error, stays on OTP, no session', (t) async {
    await launchAndRequest(t, '9876543210');
    final wrong = shownCode(t) == '111111' ? '222222' : '111111';
    await verifyWith(t, wrong);
    expect(
      find.text("That code isn't correct. Please try again."),
      findsOneWidget,
    );
    expect(find.text('Verify your number'), findsOneWidget);
    expect(await store.read(), isNull);
  });

  testWidgets(
    'new customer -> profile + address -> home; same number again -> home',
    (t) async {
      await launchAndRequest(t, '9876543210');
      await verifyWith(t, shownCode(t));
      expect(find.byKey(const Key('profile_continue_btn')), findsOneWidget);
      expect(await store.read(), isNotNull);

      await t.enterText(
        find.byKey(const Key('profile_name_field')),
        'Priya Rao',
      );
      await t.enterText(
        find.byKey(const Key('profile_email_field')),
        'priya@example.com',
      );
      await t.pump();
      await addHomeAddress(t);
      await t.tap(find.byKey(const Key('profile_continue_btn')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('home_find_worker_btn')), findsOneWidget);
      expect(await store.read(), isNotNull);

      // Log in again with the same number (new session): now an existing customer.
      await t.pumpWidget(const SizedBox());
      await launchAndRequest(t, '9876543210');
      await verifyWith(t, shownCode(t));
      expect(find.byKey(const Key('home_find_worker_btn')), findsOneWidget);
    },
  );

  testWidgets('a different number is a new customer', (t) async {
    await launchAndRequest(t, '9876543210');
    await verifyWith(t, shownCode(t));
    // 9876543210 has no saved profile yet, so a different number is new as well.
    await t.pumpWidget(const SizedBox());
    await launchAndRequest(t, '9123456780');
    await verifyWith(t, shownCode(t));
    expect(find.byKey(const Key('profile_continue_btn')), findsOneWidget);
  });

  test('code expires after 5 minutes', () async {
    var now = DateTime(2026);
    final repo = AuthRepositoryDemo(now: () => now);
    final c = await repo.requestOtp('9876543210');
    now = now.add(const Duration(minutes: 6));
    expect(
      () => repo.verifyOtp('9876543210', c.otp!),
      throwsA(isA<OtpFailure>()),
    );
  });
}
