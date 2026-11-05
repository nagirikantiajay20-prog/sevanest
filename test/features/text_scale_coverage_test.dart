// Gap-closing widget tests: worker reviews empty state, and OTP / Budget / Start date / Confirm
// worker at text scale 1.3 (no overflow, primary action reachable and >= 44 dp).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/features/service_discovery/domain/catalog.dart';
import 'package:sevanest_customer/features/service_discovery/domain/timing.dart';

import '../helpers/discover_harness.dart';
import '../helpers/fakes.dart';

Finder k(String key) => find.byKey(Key(key));

void _scale(WidgetTester t, [double s = 1.3]) {
  t.platformDispatcher.textScaleFactorTestValue = s;
  addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
}

Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 3; i++) {
    await t.pumpAndSettle();
    await t.pump(const Duration(seconds: 1));
  }
  await t.pumpAndSettle();
}

void _noThrow(WidgetTester t) {
  final e = t.takeException();
  if (e != null) fail(e is FlutterError ? e.toStringDeep() : e.toString());
}

void main() {
  testWidgets('worker reviews: empty state with a way back to the profile', (
    t,
  ) async {
    final env = await launchDiscover(t);
    await env.go('/workers/cook-1');
    await settle(t);
    await env.go('/workers/cook-1/reviews'); // unrated worker: no reviews
    await settle(t);
    _noThrow(t);
    expect(find.text('No reviews yet'), findsOneWidget);
    expect(k('reviews_back_to_profile_btn'), findsOneWidget);
    await env.tapKey('reviews_back_to_profile_btn');
    await settle(t);
    expect(env.where, '/workers/cook-1');
  });

  testWidgets('OTP at 1.3: no overflow, input and Verify reachable', (t) async {
    _scale(t);
    useTestPhone(t);
    final repo = FakeAuthRepository();
    await t.pumpWidget(testRootApp(store: InMemorySessionStore(), repo: repo));
    await t.pumpAndSettle();
    await t.enterText(
      find.byKey(const Key('login_mobile_field')),
      '9876543210',
    );
    await t.pump();
    await t.tap(find.byKey(const Key('login_get_otp_btn')));
    await t.pumpAndSettle();
    expect(k('otp_input_field'), findsOneWidget);
    _noThrow(t);
    await t.ensureVisible(k('otp_verify_btn'));
    expect(t.getSize(k('otp_verify_btn')).height, greaterThanOrEqualTo(44));
  });

  Future<DiscoverEnv> draftEnv(WidgetTester t, {required String route}) async {
    final env = await launchDiscover(t, height: 1600);
    env.stepsOneToThree(EngagementType.partTime);
    env.draftNotifier
      ..setTiming(
        const Timing(
          window: TimeWindow.morning,
          startMinutes: 480,
          endMinutes: 720,
          days: {1, 2, 3, 4, 5, 6},
        ),
      )
      ..setStartDate(DateTime(2026, 10, 12));
    await env.go(route);
    return env;
  }

  testWidgets('Budget at 1.3: no overflow, Continue enabled and >= 44 dp', (
    t,
  ) async {
    _scale(t);
    final env = await draftEnv(t, route: '/discover/budget');
    _noThrow(t);
    expect(k('discover_budget_min_field'), findsOneWidget);
    expect(env.nextEnabled, isTrue);
    expect(t.getSize(k('discover_next_btn')).height, greaterThanOrEqualTo(44));
  });

  testWidgets('Start date at 1.3: no overflow, a day can be picked', (t) async {
    _scale(t);
    final env = await launchDiscover(t, height: 1600);
    env.stepsOneToThree(EngagementType.partTime);
    env.draftNotifier.setTiming(
      const Timing(
        window: TimeWindow.morning,
        startMinutes: 480,
        endMinutes: 720,
        days: {1, 2, 3, 4, 5, 6},
      ),
    );
    await env.go('/discover/start-date');
    _noThrow(t);
    expect(env.nextEnabled, isFalse);
    await env.tapKey('discover_shortcut_tomorrow');
    _noThrow(t);
    expect(env.nextEnabled, isTrue);
    expect(t.getSize(k('discover_next_btn')).height, greaterThanOrEqualTo(44));
  });

  testWidgets('Confirm worker at 1.3: no overflow, Confirm reachable', (
    t,
  ) async {
    _scale(t);
    final env = await launchDiscover(t, height: 2400);
    env.stepsOneToThree(EngagementType.fullTime);
    await env.go('/bookings/confirm?interviewId=iv_302');
    await settle(t);
    _noThrow(t);
    expect(k('confirm_worker_card'), findsOneWidget);
    await t.ensureVisible(k('confirm_pay_btn'));
    expect(t.getSize(k('confirm_pay_btn')).height, greaterThanOrEqualTo(44));
  });
}
