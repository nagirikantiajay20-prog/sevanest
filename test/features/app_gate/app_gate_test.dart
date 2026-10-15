import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/features/app_gate/app_gate.dart';
import 'package:sevanest_customer/features/app_gate/app_gate_host.dart';

import '../../helpers/fakes.dart';

AppGate _open() => AppGate.open;

void main() {
  group('isBelowMinVersion', () {
    test('compares numerically, not as text', () {
      expect(isBelowMinVersion('1.2.3', '1.10.0'), isTrue);
      expect(isBelowMinVersion('1.10.0', '1.2.3'), isFalse);
      expect(isBelowMinVersion('0.9.9', '1.0.0'), isTrue);
    });
    test('equal is not blocked', () {
      expect(isBelowMinVersion('1.2.0', '1.2.0'), isFalse);
      expect(isBelowMinVersion('1.2.0+5', '1.2.0'), isFalse);
    });
    test('build numbers count only when both sides have one', () {
      expect(isBelowMinVersion('1.2.0+4', '1.2.0+5'), isTrue);
      expect(isBelowMinVersion('1.2.0+5', '1.2.0+5'), isFalse);
      expect(isBelowMinVersion('1.2.0+9', '1.2.0+5'), isFalse);
      expect(isBelowMinVersion('1.2.0', '1.2.0+5'), isFalse);
      expect(isBelowMinVersion('1.2.0 (4)', '1.2.0+5'), isTrue);
    });
    test('malformed or missing minVersion is not blocked', () {
      for (final m in [null, '', 'abc', '1.2', '1.2.x', 'v1.2.3', '1.2.3.4']) {
        expect(isBelowMinVersion('1.0.0', m), isFalse, reason: '$m');
      }
      expect(isBelowMinVersion('garbage', '1.0.0'), isFalse);
    });
  });

  group('AppGateHost', () {
    // The host is mounted by SevaNestApp; drive the whole app so signed-in and signed-out both run.
    Future<void> pumpApp(
      WidgetTester t, {
      required InMemorySessionStore store,
      required Future<AppGate> Function() fetch,
      List<String>? opened,
    }) async {
      useTestPhone(t);
      await t.pumpWidget(
        testRootApp(
          store: store,
          repo: FakeAuthRepository(),
          overrides: [
            appGateFetcherProvider.overrideWithValue(fetch),
            openStoreProvider.overrideWithValue((url) async {
              opened?.add(url);
              return true;
            }),
          ],
        ),
      );
      await t.pumpAndSettle();
    }

    final signedOut = InMemorySessionStore();
    InMemorySessionStore signedIn() =>
        InMemorySessionStore((access: 'a', refresh: 'r'));

    for (final inn in [false, true]) {
      testWidgets(
        'force update blocks, Back does nothing (signed ${inn ? "in" : "out"})',
        (t) async {
          final opened = <String>[];
          await pumpApp(
            t,
            store: inn ? signedIn() : InMemorySessionStore(),
            fetch: () async => const AppGate(
              AppGateKind.forceUpdate,
              storeUrl: 'https://s.example/app',
            ),
            opened: opened,
          );
          expect(find.text('Update required'), findsOneWidget);
          expect(find.byKey(const Key('login_mobile_field')), findsNothing);
          expect(find.byKey(const Key('home_find_worker_btn')), findsNothing);
          await t.binding.handlePopRoute();
          await t.pumpAndSettle();
          expect(find.text('Update required'), findsOneWidget);
          await t.tap(find.byKey(const Key('gate_update_btn')));
          expect(opened, ['https://s.example/app']);
        },
      );
    }

    testWidgets('force update without a store URL has no Update button', (
      t,
    ) async {
      await pumpApp(
        t,
        store: signedOut,
        fetch: () async => const AppGate(AppGateKind.forceUpdate),
      );
      expect(find.text('Update required'), findsOneWidget);
      expect(find.byKey(const Key('gate_update_btn')), findsNothing);
    });

    testWidgets('maintenance Retry clears it once the flag is false', (
      t,
    ) async {
      var down = true;
      await pumpApp(
        t,
        store: signedIn(),
        fetch: () async =>
            down ? const AppGate(AppGateKind.maintenance) : _open(),
      );
      expect(find.byKey(const Key('gate_retry_btn')), findsOneWidget);
      await t.tap(find.byKey(const Key('gate_retry_btn')));
      await t.pumpAndSettle();
      expect(
        find.byKey(const Key('gate_retry_btn')),
        findsOneWidget,
      ); // still down
      down = false;
      await t.tap(find.byKey(const Key('gate_retry_btn')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('gate_retry_btn')), findsNothing);
      expect(find.byKey(const Key('home_find_worker_btn')), findsOneWidget);
    });

    testWidgets('a failed launch check lets the app on', (t) async {
      await pumpApp(
        t,
        store: signedOut,
        fetch: () async => throw Exception('offline'),
      );
      expect(find.byKey(const Key('login_mobile_field')), findsOneWidget);
    });

    testWidgets('a failed Retry keeps maintenance and says so', (t) async {
      var fail = false;
      await pumpApp(
        t,
        store: signedOut,
        fetch: () async {
          if (fail) throw Exception('offline');
          return const AppGate(AppGateKind.maintenance);
        },
      );
      fail = true;
      await t.tap(find.byKey(const Key('gate_retry_btn')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('gate_retry_failed')), findsOneWidget);
      expect(find.byKey(const Key('gate_retry_btn')), findsOneWidget);
    });

    testWidgets('re-checks on resume', (t) async {
      var calls = 0;
      var down = false;
      await pumpApp(
        t,
        store: signedIn(),
        fetch: () async {
          calls++;
          return down ? const AppGate(AppGateKind.maintenance) : _open();
        },
      );
      final before = calls;
      down = true;
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await t.pumpAndSettle();
      expect(calls, greaterThan(before));
      expect(find.byKey(const Key('gate_retry_btn')), findsOneWidget);
    });
  });

  group('first-check hold', () {
    Future<void> pump(WidgetTester t, Future<AppGate> Function() fetch) async {
      useTestPhone(t);
      await t.pumpWidget(
        testRootApp(
          store: InMemorySessionStore(),
          repo: FakeAuthRepository(),
          overrides: [appGateFetcherProvider.overrideWithValue(fetch)],
        ),
      );
    }

    final login = find.byKey(
      const Key('login_mobile_field'),
      skipOffstage: false,
    );

    testWidgets(
      'blocked on launch: login never shows, not even offstage-visible',
      (t) async {
        final c = Completer<AppGate>();
        await pump(t, () => c.future);
        await t.pump(const Duration(seconds: 1));
        expect(find.byKey(const Key('gate_hold')), findsOneWidget);
        expect(find.byKey(const Key('login_mobile_field')), findsNothing);
        c.complete(const AppGate(AppGateKind.forceUpdate));
        await t.pumpAndSettle();
        expect(find.text('Update required'), findsOneWidget);
        expect(find.byKey(const Key('gate_hold')), findsNothing);
        expect(find.byKey(const Key('login_mobile_field')), findsNothing);
        expect(login, findsOneWidget); // still mounted underneath, hidden
      },
    );

    testWidgets('a slow check releases after the cap', (t) async {
      await pump(t, () => Completer<AppGate>().future);
      await t.pump(const Duration(seconds: 2));
      expect(find.byKey(const Key('gate_hold')), findsOneWidget);
      await t.pump(appGateHoldCap);
      await t.pumpAndSettle();
      expect(find.byKey(const Key('gate_hold')), findsNothing);
      expect(find.byKey(const Key('login_mobile_field')), findsOneWidget);
    });

    testWidgets('a failing check releases at once', (t) async {
      await pump(t, () async => throw Exception('offline'));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('gate_hold')), findsNothing);
      expect(find.byKey(const Key('login_mobile_field')), findsOneWidget);
    });

    testWidgets('a late answer after the cap still blocks', (t) async {
      final c = Completer<AppGate>();
      await pump(t, () => c.future);
      await t.pump(appGateHoldCap);
      await t.pumpAndSettle();
      expect(find.byKey(const Key('login_mobile_field')), findsOneWidget);
      c.complete(const AppGate(AppGateKind.maintenance));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('gate_retry_btn')), findsOneWidget);
    });
  });
}
