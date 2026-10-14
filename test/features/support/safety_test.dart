// Module 12: report and block a worker (SUP-10, SUP-11), from the worker profile, the booking and
// the active service. The sheet is design screen 22 "Report sheet open"; the routes are
// `POST /safety/reports` and `POST /safety/blocks`.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/features/support/domain/support.dart';

import '../../helpers/discover_harness.dart';
import '../../helpers/support_fakes.dart';

Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 3; i++) {
    await t.pumpAndSettle();
    await t.pump(const Duration(seconds: 1));
  }
  await t.pumpAndSettle();
}

Finder k(String key) => find.byKey(Key(key));

void main() {
  late FakeSafetyRepository safety;

  setUp(() => safety = FakeSafetyRepository());

  Future<DiscoverEnv> open(WidgetTester t, String route) async {
    final env = await launchDiscover(t, height: 1400, safety: safety);
    await env.go(route);
    await settle(t);
    return env;
  }

  Future<void> tap(WidgetTester t, String key) async {
    await t.ensureVisible(k(key));
    await t.pump();
    await t.tap(k(key));
    await settle(t);
  }

  Future<void> openReport(WidgetTester t) async {
    await tap(t, 'safety_menu_btn');
    await tap(t, 'report_open_btn');
  }

  group('Report sheet (SUP-10)', () {
    testWidgets(
      'reachable from the worker profile menu; submit needs a reason',
      (t) async {
        await open(t, '/workers/cook-2');
        await openReport(t);
        expect(find.text('Report a problem'), findsOneWidget);
        expect(find.text('What went wrong?'), findsOneWidget);
        for (final r in ReportReason.values) {
          expect(k('report_reason_${r.code}'), findsOneWidget);
        }
        expect(
          t
              .widget<FilledButton>(
                find.descendant(
                  of: k('report_submit_btn'),
                  matching: find.byType(FilledButton),
                ),
              )
              .onPressed,
          isNull,
        );
      },
    );

    testWidgets('submit: one POST with the reason, the note and the worker', (
      t,
    ) async {
      await open(t, '/workers/cook-2');
      await openReport(t);
      await tap(t, 'report_reason_THEFT');
      await t.enterText(k('report_note_field'), 'Took cash from the drawer');
      await tap(t, 'report_submit_btn');
      expect(safety.reportCalls, 1);
      expect(safety.lastWorker, 'cook-2');
      expect(safety.lastBooking, isNull);
      expect(safety.lastReason, ReportReason.theft);
      expect(safety.lastNote, 'Took cash from the drawer');
      expect(safety.lastAlsoBlock, isFalse);
      // Closed, with the thank-you shown only after the server said yes.
      expect(k('report_submit_btn'), findsNothing);
      expect(find.text('Thanks, our team will review this'), findsOneWidget);
      expect(safety.blockCalls, 0);
    });

    testWidgets('a double tap sends once and the button shows a spinner', (
      t,
    ) async {
      safety.gate = Completer();
      await open(t, '/workers/cook-2');
      await openReport(t);
      await tap(t, 'report_reason_OTHER');
      await t.tap(k('report_submit_btn'));
      await t.pump();
      await t.tap(k('report_submit_btn'), warnIfMissed: false);
      await t.pump();
      expect(find.text('Submitting…'), findsOneWidget);
      expect(safety.reportCalls, 1);
      safety.gate!.complete();
      await settle(t);
      expect(safety.reportCalls, 1);
      expect(k('report_submit_btn'), findsNothing);
    });

    testWidgets('failure keeps the sheet open with what was entered', (
      t,
    ) async {
      safety.reportFail = const ServerFailure();
      await open(t, '/workers/cook-2');
      await openReport(t);
      await tap(t, 'report_reason_MISCONDUCT');
      await t.enterText(k('report_note_field'), 'He shouted at me');
      await tap(t, 'report_submit_btn');
      expect(k('report_submit_btn'), findsOneWidget);
      expect(k('report_error'), findsOneWidget);
      expect(find.text('He shouted at me'), findsOneWidget);
      expect(find.text('Thanks, our team will review this'), findsNothing);
      safety.reportFail = null;
      await tap(t, 'report_submit_btn');
      expect(k('report_submit_btn'), findsNothing);
      expect(safety.reportCalls, 2);
    });

    testWidgets('a worker the backend does not know (404) is said plainly', (
      t,
    ) async {
      safety.reportFail = const NotFoundFailure();
      await open(t, '/workers/cook-2');
      await openReport(t);
      await tap(t, 'report_reason_NO_SHOW');
      await tap(t, 'report_submit_btn');
      expect(find.text("We couldn't find that worker."), findsOneWidget);
    });

    testWidgets('Also block sends alsoBlock', (t) async {
      await open(t, '/workers/cook-2');
      await openReport(t);
      await tap(t, 'report_reason_HARASSMENT');
      await tap(t, 'report_also_block_switch');
      await tap(t, 'report_submit_btn');
      expect(safety.lastAlsoBlock, isTrue);
    });

    testWidgets('a safety concern points to emergency services', (t) async {
      await open(t, '/workers/cook-2');
      await openReport(t);
      expect(k('report_emergency_note'), findsNothing);
      await tap(t, 'report_reason_SAFETY_CONCERN');
      expect(k('report_emergency_note'), findsOneWidget);
    });

    testWidgets('Cancel and the close icon leave without a call', (t) async {
      await open(t, '/workers/cook-2');
      await openReport(t);
      await tap(t, 'report_cancel_btn');
      expect(k('report_submit_btn'), findsNothing);
      await openReport(t);
      await tap(t, 'report_close_btn');
      expect(k('report_submit_btn'), findsNothing);
      expect(safety.reportCalls, 0);
    });
  });

  group('Block (SUP-11)', () {
    testWidgets('confirm -> POST once -> back to the previous screen', (
      t,
    ) async {
      final env = await open(t, '/workers/cook-2');
      await tap(t, 'safety_menu_btn');
      await tap(t, 'block_open_btn');
      expect(find.text('Block this worker?'), findsOneWidget);
      expect(safety.blockCalls, 0); // nothing before the confirmation
      await tap(t, 'block_confirm_btn');
      expect(safety.blockCalls, 1);
      expect(safety.lastWorker, 'cook-2');
      expect(env.where, isNot('/workers/cook-2'));
      expect(find.text('Worker blocked'), findsOneWidget);
    });

    testWidgets('cancelling the dialog does nothing', (t) async {
      final env = await open(t, '/workers/cook-2');
      await tap(t, 'safety_menu_btn');
      await tap(t, 'block_open_btn');
      await tap(t, 'dialog_cancel_btn');
      expect(safety.blockCalls, 0);
      expect(env.where, '/workers/cook-2');
    });

    testWidgets('a failure leaves the profile open with a message', (t) async {
      safety.blockFail = const NetworkFailure();
      final env = await open(t, '/workers/cook-2');
      await tap(t, 'safety_menu_btn');
      await tap(t, 'block_open_btn');
      await tap(t, 'block_confirm_btn');
      expect(safety.blockCalls, 1);
      expect(env.where, '/workers/cook-2');
      expect(find.text('Worker blocked'), findsNothing);
      expect(
        find.text(
          "Couldn't reach SevaNest. Check your connection and try again.",
        ),
        findsOneWidget,
      );
    });
  });

  group('entry points', () {
    testWidgets('the booking names the worker by its booking id', (t) async {
      await open(t, '/bookings/bk_2048');
      await openReport(t);
      await tap(t, 'report_reason_NO_SHOW');
      await tap(t, 'report_submit_btn');
      expect(safety.lastBooking, 'bk_2048');
      expect(safety.lastWorker, isNull);
    });

    testWidgets('the active service has the menu too, block by booking', (
      t,
    ) async {
      await open(t, '/services/current?bookingId=bk_2048');
      await tap(t, 'safety_menu_btn');
      await tap(t, 'block_open_btn');
      await tap(t, 'block_confirm_btn');
      expect(safety.blockCalls, 1);
      expect(safety.lastBooking, 'bk_2048');
    });

    testWidgets('no menu on a worker that is gone', (t) async {
      await open(t, '/workers/cook-gone-9');
      expect(k('safety_menu_btn'), findsNothing);
    });
  });
}
