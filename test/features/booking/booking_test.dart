// Module 08: bookings list, detail (actions, timeline, resume), cancel sheet, confirm worker.
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/features/booking/data/booking_repository_mock.dart';
import 'package:sevanest_customer/features/booking/domain/booking.dart';
import 'package:sevanest_customer/features/booking/presentation/providers/booking_providers.dart';
import 'package:sevanest_customer/features/interview_trial/domain/interview.dart';
import 'package:sevanest_customer/features/service_discovery/domain/catalog.dart';

import '../../helpers/discover_harness.dart';
import '../../helpers/fakes.dart';

Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 3; i++) {
    await t.pumpAndSettle();
    await t.pump(const Duration(seconds: 1));
  }
  await t.pumpAndSettle();
}

/// The seeded booking mock with counters and failure hooks.
class _Spy implements BookingRepository {
  _Spy({bool returning = true})
    : inner = BookingRepositoryMock(
        () => MockApiState(returningUser: returning),
        now: () => testNow,
      );
  final BookingRepositoryMock inner;
  var getCalls = 0;
  var cancelCalls = 0;
  var confirmCalls = 0;
  String? lastReason;
  DateTime? lastStart;
  Object? confirmFails;

  /// Confirm succeeds server-side but the answer is lost.
  bool loseConfirmAnswer = false;
  Object? cancelFails;
  Object? listFails;
  Completer<void>? gate;
  Booking? forced;

  @override
  Future<Booking> create(BookingRequest r, {required String idempotencyKey}) =>
      inner.create(r, idempotencyKey: idempotencyKey);

  @override
  Future<BookingPage> list({String? cursor}) async {
    final f = listFails;
    if (f != null) throw f;
    return inner.list(cursor: cursor);
  }

  @override
  Future<Booking> get(String id, {CancelToken? cancel}) async {
    getCalls++;
    return forced ?? await inner.get(id, cancel: cancel);
  }

  @override
  Future<Booking> schedule(String id, InterviewType type, DateTime at) =>
      inner.schedule(id, type, at);

  @override
  Future<Booking> interviewComplete(String id, {String? note}) =>
      inner.interviewComplete(id, note: note);

  @override
  Future<Booking> confirmWorker(String id, DateTime startDate) async {
    confirmCalls++;
    lastStart = startDate;
    await gate?.future;
    final f = confirmFails;
    if (f != null) throw f;
    final b = await inner.confirmWorker(id, startDate);
    if (loseConfirmAnswer) throw const NetworkFailure();
    return b;
  }

  @override
  Future<Booking> reopenMatching(String id) => inner.reopenMatching(id);

  @override
  Future<Booking> rebook(String bookingId, {DateTime? startDate}) =>
      inner.rebook(bookingId, startDate: startDate);

  @override
  Future<BookingPage> history(HistoryFilter filter, {String? cursor}) =>
      inner.history(filter, cursor: cursor);

  @override
  Future<HistorySummary> historySummary(HistoryFilter filter) =>
      inner.historySummary(filter);

  @override
  Future<Booking> cancel(String id, String reason) async {
    cancelCalls++;
    lastReason = reason;
    final f = cancelFails;
    if (f != null) throw f;
    return inner.cancel(id, reason);
  }
}

