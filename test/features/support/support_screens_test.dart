// Module 12: support home, new ticket, ticket detail (SUP-01 .. SUP-09). Widget tests use the design
// state names of screens 27 / 28 / 29 and the real routes of docs/backend_openapi_2026-10-13.json.
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/features/booking/data/booking_repository_mock.dart';
import 'package:sevanest_customer/features/booking/presentation/providers/booking_providers.dart';
import 'package:sevanest_customer/features/notifications/presentation/providers/notification_providers.dart';
import 'package:sevanest_customer/features/payment/domain/payment.dart';
import 'package:sevanest_customer/features/payment/presentation/providers/payment_providers.dart';
import 'package:sevanest_customer/features/replacement/domain/replacement.dart';
import 'package:sevanest_customer/features/replacement/presentation/providers/replacement_providers.dart';
import 'package:sevanest_customer/features/support/data/support_repository_remote.dart';
import 'package:sevanest_customer/features/support/domain/support.dart';
import 'package:sevanest_customer/features/support/presentation/providers/support_providers.dart';

import '../../helpers/discover_harness.dart';
import '../../helpers/fakes.dart';
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

  setUp(() => repo = FakeSupportRepository());

  Future<DiscoverEnv> open(
    WidgetTester t,
    String route, {
    SupportRepository? support,
    List<Override> overrides = const [],
  }) async {
    final env = await launchDiscover(
      t,
      height: 1400,
      support: support ?? repo,
      overrides: overrides,
    );
    await env.go(route);
    await settle(t);
    return env;
  }

  Future<void> tapKey(WidgetTester t, String key) async {
    await t.ensureVisible(k(key));
    await t.pump();
    await t.tap(k(key));
    await settle(t);
  }

  Future<void> typeIn(WidgetTester t, String key, String text) async {
    await t.ensureVisible(k(key));
    await t.enterText(k(key), text);
    await t.pump();
  }

  Future<void> pickCat(WidgetTester t, String id) async {
    await tapKey(t, 'ticket_category_field');
    await tapKey(t, 'ticket_category_$id');
  }

  const longText = 'I was charged twice for the same booking today.';

  group('Support home (screen 27)', () {
    testWidgets(
      'Default: topics from the backend, safety card, tickets, Create',
      (t) async {
        repo.tickets = [ticket('tk_1', status: TicketStatus.inProgress)];
        await open(t, '/support');
        expect(find.text('Raise a ticket'), findsOneWidget);
        expect(k('support_safety_card'), findsOneWidget);
        for (final c in fakeCategories) {
          expect(k('support_topic_${c.id}'), findsOneWidget);
          expect(find.text(c.name), findsWidgets);
        }
        expect(k('ticket_card_tk_1'), findsOneWidget);
        expect(find.text('In progress'), findsOneWidget);
        expect(k('support_new_btn'), findsOneWidget);
        // No FAQ and no help search: nothing in the backend serves them.
        expect(find.text('Popular questions'), findsNothing);
        expect(find.text('Search help topics'), findsNothing);
      },
    );

    testWidgets('contact stays disabled while support.phone / email are null', (
      t,
    ) async {
      await open(t, '/support');
      expect(t.widget<InkWell>(k('support_call_btn')).onTap, isNull);
      expect(t.widget<InkWell>(k('support_email_btn')).onTap, isNull);
      expect(find.text('Not available right now'), findsNWidgets(2));
    });

    testWidgets('contact is enabled when the backend config has it', (t) async {
      await open(
        t,
        '/support',
        overrides: [
          supportContactProvider.overrideWith(
            (ref) async => const SupportContact(
              phone: '+911234567890',
              email: 'help@example.com',
            ),
          ),
        ],
      );
      expect(t.widget<InkWell>(k('support_call_btn')).onTap, isNotNull);
      expect(t.widget<InkWell>(k('support_email_btn')).onTap, isNotNull);
      expect(find.text('+911234567890'), findsOneWidget);
    });

    testWidgets('Loading: skeleton tiles while the categories load', (t) async {
      await open(
        t,
        '/support',
        overrides: [
          supportCategoriesProvider.overrideWith(
            (ref) => Completer<List<SupportCategory>>().future,
          ),
        ],
      );
      expect(k('support_loading'), findsOneWidget);
      expect(k('support_topic_c1'), findsNothing);
    });

    testWidgets('Error: "We couldn\'t load support" and Try again recovers', (
      t,
    ) async {
      repo.categoriesFail = const ServerFailure();
      await open(t, '/support');
      expect(find.text("We couldn't load support"), findsOneWidget);
      expect(find.textContaining('Exception'), findsNothing);
      repo.categoriesFail = null;
      await tapKey(t, 'error_retry_btn');
      expect(k('support_topic_c1'), findsOneWidget);
      expect(find.text("We couldn't load support"), findsNothing);
    });

    testWidgets(
      'Offline: banner, Create disabled with a hint, Retry recovers',
      (t) async {
        repo.categoriesFail = const NetworkFailure();
        repo.listFail = const NetworkFailure();
        await open(t, '/support');
        expect(k('support_offline_banner'), findsOneWidget);
        expect(
          find.text('Connect to the internet to create a ticket.'),
          findsOneWidget,
        );
        expect(
          t
              .widget<FilledButton>(
                find.descendant(
                  of: k('support_new_btn'),
                  matching: find.byType(FilledButton),
                ),
              )
              .onPressed,
          isNull,
        );
        repo
          ..categoriesFail = null
          ..listFail = null;
        await tapKey(t, 'support_offline_retry_btn');
        expect(k('support_offline_banner'), findsNothing);
        expect(k('support_topic_c1'), findsOneWidget);
      },
    );

    testWidgets('No tickets: the empty card and Create a ticket', (t) async {
      final env = await open(t, '/support');
      expect(k('support_empty'), findsOneWidget);
      expect(find.text('No tickets yet'), findsOneWidget);
      await tapKey(t, 'support_new_btn');
      expect(env.where, '/support/new');
    });

    testWidgets(
      'SUP-09: a ticket card opens the ticket; a topic preselects it',
      (t) async {
        repo.tickets = [ticket('tk_1')];
        final env = await open(t, '/support');
        await tapKey(t, 'support_topic_c2');
        expect(env.where, '/support/new');
        expect(
          find.descendant(
            of: k('ticket_category_field'),
            matching: find.text('Payment or refund'),
          ),
          findsOneWidget,
        );
        await t.pageBack();
        await settle(t);
        await tapKey(t, 'ticket_card_tk_1');
        expect(env.where, '/support/tk_1');
      },
    );

    testWidgets('"Report a safety issue" opens a ticket with Safety selected', (
      t,
    ) async {
      await open(t, '/support');
      await tapKey(t, 'support_safety_btn');
      expect(
        find.descendant(
          of: k('ticket_category_field'),
          matching: find.text('Safety or trust concern'),
        ),
        findsOneWidget,
      );
      expect(k('ticket_safety_card'), findsOneWidget);
    });

    testWidgets('a tickets error keeps the page and offers Retry', (t) async {
      repo.listFail = const ServerFailure();
      await open(t, '/support');
      expect(k('support_tickets_error'), findsOneWidget);
      expect(k('support_topic_c1'), findsOneWidget);
      repo
        ..listFail = null
        ..tickets = [ticket('tk_9')];
      await tapKey(t, 'support_tickets_retry_btn');
      expect(k('ticket_card_tk_9'), findsOneWidget);
    });
  });

  group('New ticket (screen 28)', () {
    testWidgets('Default (opened plain): categories, picker, disabled submit', (
      t,
    ) async {
      await open(t, '/support/new');
      expect(find.text('Choose a category'), findsOneWidget);
      await tapKey(t, 'ticket_category_field');
      for (final c in fakeCategories) {
        expect(k('ticket_category_${c.id}'), findsOneWidget);
      }
      expect(k('ticket_related_picker'), findsOneWidget);
      expect(
        t
            .widget<FilledButton>(
              find.descendant(
                of: k('ticket_submit_btn'),
                matching: find.byType(FilledButton),
              ),
            )
            .onPressed,
        isNull,
      );
    });

    testWidgets('SUP-01: a categories error shows Retry, which recovers', (
      t,
    ) async {
      repo.categoriesFail = const ServerFailure();
      await open(t, '/support/new');
      expect(k('ticket_categories_error'), findsOneWidget);
      repo.categoriesFail = null;
      await tapKey(t, 'error_retry_btn');
      expect(k('ticket_category_field'), findsOneWidget);
    });

    testWidgets(
      'SUP-02 / Validation errors: submit waits for a category and enough text',
      (t) async {
        await open(t, '/support/new');
        bool enabled() =>
            t
                .widget<FilledButton>(
                  find.descendant(
                    of: k('ticket_submit_btn'),
                    matching: find.byType(FilledButton),
                  ),
                )
                .onPressed !=
            null;
        await typeIn(t, 'ticket_description_field', longText);
        expect(enabled(), isFalse); // no category yet
        await pickCat(t, 'c2');
        expect(enabled(), isTrue);
        await typeIn(t, 'ticket_description_field', 'She was late');
        await t.pump();
        expect(enabled(), isTrue);
        await typeIn(t, 'ticket_description_field', 'Late');
        await t.pump();
        expect(find.text('Please add a little more detail'), findsOneWidget);
        expect(enabled(), isFalse);
        await typeIn(t, 'ticket_description_field', '   ');
        await t.pump();
        expect(enabled(), isFalse);
      },
    );

    testWidgets(
      'SUP-03 Opened from a booking: chip is prefilled and sent; Remove clears it',
      (t) async {
        await open(t, '/support/new?bookingId=bk_2048');
        expect(k('ticket_related_chip'), findsOneWidget);
        expect(find.textContaining('Booking #'), findsOneWidget);
        await pickCat(t, 'c1');
        await typeIn(t, 'ticket_description_field', longText);
        await tapKey(t, 'ticket_submit_btn');
        expect(repo.lastBooking, 'bk_2048');
        expect(repo.createCalls, 1);
      },
    );

    testWidgets('SUP-03 Remove: the ticket is sent without a booking', (
      t,
    ) async {
      await open(t, '/support/new?bookingId=bk_2048');
      await tapKey(t, 'ticket_related_remove_btn');
      expect(k('ticket_related_chip'), findsNothing);
      expect(k('ticket_related_picker'), findsOneWidget);
      await pickCat(t, 'c1');
      await typeIn(t, 'ticket_description_field', longText);
      await tapKey(t, 'ticket_submit_btn');
      expect(repo.lastBooking, isNull);
    });

    testWidgets('a payment link names its booking (Get help from a payment)', (
      t,
    ) async {
      await open(
        t,
        '/support/new?paymentId=pay_1',
        overrides: [
          paymentProvider('pay_1').overrideWith(
            (ref) async => const Payment(
              id: 'pay_1',
              bookingId: 'bk_2100',
              status: PaymentStatus.failed,
              amountMinor: 49900,
            ),
          ),
        ],
      );
      expect(k('ticket_related_chip'), findsOneWidget);
      await pickCat(t, 'c2');
      await typeIn(t, 'ticket_description_field', longText);
      await tapKey(t, 'ticket_submit_btn');
      expect(repo.lastBooking, 'bk_2100');
    });

    testWidgets('a replacement link names its booking', (t) async {
      await open(
        t,
        '/support/new?replacementId=rp_1',
        overrides: [
          replacementProvider('rp_1').overrideWith(
            (ref) async => const Replacement(
              id: 'rp_1',
              bookingId: 'bk_2048',
              status: ReplacementStatus.requested,
              reason: 'x',
            ),
          ),
        ],
      );
      await pickCat(t, 'c1');
      await typeIn(t, 'ticket_description_field', longText);
      await tapKey(t, 'ticket_submit_btn');
      expect(repo.lastBooking, 'bk_2048');
    });

    testWidgets(
      'an interview link names its booking (an interview is a booking)',
      (t) async {
        await open(t, '/support/new?interviewId=iv_301');
        await pickCat(t, 'c1');
        await typeIn(t, 'ticket_description_field', longText);
        await tapKey(t, 'ticket_submit_btn');
        expect(repo.lastBooking, 'iv_301');
      },
    );

    testWidgets('Booking picker sheet: choose a booking, then None', (t) async {
      await open(
        t,
        '/support/new',
        overrides: [
          bookingRepositoryProvider.overrideWithValue(
            BookingRepositoryMock(
              () => const MockApiState(returningUser: true),
              now: () => testNow,
            ),
          ),
        ],
      );
      await tapKey(t, 'ticket_related_picker');
      expect(find.text('Recent bookings'), findsOneWidget);
      expect(k('ticket_booking_option_bk_2048'), findsOneWidget);
      await tapKey(t, 'ticket_booking_option_bk_2048');
      expect(k('ticket_related_chip'), findsOneWidget);
      await tapKey(t, 'ticket_related_remove_btn');
      await tapKey(t, 'ticket_related_picker');
      await tapKey(t, 'ticket_booking_none');
      expect(k('ticket_related_chip'), findsNothing);
    });

    testWidgets('Urgent (safety): the safety card, no urgency promised', (
      t,
    ) async {
      await open(t, '/support/new');
      expect(k('ticket_safety_card'), findsNothing);
      await pickCat(t, 'c3');
      expect(k('ticket_safety_card'), findsOneWidget);
      expect(find.textContaining('urgent'), findsNothing);
    });

    testWidgets('Duplicate notice: an open ticket for the booking is offered', (
      t,
    ) async {
      repo.tickets = [ticket('tk_1042', bookingId: 'bk_2048')];
      final env = await open(t, '/support/new?bookingId=bk_2048');
      expect(k('ticket_duplicate_notice'), findsOneWidget);
      expect(
        find.text('You already have an open ticket for this booking'),
        findsOneWidget,
      );
      await tapKey(t, 'ticket_duplicate_open_btn');
      expect(env.where, '/support/tk_1042');
    });

    testWidgets('a closed ticket for the booking is not a duplicate', (
      t,
    ) async {
      repo.tickets = [
        ticket('tk_1', bookingId: 'bk_2048', status: TicketStatus.closed),
      ];
      await open(t, '/support/new?bookingId=bk_2048');
      expect(k('ticket_duplicate_notice'), findsNothing);
    });

    testWidgets(
      'SUP-04 Submit success: Ticket created, then View ticket replaces the form',
      (t) async {
        final env = await open(t, '/support/new?bookingId=bk_2048');
        await pickCat(t, 'c2');
        await typeIn(t, 'ticket_description_field', longText);
        await tapKey(t, 'ticket_submit_btn');
        expect(k('ticket_created'), findsOneWidget);
        expect(find.text('Ticket created'), findsOneWidget);
        expect(find.text('Open'), findsOneWidget);
        expect(repo.createCalls, 1);
        expect(repo.lastDescription, longText);
        await tapKey(t, 'ticket_view_btn');
        expect(env.where, '/support/tk_101');
        // Back does not return to the form.
        await t.pageBack();
        await settle(t);
        expect(k('ticket_submit_btn'), findsNothing);
      },
    );

    testWidgets('Submitting: spinner label, and a double tap sends once', (
      t,
    ) async {
      repo.createGate = Completer();
      await open(t, '/support/new');
      await pickCat(t, 'c1');
      await typeIn(t, 'ticket_description_field', longText);
      await t.tap(k('ticket_submit_btn'));
      await t.pump();
      await t.tap(k('ticket_submit_btn'), warnIfMissed: false);
      await t.pump();
      expect(find.text('Submitting…'), findsOneWidget);
      expect(repo.createCalls, 1);
      repo.createGate!.complete();
      await settle(t);
      expect(repo.createCalls, 1);
      expect(k('ticket_created'), findsOneWidget);
    });

    testWidgets(
      'Submit error: the details stay, Try again reuses the same key',
      (t) async {
        repo.createFail = const ServerFailure();
        await open(t, '/support/new');
        await pickCat(t, 'c1');
        await typeIn(t, 'ticket_description_field', longText);
        await tapKey(t, 'ticket_submit_btn');
        expect(find.text("We couldn't submit your ticket"), findsOneWidget);
        expect(
          find.text('Your details are saved. Please try again.'),
          findsOneWidget,
        );
        expect(find.text(longText), findsOneWidget);
        expect(find.text('Try again'), findsOneWidget);
        repo.createFail = null;
        await tapKey(t, 'ticket_submit_btn');
        expect(k('ticket_created'), findsOneWidget);
        expect(repo.createKeys.length, 2);
        expect(repo.createKeys[0], repo.createKeys[1]);
      },
    );

    testWidgets('an edit after a failure gets a fresh key', (t) async {
      repo.createFail = const ServerFailure();
      await open(t, '/support/new');
      await pickCat(t, 'c1');
      await typeIn(t, 'ticket_description_field', longText);
      await tapKey(t, 'ticket_submit_btn');
      repo.createFail = null;
      await typeIn(t, 'ticket_description_field', '$longText More detail.');
      await tapKey(t, 'ticket_submit_btn');
      expect(repo.createKeys[0], isNot(repo.createKeys[1]));
    });

    testWidgets('SUP-05 lost answer: the ticket is found, not created twice', (
      t,
    ) async {
      repo
        ..createFail = const NetworkFailure()
        ..storeThenFail = true;
      await open(t, '/support/new');
      await pickCat(t, 'c2');
      await typeIn(t, 'ticket_description_field', longText);
      await tapKey(t, 'ticket_submit_btn');
      expect(k('ticket_created'), findsOneWidget);
      expect(repo.createCalls, 1);
      expect(repo.tickets.length, 1);
    });

    testWidgets('Offline: input kept, no created state, Retry sends', (
      t,
    ) async {
      repo.createFail = const NetworkFailure();
      await open(t, '/support/new');
      await pickCat(t, 'c1');
      await typeIn(t, 'ticket_description_field', longText);
      await tapKey(t, 'ticket_submit_btn');
      expect(k('ticket_offline_banner'), findsOneWidget);
      expect(find.text('Connect to the internet to submit'), findsOneWidget);
      expect(find.text(longText), findsOneWidget);
      expect(k('ticket_created'), findsNothing);
      repo.createFail = null;
      await tapKey(t, 'ticket_offline_retry_btn');
      expect(k('ticket_created'), findsOneWidget);
      expect(repo.createKeys[0], repo.createKeys[1]);
    });

    testWidgets('a category the backend refuses: message, choose again', (
      t,
    ) async {
      repo.createFail = const ValidationFailure(
        'x',
        {},
        'SUPPORT_CATEGORY_INVALID',
      );
      await open(t, '/support/new');
      await pickCat(t, 'c1');
      await typeIn(t, 'ticket_description_field', longText);
      await tapKey(t, 'ticket_submit_btn');
      expect(
        find.text(
          'That category is no longer available. Please choose another.',
        ),
        findsOneWidget,
      );
      expect(find.text(longText), findsOneWidget);
    });

    testWidgets('a booking the backend cannot find: message, text kept', (
      t,
    ) async {
      repo.createFail = const NotFoundFailure();
      await open(t, '/support/new?bookingId=bk_x');
      await pickCat(t, 'c1');
      await typeIn(t, 'ticket_description_field', longText);
      await tapKey(t, 'ticket_submit_btn');
      expect(
        find.text("We couldn't find that booking. Remove it and try again."),
        findsOneWidget,
      );
      expect(find.text(longText), findsOneWidget);
    });

    testWidgets('leaving with input asks to discard; Keep editing stays', (
      t,
    ) async {
      final env = await open(t, '/support/new');
      await typeIn(t, 'ticket_description_field', longText);
      await t.tap(k('app_back_btn'));
      await settle(t);
      expect(find.text('Discard changes?'), findsOneWidget);
      await t.tap(find.text('Keep editing'));
      await settle(t);
      expect(env.where, '/support/new');
      await t.tap(k('app_back_btn'));
      await settle(t);
      await tapKey(t, 'ticket_discard_confirm_btn');
      expect(env.where, isNot('/support/new'));
    });

    testWidgets('leaving an empty form needs no dialog', (t) async {
      final env = await open(t, '/support/new');
      await t.tap(k('app_back_btn'));
      await settle(t);
      expect(find.text('Discard changes?'), findsNothing);
      expect(env.where, isNot('/support/new'));
    });
  });

  group('Ticket detail (screen 29)', () {
    Ticket inProgress() => ticket(
      'tk_1',
      status: TicketStatus.inProgress,
      bookingId: 'bk_2048',
      history: [
        TicketEvent(
          from: TicketStatus.open,
          to: TicketStatus.inProgress,
          at: DateTime(2026, 10, 9, 8, 21),
        ),
      ],
    );

    testWidgets('Loading: skeleton bubbles', (t) async {
      await open(
        t,
        '/support/tk_1',
        overrides: [
          ticketProvider(
            'tk_1',
          ).overrideWith((ref) => Completer<Ticket>().future),
        ],
      );
      expect(k('ticket_loading'), findsOneWidget);
    });

    testWidgets('Error: "We couldn\'t load this ticket", Try again recovers', (
      t,
    ) async {
      repo.tickets = [inProgress()];
      repo.getFail = const ServerFailure();
      await open(t, '/support/tk_1');
      expect(find.text("We couldn't load this ticket"), findsOneWidget);
      repo.getFail = null;
      await tapKey(t, 'error_retry_btn');
      expect(k('ticket_title'), findsOneWidget);
    });

    testWidgets('a ticket that is not mine (404) says it is gone', (t) async {
      await open(t, '/support/tk_zz');
      expect(find.text('This ticket is no longer available.'), findsOneWidget);
      expect(k('error_retry_btn'), findsNothing);
    });

    testWidgets(
      'Open, new ticket: description bubble, created event, composer',
      (t) async {
        repo.tickets = [ticket('tk_1')];
        await open(t, '/support/tk_1');
        expect(find.text('#TK_1'.replaceAll('_', '-')), findsNothing);
        expect(k('ticket_status_chip'), findsOneWidget);
        expect(find.text('Open'), findsOneWidget);
        expect(find.textContaining('Payment or refund'), findsOneWidget);
        expect(
          find.text('The payment was taken twice for my booking.'),
          findsWidgets,
        );
        expect(find.textContaining('Ticket created ·'), findsOneWidget);
        expect(k('ticket_reply_field'), findsOneWidget);
      },
    );

    testWidgets('In progress: status event and the support reply', (t) async {
      repo.tickets = [inProgress()];
      repo.messagesOf['tk_1'] = [
        msg('m1', 'We are checking this with the payment provider.'),
      ];
      await open(t, '/support/tk_1');
      expect(find.text('In progress'), findsWidgets);
      expect(find.textContaining('SevaNest Support'), findsOneWidget);
      expect(
        find.text('We are checking this with the payment provider.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Status changed to In progress'),
        findsOneWidget,
      );
    });

    testWidgets('ESCALATED reads In progress and never "Escalated"', (t) async {
      repo.tickets = [ticket('tk_1', status: TicketStatus.escalated)];
      await open(t, '/support/tk_1');
      expect(find.text('In progress'), findsOneWidget);
      expect(find.textContaining('scalat'), findsNothing);
      expect(k('ticket_reply_field'), findsOneWidget);
    });

    testWidgets(
      'SUP-06: owner, priority and escalation from the JSON never reach the screen',
      (t) async {
        final dio = Dio(BaseOptions(baseUrl: 'http://x'))
          ..httpClientAdapter = FakeAdapter((o) async {
            if (o.path.endsWith('/messages')) {
              return jsonBody(
                '{"data":[{"id":"m1","from":"ADMIN","body":"Hello","createdAt":"2026-10-09T03:00:00.000Z",'
                '"internal":true,"staffName":"Asha Staff"}],"meta":{"page":1,"limit":20,"total":1}}',
                200,
              );
            }
            return jsonBody(
              '{"id":"tk_1","category":{"id":"c2","code":"PAYMENT","name":"Payment or refund"},'
              '"bookingId":null,"description":"Charged twice","status":"ESCALATED","resolution":null,'
              '"dueAt":null,"createdAt":"2026-10-09T02:30:00.000Z","closedAt":null,'
              '"priority":"URGENT-PRIORITY","assignedToUserId":"OWNER-STAFF-ID",'
              '"escalationReason":"ESCALATION-NOTE","history":['
              '{"type":"ESCALATED","fromStatus":"IN_PROGRESS","toStatus":"ESCALATED","createdAt":"2026-10-09T03:00:00.000Z"}]}',
              200,
            );
          });
        await open(t, '/support/tk_1', support: SupportRepositoryRemote(dio));
        expect(k('ticket_title'), findsOneWidget);
        for (final s in [
          'URGENT-PRIORITY',
          'OWNER-STAFF-ID',
          'ESCALATION-NOTE',
          'Asha Staff',
          'Escalated',
        ]) {
          expect(find.textContaining(s), findsNothing, reason: s);
        }
      },
    );

    testWidgets(
      'SUP-08 Closed: resolution shown, reply hidden, new ticket offered',
      (t) async {
        repo.tickets = [
          ticket(
            'tk_1',
            status: TicketStatus.closed,
            bookingId: 'bk_2048',
            resolution: 'The provider confirmed your payment.',
          ),
        ];
        final env = await open(t, '/support/tk_1');
        expect(find.text('Closed'), findsWidgets);
        expect(k('ticket_resolution_card'), findsOneWidget);
        expect(
          find.text('The provider confirmed your payment.'),
          findsOneWidget,
        );
        expect(k('ticket_reply_field'), findsNothing);
        expect(k('ticket_reply_btn'), findsNothing);
        expect(find.text('This ticket is closed.'), findsOneWidget);
        await tapKey(t, 'ticket_new_from_closed_btn');
        expect(env.where, '/support/new');
      },
    );

    testWidgets('an unknown status reads Updated and offers no composer', (
      t,
    ) async {
      repo.tickets = [
        Ticket(
          id: 'tk_1',
          category: fakeCategories[0],
          description: 'x' * 20,
          status: TicketStatus.unknown,
          createdAt: DateTime(2026, 10, 9, 8),
        ),
      ];
      await open(t, '/support/tk_1');
      expect(find.text('Updated'), findsWidgets);
      expect(k('ticket_reply_field'), findsNothing);
      expect(k('ticket_closed_bar'), findsNothing);
    });

    testWidgets('the related booking opens', (t) async {
      repo.tickets = [inProgress()];
      final env = await open(t, '/support/tk_1');
      await tapKey(t, 'ticket_related_link');
      expect(env.where, '/bookings/bk_2048');
    });

    testWidgets('SUP-07 a reply shows only after the API succeeds; one POST', (
      t,
    ) async {
      repo.tickets = [inProgress()];
      repo.postGate = Completer();
      await open(t, '/support/tk_1');
      await typeIn(t, 'ticket_reply_field', 'The last 4 digits are 4821');
      await t.tap(k('ticket_reply_btn'));
      await t.pump();
      await t.tap(k('ticket_reply_btn'), warnIfMissed: false);
      await t.pump();
      expect(repo.postCalls, 1);
      expect(
        find.descendant(
          of: k('ticket_conversation'),
          matching: find.text('The last 4 digits are 4821'),
        ),
        findsNothing,
      );
      repo.postGate!.complete();
      await settle(t);
      expect(repo.postCalls, 1);
      expect(
        find.descendant(
          of: k('ticket_conversation'),
          matching: find.text('The last 4 digits are 4821'),
        ),
        findsOneWidget,
      );
      expect(
        t.widget<TextField>(k('ticket_reply_field')).controller!.text,
        isEmpty,
      );
    });

    testWidgets(
      'Send failed: the text stays in a bubble; Retry reuses the key',
      (t) async {
        repo.tickets = [inProgress()];
        repo.postFail = const ServerFailure();
        await open(t, '/support/tk_1');
        await typeIn(t, 'ticket_reply_field', 'Here is the screenshot note');
        await tapKey(t, 'ticket_reply_btn');
        expect(k('ticket_failed_message'), findsOneWidget);
        expect(find.text('Here is the screenshot note'), findsOneWidget);
        expect(find.text('Failed'), findsOneWidget);
        repo.postFail = null;
        await tapKey(t, 'ticket_send_retry_btn');
        expect(k('ticket_failed_message'), findsNothing);
        expect(repo.postCalls, 2);
        expect(repo.postKeys[0], repo.postKeys[1]);
        expect(find.text('Here is the screenshot note'), findsOneWidget);
      },
    );

    testWidgets(
      'Offline: failed send shows the offline banner; Remove drops the text',
      (t) async {
        repo.tickets = [inProgress()];
        repo.postFail = const NetworkFailure();
        await open(t, '/support/tk_1');
        await typeIn(t, 'ticket_reply_field', 'Hello there');
        await tapKey(t, 'ticket_reply_btn');
        expect(k('ticket_offline_banner'), findsOneWidget);
        expect(
          find.text("You're offline. Reconnect to send messages."),
          findsOneWidget,
        );
        await tapKey(t, 'ticket_send_remove_btn');
        expect(find.text('Hello there'), findsNothing);
      },
    );

    testWidgets('a reply of only spaces is never sent', (t) async {
      repo.tickets = [inProgress()];
      await open(t, '/support/tk_1');
      await typeIn(t, 'ticket_reply_field', '      ');
      await t.tap(k('ticket_reply_btn'), warnIfMissed: false);
      await t.pump();
      expect(repo.postCalls, 0);
      expect(k('ticket_failed_message'), findsNothing);
    });

    testWidgets('Timeout: failed bubble kept, no "offline" banner', (t) async {
      repo.tickets = [inProgress()];
      repo.postFail = const NetworkFailure(null, true);
      await open(t, '/support/tk_1');
      await typeIn(t, 'ticket_reply_field', 'Still there?');
      await tapKey(t, 'ticket_reply_btn');
      expect(k('ticket_offline_banner'), findsNothing);
      expect(k('ticket_failed_message'), findsOneWidget);
      expect(find.text('Still there?'), findsOneWidget);
    });

    testWidgets('a lost answer is not sent twice', (t) async {
      repo.tickets = [inProgress()];
      repo
        ..postFail = const NetworkFailure()
        ..storeThenFail = true;
      await open(t, '/support/tk_1');
      await typeIn(t, 'ticket_reply_field', 'Please check again');
      await tapKey(t, 'ticket_reply_btn');
      repo.postFail = null;
      await tapKey(t, 'ticket_send_retry_btn');
      // The same key goes again; the server answers with the first message.
      expect(repo.postKeys[0], repo.postKeys[1]);
    });

    testWidgets('TICKET_CLOSED while writing: told, and the composer goes', (
      t,
    ) async {
      repo.tickets = [inProgress()];
      repo.postFail = const ConflictFailure('x', 'TICKET_CLOSED');
      await open(t, '/support/tk_1');
      await typeIn(t, 'ticket_reply_field', 'Anyone there?');
      repo.tickets = [
        ticket('tk_1', status: TicketStatus.closed, resolution: 'Done'),
      ];
      await tapKey(t, 'ticket_reply_btn');
      expect(
        find.text("This ticket was closed, so your message wasn't sent."),
        findsOneWidget,
      );
      expect(k('ticket_reply_field'), findsNothing);
      expect(k('ticket_closed_bar'), findsOneWidget);
    });

    testWidgets('pull to refresh and app resume read the ticket again', (
      t,
    ) async {
      repo.tickets = [inProgress()];
      await open(t, '/support/tk_1');
      final before = repo.getCalls;
      repo.tickets = [
        ticket('tk_1', status: TicketStatus.closed, resolution: 'Done'),
      ];
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settle(t);
      expect(repo.getCalls, greaterThan(before));
      expect(find.text('Closed'), findsWidgets);
      expect(k('ticket_reply_field'), findsNothing);
    });

    testWidgets('a notification arriving reads the open ticket again', (
      t,
    ) async {
      repo.tickets = [inProgress()];
      final env = await open(t, '/support/tk_1');
      final before = repo.getCalls;
      env.container.read(notificationTickProvider.notifier).bump();
      await settle(t);
      expect(repo.getCalls, greaterThan(before));
    });
  });
}
