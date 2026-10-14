// Module 14: Account & Settings. ACC-01..07 (ACC-08, legal links open on both platforms, is manual).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/features/customer_profile/domain/customer_profile.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/providers/account_providers.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/providers/customer_profile_providers.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/screens/account_screen.dart';
import 'package:sevanest_customer/features/notifications/domain/push_service.dart';

import '../../helpers/discover_harness.dart';
import '../../helpers/fakes.dart';
import '../../helpers/notification_fakes.dart';

const _profile = CustomerProfile(
  name: 'Asha Rao',
  email: 'asha@example.com',
  preferredLanguage: 'en',
  mobile: '+919999900002',
  verificationStatus: 'VERIFIED',
);

Finder k(String key) => find.byKey(Key(key));

Future<DiscoverEnv> open(
  WidgetTester t, {
  PushService? push,
  FakeProfileRepository? profiles,
  List<Override> overrides = const [],
}) async {
  final env = await launchDiscover(
    t,
    height: 1400,
    push: push,
    profiles: profiles ?? FakeProfileRepository(_profile),
    overrides: overrides,
  );
  await env.tapKey('nav_account');
  return env;
}

void main() {
  group('ACC-01 each row opens its exact route', () {
    // Pushed routes sit on top of the tab; Shortlist and Bookings switch tab.
    const rows = {
      'account_profile_btn': '/profile',
      'account_addresses_btn': '/addresses',
      'account_favourites_btn': '/favourites',
      'account_bookings_btn': '/bookings',
      'account_interviews_btn': '/interviews',
      'account_history_btn': '/services/history',
      'account_transactions_btn': '/transactions',
      'account_support_btn': '/support',
      'account_notifications_btn': '/notifications',
    };
    for (final MapEntry(key: key, value: route) in rows.entries) {
      testWidgets('$key -> $route', (t) async {
        final env = await open(t);
        await env.tapKey(key);
        expect(env.where, route);
        // Let the opened screen's loading timers finish.
        await t.pumpWidget(const SizedBox());
        await t.pump(const Duration(seconds: 5));
      });
    }
  });

  testWidgets(
    'ACC-02 the Language row is hidden while only English is enabled',
    (t) async {
      await open(t);
      expect(k('account_language_btn'), findsNothing);
    },
  );

  testWidgets(
    'ACC-02b the Language row shows when more languages are enabled',
    (t) async {
      await open(
        t,
        overrides: [
          accountConfigProvider.overrideWith(
            (ref) async => const AccountConfig(languages: ['en', 'hi']),
          ),
        ],
      );
      expect(k('account_language_btn'), findsOneWidget);
    },
  );

  group('Log out', () {
    testWidgets(
      'ACC-03 Cancel stays; Confirm clears the session and opens /login',
      (t) async {
        await open(t);
        await t.tap(k('account_logout_btn'));
        await t.pumpAndSettle();
        await t.tap(k('account_logout_cancel_btn'));
        await t.pumpAndSettle();
        expect(k('account_logout_btn'), findsOneWidget);

        await t.tap(k('account_logout_btn'));
        await t.pumpAndSettle();
        await t.tap(k('account_logout_confirm_btn'));
        await t.pumpAndSettle();
        expect(k('login_mobile_field'), findsOneWidget);
        expect(k('account_logout_btn'), findsNothing);
      },
    );

    testWidgets('ACC-04 Back cannot return to Account or Home', (t) async {
      await open(t);
      await t.tap(k('account_logout_btn'));
      await t.pumpAndSettle();
      await t.tap(k('account_logout_confirm_btn'));
      await t.pumpAndSettle();
      final router = GoRouter.of(t.element(find.byType(Scaffold).first));
      expect(router.canPop(), isFalse);
      await t.binding.handlePopRoute();
      await t.pumpAndSettle();
      expect(k('login_mobile_field'), findsOneWidget);
      expect(k('account_logout_btn'), findsNothing);
      expect(k('home_find_worker_btn'), findsNothing);
    });

    testWidgets('a failing server logout still clears the local session', (
      t,
    ) async {
      final auth = FakeAuthRepository()
        ..onProfile = (() async => true)
        ..onLogout = () async => throw Exception('offline');
      useTestPhone(t);
      t.view.physicalSize = const Size(1170, 4200);
      await t.pumpWidget(
        testRootApp(
          store: InMemorySessionStore((access: 'a', refresh: 'r')),
          repo: auth,
          overrides: [
            customerProfileRepositoryProvider.overrideWithValue(
              FakeProfileRepository(_profile),
            ),
          ],
        ),
      );
      await t.pumpAndSettle();
      await t.tap(k('nav_account'));
      await t.pumpAndSettle();
      await t.ensureVisible(k('account_logout_btn'));
      await t.tap(k('account_logout_btn'));
      await t.pumpAndSettle();
      await t.tap(k('account_logout_confirm_btn'));
      await t.pumpAndSettle();
      expect(k('login_mobile_field'), findsOneWidget);
    });

    testWidgets(
      'ACC-07 all providers are reset: the next user sees nothing of the last one',
      (t) async {
        final profiles = FakeProfileRepository(_profile);
        final env = await open(t, profiles: profiles);
        // First user's data is loaded in the live scope.
        expect(k('account_name'), findsOneWidget);
        expect(env.container.read(profileProvider).value?.name, 'Asha Rao');
        final before = env.container;

        await t.tap(k('account_logout_btn'));
        await t.pumpAndSettle();
        await t.tap(k('account_logout_confirm_btn'));
        await t.pumpAndSettle();

        // A brand-new scope: nothing is carried over.
        final after = ProviderScope.containerOf(
          t.element(find.byKey(const Key('login_mobile_field'))),
        );
        expect(identical(before, after), isFalse);
        expect(after.read(profileProvider).hasValue, isFalse);
        expect(find.text('Asha Rao'), findsNothing);
      },
    );
  });

  group('Header', () {
    testWidgets(
      'ACC-05 the mobile is masked; the verification chip is read-only',
      (t) async {
        await open(t);
        expect(find.text(maskMobile('+919999900002')), findsOneWidget);
        expect(find.textContaining('9999900'), findsNothing);
        expect(k('account_name'), findsOneWidget);
        expect(find.text('AR'), findsOneWidget);
        expect(k('account_verification_chip'), findsOneWidget);
        expect(t.widget<Chip>(k('account_verification_chip')), isA<Chip>());
        expect(find.byType(ActionChip), findsNothing);
      },
    );

    test('maskMobile keeps only the last four digits', () {
      expect(maskMobile('9999900002'), '+91 ••••••0002');
      expect(maskMobile(null), '');
    });

    testWidgets('a saved profile change updates the Account header', (t) async {
      final env = await open(t);
      await env.tapKey('account_profile_btn');
      await env.tapKey('profile_edit_btn');
      await t.enterText(k('profile_name_field'), 'Bina Rao');
      await t.pump();
      await env.tapKey('profile_save_btn');
      // Back out of /profile to the tab.
      GoRouter.of(t.element(find.byType(Scaffold).first)).pop();
      await t.pumpAndSettle();
      expect(t.widget<Text>(k('account_name')).data, 'Bina Rao');
      expect(find.text('BR'), findsOneWidget);
    });
  });

  group('Notification row', () {
    testWidgets(
      'ACC-06 the Open settings row shows only when the OS permission is denied',
      (t) async {
        final granted = FakePushService(state: PushPermission.granted);
        await open(t, push: granted);
        expect(k('notif_open_settings_btn'), findsNothing);
      },
    );

    testWidgets('ACC-06b denied: shown, and it opens the OS settings', (
      t,
    ) async {
      final push = FakePushService(state: PushPermission.denied);
      await open(t, push: push);
      expect(k('notif_open_settings_btn'), findsOneWidget);
      await t.tap(k('notif_open_settings_btn'));
      await t.pumpAndSettle();
      expect(push.settingsCalls, 1);
    });
  });

  group('Legal and About', () {
    testWidgets('no URL from /app-config: "not available yet", nothing opens', (
      t,
    ) async {
      final opened = <String>[];
      await open(
        t,
        overrides: [
          openInAppBrowserProvider.overrideWithValue((u) async {
            opened.add(u);
            return true;
          }),
        ],
      );
      await t.tap(k('account_terms_btn'));
      await t.pump();
      expect(k('account_legal_unavailable'), findsOneWidget);
      expect(opened, isEmpty);
    });

    testWidgets('URLs from /app-config open in the in-app browser', (t) async {
      final opened = <String>[];
      await open(
        t,
        overrides: [
          accountConfigProvider.overrideWith(
            (ref) async => const AccountConfig(
              termsUrl: 'https://example.test/terms',
              privacyUrl: 'https://example.test/privacy',
            ),
          ),
          openInAppBrowserProvider.overrideWithValue((u) async {
            opened.add(u);
            return true;
          }),
        ],
      );
      await t.tap(k('account_terms_btn'));
      await t.tap(k('account_privacy_btn'));
      await t.pump();
      expect(opened, [
        'https://example.test/terms',
        'https://example.test/privacy',
      ]);
      expect(k('account_legal_unavailable'), findsNothing);
    });

    testWidgets('About shows the app version in a bottom sheet', (t) async {
      await open(t);
      await t.tap(k('account_about_btn'));
      await t.pumpAndSettle();
      expect(k('account_about_version'), findsOneWidget);
    });

    testWidgets('Delete account is not offered (OPEN_QUESTIONS #18)', (
      t,
    ) async {
      await open(t);
      expect(find.textContaining('Delete', findRichText: true), findsNothing);
    });
  });
}
