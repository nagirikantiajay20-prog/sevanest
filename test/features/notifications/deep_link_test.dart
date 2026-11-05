// Module 13: deep links and the foreground banner. NOT-08 (signed out: sign in, then the target),
// NOT-09 (a missing target says so, with a way Home), NOT-10 (the entity is read fresh, not taken
// from the payload), cold start, background tap, foreground arrival (a banner, never a jump).
// A real device is needed for the Firebase side (NOT-11): see docs/PROGRESS.md.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/features/notifications/domain/push_service.dart';
import 'package:sevanest_customer/features/notifications/presentation/providers/notification_prefs.dart';
import 'package:sevanest_customer/features/notifications/presentation/providers/push_providers.dart';
import 'package:sevanest_customer/features/support/domain/support.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/discover_harness.dart';
import '../../helpers/fakes.dart';
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

PushMessage msgFor(String type, String id, {String? mid}) => PushMessage(
  id: mid,
  title: 'Booking confirmed',
  body: 'Your booking is confirmed.',
  data: {
    'route': {'type': type, 'id': id},
  },
);

void main() {
  late FakePushService push;
  late FakeSupportRepository support;
  late FakeNotificationRepository inbox;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    push = FakePushService(state: PushPermission.granted);
    support = FakeSupportRepository()..tickets = [ticket('tk_1')];
    inbox = FakeNotificationRepository()..unreadFails = false;
  });

  Future<DiscoverEnv> open(WidgetTester t) async {
    final env = await launchDiscover(
      t,
      height: 1400,
      push: push,
      support: support,
      notifications: inbox,
    );
    await settle(t);
    return env;
  }

  group('foreground arrival', () {
    testWidgets('a banner and a fresh unread count, no automatic navigation', (
      t,
    ) async {
      final env = await open(t);
      final before = inbox.unreadCalls;
      push.foreground.add(msgFor('ticket', 'tk_1', mid: 'm1'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byKey(const Key('notif_banner_1')), findsOneWidget);
      expect(find.text('Booking confirmed'), findsOneWidget);
      expect(env.where, '/home'); // never jumps
      await settle(t);
      expect(inbox.unreadCalls, greaterThan(before));
    });

    testWidgets(
      'a muted category shows no banner but still refreshes the count',
      (t) async {
        final env = await open(t);
        await env.container
            .read(mutedCategoriesProvider.notifier)
            .setEnabled('support', enabled: false);
        final before = inbox.unreadCalls;
        push.foreground.add(msgFor('ticket', 'tk_1', mid: 'm1'));
        await t.pump();
        await t.pump(const Duration(milliseconds: 400));
        expect(find.byKey(const Key('notif_banner_1')), findsNothing);
        await settle(t);
        expect(inbox.unreadCalls, greaterThan(before));
        // another category still shows
        push.foreground.add(msgFor('booking', 'bk_1', mid: 'm2'));
        await t.pump();
        await t.pump(const Duration(milliseconds: 400));
        expect(find.byKey(const Key('notif_banner_1')), findsOneWidget);
      },
    );

    testWidgets('tapping the banner opens the target', (t) async {
      final env = await open(t);
      push.foreground.add(msgFor('ticket', 'tk_1'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
      await t.tap(find.text('Booking confirmed'));
      await settle(t);
      expect(env.where, '/support/tk_1');
    });

    testWidgets('the banner goes by itself, or with Close', (t) async {
      await open(t);
      push.foreground.add(msgFor('booking', 'bk_2048'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
      expect(find.text('Booking confirmed'), findsOneWidget);
      await t.pump(const Duration(seconds: 7));
      expect(find.text('Booking confirmed'), findsNothing);
      push.foreground.add(msgFor('booking', 'bk_2048'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
      await t.tap(k('notif_banner_close_btn'));
      await t.pump();
      expect(find.text('Booking confirmed'), findsNothing);
      await t.pump(const Duration(seconds: 7));
    });

    testWidgets('an open ticket is read again when the push arrives (NOT-10)', (
      t,
    ) async {
      final env = await open(t);
      await env.go('/support/tk_1');
      await settle(t);
      expect(find.text('Open'), findsOneWidget);
      final before = support.getCalls;
      support.tickets = [
        ticket('tk_1', status: TicketStatus.closed, resolution: 'Sorted out'),
      ];
      push.foreground.add(msgFor('ticket', 'tk_1'));
      await t.pump();
      await settle(t);
      expect(support.getCalls, greaterThan(before));
      expect(find.text('Sorted out'), findsOneWidget);
      await t.pump(const Duration(seconds: 7));
    });
  });

  group('tapping a notification', () {
    testWidgets(
      'delivery is acked: RECEIVED in the foreground, TAPPED on tap',
      (t) async {
        await open(t);
        const withId = {
          'notificationId': 'n1',
          'routeType': 'booking',
          'routeId': 'bk_1',
        };
        push.foreground.add(
          const PushMessage(title: 'T', body: 'B', data: withId),
        );
        await settle(t);
        push.opened.add(const PushMessage(title: 'T', body: 'B', data: withId));
        await settle(t);
        expect(inbox.acks.map((a) => (a.id, a.status)), [
          ('n1', 'RECEIVED'),
          ('n1', 'TAPPED'),
        ]);
      },
    );

    testWidgets('from the background: the target opens over Home', (t) async {
      final env = await open(t);
      push.opened.add(msgFor('ticket', 'tk_1'));
      await settle(t);
      expect(env.where, '/support/tk_1');
      // Back goes Home, not out of the app.
      await t.pageBack();
      await settle(t);
      expect(env.where, '/home');
    });

    testWidgets(
      'cold start: the launching notification opens after the splash',
      (t) async {
        useTestPhone(t);
        push.initial = msgFor('booking', 'bk_2048');
        final auth = FakeAuthRepository()..onProfile = () async => true;
        await t.pumpWidget(
          testRootApp(
            store: InMemorySessionStore((access: 'a', refresh: 'r')),
            repo: auth,
            push: push,
            support: support,
            notifications: inbox,
          ),
        );
        await settle(t);
        final env = DiscoverEnv(
          t,
          ProviderScope.containerOf(t.element(find.byType(MaterialApp).first)),
        );
        expect(env.where, '/bookings/bk_2048');
        await t.pageBack();
        await settle(t);
        expect(env.where, '/home');
      },
    );

    testWidgets('an unknown type opens the centre, a missing id too', (
      t,
    ) async {
      final env = await open(t);
      push.opened.add(const PushMessage(data: {'type': 'promo'}));
      await settle(t);
      expect(env.where, '/notifications');
      await t.pageBack();
      await settle(t);
      push.opened.add(
        const PushMessage(
          data: {
            'route': {'type': 'booking'},
          },
        ),
      );
      await settle(t);
      expect(env.where, '/notifications');
    });

    testWidgets('a payload without a route never crashes', (t) async {
      final env = await open(t);
      push.opened.add(const PushMessage());
      await settle(t);
      expect(env.where, '/notifications');
    });
  });

  group('NOT-09 / NOT-10 the entity is read first', () {
    testWidgets(
      'a target that is not there: "This item isn\'t available" and Home',
      (t) async {
        final env = await open(t);
        push.opened.add(msgFor('ticket', 'tk_gone'));
        await settle(t);
        expect(k('link_unavailable'), findsOneWidget);
        expect(find.text("This item isn't available"), findsOneWidget);
        await t.tap(k('link_home_btn'));
        await settle(t);
        expect(env.where, '/home');
      },
    );

    testWidgets('someone else\'s item (403) reads the same', (t) async {
      support.getFail = const ForbiddenFailure();
      await open(t);
      push.opened.add(msgFor('ticket', 'tk_1'));
      await settle(t);
      expect(k('link_unavailable'), findsOneWidget);
    });

    testWidgets('every entity type is probed: a missing one is unavailable', (
      t,
    ) async {
      await open(t);
      for (final type in ['booking', 'payment', 'replacement', 'interview']) {
        push.opened.add(msgFor(type, 'does-not-exist-1'));
        await settle(t);
        expect(k('link_unavailable'), findsOneWidget, reason: type);
        await t.tap(k('link_home_btn'));
        await settle(t);
      }
    });

    testWidgets('an existing entity opens, read fresh (not from the payload)', (
      t,
    ) async {
      final env = await open(t);
      support.tickets = [
        ticket('tk_1', status: TicketStatus.closed, resolution: 'Fixed today'),
      ];
      push.opened.add(
        const PushMessage(
          title: 'Ticket still open',
          data: {
            'route': {'type': 'ticket', 'id': 'tk_1'},
            'status': 'OPEN',
          },
        ),
      );
      await settle(t);
      expect(env.where, '/support/tk_1');
      // The screen shows the server's state, not the payload's.
      expect(find.text('Fixed today'), findsOneWidget);
      // Once for the check, once for the screen.
      expect(support.getCalls, greaterThanOrEqualTo(2));
    });

    testWidgets('offline: the check says so and Retry opens it', (t) async {
      support.getFail = const NetworkFailure();
      await open(t);
      push.opened.add(msgFor('ticket', 'tk_1'));
      await settle(t);
      expect(k('link_error'), findsOneWidget);
      expect(k('link_unavailable'), findsNothing);
      support.getFail = null;
      await t.tap(k('error_retry_btn'));
      await settle(t);
      expect(find.text('Open'), findsOneWidget);
    });
  });

  group('NOT-08 signed out', () {
    testWidgets('sign in first, then the target opens', (t) async {
      useTestPhone(t);
      push.initial = msgFor('ticket', 'tk_1');
      final auth = FakeAuthRepository()..onProfile = () async => true;
      await t.pumpWidget(
        testRootApp(
          store: InMemorySessionStore(),
          repo: auth,
          push: push,
          support: support,
          notifications: inbox,
        ),
      );
      await settle(t);
      // Signed out: the sign-in screen, nothing opened.
      expect(k('login_mobile_field'), findsOneWidget);
      expect(k('ticket_title'), findsNothing);
      await t.enterText(k('login_mobile_field'), '9876543210');
      await t.pump();
      await t.tap(k('login_get_otp_btn'));
      await t.pumpAndSettle();
      await t.enterText(k('otp_input_field'), '123456');
      await t.pump();
      await t.tap(k('otp_verify_btn'));
      await t.pump();
      await t.pump(const Duration(seconds: 1));
      await settle(t);
      expect(k('ticket_title'), findsOneWidget);
      // Back from it is Home.
      await t.pageBack();
      await settle(t);
      expect(k('home_find_worker_btn'), findsOneWidget);
    });

    testWidgets('a banner is not shown while signed out', (t) async {
      useTestPhone(t);
      final auth = FakeAuthRepository();
      await t.pumpWidget(
        testRootApp(
          store: InMemorySessionStore(),
          repo: auth,
          push: push,
          support: support,
          notifications: inbox,
        ),
      );
      await settle(t);
      push.foreground.add(msgFor('ticket', 'tk_1'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
      expect(find.text('Booking confirmed'), findsNothing);
    });
  });
}

class _FakeDisplay implements PushDisplay {
  _FakeDisplay({this.shows = true});
  final bool shows;
  final shown = <PushMessage>[];
  final tap = StreamController<PushMessage>.broadcast();
  @override
  Future<bool> show(PushMessage m) async {
    if (shows) shown.add(m);
    return shows;
  }

  @override
  Stream<PushMessage> get onTap => tap.stream;
}

void displayTests() {
  const msg = PushMessage(
    title: 'Hi',
    body: 'There',
    data: {'notificationId': 'n1', 'routeType': 'booking', 'routeId': 'b1'},
  );

  Future<(DiscoverEnv, FakeNotificationRepository, FakePushService)> boot(
    WidgetTester t,
    PushDisplay display,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final push = FakePushService(state: PushPermission.granted);
    final inbox = FakeNotificationRepository()..unreadFails = false;
    final env = await launchDiscover(
      t,
      height: 1400,
      push: push,
      notifications: inbox,
      overrides: [pushDisplayProvider.overrideWithValue(display)],
    );
    await settle(t);
    return (env, inbox, push);
  }

  testWidgets(
    'foreground: system notification, RECEIVED then DISPLAYED once, no banner',
    (t) async {
      final d = _FakeDisplay();
      final (_, inbox, push) = await boot(t, d);
      push.foreground
        ..add(msg)
        ..add(msg);
      await settle(t);
      expect(d.shown, hasLength(2));
      expect(find.byKey(const Key('notif_banner_1')), findsNothing);
      expect(inbox.acks.map((a) => a.status), ['RECEIVED', 'DISPLAYED']);
    },
  );

  testWidgets('foreground: display refused -> banner, no DISPLAYED ack', (
    t,
  ) async {
    final (_, inbox, push) = await boot(t, _FakeDisplay(shows: false));
    push.foreground.add(msg);
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('notif_banner_1')), findsOneWidget);
    expect(inbox.acks.map((a) => a.status), ['RECEIVED']);
  });

  testWidgets(
    'tapping the system notification acks TAPPED and opens the target',
    (t) async {
      final d = _FakeDisplay();
      final (env, inbox, _) = await boot(t, d);
      d.tap.add(msg);
      await settle(t);
      expect(inbox.acks.map((a) => a.status), ['TAPPED']);
      expect(env.where, isNot('/home'));
    },
  );
}
