// WIDGET tests: real app + router + address screens, with an in-memory fake repository (no network).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/theme/app_theme.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/features/addresses/domain/address.dart';
import 'package:sevanest_customer/features/addresses/presentation/providers/address_providers.dart';
import 'package:sevanest_customer/features/addresses/presentation/screens/address_list_screen.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/providers/customer_profile_providers.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

import '../../helpers/fakes.dart';

const _home = Address(
  id: 'h1',
  line: 'Flat 402, Sai Residency',
  area: 'Madhapur',
  city: 'Hyderabad',
  pincode: '500081',
  isDefault: true,
);
const _office = Address(
  id: 'o1',
  line: 'Plot 18, HITEC City',
  area: 'Gachibowli',
  city: 'Hyderabad',
  pincode: '500032',
);

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

  Future<void> launch(WidgetTester t, {bool complete = true}) async {
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

  Future<void> openList(WidgetTester t) async {
    await t.tap(find.byKey(const Key('nav_account')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('account_addresses_tile')));
    await t.pumpAndSettle();
  }

  Future<void> enter(WidgetTester t, String key, String text) async {
    await t.ensureVisible(find.byKey(Key(key)));
    await t.enterText(find.byKey(Key(key)), text);
    await t.pump();
  }

  Future<void> tapKey(WidgetTester t, String key) async {
    await t.ensureVisible(find.byKey(Key(key)));
    await t.pump();
    await t.tap(find.byKey(Key(key)));
    await t.pumpAndSettle();
  }

  Future<void> fillValid(WidgetTester t) async {
    await enter(t, 'address_line1_field', 'Flat 7B');
    await enter(t, 'address_line2_field', 'Lake View Apartments');
    await tapKey(
      t,
      'address_area_field',
    ); // picker (areas load from the backend)
    await t.tap(find.byKey(const Key('area_option_Madhapur')));
    await t.pumpAndSettle();
    await enter(t, 'address_pincode_field', '500081');
  }

  setUp(() {
    auth = FakeAuthRepository();
    profiles = FakeProfileRepository();
    addresses = FakeAddressRepository();
  });

  group('Address list (screen 2.3)', () {
    testWidgets('ADDR-08 loading skeleton, then cards with the Default tag', (
      t,
    ) async {
      addresses.items = [_office, _home];
      await launch(t);
      await t.tap(find.byKey(const Key('nav_account')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('account_addresses_tile')));
      // Home already warmed the address list, so the screen shows data straight away.
      await t.pumpAndSettle();

      expect(find.byKey(const Key('address_card_h1')), findsOneWidget);
      expect(find.byKey(const Key('address_card_o1')), findsOneWidget);
      expect(find.byKey(const Key('address_default_tag_h1')), findsOneWidget);
      expect(find.byKey(const Key('address_default_tag_o1')), findsNothing);
      // Default first (backend order is kept).
      expect(
        t.getTopLeft(find.byKey(const Key('address_card_h1'))).dy,
        lessThan(t.getTopLeft(find.byKey(const Key('address_card_o1'))).dy),
      );
    });

    testWidgets('ADDR-08 empty list shows the CTA, which opens the form', (
      t,
    ) async {
      await launch(t);
      await openList(t);
      expect(find.text('Add your first address'), findsOneWidget);
      await t.tap(find.byKey(const Key('addresses_empty_add_btn')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('address_save_btn')), findsOneWidget);
    });

    testWidgets('ADDR-08 error shows retry; retry reloads', (t) async {
      addresses
        ..items = [_home]
        ..failList = const NetworkFailure();
      await launch(t);
      await openList(t);
      expect(find.byKey(const Key('error_retry_btn')), findsOneWidget);

      addresses.failList = null;
      await t.tap(find.byKey(const Key('error_retry_btn')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('address_card_h1')), findsOneWidget);
    });

    testWidgets('ADDR-06 Set default moves the tag and confirms', (t) async {
      addresses.items = [_home, _office];
      await launch(t);
      await openList(t);

      await t.tap(find.byKey(const Key('address_menu_o1')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('address_set_default_o1')));
      await t.pumpAndSettle();

      expect(addresses.defaultCalls, 1);
      expect(find.text('Default address updated'), findsOneWidget);
      expect(find.byKey(const Key('address_default_tag_o1')), findsOneWidget);
      expect(find.byKey(const Key('address_default_tag_h1')), findsNothing);
    });

    testWidgets('default address has no "Set as default" menu entry', (
      t,
    ) async {
      addresses.items = [_home];
      await launch(t);
      await openList(t);
      await t.tap(find.byKey(const Key('address_menu_h1')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('address_set_default_h1')), findsNothing);
      expect(find.byKey(const Key('address_edit_h1')), findsOneWidget);
    });

    testWidgets(
      'ADDR-05 delete: confirm dialog -> one DELETE -> list refreshed',
      (t) async {
        addresses.items = [_home, _office];
        await launch(t);
        await openList(t);

        await t.tap(find.byKey(const Key('address_menu_o1')));
        await t.pumpAndSettle();
        await t.tap(find.byKey(const Key('address_menu_delete_o1')));
        await t.pumpAndSettle();
        expect(find.text('Delete this address?'), findsOneWidget);

        // Cancelling does nothing.
        await t.tap(find.byKey(const Key('dialog_cancel_btn')));
        await t.pumpAndSettle();
        expect(addresses.deleteCalls, 0);

        await t.tap(find.byKey(const Key('address_menu_o1')));
        await t.pumpAndSettle();
        await t.tap(find.byKey(const Key('address_menu_delete_o1')));
        await t.pumpAndSettle();
        await t.tap(find.byKey(const Key('address_delete_confirm_btn')));
        await t.pumpAndSettle();

        expect(addresses.deleteCalls, 1);
        expect(find.byKey(const Key('address_card_o1')), findsNothing);
        expect(find.text('Address deleted'), findsOneWidget);
      },
    );

    testWidgets(
      'ADDR-05 409 (used by an active booking) shows a dialog, keeps the row',
      (t) async {
        addresses
          ..items = [_home, _office]
          ..failNext = const ConflictFailure('in use');
        await launch(t);
        await openList(t);
        await t.tap(find.byKey(const Key('address_menu_o1')));
        await t.pumpAndSettle();
        await t.tap(find.byKey(const Key('address_menu_delete_o1')));
        await t.pumpAndSettle();
        await t.tap(find.byKey(const Key('address_delete_confirm_btn')));
        await t.pumpAndSettle();

        expect(
          find.text('This address is used by an active booking.'),
          findsOneWidget,
        );
        await t.tap(find.byKey(const Key('dialog_ok_btn')));
        await t.pumpAndSettle();
        expect(find.byKey(const Key('address_card_o1')), findsOneWidget);
      },
    );

    testWidgets('tapping a card opens the editor prefilled from the backend', (
      t,
    ) async {
      addresses.items = [_home];
      await launch(t);
      await openList(t);
      await t.tap(find.byKey(const Key('address_card_h1')));
      await t.pumpAndSettle();

      String text(String k) =>
          t.widget<TextField>(find.byKey(Key(k))).controller!.text;
      expect(text('address_line1_field'), 'Flat 402');
      expect(text('address_line2_field'), 'Sai Residency');
      expect(text('address_area_field'), 'Madhapur');
      expect(text('address_pincode_field'), '500081');
      expect(find.byKey(const Key('address_delete_btn')), findsOneWidget);
    });

    testWidgets(
      'ADDR-07 select mode returns the tapped address to the caller',
      (t) async {
        addresses.items = [_home, _office];
        useTestPhone(t);
        Address? picked;
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, _) => Scaffold(
                body: TextButton(
                  key: const Key('open_picker'),
                  onPressed: () async =>
                      picked = await context.push<Address>('/pick'),
                  child: const Text('pick'),
                ),
              ),
            ),
            GoRoute(
              path: '/pick',
              builder: (context, _) =>
                  const AddressListScreen(selectMode: true),
            ),
            GoRoute(
              path: '/addresses/:id/edit',
              builder: (_, _) => const Text('edit'),
            ),
          ],
        );
        await t.pumpWidget(
          ProviderScope(
            overrides: [addressRepositoryProvider.overrideWithValue(addresses)],
            child: MaterialApp.router(
              routerConfig: router,
              theme: AppTheme.light,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            ),
          ),
        );
        await t.tap(find.byKey(const Key('open_picker')));
        await t.pumpAndSettle();
        await t.tap(find.byKey(const Key('address_card_o1')));
        await t.pumpAndSettle();

        expect(picked?.id, 'o1');
        expect(find.byKey(const Key('open_picker')), findsOneWidget);
        expect(find.text('edit'), findsNothing);
      },
    );
  });

  group('Address form (screen 2.2)', () {
    testWidgets(
      'Save is disabled until valid; a bad pincode shows an inline error',
      (t) async {
        await launch(t);
        await openList(t);
        await t.tap(find.byKey(const Key('addresses_empty_add_btn')));
        await t.pumpAndSettle();
        expect(fb(t, const Key('address_save_btn')).onPressed, isNull);

        await enter(t, 'address_line1_field', 'Flat 7B');
        await enter(t, 'address_line2_field', 'Lake View Apartments');
        await tapKey(t, 'address_area_field');
        await t.tap(find.byKey(const Key('area_option_Madhapur')));
        await t.pumpAndSettle();
        await enter(t, 'address_pincode_field', '5000');
        expect(
          find.byKey(const Key('address_pincode_field_error')),
          findsOneWidget,
        );
        expect(fb(t, const Key('address_save_btn')).onPressed, isNull);

        await enter(t, 'address_pincode_field', '500081');
        expect(
          find.byKey(const Key('address_pincode_field_error')),
          findsNothing,
        );
        expect(fb(t, const Key('address_save_btn')).onPressed, isNotNull);
      },
    );

    testWidgets(
      'city is prefilled with Hyderabad; the first address defaults to "default"',
      (t) async {
        await launch(t);
        await openList(t);
        await t.tap(find.byKey(const Key('addresses_empty_add_btn')));
        await t.pumpAndSettle();
        expect(
          t
              .widget<TextField>(find.byKey(const Key('address_city_field')))
              .controller!
              .text,
          'Hyderabad',
        );
        expect(
          t
              .widget<SwitchListTile>(
                find.byKey(const Key('address_default_switch')),
              )
              .value,
          isTrue,
        );
      },
    );

    testWidgets(
      'ADDR-01 non-first save: POST fields, pops back to the list showing the new item',
      (t) async {
        addresses.items = [_home];
        await launch(t);
        await openList(t);
        await t.tap(find.byKey(const Key('addresses_add_btn')));
        await t.pumpAndSettle();
        await fillValid(t);
        await tapKey(t, 'address_save_btn');

        expect(addresses.createCalls, 1);
        expect(addresses.lastInput!.line, 'Flat 7B, Lake View Apartments');
        expect(addresses.lastInput!.city, 'Hyderabad');
        expect(addresses.lastInput!.isDefault, isFalse);
        expect(find.byKey(const Key('addresses_add_btn')), findsOneWidget);
        expect(find.text('Address saved'), findsOneWidget);
        expect(
          find.text('Flat 7B, Lake View Apartments, Hyderabad 500081'),
          findsOneWidget,
        );
      },
    );

    testWidgets('ADDR-01 first-time save goes to Home', (t) async {
      await launch(t, complete: false);
      await t.enterText(
        find.byKey(const Key('profile_name_field')),
        'Priya Sharma',
      );
      await t.enterText(
        find.byKey(const Key('profile_email_field')),
        'p@example.com',
      );
      await t.pump();
      await t.tap(find.byKey(const Key('profile_continue_btn')));
      await t.pumpAndSettle();
      await fillValid(t);
      await tapKey(t, 'address_save_btn');

      expect(addresses.createCalls, 1);
      expect(addresses.lastInput!.isDefault, isTrue);
      expect(find.byKey(const Key('nav_home')), findsOneWidget);
    });

    testWidgets('ADDR-02 Skip goes to Home without creating an address', (
      t,
    ) async {
      await launch(t, complete: false);
      await t.enterText(
        find.byKey(const Key('profile_name_field')),
        'Priya Sharma',
      );
      await t.enterText(
        find.byKey(const Key('profile_email_field')),
        'p@example.com',
      );
      await t.pump();
      await t.tap(find.byKey(const Key('profile_continue_btn')));
      await t.pumpAndSettle();
      await tapKey(t, 'address_skip_btn');

      expect(addresses.createCalls, 0);
      expect(find.byKey(const Key('nav_home')), findsOneWidget);
    });

    testWidgets(
      'ADDR-04 backend rejects the area -> inline message, Save re-enabled, retry works',
      (t) async {
        addresses.failNext = const ValidationFailure('bad', {
          'area': "We don't serve this area yet",
        });
        await launch(t);
        await openList(t);
        await t.tap(find.byKey(const Key('addresses_empty_add_btn')));
        await t.pumpAndSettle();
        await fillValid(t);
        await tapKey(t, 'address_save_btn');

        expect(find.text("We don't serve this area yet"), findsOneWidget);
        expect(find.byKey(const Key('address_save_btn')), findsOneWidget);
        expect(fb(t, const Key('address_save_btn')).onPressed, isNotNull);

        await tapKey(t, 'address_save_btn');
        expect(addresses.createCalls, 2);
        expect(find.byKey(const Key('addresses_add_btn')), findsOneWidget);
      },
    );

    testWidgets('network failure keeps the typed values and shows a banner', (
      t,
    ) async {
      addresses.failNext = const NetworkFailure();
      await launch(t);
      await openList(t);
      await t.tap(find.byKey(const Key('addresses_empty_add_btn')));
      await t.pumpAndSettle();
      await fillValid(t);
      await tapKey(t, 'address_save_btn');
      expect(find.byKey(const Key('address_error_banner')), findsOneWidget);
      expect(find.text('Lake View Apartments'), findsOneWidget);
    });

    testWidgets('area picker lists backend service areas and fills the field', (
      t,
    ) async {
      await launch(t);
      await openList(t);
      await t.tap(find.byKey(const Key('addresses_empty_add_btn')));
      await t.pumpAndSettle();
      await tapKey(t, 'address_area_field');
      expect(find.byKey(const Key('area_option_Gachibowli')), findsOneWidget);
      await t.tap(find.byKey(const Key('area_option_Gachibowli')));
      await t.pumpAndSettle();
      expect(
        t
            .widget<TextField>(find.byKey(const Key('address_area_field')))
            .controller!
            .text,
        'Gachibowli',
      );
    });

    testWidgets('service-areas failure falls back to a free-text area field', (
      t,
    ) async {
      addresses.failAreas = const NetworkFailure();
      await launch(t);
      await openList(t);
      await t.tap(find.byKey(const Key('addresses_empty_add_btn')));
      await t.pumpAndSettle();
      expect(
        t
            .widget<TextField>(find.byKey(const Key('address_area_field')))
            .readOnly,
        isFalse,
      );
      expect(find.textContaining('type your area'), findsOneWidget);
    });

    testWidgets('edit: PATCH then PUT default when the switch is turned on', (
      t,
    ) async {
      addresses.items = [_home, _office];
      await launch(t);
      await openList(t);
      await t.tap(find.byKey(const Key('address_card_o1')));
      await t.pumpAndSettle();
      await enter(t, 'address_pincode_field', '500033');
      await tapKey(t, 'address_default_switch');
      await tapKey(t, 'address_save_btn');

      expect(addresses.lastInput!.pincode, '500033');
      expect(addresses.defaultCalls, 1);
      expect(find.byKey(const Key('address_default_tag_o1')), findsOneWidget);
    });

    testWidgets('the default address cannot be un-defaulted from the form', (
      t,
    ) async {
      addresses.items = [_home];
      await launch(t);
      await openList(t);
      await t.tap(find.byKey(const Key('address_card_h1')));
      await t.pumpAndSettle();
      expect(
        t
            .widget<SwitchListTile>(
              find.byKey(const Key('address_default_switch')),
            )
            .onChanged,
        isNull,
      );
    });

    testWidgets('ADDR-09 back with unsaved edits asks to discard', (t) async {
      addresses.items = [_home];
      await launch(t);
      await openList(t);
      await t.tap(find.byKey(const Key('address_card_h1')));
      await t.pumpAndSettle();
      await enter(t, 'address_pincode_field', '500099');

      await t.binding.handlePopRoute();
      await t.pumpAndSettle();
      expect(find.text('Discard changes?'), findsOneWidget);

      await t.tap(find.byKey(const Key('address_discard_confirm_btn')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('addresses_add_btn')), findsOneWidget);
      expect(addresses.items.single.pincode, '500081');
    });

    testWidgets('ADDR-09 back with no edits leaves without a prompt', (
      t,
    ) async {
      addresses.items = [_home];
      await launch(t);
      await openList(t);
      await t.tap(find.byKey(const Key('address_card_h1')));
      await t.pumpAndSettle();
      await t.binding.handlePopRoute();
      await t.pumpAndSettle();
      expect(find.text('Discard changes?'), findsNothing);
      expect(find.byKey(const Key('addresses_add_btn')), findsOneWidget);
    });

    testWidgets(
      'edit-form delete: confirm -> DELETE once -> back to the list',
      (t) async {
        addresses.items = [_home, _office];
        await launch(t);
        await openList(t);
        await t.tap(find.byKey(const Key('address_card_o1')));
        await t.pumpAndSettle();
        await tapKey(t, 'address_delete_btn');
        await t.tap(find.byKey(const Key('address_delete_confirm_btn')));
        await t.pumpAndSettle();

        expect(addresses.deleteCalls, 1);
        expect(find.byKey(const Key('address_card_o1')), findsNothing);
        expect(find.byKey(const Key('address_card_h1')), findsOneWidget);
      },
    );

    testWidgets('edit-form delete 409 shows the in-use dialog and stays', (
      t,
    ) async {
      addresses
        ..items = [_home, _office]
        ..failNext = const ConflictFailure('in use');
      await launch(t);
      await openList(t);
      await t.tap(find.byKey(const Key('address_card_o1')));
      await t.pumpAndSettle();
      await tapKey(t, 'address_delete_btn');
      await t.tap(find.byKey(const Key('address_delete_confirm_btn')));
      await t.pumpAndSettle();
      expect(
        find.text('This address is used by an active booking.'),
        findsOneWidget,
      );
      await t.tap(find.byKey(const Key('dialog_ok_btn')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('address_delete_btn')), findsOneWidget);
    });
  });
}
