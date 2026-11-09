// Regression tests: native-only notification permission, location failure messages, customer-safe
// error text, the navy Discard dialog and the 5-minute time picker. Fakes only, no backend.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/app/theme/app_theme.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/localization/failure_message.dart';
import 'package:sevanest_customer/core/services/location_service.dart';
import 'package:sevanest_customer/features/addresses/domain/address.dart';
import 'package:sevanest_customer/features/notifications/domain/push_service.dart';
import 'package:sevanest_customer/features/notifications/presentation/providers/notification_providers.dart';
import 'package:sevanest_customer/features/notifications/presentation/providers/push_providers.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/time_picker_sheet.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/discover_harness.dart';
import '../helpers/notification_fakes.dart';

Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 3; i++) {
    await t.pumpAndSettle();
    await t.pump(const Duration(seconds: 1));
  }
  await t.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('notification permission', () {
    for (final result in [PushPermission.granted, PushPermission.denied]) {
      test('undecided, OS answers $result: asked exactly once', () async {
        final push = FakePushService()..allowResult = result;
        final c = ProviderContainer(
          overrides: [
            pushServiceProvider.overrideWithValue(push),
            notificationRepositoryProvider.overrideWithValue(
              FakeNotificationRepository(),
            ),
          ],
        );
        addTearDown(c.dispose);
        final ctl = c.read(pushControllerProvider);
        expect(await ctl.shouldAsk(), isTrue);
        await ctl.allow();
        push.state = PushPermission.notDetermined; // even if the OS forgot
        expect(await ctl.shouldAsk(), isFalse);
        expect(push.requestCalls, 1);
      });
    }

    test('previously granted or denied is never asked', () async {
      for (final s in [PushPermission.granted, PushPermission.denied]) {
        final push = FakePushService(state: s);
        final c = ProviderContainer(
          overrides: [pushServiceProvider.overrideWithValue(push)],
        );
        addTearDown(c.dispose);
        expect(await c.read(pushControllerProvider).shouldAsk(), isFalse);
        expect(push.requestCalls, 0);
      }
    });
  });

  group('failure messages', () {
    final l10n = lookupAppLocalizations(const Locale('en'));

    test('known conditions map to plain text', () {
      expect(failureMessage(l10n, const NetworkFailure()), l10n.errorNetwork);
      expect(
        failureMessage(l10n, const ServerFailure('boom')),
        l10n.errorServer,
      );
      expect(
        failureMessage(l10n, const NotFoundFailure('Not Found')),
        l10n.errorNotFound,
      );
      expect(
        failureMessage(l10n, const RateLimitedFailure(null, 30)),
        l10n.errorRateLimitedIn(30),
      );
      expect(
        failureMessage(l10n, const RateLimitedFailure()),
        l10n.errorRateLimited,
      );
    });

    test('technical text is never shown; plain validation text is kept', () {
      for (final raw in [
        'PrismaClientKnownRequestError: invalid value',
        'TypeError: undefined is not a function',
        'Request failed with status code 500',
        '{"error":"x"}',
        'cancelled' * 40,
      ]) {
        expect(
          failureMessage(l10n, ValidationFailure(raw)),
          l10n.errorGeneric,
          reason: raw,
        );
      }
      expect(
        failureMessage(l10n, const UnknownFailure('cancelled')),
        l10n.errorGeneric,
      );
      expect(
        failureMessage(
          l10n,
          const ValidationFailure('Pincode must be 6 digits.'),
        ),
        'Pincode must be 6 digits.',
      );
      expect(
        failureMessage(
          l10n,
          const ConflictFailure('You already have a booking at this time.'),
        ),
        'You already have a booking at this time.',
      );
    });
  });

  group('location failures in the address form', () {
    Future<DiscoverEnv> open(WidgetTester t, LocationOutcome o) async {
      final env = await launchDiscover(t);
      env.location.result = LocationResult(o);
      await env.go('/addresses/new');
      await settle(t);
      await t.tap(find.byKey(const Key('address_use_location_btn')));
      await settle(t);
      return env;
    }

    String shown(WidgetTester t) =>
        t.widget<Text>(find.byKey(const Key('address_location_error'))).data!;

    testWidgets('permission denied -> Open Settings', (t) async {
      final env = await open(t, LocationOutcome.denied);
      expect(shown(t), startsWith('Location access is turned off.'));
      await t.tap(find.byKey(const Key('address_location_action_btn')));
      await t.pump();
      expect(env.location.settingsCalls, 1);
      expect(env.location.calls, 1); // no second permission request
    });

    testWidgets('permanently denied -> app settings', (t) async {
      final env = await open(t, LocationOutcome.deniedForever);
      expect(shown(t), contains('Enable it in your phone settings'));
      await t.tap(find.byKey(const Key('address_location_action_btn')));
      await t.pump();
      expect(env.location.settingsCalls, 1);
    });

    testWidgets('GPS off -> Location Settings', (t) async {
      final env = await open(t, LocationOutcome.gpsOff);
      expect(shown(t), contains('location is turned off'));
      await t.tap(find.byKey(const Key('address_location_action_btn')));
      await t.pump();
      expect(env.location.locationSettingsCalls, 1);
      expect(env.location.settingsCalls, 0);
    });

    for (final (o, text) in [
      (LocationOutcome.unavailable, "couldn't find your location right now"),
      (LocationOutcome.network, 'Check your internet connection'),
    ]) {
      testWidgets('$o -> Try again retries', (t) async {
        final env = await open(t, o);
        expect(shown(t), contains(text));
        env.location.result = const LocationResult(
          LocationOutcome.found,
          AddressInput(
            line: '',
            area: 'Madhapur',
            city: 'Hyderabad',
            pincode: '500081',
          ),
        );
        await t.tap(find.byKey(const Key('address_location_action_btn')));
        await settle(t);
        expect(env.location.calls, 2);
        expect(find.byKey(const Key('address_location_error')), findsNothing);
      });
    }

    testWidgets('manual entry stays available, no raw error leaks', (t) async {
      await open(t, LocationOutcome.network);
      expect(find.byKey(const Key('address_line1_field')), findsOneWidget);
      expect(find.textContaining('Exception'), findsNothing);
    });
  });

  group('Discard changes dialog', () {
    Future<void> edit(WidgetTester t) async {
      final env = await launchDiscover(t);
      await env.go('/addresses/new');
      await settle(t);
      await t.enterText(find.byKey(const Key('address_line1_field')), '7B');
      await t.pump();
      await t.binding.handlePopRoute();
      await t.pumpAndSettle();
    }

    testWidgets('Keep editing keeps the entered data', (t) async {
      await edit(t);
      expect(find.text('Discard changes?'), findsOneWidget);
      await t.tap(find.text('Keep editing'));
      await t.pumpAndSettle();
      expect(find.text('Discard changes?'), findsNothing);
      expect(
        t
            .widget<TextField>(find.byKey(const Key('address_line1_field')))
            .controller!
            .text,
        '7B',
      );
    });

    testWidgets('Discard leaves the form', (t) async {
      await edit(t);
      await t.tap(find.byKey(const Key('address_discard_confirm_btn')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('address_line1_field')), findsNothing);
    });

    testWidgets('1.3x text on a short phone does not overflow', (t) async {
      t.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      t.view.physicalSize = const Size(720, 1000);
      t.view.devicePixelRatio = 2;
      addTearDown(t.view.resetPhysicalSize);
      await edit(t);
      expect(find.text('Discard changes?'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  });

  group('time picker 5-minute steps', () {
    int? result;
    Future<void> open(WidgetTester t, int initial) async {
      result = -1;
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (c) => Scaffold(
              body: TextButton(
                key: const Key('open'),
                onPressed: () async => result = await showTimePickerSheet(
                  c,
                  title: 'Start time',
                  initialMinutes: initial,
                ),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.byKey(const Key('open')));
      await t.pumpAndSettle();
    }

    Future<void> done(WidgetTester t) async {
      await t.tap(find.byKey(const Key('time_picker_set_btn')));
      await t.pumpAndSettle();
    }

    testWidgets('every one of the 12 minutes can be picked', (t) async {
      for (var i = 0; i < 12; i++) {
        await open(t, 9 * 60);
        await t.drag(
          find.byKey(const Key('time_picker_minute')),
          Offset(0, -44.0 * i),
        );
        await t.pumpAndSettle();
        await done(t);
        expect(result, 9 * 60 + 5 * i, reason: 'minute index $i');
      }
    });

    testWidgets('12 AM, 12 PM and 11:55 PM survive a no-change Done', (
      t,
    ) async {
      for (final m in [0, 5, 12 * 60, 12 * 60 + 35, 23 * 60 + 55]) {
        await open(t, m);
        await done(t);
        expect(result, m);
      }
    });

    testWidgets('AM/PM change keeps hour and minute', (t) async {
      await open(t, 9 * 60 + 35);
      await t.drag(
        find.byKey(const Key('time_picker_period')),
        const Offset(0, -44),
      );
      await t.pumpAndSettle();
      await done(t);
      expect(result, 21 * 60 + 35);
    });
  });
}
