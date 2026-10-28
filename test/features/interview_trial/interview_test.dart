// Module 07: interviews are states of a booking. Statuses, the booking-backed repositories,
// request form, detail actions, list, Flow D.
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/features/booking/data/booking_repository_mock.dart';
import 'package:sevanest_customer/features/booking/data/booking_repository_remote.dart';
import 'package:sevanest_customer/features/booking/domain/booking.dart';
import 'package:sevanest_customer/features/interview_trial/data/interview_repository_over_bookings.dart';
import 'package:sevanest_customer/features/interview_trial/domain/interview.dart';
import 'package:sevanest_customer/features/interview_trial/presentation/providers/interview_providers.dart';
import 'package:sevanest_customer/features/service_discovery/domain/budget.dart';
import 'package:sevanest_customer/features/service_discovery/domain/catalog.dart';
import 'package:sevanest_customer/features/worker_search/data/worker_search_repository_mock.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/discover_harness.dart';
import '../../helpers/fakes.dart';
import '../../helpers/notification_fakes.dart';

/// Chained mock calls each need their own wait: pumpAndSettle ignores the latency timers.
Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 3; i++) {
    await t.pumpAndSettle();
    await t.pump(const Duration(seconds: 1));
  }
  await t.pumpAndSettle();
}

/// The booking-backed interview repository on the seeded booking mock, with counters and failure
/// hooks.
class _Spy implements InterviewRepository {
  _Spy({bool returning = true})
    : inner = InterviewRepositoryOverBookings(
        BookingRepositoryMock(
          () => MockApiState(returningUser: returning),
          now: () => testNow,
        ),
        WorkerSearchRepositoryMock(
          () => const MockApiState(returningUser: true),
        ),
        areaIdFor: (d) async => d.address!.area,
        now: () => testNow,
      );
  final InterviewRepositoryOverBookings inner;
  final keys = <String>[];
  var createCalls = 0;
  var cancelCalls = 0;
  var declineCalls = 0;
  var completeCalls = 0;
  Object? createFails;

  /// Fails the first create with this, then behaves.
  Object? createFailsOnce;

  /// Create succeeds server-side but the answer is lost (network error).
  bool loseAnswer = false;
  Completer<void>? gate;
  Interview? forced;

  @override
  Future<String?> interviewIdFor(String bookingId, {bool openOnly = false}) =>
      inner.interviewIdFor(bookingId, openOnly: openOnly);

  @override
  Future<Interview> create(
    InterviewRequest r, {
    required String idempotencyKey,
  }) async {
    createCalls++;
    keys.add(idempotencyKey);
    await gate?.future;
    final once = createFailsOnce;
    if (once != null) {
      createFailsOnce = null;
      throw once;
    }
    final f = createFails;
    if (f != null) throw f;
    final made = await inner.create(r, idempotencyKey: idempotencyKey);
    if (loseAnswer) throw const NetworkFailure();
    return made;
  }

  @override
  Future<Interview> reschedule(
    String id,
    DateTime date,
    String slot, {
    required String idempotencyKey,
  }) => inner.reschedule(id, date, slot, idempotencyKey: idempotencyKey);

  @override
  Future<InterviewPage> list({String? cursor}) => inner.list(cursor: cursor);

  @override
  Future<Interview> get(String id, {CancelToken? cancel}) async =>
      forced ?? await inner.get(id, cancel: cancel);

  @override
  Future<Interview> cancel(String id, {String? reason}) {
    cancelCalls++;
    return inner.cancel(id, reason: reason);
  }

  @override
  Future<Interview> decline(String id) {
    declineCalls++;
    return inner.decline(id);
  }

  @override
  Future<Interview> complete(String id) {
    completeCalls++;
    return inner.complete(id);
  }

  @override
  Future<Interview> answerProposal(String id, {required bool accept}) =>
      inner.answerProposal(id, accept: accept);

  @override
  Future<List<InterviewSlot>> slots(String workerId, DateTime date) =>
      inner.slots(workerId, date);
}

