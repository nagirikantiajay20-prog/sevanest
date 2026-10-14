// Module 13: push lifecycle. NOT-05 (token on sign-in, on refresh, dropped on logout), NOT-06 (the
// permission pre-prompt), NOT-07 (permission denied: the app works, Account says Off).
// Firebase itself cannot run here (no config files): everything goes through the fake PushService.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/theme/app_theme.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/services/clock.dart';
import 'package:sevanest_customer/core/session/auth_state.dart';
import 'package:sevanest_customer/features/notifications/domain/push_service.dart';
import 'package:sevanest_customer/features/notifications/presentation/providers/notification_providers.dart';
import 'package:sevanest_customer/features/notifications/presentation/providers/push_providers.dart';
import 'package:sevanest_customer/features/notifications/presentation/push_prompt.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';
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
      final push = FakePushService();
      final repo = FakeNotificationRepository();
      await launchDiscover(t, push: push, notifications: repo);
      await settle(t);
      expect(repo.registered, isEmpty);
      expect(push.requestCalls, 0);
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
      await t.tap(k('logout_confirm_btn'));
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

  group('NOT-06 permission pre-prompt', () {
    late FakePushService push;
    late FakeNotificationRepository repo;
    var nowValue = DateTime(2026, 10, 9, 10);

    Future<void> pumpHost(WidgetTester t) async {
      nowValue = DateTime(2026, 10, 9, 10);
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            pushServiceProvider.overrideWithValue(push),
            notificationRepositoryProvider.overrideWithValue(repo),
            authProvider.overrideWith(_Signed.new),
            nowProvider.overrideWithValue(() => nowValue),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Consumer(
              builder: (context, ref, _) => Scaffold(
                body: Center(
                  child: TextButton(
                    key: const Key('first_action'),
                    onPressed: () => askForPushAfterAction(
                      context,
                      ref.read(pushControllerProvider),
                    ),
                    child: const Text('go'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    setUp(() {
      push = FakePushService();
      repo = FakeNotificationRepository();
    });

    testWidgets('Allow: the OS dialog is requested and the token is bound', (
      t,
    ) async {
      await pumpHost(t);
      await t.tap(k('first_action'));
      await settle(t);
      expect(k('notif_prompt'), findsOneWidget);
      expect(find.text('Stay in the loop'), findsOneWidget);
      expect(push.requestCalls, 0); // the pre-prompt itself asks nothing
      await t.tap(k('notif_prompt_allow_btn'));
      await settle(t);
      expect(push.requestCalls, 1);
      expect(repo.registered.length, 1);
      expect(k('notif_prompt'), findsNothing);
    });

    testWidgets('Allow, but the OS says no: no token, no loop', (t) async {
      push.allowResult = PushPermission.denied;
      await pumpHost(t);
      await t.tap(k('first_action'));
      await settle(t);
      await t.tap(k('notif_prompt_allow_btn'));
      await settle(t);
      expect(push.requestCalls, 1);
      expect(repo.registered, isEmpty);
      // Denied is never asked again.
      await t.tap(k('first_action'));
      await settle(t);
      expect(k('notif_prompt'), findsNothing);
    });

    testWidgets('Later: no OS request, and the re-ask window is honoured', (
      t,
    ) async {
      await pumpHost(t);
      await t.tap(k('first_action'));
      await settle(t);
      await t.tap(k('notif_prompt_later_btn'));
      await settle(t);
      expect(push.requestCalls, 0);
      // Same day: not asked again.
      await t.tap(k('first_action'));
      await settle(t);
      expect(k('notif_prompt'), findsNothing);
      // After the window it is offered again.
      nowValue = nowValue.add(const Duration(days: 4));
      await t.tap(k('first_action'));
      await settle(t);
      expect(k('notif_prompt'), findsOneWidget);
    });

    testWidgets('dismissing the dialog counts as Later', (t) async {
      await pumpHost(t);
      await t.tap(k('first_action'));
      await settle(t);
      await t.tapAt(const Offset(5, 5));
      await settle(t);
      expect(push.requestCalls, 0);
      await t.tap(k('first_action'));
      await settle(t);
      expect(k('notif_prompt'), findsNothing);
    });

    testWidgets('already granted or unavailable: no prompt at all', (t) async {
      push.state = PushPermission.granted;
      await pumpHost(t);
      await t.tap(k('first_action'));
      await settle(t);
      expect(k('notif_prompt'), findsNothing);
      push.state = PushPermission.unavailable;
      await t.tap(k('first_action'));
      await settle(t);
      expect(k('notif_prompt'), findsNothing);
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
      expect(k('account_profile_tile'), findsOneWidget);
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
      final env = await launchDiscover(t, push: FakePushService());
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
        expect(k('account_notifications_tile'), findsOneWidget);
        expect(k('account_notifications_status'), findsNothing);
        expect(k('notif_open_settings_btn'), findsNothing);
      },
    );
  });
}
