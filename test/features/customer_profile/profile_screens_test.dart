// WIDGET tests: real app + router + profile screens, with in-memory fake repositories (no network).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/features/addresses/presentation/providers/address_providers.dart';
import 'package:sevanest_customer/features/customer_profile/domain/customer_profile.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/providers/customer_profile_providers.dart';

import '../../helpers/fakes.dart';

const _name = Key('profile_name_field');
const _email = Key('profile_email_field');
const _continue = Key('profile_continue_btn');

FilledButton fb(WidgetTester t, Key key) {
  final inner = find.descendant(
    of: find.byKey(key),
    matching: find.byType(FilledButton),
  );
  return t.widget<FilledButton>(
    inner.evaluate().isNotEmpty ? inner : find.byKey(key),
  );
}

void main() {
  late FakeAuthRepository auth;
  late FakeProfileRepository profiles;
  late FakeAddressRepository addresses;

  Future<void> launch(WidgetTester t, {required bool complete}) async {
    useTestPhone(t);
    auth.onProfile = () async => complete;
    await t.pumpWidget(
      testRootApp(
        store: InMemorySessionStore((access: 'a', refresh: 'r')),
        repo: auth,
        overrides: [
          customerProfileRepositoryProvider.overrideWithValue(profiles),
          addressRepositoryProvider.overrideWithValue(addresses),
        ],
      ),
    );
    await t.pumpAndSettle();
  }

  Future<void> openProfile(WidgetTester t) async {
    await t.tap(find.byKey(const Key('nav_account')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('account_profile_btn')));
    await t.pumpAndSettle();
  }

  setUp(() {
    auth = FakeAuthRepository();
    profiles = FakeProfileRepository();
    addresses = FakeAddressRepository();
  });

  group('Profile setup (screen 2.1)', () {
    testWidgets('PROF-02 Continue stays disabled until the name is valid', (
      t,
    ) async {
      await launch(t, complete: false);
      expect(find.byKey(_continue), findsOneWidget);
      expect(fb(t, _continue).onPressed, isNull);

      await t.enterText(find.byKey(_name), 'P');
      await t.pump();
      expect(fb(t, _continue).onPressed, isNull);

      await t.enterText(find.byKey(_name), 'Priya Sharma');
      await t.pump();
      expect(fb(t, _continue).onPressed, isNotNull);
    });

    testWidgets('English is selectable; other languages are disabled', (
      t,
    ) async {
      await launch(t, complete: false);
      final hindi = t.widget<ChoiceChip>(
        find.byKey(const Key('profile_language_chip_hi')),
      );
      expect(hindi.onSelected, isNull);
      final english = t.widget<ChoiceChip>(
        find.byKey(const Key('profile_language_chip_en')),
      );
      expect(english.selected, isTrue);
    });

    testWidgets(
      'missing / malformed email blocks the request (backend needs it)',
      (t) async {
        await launch(t, complete: false);
        await t.enterText(find.byKey(_name), 'Priya Sharma');
        await t.pump();
        await t.tap(find.byKey(_continue));
        await t.pump();
        expect(
          find.byKey(const Key('profile_email_field_error')),
          findsOneWidget,
        );
        expect(profiles.createCalls, 0);

        await t.enterText(find.byKey(_email), 'priya.sharma@gmail');
        await t.pump();
        expect(
          find.byKey(const Key('profile_email_field_error')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'PROF-03 Continue creates the profile once and goes to the first-time address form; system back does nothing',
      (t) async {
        await launch(t, complete: false);
        await t.binding.handlePopRoute();
        await t.pumpAndSettle();
        expect(find.byKey(_continue), findsOneWidget);

        await t.enterText(find.byKey(_name), 'Priya Sharma');
        await t.enterText(find.byKey(_email), 'priya@example.com');
        await t.pump();
        await t.tap(find.byKey(_continue));
        await t.pumpAndSettle();

        expect(profiles.createCalls, 1);
        expect(profiles.stored!.name, 'Priya Sharma');
        expect(profiles.stored!.preferredLanguage, 'en');
        expect(find.byKey(const Key('address_save_btn')), findsOneWidget);
        expect(find.byKey(const Key('address_skip_btn')), findsOneWidget);
      },
    );

    testWidgets('PROF-04 backend field errors show under the field', (t) async {
      profiles.failNext = const ValidationFailure('bad', {
        'email': 'email must be an email',
      });
      await launch(t, complete: false);
      await t.enterText(find.byKey(_name), 'Priya Sharma');
      await t.enterText(find.byKey(_email), 'priya@example.com');
      await t.pump();
      await t.tap(find.byKey(_continue));
      await t.pumpAndSettle();

      expect(find.text('email must be an email'), findsOneWidget);
      expect(find.byKey(_continue), findsOneWidget);
      expect(fb(t, _continue).onPressed, isNotNull); // re-enabled
    });

    testWidgets('network failure keeps the typed values and allows retry', (
      t,
    ) async {
      profiles.failNext = const NetworkFailure();
      await launch(t, complete: false);
      await t.enterText(find.byKey(_name), 'Priya Sharma');
      await t.enterText(find.byKey(_email), 'priya@example.com');
      await t.pump();
      await t.tap(find.byKey(_continue));
      await t.pumpAndSettle();

      expect(find.byKey(const Key('profile_error_banner')), findsOneWidget);
      expect(find.text('Priya Sharma'), findsOneWidget);

      await t.tap(find.byKey(_continue));
      await t.pumpAndSettle();
      expect(profiles.createCalls, 2);
      expect(find.byKey(const Key('address_save_btn')), findsOneWidget);
    });

    testWidgets('double tap while saving sends one request', (t) async {
      final gate = Completer<void>();
      profiles.gate = gate.future;
      await launch(t, complete: false);
      await t.enterText(find.byKey(_name), 'Priya Sharma');
      await t.enterText(find.byKey(_email), 'priya@example.com');
      await t.pump();
      await t.tap(find.byKey(_continue));
      await t.pump();
      await t.tap(find.byKey(_continue), warnIfMissed: false);
      await t.pump();
      expect(find.text('Saving...'), findsOneWidget);
      expect(profiles.createCalls, 1);

      gate.complete();
      await t.pumpAndSettle();
      expect(profiles.createCalls, 1);
    });

    testWidgets('409 (profile already exists) continues to Home', (t) async {
      profiles.failNext = const ConflictFailure('exists');
      await launch(t, complete: false);
      await t.enterText(find.byKey(_name), 'Priya Sharma');
      await t.enterText(find.byKey(_email), 'priya@example.com');
      await t.pump();
      await t.tap(find.byKey(_continue));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('nav_home')), findsOneWidget);
    });
  });

  group('Profile (screen 2.4)', () {
    const existing = CustomerProfile(
      name: 'Asha Rao',
      email: 'asha@example.com',
      preferredLanguage: 'en',
      mobile: '9876543210',
      verificationStatus: 'PENDING',
    );

    testWidgets(
      'read mode shows backend data; verification chip is read-only',
      (t) async {
        profiles.stored = existing;
        await launch(t, complete: true);
        await openProfile(t);
        expect(
          t.widget<TextField>(find.byKey(_name)).controller!.text,
          'Asha Rao',
        );
        expect(t.widget<TextField>(find.byKey(_name)).readOnly, isTrue);
        expect(find.text('PENDING'), findsOneWidget);
        expect(find.byKey(const Key('profile_edit_btn')), findsOneWidget);
      },
    );

    testWidgets('PROF-05 mobile stays read-only, also in edit mode', (t) async {
      profiles.stored = existing;
      await launch(t, complete: true);
      await openProfile(t);
      const mobile = Key('profile_mobile_field');
      expect(t.widget<TextField>(find.byKey(mobile)).readOnly, isTrue);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);

      await t.tap(find.byKey(const Key('profile_edit_btn')));
      await t.pumpAndSettle();
      expect(t.widget<TextField>(find.byKey(_name)).readOnly, isFalse);
      expect(t.widget<TextField>(find.byKey(mobile)).readOnly, isTrue);
    });

    testWidgets('edit -> save sends PATCH once, confirms, returns to read mode', (
      t,
    ) async {
      profiles.stored = existing;
      await launch(t, complete: true);
      await openProfile(t);
      await t.tap(find.byKey(const Key('profile_edit_btn')));
      await t.pumpAndSettle();
      expect(fb(t, const Key('profile_save_btn')).onPressed, isNull);

      await t.enterText(find.byKey(_name), 'Asha K Rao');
      await t.pump();
      await t.tap(find.byKey(const Key('profile_save_btn')));
      await t.pumpAndSettle();

      expect(profiles.updateCalls, 1);
      expect(find.text('Profile updated'), findsOneWidget);
      expect(find.byKey(const Key('profile_edit_btn')), findsOneWidget);
      expect(
        t.widget<TextField>(find.byKey(_name)).controller!.text,
        'Asha K Rao',
      );
      // Mobile survives the PATCH even though the (mock) response omits nothing here.
      expect(find.byKey(const Key('profile_mobile_field')), findsOneWidget);
    });

    testWidgets(
      'backend validation error shows under the field and keeps edit mode',
      (t) async {
        profiles.stored = existing;
        await launch(t, complete: true);
        await openProfile(t);
        await t.tap(find.byKey(const Key('profile_edit_btn')));
        await t.pumpAndSettle();
        profiles.failNext = const ValidationFailure('bad', {
          'email': 'email already in use',
        });
        await t.enterText(find.byKey(_email), 'taken@example.com');
        await t.pump();
        await t.tap(find.byKey(const Key('profile_save_btn')));
        await t.pumpAndSettle();
        expect(find.text('email already in use'), findsOneWidget);
        expect(find.byKey(const Key('profile_save_btn')), findsOneWidget);
      },
    );

    testWidgets('Cancel with changes asks to discard, then reverts', (t) async {
      profiles.stored = existing;
      await launch(t, complete: true);
      await openProfile(t);
      await t.tap(find.byKey(const Key('profile_edit_btn')));
      await t.pumpAndSettle();
      await t.enterText(find.byKey(_name), 'Someone Else');
      await t.pump();
      await t.scrollUntilVisible(
        find.byKey(const Key('profile_cancel_btn')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await t.ensureVisible(find.byKey(const Key('profile_cancel_btn')));
      await t.pump();
      await t.tap(find.byKey(const Key('profile_cancel_btn')));
      await t.pumpAndSettle();
      expect(find.text('Discard changes?'), findsOneWidget);

      await t.tap(find.byKey(const Key('profile_discard_confirm_btn')));
      await t.pumpAndSettle();
      expect(
        t.widget<TextField>(find.byKey(_name)).controller!.text,
        'Asha Rao',
      );
      expect(find.byKey(const Key('profile_edit_btn')), findsOneWidget);
      expect(profiles.updateCalls, 0);
    });

    testWidgets('load failure shows retry; retry loads the profile', (t) async {
      await launch(t, complete: true);
      // First GET fails (no stored profile -> NotFoundFailure), then data appears.
      await openProfile(t);
      expect(find.byKey(const Key('error_retry_btn')), findsOneWidget);
      profiles.stored = existing;
      await t.tap(find.byKey(const Key('error_retry_btn')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('profile_edit_btn')), findsOneWidget);
    });
  });
}