void main() {
  group('status, actions, parsing', () {
    test('INT-01 every known status maps; unknown and null are neutral', () {
      expect(interviewStatusFrom('REQUESTED'), InterviewStatus.requested);
      expect(interviewStatusFrom('CONFIRMED'), InterviewStatus.scheduled);
      expect(
        interviewStatusFrom('RESCHEDULE_PROPOSED'),
        InterviewStatus.rescheduleProposed,
      );
      expect(interviewStatusFrom('COMPLETED'), InterviewStatus.completed);
      expect(interviewStatusFrom('CANCELLED'), InterviewStatus.cancelled);
      expect(interviewStatusFrom('DECLINED'), InterviewStatus.declined);
      // Not backend interview statuses any more.
      expect(interviewStatusFrom('SCHEDULED'), InterviewStatus.unknown);
      expect(interviewStatusFrom('NOT_A_FIT'), InterviewStatus.unknown);
      expect(interviewStatusFrom('SOMETHING_NEW'), InterviewStatus.unknown);
      expect(interviewStatusFrom(null), InterviewStatus.unknown);
      expect(interviewStatusFrom(7), InterviewStatus.unknown);
    });

    test('allowedActions: known kept, unknown ignored, bad shape empty', () {
      expect(
        interviewActionsFrom([
          'cancel',
          'RESCHEDULE',
          'accept-proposal',
          'reject-proposal',
          'teleport',
        ]),
        {
          InterviewAction.cancel,
          InterviewAction.reschedule,
          InterviewAction.acceptProposal,
          InterviewAction.rejectProposal,
        },
      );
      expect(interviewActionsFrom(null), isEmpty);
      expect(interviewActionsFrom('cancel'), isEmpty);
    });

    test('Interview.fromJson tolerates a bare minimum', () {
      final i = Interview.fromJson({'id': 'x'})!;
      expect(i.status, InterviewStatus.unknown);
      expect(i.actions, isEmpty);
      expect(i.date, isNull);
      expect(i.worker, isNull);
      expect(Interview.fromJson({'status': 'REQUESTED'}), isNull);
    });

    test('slot helpers', () {
      expect(parseSlot('17:30'), 1050);
      expect(parseSlot('9:05'), 545);
      expect(parseSlot('25:00'), isNull);
      expect(parseSlot('nope'), isNull);
      expect(slotId(545), '09:05');
    });
  });

  group('booking-backed repositories (deployed Swagger)', () {
    test(
      'POST /bookings sends the key and money in paise; schedule posts the time',
      () async {
        final seen = <RequestOptions>[];
        final dio = Dio(BaseOptions(baseUrl: 'http://x'))
          ..httpClientAdapter = FakeAdapter((o) async {
            seen.add(o);
            return jsonBody(
              '{"id":"bk1","status":"MATCHED","workerId":"w1","category":{"code":"COOK","name":"Cook"},'
              '"scheduleType":"TRIAL","scheduledAt":"2026-10-12T04:30:00.000Z"}',
              o.method == 'POST' && o.path == '/bookings' ? 201 : 200,
            );
          });
        final repo = BookingRepositoryRemote(dio);
        final b = await repo.create(
          BookingRequest(
            category: 'COOK',
            areaId: 'a1',
            addressId: 'ad1',
            startDate: DateTime(2026, 11, 1),
            workerId: 'w1',
            engagement: EngagementType.partTime,
            availableFrom: '09:00',
            availableTo: '13:00',
            budgetMin: 6000,
            budgetMax: 10000,
            budgetPeriod: BudgetPeriod.monthly,
            note: 'hi',
          ),
          idempotencyKey: 'k-1',
        );
        final o = seen.single;
        expect(o.path, '/bookings');
        expect(o.headers['Idempotency-Key'], 'k-1');
        final body = o.data as Map;
        expect(body['category'], 'COOK');
        expect(body['areaId'], 'a1');
        expect(body['startDate'], '2026-11-01');
        expect(body['engagement'], 'PART_TIME');
        expect(body['budgetMinMinor'], 600000);
        expect(body['budgetMaxMinor'], 1000000);
        expect(body['budgetPeriod'], 'MONTH');
        expect(body['requirementNote'], 'hi');
        expect(b.status, BookingStatus.matched);

        await repo.schedule(
          'bk1',
          InterviewType.trial,
          DateTime.utc(2026, 10, 12, 4, 30),
        );
        final post = seen.firstWhere((r) => r.path == '/bookings/bk1/schedule');
        expect((post.data as Map)['scheduleType'], 'TRIAL');
        expect((post.data as Map)['scheduledAt'], '2026-10-12T04:30:00.000Z');
        expect(seen.last.method, 'GET'); // re-read afterwards
      },
    );

    test(
      'actions hit /bookings/{id}/{action}; cancel carries the reason',
      () async {
        final seen = <RequestOptions>[];
        final dio = Dio(BaseOptions(baseUrl: 'http://x'))
          ..httpClientAdapter = FakeAdapter((o) async {
            seen.add(o);
            return jsonBody('{"id":"bk1","status":"CANCELLED"}', 200);
          });
        final repo = BookingRepositoryRemote(dio);
        await repo.cancel('bk1', 'Plans changed');
        await repo.confirmWorker('bk1', DateTime(2026, 11, 1));
        await repo.reopenMatching('bk1');
        await repo.interviewComplete('bk1');
        final posts = seen.where((r) => r.method == 'POST').toList();
        expect(posts.map((r) => r.path), [
          '/bookings/bk1/cancel',
          '/bookings/bk1/confirm-worker',
          '/bookings/bk1/reopen-matching',
          '/bookings/bk1/interview-complete',
        ]);
        expect((posts[0].data as Map)['reason'], 'Plans changed');
        expect((posts[1].data as Map)['startDate'], '2026-11-01');
      },
    );

    test('list pages by number; a 404 is a NotFoundFailure', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://x'))
        ..httpClientAdapter = FakeAdapter((o) async {
          if (o.path == '/bookings/nope') {
            return jsonBody('{"code":"NOT_FOUND"}', 404);
          }
          return jsonBody(
            '{"data":[{"id":"a","status":"ACTIVE"},{"id":"b","status":"WEIRD"}],"meta":{"total":45}}',
            200,
          );
        });
      final repo = BookingRepositoryRemote(dio);
      final page = await repo.list();
      expect(page.items.map((e) => e.status), [
        BookingStatus.active,
        BookingStatus.unknown,
      ]);
      expect(page.nextCursor, '2');
      expect((await repo.list(cursor: '3')).nextCursor, isNull);
      await expectLater(repo.get('nope'), throwsA(isA<NotFoundFailure>()));
    });

    test('a 409 keeps the backend error code', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://x'))
        ..httpClientAdapter = FakeAdapter(
          (o) async => jsonBody(
            '{"code":"DUPLICATE_BOOKING","message":"already open"}',
            409,
          ),
        );
      await expectLater(
        BookingRepositoryRemote(dio).create(
          BookingRequest(
            category: 'COOK',
            areaId: 'a1',
            addressId: 'ad1',
            startDate: DateTime(2026, 11, 1),
          ),
          idempotencyKey: 'k',
        ),
        throwsA(
          isA<ConflictFailure>().having(
            (e) => e.code,
            'code',
            'DUPLICATE_BOOKING',
          ),
        ),
      );
    });

    test('booking status mapper and derived actions', () {
      expect(
        bookingStatusFrom('INTERVIEW_TRIAL_SCHEDULED'),
        BookingStatus.interviewTrialScheduled,
      );
      expect(bookingStatusFrom('nonsense'), BookingStatus.unknown);
      expect(
        derivedBookingActions(BookingStatus.pendingPayment),
        contains(BookingAction.pay),
      );
      expect(derivedBookingActions(BookingStatus.cancelled), isEmpty);
      // A backend-supplied list always wins.
      final b = Booking.fromJson({
        'id': 'x',
        'status': 'ACTIVE',
        'allowedActions': ['cancel', 'bogus'],
      })!;
      expect(b.actions, {BookingAction.cancel});
    });
  });

  test('slots: hourly in the worker window, today needs an hour of notice', () {
    final later = generateInterviewSlots(
      date: DateTime(2026, 10, 10),
      now: DateTime(2026, 10, 9, 10, 30),
      windowStart: '08:00',
      windowEnd: '18:00',
    );
    expect(later.first.id, '08:00');
    expect(later.last.id, '17:00');
    final today = generateInterviewSlots(
      date: DateTime(2026, 10, 9),
      now: DateTime(2026, 10, 9, 10, 30),
      windowStart: '08:00',
      windowEnd: '18:00',
    );
    expect(today.first.id, '12:00'); // 10:30 + 1 h = 11:30 -> next whole hour
    final noWindow = generateInterviewSlots(
      date: DateTime(2026, 10, 10),
      now: DateTime(2026, 10, 9),
    );
    expect(noWindow.first.id, '09:00');
  });

  group('screens', () {
    // cook-4 is not in the seeded bookings, so a request for it is not a duplicate.
    const newRoute = '/interviews/new?workerId=cook-4';

    Future<DiscoverEnv> open(
      WidgetTester t, {
      required String route,
      _Spy? spy,
      bool returning = true,
      FakePushService? push,
    }) async {
      final s = spy ?? _Spy(returning: returning);
      final env = await launchDiscover(
        t,
        push: push,
        overrides: [interviewRepositoryProvider.overrideWithValue(s)],
      );
      env.stepsOneToThree(EngagementType.fullTime);
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

    /// Picks tomorrow (the picker's initial date) and a slot.
    Future<void> pickDateAndSlot(
      WidgetTester t, {
      String slot = '10:00',
    }) async {
      await tapKey(t, 'interview_date_btn');
      await t.tap(find.text('OK'));
      await settle(t);
      await tapKey(t, 'interview_slot_$slot');
    }

    bool submitEnabled(WidgetTester t) {
      final b = find.descendant(
        of: find.byKey(const Key('interview_submit_btn')),
        matching: find.byType(FilledButton),
      );
      return t.widget<FilledButton>(b).onPressed != null;
    }

    group('request form', () {
      testWidgets(
        'INT-02 Submit stays disabled until date and slot are chosen',
        (t) async {
          await open(t, route: newRoute);
          expect(submitEnabled(t), isFalse);
          expect(find.text('Pick a date to see free times.'), findsOneWidget);
          await tapKey(t, 'interview_date_btn');
          await t.tap(find.text('OK'));
          await settle(t);
          expect(submitEnabled(t), isFalse); // date alone is not enough
          await tapKey(t, 'interview_slot_10:00');
          expect(submitEnabled(t), isTrue);
        },
      );

      testWidgets('INT-11 the date picker cannot go before today', (t) async {
        await open(t, route: newRoute);
        await tapKey(t, 'interview_date_btn');
        final p = t.widget<CalendarDatePicker>(find.byType(CalendarDatePicker));
        expect(p.firstDate, DateTime(2026, 10, 9));
        expect(p.lastDate, DateTime(2026, 10, 22));
      });

      testWidgets(
        'the first request offers notifications once, via the pre-prompt',
        (t) async {
          SharedPreferences.setMockInitialValues({});
          final push = FakePushService();
          await open(t, route: newRoute, push: push);
          await pickDateAndSlot(t);
          await tapKey(t, 'interview_submit_btn');
          expect(find.byKey(const Key('notif_prompt')), findsOneWidget);
          expect(push.requestCalls, 0);
          await tapKey(t, 'notif_prompt_allow_btn');
          expect(push.requestCalls, 1);
        },
      );

      testWidgets('INT-03 success replaces the form with the detail', (
        t,
      ) async {
        final spy = _Spy();
        final env = await open(t, route: newRoute, spy: spy);
        await tapKey(t, 'interview_note_field');
        await t.enterText(
          find.byKey(const Key('interview_note_field')),
          'Mornings',
        );
        await pickDateAndSlot(t);
        await tapKey(t, 'interview_submit_btn');
        expect(env.where, '/interviews/iv_401');
        expect(find.byKey(const Key('interview_status_chip')), findsOneWidget);
        // The booking was created and scheduled in one go.
        expect(find.text('Scheduled'), findsOneWidget);
        GoRouter.of(t.element(find.byType(Scaffold).first)).pop();
        await settle(t);
        expect(env.where, isNot(contains('/interviews/new')));
      });

      testWidgets('INT-04 double tap sends one request', (t) async {
        final spy = _Spy()..gate = Completer();
        await open(t, route: newRoute, spy: spy);
        await pickDateAndSlot(t);
        final btn = find.byKey(const Key('interview_submit_btn'));
        await t.ensureVisible(btn);
        await t.tap(btn);
        await t.pump();
        await t.tap(btn, warnIfMissed: false);
        await t.pump();
        expect(spy.createCalls, 1);
        spy.gate!.complete();
        await settle(t);
        expect(spy.createCalls, 1);
      });

      testWidgets(
        'INT-05 slot taken: message, slot cleared, still on the form',
        (t) async {
          final spy = _Spy()
            ..createFailsOnce = const ConflictFailure('taken', 'SLOT_TAKEN');
          final env = await open(t, route: newRoute, spy: spy);
          await pickDateAndSlot(t, slot: '17:00');
          await tapKey(t, 'interview_submit_btn');
          expect(find.byKey(const Key('interview_error')), findsOneWidget);
          expect(
            find.text('That time is no longer available. Pick another.'),
            findsOneWidget,
          );
          expect(env.where, '/interviews/new');
          expect(submitEnabled(t), isFalse);
          await tapKey(t, 'interview_slot_16:00');
          await tapKey(t, 'interview_submit_btn');
          expect(env.where, startsWith('/interviews/iv_'));
        },
      );

      testWidgets('an open request with this worker already exists', (t) async {
        // cook-2 already has the seeded booking iv_301.
        final env = await open(t, route: '/interviews/new?workerId=cook-2');
        await pickDateAndSlot(t);
        await tapKey(t, 'interview_submit_btn');
        expect(
          find.text('You already have an open request with this worker.'),
          findsOneWidget,
        );
        expect(env.where, '/interviews/new');
        expect(submitEnabled(t), isTrue); // choices kept
      });

      testWidgets('INT-06 lost answer: finds the request and opens it', (
        t,
      ) async {
        final spy = _Spy()..loseAnswer = true;
        final env = await open(t, route: newRoute, spy: spy);
        await pickDateAndSlot(t);
        await tapKey(t, 'interview_submit_btn');
        expect(spy.createCalls, 1);
        expect(env.where, '/interviews/iv_401');
      });

      testWidgets('a real network failure shows the error and stays', (
        t,
      ) async {
        final spy = _Spy()..createFails = const NetworkFailure();
        final env = await open(t, route: newRoute, spy: spy);
        await pickDateAndSlot(t);
        await tapKey(t, 'interview_submit_btn');
        expect(find.byKey(const Key('interview_error')), findsOneWidget);
        expect(env.where, '/interviews/new');
        // Retry reuses the same key.
        await tapKey(t, 'interview_submit_btn');
        expect(spy.keys.toSet().length, 1);
        expect(spy.createCalls, 2);
      });

      testWidgets('worker gone: dialog, Find another goes to the results', (
        t,
      ) async {
        final spy = _Spy()..createFails = const NotFoundFailure();
        final env = await open(t, route: newRoute, spy: spy);
        await pickDateAndSlot(t);
        await tapKey(t, 'interview_submit_btn');
        await tapKey(t, 'interview_find_another_btn');
        expect(env.where, '/workers');
      });

      testWidgets('Back with choices asks before discarding', (t) async {
        final env = await open(t, route: newRoute);
        await pickDateAndSlot(t);
        await tapKey(t, 'app_back_btn');
        expect(
          find.byKey(const Key('interview_discard_confirm_btn')),
          findsOneWidget,
        );
        await t.tap(find.byKey(const Key('dialog_cancel_btn')));
        await settle(t);
        expect(env.where, '/interviews/new');
        await tapKey(t, 'app_back_btn');
        await t.tap(find.byKey(const Key('interview_discard_confirm_btn')));
        await settle(t);
        expect(env.where, isNot('/interviews/new'));
      });

      testWidgets('type can be switched to Trial and is sent', (t) async {
        final env = await open(t, route: newRoute);
        await tapKey(t, 'interview_type_trial');
        await pickDateAndSlot(t);
        await tapKey(t, 'interview_submit_btn');
        expect(find.text('Trial visit'), findsWidgets); // shown on the detail
        expect(env.where, '/interviews/iv_401');
      });
    });

    group('detail', () {
      testWidgets('INT-07 scheduled: exactly the allowed actions', (t) async {
        await open(t, route: '/interviews/iv_301');
        expect(find.byKey(const Key('interview_cancel_btn')), findsOneWidget);
        expect(
          find.byKey(const Key('interview_reschedule_btn')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('interview_complete_btn')), findsOneWidget);
        expect(
          find.byKey(const Key('interview_confirm_worker_btn')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('interview_reject_worker_btn')),
          findsNothing,
        );
        expect(find.byKey(const Key('interview_support_btn')), findsOneWidget);
      });

      testWidgets('completed: confirm and not-a-fit, not "interview done"', (
        t,
      ) async {
        await open(t, route: '/interviews/iv_302');
        expect(
          find.text('Decide whether to confirm this worker'),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('interview_confirm_worker_btn')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('interview_reject_worker_btn')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('interview_complete_btn')), findsNothing);
      });

      testWidgets(
        'matched (not scheduled yet): the button reads Choose a time',
        (t) async {
          await open(t, route: '/interviews/iv_303');
          expect(find.text('Choose a time'), findsOneWidget);
        },
      );

      testWidgets('Interview done moves it on to the decision', (t) async {
        final spy = _Spy();
        await open(t, route: '/interviews/iv_301', spy: spy);
        await tapKey(t, 'interview_complete_btn');
        expect(spy.completeCalls, 1);
        expect(
          find.byKey(const Key('interview_confirm_worker_btn')),
          findsOneWidget,
        );
      });

      testWidgets('INT-08 Cancel: dialog, one call, status refetched', (
        t,
      ) async {
        final spy = _Spy();
        await open(t, route: '/interviews/iv_303', spy: spy);
        await tapKey(t, 'interview_cancel_btn');
        await t.tap(find.byKey(const Key('interview_cancel_confirm_btn')));
        await settle(t);
        expect(spy.cancelCalls, 1);
        expect(find.text('Cancelled'), findsOneWidget);
        expect(find.byKey(const Key('interview_cancel_btn')), findsNothing);
      });

      testWidgets('Keep request leaves it alone', (t) async {
        final spy = _Spy();
        await open(t, route: '/interviews/iv_303', spy: spy);
        await tapKey(t, 'interview_cancel_btn');
        await t.tap(find.byKey(const Key('dialog_cancel_btn')));
        await settle(t);
        expect(spy.cancelCalls, 0);
      });

      testWidgets('INT-09 Confirm worker opens the booking confirmation', (
        t,
      ) async {
        final env = await open(t, route: '/interviews/iv_302');
        await tapKey(t, 'interview_confirm_worker_btn');
        expect(env.where, '/bookings/confirm');
        expect(find.byKey(const Key('confirm_pay_btn')), findsOneWidget);
      });

      // reopen-matching returns the booking to MATCHED with the same worker (not NEW_REQUEST),
      // so the refetched interview no longer reads "Not a fit" (open question for the app flow).
      testWidgets('INT-10 Not a fit sends reopen-matching once', (t) async {
        final spy = _Spy();
        await open(t, route: '/interviews/iv_302', spy: spy);
        await tapKey(t, 'interview_reject_worker_btn');
        await t.tap(find.byKey(const Key('interview_decline_confirm_btn')));
        await settle(t);
        expect(spy.declineCalls, 1);
        expect(find.text('Not a fit'), findsNothing);
      });

      testWidgets('INT-12 an unknown status renders neutrally', (t) async {
        final spy = _Spy()
          ..forced = const Interview(
            id: 'iv_x',
            status: InterviewStatus.unknown,
            type: InterviewType.interview,
            workerId: 'cook-2',
          );
        await open(t, route: '/interviews/iv_x', spy: spy);
        expect(find.text('Updated'), findsOneWidget);
        expect(find.text('Status updated'), findsOneWidget);
        expect(t.takeException(), isNull);
      });

      testWidgets('worker card opens the worker profile', (t) async {
        final env = await open(t, route: '/interviews/iv_301');
        await tapKey(t, 'interview_worker_card');
        expect(env.where, '/workers/cook-2');
      });

      testWidgets('Contact support passes the interview id', (t) async {
        final env = await open(t, route: '/interviews/iv_301');
        await tapKey(t, 'interview_support_btn');
        expect(env.where, '/support/new');
      });

      testWidgets('Reschedule moves the time and returns to the detail', (
        t,
      ) async {
        final env = await open(t, route: '/interviews/iv_301');
        await tapKey(t, 'interview_reschedule_btn');
        expect(env.where, '/interviews/new');
        expect(find.byKey(const Key('interview_type_segment')), findsNothing);
        await pickDateAndSlot(t, slot: '12:00');
        await tapKey(t, 'interview_submit_btn');
        expect(env.where, '/interviews/iv_301');
        expect(find.text('Scheduled'), findsOneWidget);
      });

      testWidgets('unknown interview id shows the error with Retry', (t) async {
        await open(t, route: '/interviews/nope');
        expect(find.byKey(const Key('error_retry_btn')), findsOneWidget);
      });
    });

    group('list', () {
      testWidgets('shows only interview-stage bookings and opens one', (
        t,
      ) async {
        final env = await open(t, route: '/interviews');
        expect(find.byKey(const Key('interview_card_iv_301')), findsOneWidget);
        expect(find.byKey(const Key('interview_card_iv_302')), findsOneWidget);
        expect(find.byKey(const Key('interview_card_iv_303')), findsOneWidget);
        // Later stages live on the Bookings tab.
        expect(find.byKey(const Key('interview_card_bk_2100')), findsNothing);
        expect(find.byKey(const Key('interview_card_bk_2048')), findsNothing);
        await tapKey(t, 'interview_card_iv_302');
        expect(env.where, '/interviews/iv_302');
      });

      testWidgets('empty: message and a Find a worker button', (t) async {
        final env = await open(t, route: '/interviews', returning: false);
        expect(find.text('No interviews yet'), findsOneWidget);
        await tapKey(t, 'interviews_empty_find_btn');
        expect(env.where, '/discover/category');
      });

      testWidgets('reachable from the Account tab', (t) async {
        final env = await launchDiscover(
          t,
          overrides: [interviewRepositoryProvider.overrideWithValue(_Spy())],
        );
        await env.tapKey('nav_account');
        await env.tapKey('account_interviews_btn');
        expect(env.where, '/interviews');
        await settle(t); // let the list request finish
      });
    });

    testWidgets('Flow D: worker profile -> request -> date/time -> detail', (
      t,
    ) async {
      final env = await open(t, route: '/workers/cook-4');
      await tapKey(t, 'worker_request_interview_btn');
      expect(env.where, '/interviews/new');
      await pickDateAndSlot(t);
      await tapKey(t, 'interview_submit_btn');
      expect(env.where, '/interviews/iv_401');
      expect(find.text('Scheduled'), findsOneWidget);
    });
  });
}
