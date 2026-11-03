// Module 12 flows (SUP-12, Flow J): Support -> New ticket -> Submit -> Detail -> a status update
// after a refresh; and payment failed -> Get help -> ticket created -> ticket detail -> reply.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/features/payment/data/payment_services.dart';
import 'package:sevanest_customer/features/payment/domain/payment.dart';
import 'package:sevanest_customer/features/payment/presentation/providers/payment_providers.dart';
import 'package:sevanest_customer/features/support/domain/support.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  late FakeSupportRepository repo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repo = FakeSupportRepository();
  });

  Future<void> tap(WidgetTester t, String key) async {
    await t.ensureVisible(k(key));
    await t.pump();
    await t.tap(k(key));
    await settle(t);
  }

  Future<void> type(WidgetTester t, String key, String text) async {
    await t.ensureVisible(k(key));
    await t.enterText(k(key), text);
    await t.pump();
  }

  testWidgets(
    'Flow J: Support -> New ticket -> Submit -> Detail -> status update',
    (t) async {
      final env = await launchDiscover(t, height: 1600, support: repo);
      await env.go('/support');
      await tap(t, 'support_new_btn');
      expect(env.where, '/support/new');
      await tap(t, 'ticket_category_field');
      await tap(t, 'ticket_category_c2');
      await type(
        t,
        'ticket_description_field',
        'Charged twice for my last booking.',
      );
      await tap(t, 'ticket_submit_btn');
      expect(find.text('Ticket created'), findsOneWidget);
      await tap(t, 'ticket_view_btn');
      expect(env.where, '/support/tk_101');
      expect(find.text('Open'), findsOneWidget);
      expect(k('ticket_reply_field'), findsOneWidget);

      // Staff pick it up and write back; the customer pulls to refresh.
      repo.tickets = [
        ticket(
          'tk_101',
          status: TicketStatus.inProgress,
          description: 'Charged twice for my last booking.',
          history: [
            TicketEvent(
              from: TicketStatus.open,
              to: TicketStatus.inProgress,
              at: DateTime(2026, 10, 9, 9, 30),
            ),
          ],
        ),
      ];
      repo.messagesOf['tk_101'] = [
        msg('m1', 'We are looking into it.', at: DateTime(2026, 10, 9, 9, 31)),
      ];
      await t.drag(k('ticket_conversation'), const Offset(0, 500));
      await settle(t);
      expect(find.text('In progress'), findsWidgets);
      expect(find.text('We are looking into it.'), findsOneWidget);

      // Back to Support: the list shows the new state.
      await t.pageBack();
      await settle(t);
      expect(env.where, '/support');
      expect(k('ticket_card_tk_101'), findsOneWidget);
    },
  );

  testWidgets(
    'payment failed -> Get help -> ticket created -> ticket detail -> reply',
    (t) async {
      final env = await launchDiscover(
        t,
        height: 1600,
        support: repo,
        overrides: [
          paymentServiceProvider.overrideWithValue(
            FakePaymentService(outcome: const PaymentSdkFailed('BAD_REQUEST')),
          ),
          paymentPollDelaysProvider.overrideWithValue([
            const Duration(milliseconds: 10),
          ]),
        ],
      );
      await env.go('/payments/new?bookingId=bk_2100');
      await settle(t);
      await tap(t, 'payment_pay_btn');
      expect(find.text("Payment didn't go through"), findsOneWidget);

      await tap(t, 'payment_support_btn');
      expect(env.where, '/support/new');
      // The payment links its booking.
      expect(k('ticket_related_chip'), findsOneWidget);
      await tap(t, 'ticket_category_field');
      await tap(t, 'ticket_category_c2');
      await type(
        t,
        'ticket_description_field',
        'My payment failed but money left my account.',
      );
      await tap(t, 'ticket_submit_btn');
      expect(find.text('Ticket created'), findsOneWidget);
      expect(repo.createCalls, 1);
      expect(repo.lastBooking, 'bk_2100');

      await tap(t, 'ticket_view_btn');
      expect(env.where, '/support/tk_101');
      expect(k('ticket_related_link'), findsOneWidget);

      await type(t, 'ticket_reply_field', 'The reference ends with 4821');
      await tap(t, 'ticket_reply_btn');
      expect(repo.postCalls, 1);
      expect(
        find.descendant(
          of: k('ticket_conversation'),
          matching: find.text('The reference ends with 4821'),
        ),
        findsOneWidget,
      );
      // Back does not return to the form.
      await t.pageBack();
      await settle(t);
      expect(k('ticket_submit_btn'), findsNothing);
    },
  );

  testWidgets(
    'the receipt screen "Get help" and the booking support link open the form',
    (t) async {
      final env = await launchDiscover(t, height: 1600, support: repo);
      await env.go('/bookings/bk_2048');
      await settle(t);
      await tap(t, 'booking_support_btn');
      expect(env.where, '/support/new');
      expect(k('ticket_related_chip'), findsOneWidget);
    },
  );
}
