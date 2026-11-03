// Module 13: the notification centre (NOT-02, NOT-03, NOT-04) and the Home bell badge. Widget tests
// use the design state names of screen 32.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/features/notifications/domain/notification.dart';
import 'package:sevanest_customer/features/notifications/domain/push_service.dart';
import 'package:sevanest_customer/features/notifications/presentation/providers/notification_prefs.dart';
import 'package:sevanest_customer/features/notifications/presentation/providers/notification_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/discover_harness.dart';
import '../../helpers/notification_fakes.dart';
import '../../helpers/support_fakes.dart';

Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 3; i++) {
    await t.pumpAndSettle();
    await t.pump(const Duration(seconds: 1));
  }
  await t.pumpAndSettle();
}

Finder k(String key) => find.byKey(Key(key));

final _today = DateTime(2026, 10, 9, 8);
final _yesterday = DateTime(2026, 10, 8, 18, 30);

List<AppNotification> _items() => [
  notif(
    'n1',
    title: 'Interview confirmed',
    type: 'interview',
    entity: 'iv_301',
    at: _today,
  ),
  notif(
    'n2',
    title: 'Payment successful',
    type: 'payment',
    entity: 'pay_9',
    at: _today,
  ),
  notif(
    'n3',
    title: 'Support replied',
    type: 'ticket',
    entity: 'tk_1',
    at: _today,
  ),
  notif(
    'n4',
    title: '3 alternatives ready',
    type: 'replacement',
    entity: 'rp_1',
    read: true,
    at: _yesterday,
  ),
  notif(
    'n5',
    title: 'Rate your experience',
    type: 'booking',
    entity: 'bk_2048',
    read: true,
    at: _yesterday,
  ),
];

