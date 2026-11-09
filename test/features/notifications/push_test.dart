// Module 13: push lifecycle. NOT-05 (token on sign-in, on refresh, dropped on logout), NOT-06 (the
// permission pre-prompt), NOT-07 (permission denied: the app works, Account says Off).
// Firebase itself cannot run here (no config files): everything goes through the fake PushService.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/session/auth_state.dart';
import 'package:sevanest_customer/features/notifications/domain/push_service.dart';
import 'package:sevanest_customer/features/notifications/presentation/providers/notification_providers.dart';
import 'package:sevanest_customer/features/notifications/presentation/providers/push_providers.dart';
import 'package:sevanest_customer/features/notifications/presentation/push_prompt.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/discover_harness.dart';
import '../../helpers/fakes.dart';
import '../../helpers/notification_fakes.dart';

Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 3; i++) {
    await t.pumpAndSettle();
    await t.pump(const Duration(seconds: 1));
  }
  await t.pumpAndSettle();
}

class _Signed extends AuthNotifier {
  @override
  AuthStatus build() => AuthStatus.authenticated;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Finder k(String key) => find.byKey(Key(key));

  group('NOT-05 device token', () {
    testWidgets('registered after sign-in once permission is granted', (
      t,
    ) async {
      final push = FakePushService(state: PushPermission.granted);
      final repo = FakeNotificationRepository();
      await launchDiscover(t, push: push, notifications: repo);
      await settle(t);
      expect(push.startCalls, 1);
      expect(repo.registered, [(token: 'tok-1', platform: 'ANDROID')]);
      expect(push.requestCalls, 0); // never asked at launch
    });

    testWidgets('nothing is registered without permission', (t) async {
      final push = FakePushService()..allowResult = PushPermission.denied;
      final repo = FakeNotificationRepository();
      await launchDiscover(t, push: push, notifications: repo);
      await settle(t);
      expect(repo.registered, isEmpty);
      expect(push.requestCalls, 1); // the OS dialog only, asked once
    });

    testWidgets('a refreshed token is registered again, the same one is not', (
      t,
    ) async {
      final push = FakePushService(state: PushPermission.granted);
      final repo = FakeNotificationRepository();
      await launchDiscover(t, push: push, notifications: repo);
      await settle(t);
      push.refresh.add('tok-2');
      await settle(t);
      push.refresh.add('tok-2');
      await settle(t);
      expect(repo.registered.map((e) => e.token), ['tok-1', 'tok-2']);
    });

    testWidgets('a failed write is not fatal and is tried again later', (
      t,
    ) async {
      final push = FakePushService(state: PushPermission.granted);
      final repo = FakeNotificationRepository()
        ..registerFails = const NetworkFailure();
      await launchDiscover(t, push: push, notifications: repo);
      await settle(t);
      expect(repo.registered, isEmpty);
      repo.registerFails = null;
      push.refresh.add('tok-1');
      await settle(t);
      expect(repo.registered.length, 1);
    });

    testWidgets('logout drops the device token before the session is cleared', (
      t,
    ) async {
      final push = FakePushService(state: PushPermission.granted);
      final auth = FakeAuthRepository();
      final order = <String>[];
      auth.onLogout = () async => order.add('logout:${push.unregisterCalls}');
      useTestPhone(t);
      t.view.physicalSize = const Size(1170, 4200); // the Account list is long
      await t.pumpWidget(
        testRootApp(
          store: InMemorySessionStore((access: 'a', refresh: 'r')),
          repo: auth,
          push: push,
        ),
      );
      await settle(t);
      GoRouter.of(t.element(find.byType(Scaffold).first)).go('/account');
      await settle(t);
      await t.tap(k('account_logout_btn'));
      await settle(t);
      await t.tap(k('account_logout_confirm_btn'));
      await settle(t);
      expect(push.unregisterCalls, 1);
      // unregister ran first: by the time POST /auth/logout ran the count was already 1.
      expect(order, ['logout:1']);
      expect(k('login_mobile_field'), findsOneWidget);
    });

    testWidgets('the token is bound again after the next sign-in', (t) async {
      final push = FakePushService(state: PushPermission.granted);
      final repo = FakeNotificationRepository();
      final c = ProviderContainer(
        overrides: [
          pushServiceProvider.overrideWithValue(push),
          notificationRepositoryProvider.overrideWithValue(repo),
          authProvider.overrideWith(_Signed.new),
        ],
      );
      addTearDown(c.dispose);
      final ctl = c.read(pushControllerProvider);
      await ctl.registerIfAllowed();
      await ctl.registerIfAllowed(); // same token: no second write
      expect(repo.registered.length, 1);
      await ctl.unregister();
      expect(push.unregisterCalls, 1);
      await ctl.registerIfAllowed(); // a new session binds it again
      expect(repo.registered.length, 2);
    });

    testWidgets('signed out: nothing is registered', (t) async {
      final push = FakePushService(state: PushPermission.granted);
      final repo = FakeNotificationRepository();
      final c = ProviderContainer(
        overrides: [
          pushServiceProvider.overrideWithValue(push),
          notificationRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(c.dispose);
      await c.read(pushControllerProvider).registerIfAllowed();
      expect(repo.registered, isEmpty);
    });
  });

  group('NOT-06 single native permission request', () {
    late FakePushService push;
    late FakeNotificationRepository repo;
    late ProviderContainer c;

    setUp(() {
      push = FakePushService();
      repo = FakeNotificationRepository();
      c = ProviderContainer(
        overrides: [
          pushServiceProvider.overrideWithValue(push),
          notificationRepositoryProvider.overrideWithValue(repo),
          authProvider.overrideWith(_Signed.new),
        ],
      );
      addTearDown(c.dispose);
    });

    Future<void> ask() => askForPushAfterAction(c.read(pushControllerProvider));

    test(
      'asks the OS once, with no custom dialog, and binds the token',
      () async {
        await ask();
        expect(push.requestCalls, 1);
        expect(repo.registered.length, 1);
      },
    );

    test('denied: no token, and never requested again', () async {
      push.allowResult = PushPermission.denied;
      await ask();
      expect(push.requestCalls, 1);
      expect(repo.registered, isEmpty);
      await ask();
      expect(push.requestCalls, 1);
    });

    test(
      'undecided but already requested before: not requested again',
      () async {
        await c.read(pushPromptStoreProvider).markAsked();
        await ask();
        expect(push.requestCalls, 0);
      },
    );

    test('already granted or unavailable: nothing requested', () async {
      push.state = PushPermission.granted;
      await ask();
      push.state = PushPermission.unavailable;
      await ask();
      expect(push.requestCalls, 0);
    });
  });

  group('NOT-07 permission denied', () {
    testWidgets('Account shows Off with a button to the system settings', (
      t,
    ) async {
      final push = FakePushService(state: PushPermission.denied);
      final env = await launchDiscover(t, push: push);
      await env.go('/account');
      await settle(t);
      expect(find.text('Off'), findsOneWidget);
      expect(k('notif_open_settings_btn'), findsOneWidget);
      // The app itself works.
      expect(k('account_profile_btn'), findsOneWidget);
      await t.tap(k('notif_open_settings_btn'));
      await t.pump();
      expect(push.settingsCalls, 1);
    });

    testWidgets('granted reads On and has no settings button', (t) async {
      final env = await launchDiscover(
        t,
        push: FakePushService(state: PushPermission.granted),
      );
      await env.go('/account');
      await settle(t);
      expect(find.text('On'), findsOneWidget);
      expect(k('notif_open_settings_btn'), findsNothing);
    });

    testWidgets('not asked yet reads "Not turned on"', (t) async {
      // The OS dialog was dismissed without an answer: still undecided.
      final env = await launchDiscover(
        t,
        push: FakePushService()..allowResult = PushPermission.notDetermined,
      );
      await env.go('/account');
      await settle(t);
      expect(find.text('Not turned on'), findsOneWidget);
    });

    testWidgets(
      'without Firebase the Account row shows no status and no button',
      (t) async {
        final env = await launchDiscover(
          t,
          push: FakePushService(state: PushPermission.unavailable),
        );
        await env.go('/account');
        await settle(t);
        expect(k('account_notifications_btn'), findsOneWidget);
        expect(k('account_notifications_status'), findsNothing);
        expect(k('notif_open_settings_btn'), findsNothing);
      },
    );
  });
}