void main() {
  Future<DiscoverEnv> open(
    WidgetTester t, {
    required String route,
    _Spy? spy,
    bool returning = true,
  }) async {
    final s = spy ?? _Spy(returning: returning);
    final env = await launchDiscover(
      t,
      overrides: [bookingRepositoryProvider.overrideWithValue(s)],
    );
    env.stepsOneToThree(EngagementType.fullTime);
    // Tall enough that worker-name cards don't push later ones out of the lazy list.
    t.view.physicalSize = const Size(1170, 3600);
    await env.go(route);
    await settle(t);
    return env;
  }

  Future<void> tapKey(WidgetTester t, String key) async {
    await t.ensureVisible(find.byKey(Key(key)));
    await t.pump();
    await t.tap(find.byKey(Key(key)));
    await settle(t);
  }

  group('list (8.2)', () {
    testWidgets('Current shows live bookings, Past the finished ones', (
      t,
    ) async {
      final env = await open(t, route: '/home');
      await tapKey(t, 'nav_bookings');
      expect(env.where, '/bookings');
      expect(find.byKey(const Key('booking_card_bk_2048')), findsOneWidget);
      expect(find.byKey(const Key('booking_card_iv_301')), findsOneWidget);
      expect(
        find.byKey(const Key('booking_card_worker_bk_2048')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('booking_card_bk_1900')), findsNothing);
      await tapKey(t, 'bookings_tab_past');
      expect(find.byKey(const Key('booking_card_bk_1900')), findsOneWidget);
      expect(find.byKey(const Key('booking_card_bk_1800')), findsOneWidget);
      expect(find.byKey(const Key('booking_card_bk_2048')), findsNothing);
    });

    testWidgets('a card opens its booking', (t) async {
      final env = await open(t, route: '/home');
      await tapKey(t, 'nav_bookings');
      await tapKey(t, 'booking_card_bk_2048');
      expect(env.where, '/bookings/bk_2048');
    });

    testWidgets('pending payment shows Complete payment, which opens payment', (
      t,
    ) async {
      final env = await open(t, route: '/home');
      await tapKey(t, 'nav_bookings');
      expect(
        find.byKey(const Key('booking_card_pay_btn_bk_2100')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('booking_card_pay_btn_bk_2048')),
        findsNothing,
      );
      await tapKey(t, 'booking_card_pay_btn_bk_2100');
      expect(env.where, '/payments/new');
    });

    testWidgets('BOOK-13 empty Current: message and CTA', (t) async {
      final env = await open(t, route: '/home', returning: false);
      await tapKey(t, 'nav_bookings');
      expect(find.text('No bookings yet'), findsOneWidget);
      await tapKey(t, 'bookings_empty_find_btn');
      expect(env.where, '/discover/category');
    });

    testWidgets('error shows Retry', (t) async {
      final spy = _Spy()..listFails = const ServerFailure();
      await open(t, route: '/home', spy: spy);
      await tapKey(t, 'nav_bookings');
      expect(find.byKey(const Key('error_retry_btn')), findsOneWidget);
      spy.listFails = null;
      await tapKey(t, 'error_retry_btn');
      expect(find.byKey(const Key('booking_card_bk_2048')), findsOneWidget);
    });
  });

  group('detail (8.3)', () {
    // BOOK-10: every state shows exactly the buttons its actions allow.
    const keys = {
      BookingAction.pay: 'booking_pay_btn',
      BookingAction.confirmWorker: 'booking_confirm_worker_btn',
      BookingAction.viewService: 'booking_view_service_btn',
      BookingAction.rate: 'booking_rate_btn',
      BookingAction.replace: 'booking_replace_btn',
      BookingAction.cancel: 'booking_cancel_btn',
      BookingAction.receipt: 'booking_receipt_btn',
    };
    final cases = {
      'bk_2100': BookingStatus.pendingPayment,
      'bk_2048': BookingStatus.active,
      'bk_1900': BookingStatus.completed,
      'bk_1800': BookingStatus.cancelled,
      'iv_302': BookingStatus.interviewTrialCompleted,
    };
    for (final c in cases.entries) {
      testWidgets('BOOK-10 ${c.value.name}: buttons match the actions', (
        t,
      ) async {
        await open(t, route: '/bookings/${c.key}');
        final allowed = derivedBookingActions(c.value);
        for (final e in keys.entries) {
          expect(
            find.byKey(Key(e.value)),
            allowed.contains(e.key) ? findsOneWidget : findsNothing,
            reason: '${c.value.name} / ${e.key.name}',
          );
        }
        expect(find.byKey(const Key('booking_support_btn')), findsOneWidget);
      });
    }

    testWidgets('a backend allowedActions list overrides the derived one', (
      t,
    ) async {
      final spy = _Spy()
        ..forced = Booking.fromJson({
          'id': 'bk_x',
          'status': 'ACTIVE',
          'allowedActions': ['rate'],
        });
      await open(t, route: '/bookings/bk_x', spy: spy);
      expect(find.byKey(const Key('booking_rate_btn')), findsOneWidget);
      expect(find.byKey(const Key('booking_replace_btn')), findsNothing);
    });

    testWidgets('status chip and plain-language line', (t) async {
      await open(t, route: '/bookings/bk_2100');
      expect(find.text('Payment due'), findsWidgets);
      expect(
        find.text('Pay the booking fee to confirm this booking'),
        findsOneWidget,
      );
    });

    testWidgets('BOOK-15 unknown status renders as Updated', (t) async {
      final spy = _Spy()
        ..forced = Booking.fromJson({'id': 'bk_x', 'status': 'BRAND_NEW'});
      await open(t, route: '/bookings/bk_x', spy: spy);
      expect(find.text('Updated'), findsOneWidget);
      expect(find.text('Status updated'), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('BOOK-11 timeline: backend events, unknown ones read Updated', (
      t,
    ) async {
      final spy = _Spy()
        ..forced = Booking.fromJson({
          'id': 'bk_x',
          'status': 'ACTIVE',
          'timeline': [
            {'status': 'NEW_REQUEST', 'at': '2026-10-01T10:00:00Z'},
            {'status': 'WHATEVER', 'at': '2026-10-02T10:00:00Z'},
            {'status': 'ACTIVE', 'at': '2026-10-03T10:00:00Z'},
          ],
        });
      await open(t, route: '/bookings/bk_x', spy: spy);
      expect(find.text('Request received'), findsOneWidget);
      expect(find.text('Updated'), findsWidgets);
      expect(find.byIcon(Icons.check_circle), findsWidgets);
    });

    testWidgets('deployed timeline {from,to,at}; scheduled shows the time and '
        'only a reschedule button', (t) async {
      final spy = _Spy()
        ..forced = Booking.fromJson({
          'id': 'bk_x',
          'status': 'INTERVIEW_TRIAL_SCHEDULED',
          'workerId': 'w1',
          'scheduleType': 'INTERVIEW',
          'scheduledAt': '2026-11-03T10:00:00',
          'timeline': [
            {'from': null, 'to': 'NEW_REQUEST', 'at': '2026-10-01T10:00:00'},
            {
              'from': 'NEW_REQUEST',
              'to': 'MATCHED',
              'at': '2026-10-02T10:00:00',
            },
            {
              'from': 'MATCHED',
              'to': 'INTERVIEW_TRIAL_SCHEDULED',
              'at': '2026-10-03T10:00:00',
            },
          ],
        });
      await open(t, route: '/bookings/bk_x', spy: spy);
      expect(find.text('Updated'), findsNothing);
      expect(find.text('Request received'), findsOneWidget);
      expect(find.byKey(const Key('booking_schedule_btn')), findsNothing);
      expect(find.byKey(const Key('booking_interview_btn')), findsOneWidget);
      expect(find.byKey(const Key('booking_reschedule_btn')), findsOneWidget);
    });

    testWidgets('no backend events: the happy path with the current step', (
      t,
    ) async {
      final spy = _Spy()
        ..forced = Booking.fromJson({
          'id': 'bk_x',
          'status': 'PENDING_PAYMENT',
        });
      await open(t, route: '/bookings/bk_x', spy: spy);
      expect(find.text('Request received'), findsOneWidget);
      expect(find.text('Interview done'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
    });

    testWidgets('worker card, support and pay open their screens', (t) async {
      final env = await open(t, route: '/bookings/bk_2100');
      await tapKey(t, 'booking_pay_btn');
      expect(env.where, '/payments/new');
      GoRouter.of(t.element(find.byType(Scaffold).first)).pop();
      await settle(t);
      expect(env.where, '/bookings/bk_2100');
      await tapKey(t, 'booking_support_btn');
      expect(env.where, '/support/new');
      GoRouter.of(t.element(find.byType(Scaffold).first)).pop();
      await settle(t);
      await tapKey(t, 'booking_worker_card');
      expect(env.where, '/workers/cook-8');
    });

    testWidgets('Confirm this worker opens the confirmation', (t) async {
      final env = await open(t, route: '/bookings/iv_302');
      await tapKey(t, 'booking_confirm_worker_btn');
      expect(env.where, '/bookings/confirm');
    });

    testWidgets('BOOK-14 refetches when the app resumes', (t) async {
      final spy = _Spy();
      await open(t, route: '/bookings/bk_2100', spy: spy);
      final before = spy.getCalls;
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settle(t);
      expect(spy.getCalls, greaterThan(before));
    });

    testWidgets('unknown booking shows the error with Retry', (t) async {
      await open(t, route: '/bookings/nope');
      expect(find.byKey(const Key('error_retry_btn')), findsOneWidget);
    });
  });

  group('cancel sheet (8.4)', () {
    testWidgets('BOOK-12 reason required; confirm calls the API once', (
      t,
    ) async {
      final spy = _Spy();
      await open(t, route: '/bookings/bk_2100', spy: spy);
      await tapKey(t, 'booking_cancel_btn');
      final confirm = find.descendant(
        of: find.byKey(const Key('cancel_confirm_btn')),
        matching: find.byType(FilledButton),
      );
      expect(t.widget<FilledButton>(confirm).onPressed, isNull);
      await tapKey(t, 'cancel_reason_1');
      await t.enterText(find.byKey(const Key('cancel_note_field')), 'Moving');
      await t.pump();
      await tapKey(t, 'cancel_confirm_btn');
      expect(spy.cancelCalls, 1);
      expect(spy.lastReason, 'My plans changed: Moving');
      expect(find.byKey(const Key('cancel_confirm_btn')), findsNothing);
      expect(find.text('Cancellation requested'), findsOneWidget);
      expect(find.text('Cancelled'), findsWidgets); // detail refetched
      expect(find.byKey(const Key('booking_cancel_btn')), findsNothing);
    });

    testWidgets('Keep booking closes the sheet and changes nothing', (t) async {
      final spy = _Spy();
      await open(t, route: '/bookings/bk_2100', spy: spy);
      await tapKey(t, 'booking_cancel_btn');
      await tapKey(t, 'cancel_dismiss_btn');
      expect(spy.cancelCalls, 0);
      expect(find.byKey(const Key('booking_cancel_btn')), findsOneWidget);
    });

    testWidgets('a failure stays in the sheet with the reason kept', (t) async {
      final spy = _Spy()..cancelFails = const ServerFailure();
      await open(t, route: '/bookings/bk_2100', spy: spy);
      await tapKey(t, 'booking_cancel_btn');
      await tapKey(t, 'cancel_reason_0');
      await tapKey(t, 'cancel_confirm_btn');
      expect(find.byKey(const Key('cancel_error')), findsOneWidget);
      expect(find.byKey(const Key('cancel_confirm_btn')), findsOneWidget);
      spy.cancelFails = null;
      await tapKey(t, 'cancel_confirm_btn');
      expect(find.byKey(const Key('cancel_confirm_btn')), findsNothing);
      expect(spy.cancelCalls, 2);
    });
  });

  group('confirm worker (8.1)', () {
    const route = '/bookings/confirm?interviewId=iv_302';

    testWidgets('shows the worker, requirement, start date and the fee note', (
      t,
    ) async {
      await open(t, route: route);
      expect(find.byKey(const Key('confirm_worker_card')), findsOneWidget);
      expect(find.byKey(const Key('confirm_start_date_btn')), findsOneWidget);
      expect(find.byKey(const Key('confirm_fee_note')), findsOneWidget);
      // No quote endpoint yet: the marked BookingQuote mock fills the rows (fee 500 + tax 90).
      expect(find.text('₹500'), findsOneWidget);
      expect(find.text('₹90'), findsOneWidget);
      expect(find.byKey(const Key('confirm_total')), findsOneWidget);
    });

    testWidgets('BOOK-02 Confirm is disabled while the booking loads', (
      t,
    ) async {
      final env = await launchDiscover(
        t,
        overrides: [bookingRepositoryProvider.overrideWithValue(_Spy())],
      );
      await env.go(route);
      await t.pump(const Duration(milliseconds: 50));
      final b = find.descendant(
        of: find.byKey(const Key('confirm_pay_btn')),
        matching: find.byType(FilledButton),
      );
      expect(t.widget<FilledButton>(b).onPressed, isNull);
      await settle(t);
      expect(t.widget<FilledButton>(b).onPressed, isNotNull);
    });

    testWidgets(
      'BOOK-03 Confirm moves it to payment due and opens the booking',
      (t) async {
        final spy = _Spy();
        final env = await open(t, route: route, spy: spy);
        await tapKey(t, 'confirm_pay_btn');
        expect(spy.confirmCalls, 1);
        expect(env.where, '/bookings/iv_302');
        expect(find.byKey(const Key('booking_pay_btn')), findsOneWidget);
        // Back from here does not return to the confirmation.
        GoRouter.of(t.element(find.byType(Scaffold).first)).pop();
        await settle(t);
        expect(env.where, isNot('/bookings/confirm'));
      },
    );

    testWidgets('the chosen start date is sent', (t) async {
      final spy = _Spy();
      await open(t, route: route, spy: spy);
      await tapKey(t, 'confirm_start_date_btn');
      await t.tap(find.text('OK'));
      await settle(t);
      await tapKey(t, 'confirm_pay_btn');
      expect(spy.lastStart, isNotNull);
      expect(spy.lastStart!.isBefore(DateTime(2026, 10, 9)), isFalse);
    });

    testWidgets('BOOK-04 double tap confirms once', (t) async {
      final spy = _Spy()..gate = Completer();
      await open(t, route: route, spy: spy);
      final btn = find.byKey(const Key('confirm_pay_btn'));
      await t.tap(btn);
      await t.pump();
      await t.tap(btn, warnIfMissed: false);
      await t.pump();
      expect(spy.confirmCalls, 1);
      spy.gate!.complete();
      await settle(t);
      expect(spy.confirmCalls, 1);
    });

    testWidgets('BOOK-06 worker no longer eligible: dialog, Find another', (
      t,
    ) async {
      final spy = _Spy()
        ..confirmFails = const ValidationFailure(
          'gone',
          {},
          'WORKER_NOT_ELIGIBLE',
        );
      final env = await open(t, route: route, spy: spy);
      await tapKey(t, 'confirm_pay_btn');
      expect(find.text('This worker is no longer available'), findsOneWidget);
      await tapKey(t, 'confirm_find_another_btn');
      expect(env.where, '/workers');
    });

    testWidgets(
      'BOOK-07 lost answer: finds the confirmed booking and goes on',
      (t) async {
        final spy = _Spy()..loseConfirmAnswer = true;
        final env = await open(t, route: route, spy: spy);
        await tapKey(t, 'confirm_pay_btn');
        expect(find.byKey(const Key('confirm_error')), findsNothing);
        expect(env.where, '/bookings/iv_302');
      },
    );

    testWidgets('a real network failure shows the error and stays', (t) async {
      final spy = _Spy()..confirmFails = const NetworkFailure();
      final env = await open(t, route: route, spy: spy);
      await tapKey(t, 'confirm_pay_btn');
      expect(find.byKey(const Key('confirm_error')), findsOneWidget);
      expect(env.where, '/bookings/confirm');
    });

    testWidgets('not confirmable any more (409): says so', (t) async {
      final spy = _Spy()
        ..confirmFails = const ConflictFailure('x', 'INVALID_TRANSITION');
      await open(t, route: route, spy: spy);
      await tapKey(t, 'confirm_pay_btn');
      expect(
        find.text("This booking can't be confirmed right now."),
        findsOneWidget,
      );
    });

    testWidgets('Edit requirement opens the review screen', (t) async {
      final env = await open(t, route: route);
      await tapKey(t, 'confirm_edit_req_btn');
      expect(env.where, '/discover/review');
    });

    testWidgets('BOOK-16 Flow E: interview -> confirm -> booking -> payment', (
      t,
    ) async {
      final env = await open(t, route: '/interviews/iv_302');
      await tapKey(t, 'interview_confirm_worker_btn');
      expect(env.where, '/bookings/confirm');
      await tapKey(t, 'confirm_pay_btn');
      expect(env.where, '/bookings/iv_302');
      await tapKey(t, 'booking_pay_btn');
      expect(env.where, '/payments/new');
      // Back from payment returns to the booking, not the confirmation.
      GoRouter.of(t.element(find.byType(Scaffold).first)).pop();
      await settle(t);
      expect(env.where, '/bookings/iv_302');
    });
  });
}