void main() {
  late FakeNotificationRepository repo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repo = FakeNotificationRepository(_items())..unreadFails = false;
  });

  Future<DiscoverEnv> open(
    WidgetTester t, {
    FakePushService? push,
    FakeSupportRepository? support,
  }) async {
    final env = await launchDiscover(
      t,
      height: 1400,
      notifications: repo,
      push: push,
      support: support,
    );
    await env.go('/notifications');
    await settle(t);
    return env;
  }

  Future<void> tap(WidgetTester t, String key) async {
    await t.ensureVisible(k(key));
    await t.pump();
    await t.tap(k(key));
    await settle(t);
  }

  bool markAllEnabled(WidgetTester t) =>
      t.widget<TextButton>(k('notif_mark_all_btn')).onPressed != null;

  group('Settings sheet', () {
    test('routes map to categories; unknown routes are never muted', () {
      expect(notificationCategoryOfRoute('/interviews/i1'), 'bookings');
      expect(notificationCategoryOfRoute('/bookings/b1'), 'bookings');
      expect(notificationCategoryOfRoute('/payments/p1'), 'payments');
      expect(notificationCategoryOfRoute('/replacements/r1'), 'replacements');
      expect(notificationCategoryOfRoute('/support/t1'), 'support');
      expect(notificationCategoryOfRoute('/notifications'), isNull);
      expect(bannerAllowed({'support'}, '/notifications'), isTrue);
      expect(bannerAllowed({'support'}, '/support/t1'), isFalse);
    });

    testWidgets('opens from the gear; a switch mutes its category', (t) async {
      final env = await open(t);
      await tap(t, 'notif_settings_btn');
      for (final c in notificationCategories) {
        expect(t.widget<SwitchListTile>(k('notif_pref_$c')).value, isTrue);
      }
      await tap(t, 'notif_pref_payments');
      expect(t.widget<SwitchListTile>(k('notif_pref_payments')).value, isFalse);
      expect(env.container.read(mutedCategoriesProvider).value, {'payments'});
    });
  });

  group('Default / Unread tab', () {
    testWidgets('Default: grouped by day, newest first, unread styled', (
      t,
    ) async {
      await open(t);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('TODAY'), findsOneWidget);
      expect(find.text('YESTERDAY'), findsOneWidget);
      for (final id in ['n1', 'n2', 'n3', 'n4', 'n5']) {
        expect(k('notification_row_$id'), findsOneWidget);
      }
      // Unread rows have the dot; read rows do not.
      for (final id in ['n1', 'n2', 'n3']) {
        expect(k('notification_dot_$id'), findsOneWidget);
      }
      for (final id in ['n4', 'n5']) {
        expect(k('notification_dot_$id'), findsNothing);
      }
      expect(find.text('3 unread'), findsOneWidget);
      expect(
        find.descendant(of: k('notif_unread_count'), matching: find.text('3')),
        findsOneWidget,
      );
      // The order on screen follows the server's.
      expect(
        t.getTopLeft(k('notification_row_n1')).dy,
        lessThan(t.getTopLeft(k('notification_row_n5')).dy),
      );
      // The settings sheet exists (device-only switches); row actions stay out: no backend.
      expect(k('notif_settings_btn'), findsOneWidget);
    });

    testWidgets('Unread tab: only unread, then "You\'re all caught up"', (
      t,
    ) async {
      await open(t);
      await tap(t, 'notif_tab_unread');
      expect(k('notification_row_n1'), findsOneWidget);
      expect(k('notification_row_n4'), findsNothing);
      expect(k('notif_caught_up'), findsOneWidget);
      expect(repo.listCalls, greaterThanOrEqualTo(2));
    });

    testWidgets('a row without a title reads "Update"', (t) async {
      repo.items = [
        notif('x1', type: 'booking').markedRead(DateTime(2026, 10, 9)),
        AppNotification(
          id: 'x2',
          event: 'E',
          body: 'Something changed',
          createdAt: _today,
        ),
      ];
      await open(t);
      expect(find.text('Update'), findsOneWidget);
      expect(find.text('Something changed'), findsOneWidget);
    });
  });

  group('NOT-04 empty / loading / error / offline', () {
    testWidgets('Empty: "No notifications yet"', (t) async {
      repo.items = [];
      await open(t);
      expect(k('notif_empty'), findsOneWidget);
      expect(find.text('No notifications yet'), findsOneWidget);
      expect(k('notif_mark_all_btn'), findsNothing);
    });

    testWidgets(
      'All read: Mark all disabled; Unread tab says so and links back',
      (t) async {
        repo.items = [
          for (final n in repo.items) n.markedRead(DateTime(2026, 10, 9)),
        ];
        await open(t);
        expect(markAllEnabled(t), isFalse);
        expect(k('notif_unread_count'), findsNothing);
        await tap(t, 'notif_tab_unread');
        expect(k('notif_unread_empty'), findsOneWidget);
        expect(find.text('No unread notifications'), findsOneWidget);
        await tap(t, 'notif_view_all_btn');
        expect(k('notification_row_n1'), findsOneWidget);
      },
    );

    testWidgets('Loading: skeleton cards', (t) async {
      repo.gate = Completer();
      final env = await launchDiscover(t, height: 1400, notifications: repo);
      env.unawaitedPush('/notifications');
      await t.pump();
      await t.pump(const Duration(milliseconds: 500));
      expect(k('notif_loading'), findsOneWidget);
      repo.gate!.complete();
      await settle(t);
      expect(k('notif_loading'), findsNothing);
      expect(k('notification_row_n1'), findsOneWidget);
    });

    testWidgets('Error: message and Try again recovers', (t) async {
      repo.listFails = const ServerFailure();
      await open(t);
      expect(k('notif_error'), findsOneWidget);
      expect(find.text("We couldn't load your notifications"), findsOneWidget);
      expect(find.textContaining('Exception'), findsNothing);
      repo.listFails = null;
      await tap(t, 'error_retry_btn');
      expect(k('notif_error'), findsNothing);
      expect(k('notification_row_n1'), findsOneWidget);
    });

    testWidgets(
      'Offline: the loaded list stays under a banner; Retry clears it',
      (t) async {
        final env = await open(t);
        repo.listFails = const NetworkFailure();
        await t.runAsync(
          () => env.container
              .read(notificationListProvider(false).notifier)
              .refresh(),
        );
        await settle(t);
        expect(k('notif_offline_banner'), findsOneWidget);
        expect(
          find.text("You're offline. Showing saved notifications."),
          findsOneWidget,
        );
        expect(k('notification_row_n1'), findsOneWidget);
        repo.listFails = null;
        await tap(t, 'notif_offline_retry_btn');
        expect(k('notif_offline_banner'), findsNothing);
      },
    );

    testWidgets(
      'Permission off: banner with Open settings; the list still works',
      (t) async {
        final push = FakePushService(state: PushPermission.denied);
        await open(t, push: push);
        expect(k('notif_off_banner'), findsOneWidget);
        expect(find.text('Notifications are turned off'), findsOneWidget);
        expect(k('notification_row_n1'), findsOneWidget);
        await tap(t, 'notif_open_settings_btn');
        expect(push.settingsCalls, 1);
      },
    );

    testWidgets('permission granted: no banner', (t) async {
      await open(t, push: FakePushService(state: PushPermission.granted));
      expect(k('notif_off_banner'), findsNothing);
    });
  });

  group('NOT-02 tapping a row', () {
    testWidgets('marks it read, then opens the ticket', (t) async {
      final support = FakeSupportRepository()..tickets = [ticket('tk_1')];
      final env = await open(t, support: support);
      await tap(t, 'notification_row_n3');
      expect(repo.readIds, ['n3']);
      expect(repo.markReadCalls, 1);
      expect(env.where, '/support/tk_1');
      // Back to the centre: the row is read now.
      await t.pageBack();
      await settle(t);
      expect(k('notification_dot_n3'), findsNothing);
      expect(k('notification_dot_n1'), findsOneWidget);
    });

    testWidgets('an already-read row opens without another write', (t) async {
      final env = await open(t);
      await tap(t, 'notification_row_n5');
      expect(repo.markReadCalls, 0);
      expect(env.where, '/bookings/bk_2048');
    });

    testWidgets('the row turns read at once (optimistic), before the answer', (
      t,
    ) async {
      repo.markGate = Completer();
      await open(t);
      await t.tap(k('notification_row_n1'));
      await t.pump();
      await t.pump();
      expect(k('notification_dot_n1'), findsNothing); // the write is still open
      expect(repo.markReadCalls, 1);
      repo.markGate!.complete();
      await settle(t);
    });

    testWidgets('a failed write puts the row back to unread, silently', (
      t,
    ) async {
      repo.markFails = const NetworkFailure();
      await open(t);
      await t.tap(k('notification_row_n1'));
      await settle(t);
      await t.pageBack();
      await settle(t);
      expect(k('notification_dot_n1'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('a notification with no target is only marked read', (t) async {
      repo.items = [notif('z1', title: 'Hello')];
      final env = await open(t);
      await tap(t, 'notification_row_z1');
      expect(repo.markReadCalls, 1);
      expect(env.where, '/notifications');
    });

    testWidgets('an unknown type opens nothing but the centre', (t) async {
      repo.items = [notif('z1', title: 'Promo', type: 'promo_banner')];
      final env = await open(t);
      await tap(t, 'notification_row_z1');
      expect(env.where, '/notifications');
    });
  });

  group('NOT-03 Mark all as read', () {
    testWidgets('one API call, dots cleared, badge 0', (t) async {
      await open(t);
      expect(markAllEnabled(t), isTrue);
      await tap(t, 'notif_mark_all_btn');
      expect(repo.markAllCalls, 1);
      expect(find.byKey(const Key('notif_unread_count')), findsNothing);
      for (final id in ['n1', 'n2', 'n3']) {
        expect(k('notification_dot_$id'), findsNothing);
      }
      expect(markAllEnabled(t), isFalse);
      expect(await repo.unreadCount(), 0);
    });

    testWidgets('a failure keeps the dots and says why', (t) async {
      repo.markAllFails = const ServerFailure();
      await open(t);
      await tap(t, 'notif_mark_all_btn');
      expect(k('notification_dot_n1'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(markAllEnabled(t), isTrue);
    });
  });

  group('refetching', () {
    testWidgets('app resume reads the list again', (t) async {
      await open(t);
      final before = repo.listCalls;
      repo.items = [
        notif('n9', title: 'New one', type: 'booking', at: _today),
        ...repo.items,
      ];
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settle(t);
      expect(repo.listCalls, greaterThan(before));
      expect(k('notification_row_n9'), findsOneWidget);
    });

    testWidgets('a push arriving refreshes an open centre', (t) async {
      final env = await open(t);
      repo.items = [
        notif('n8', title: 'Fresh', type: 'booking', at: _today),
        ...repo.items,
      ];
      env.container.read(notificationTickProvider.notifier).bump();
      await settle(t);
      expect(k('notification_row_n8'), findsOneWidget);
    });
  });

  group('Home bell', () {
    testWidgets(
      'the badge follows the unread count and clears after Mark all',
      (t) async {
        final env = await launchDiscover(t, notifications: repo);
        await settle(t);
        expect(k('home_bell_badge'), findsOneWidget);
        await tap(t, 'home_bell_btn');
        expect(env.where, '/notifications');
        await tap(t, 'notif_mark_all_btn');
        await t.pageBack();
        await settle(t);
        expect(k('home_bell_badge'), findsNothing);
      },
    );

    testWidgets('no unread: no badge', (t) async {
      repo.items = [
        for (final n in repo.items) n.markedRead(DateTime(2026, 10, 9)),
      ];
      await launchDiscover(t, notifications: repo);
      await settle(t);
      expect(k('home_bell_badge'), findsNothing);
    });
  });
}
