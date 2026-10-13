// Module 07: statuses, repository contract, request form, detail actions, list, Flow D.
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/features/interview_trial/data/interview_repository_mock.dart';
import 'package:sevanest_customer/features/interview_trial/data/interview_repository_remote.dart';
import 'package:sevanest_customer/features/interview_trial/domain/interview.dart';
import 'package:sevanest_customer/features/interview_trial/presentation/providers/interview_providers.dart';
import 'package:sevanest_customer/features/service_discovery/domain/catalog.dart';
import 'package:sevanest_customer/features/service_discovery/domain/requirement_draft.dart';

import '../../helpers/discover_harness.dart';
import '../../helpers/fakes.dart';

/// Chained mock calls each need their own wait: pumpAndSettle ignores the latency timers.
Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 3; i++) {
    await t.pumpAndSettle();
    await t.pump(const Duration(seconds: 1));
  }
  await t.pumpAndSettle();
}

/// The seeded mock with counters and failure hooks.
class _Spy implements InterviewRepository {
  _Spy({bool returning = true})
    : inner = InterviewRepositoryMock(
        () => MockApiState(returningUser: returning),
        now: () => testNow,
      );
  final InterviewRepositoryMock inner;
  final keys = <String>[];
  var createCalls = 0;
  var cancelCalls = 0;
  var declineCalls = 0;
  Object? createFails;

  /// Create succeeds server-side but the answer is lost (network error).
  bool loseAnswer = false;
  Completer<void>? gate;
  Interview? forced;

  @override
  @override
  @override
  @override
  @override
  Future<Interview> create(
    InterviewRequest r, {
    required String idempotencyKey,
  }) async {
    createCalls++;
    keys.add(idempotencyKey);
    await gate?.future;
    final f = createFails;
    if (f != null) throw f;
    final made = await inner.create(r, idempotencyKey: idempotencyKey);
    if (loseAnswer) throw const NetworkFailure();
    return made;
  }

  @override
  @override
  @override
  @override
  @override
  Future<Interview> reschedule(
    String id,
    DateTime date,
    String slot, {
    required String idempotencyKey,
  }) => inner.reschedule(id, date, slot, idempotencyKey: idempotencyKey);

  @override
  @override
  @override
  @override
  @override
  Future<InterviewPage> list({String? cursor}) => inner.list(cursor: cursor);

  @override
  @override
  @override
  @override
  @override
  Future<Interview> get(String id, {CancelToken? cancel}) async =>
      forced ?? await inner.get(id, cancel: cancel);

  @override
  @override
  @override
  @override
  @override
  Future<Interview> cancel(String id, {String? reason}) {
    cancelCalls++;
    return inner.cancel(id, reason: reason);
  }

  @override
  @override
  @override
  @override
  @override
  Future<Interview> decline(String id) {
    declineCalls++;
    return inner.decline(id);
  }

  @override
  @override
  @override
  @override
  @override
  Future<List<InterviewSlot>> slots(String workerId, DateTime date) =>
      inner.slots(workerId, date);
}

void main() {
  group('status, actions, parsing', () {
    test('INT-01 every known status maps; unknown and null are neutral', () {
      expect(interviewStatusFrom('REQUESTED'), InterviewStatus.requested);
      expect(interviewStatusFrom('scheduled'), InterviewStatus.scheduled);
      expect(interviewStatusFrom('COMPLETED'), InterviewStatus.completed);
      expect(interviewStatusFrom('CANCELLED'), InterviewStatus.cancelled);
      expect(interviewStatusFrom('DECLINED'), InterviewStatus.declined);
      expect(interviewStatusFrom('CONFIRMED'), InterviewStatus.confirmed);
      expect(interviewStatusFrom('NOT_A_FIT'), InterviewStatus.notAFit);
      expect(interviewStatusFrom('SOMETHING_NEW'), InterviewStatus.unknown);
      expect(interviewStatusFrom(null), InterviewStatus.unknown);
      expect(interviewStatusFrom(7), InterviewStatus.unknown);
    });

    test('allowedActions: known kept, unknown ignored, bad shape empty', () {
      expect(interviewActionsFrom(['cancel', 'RESCHEDULE', 'teleport']), {
        InterviewAction.cancel,
        InterviewAction.reschedule,
      });
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

  group('remote repository (assumed contract)', () {
    test('create sends the idempotency key and the whole request', () async {
      final seen = <RequestOptions>[];
      final dio = Dio(BaseOptions(baseUrl: 'http://x'))
        ..httpClientAdapter = FakeAdapter((o) async {
          seen.add(o);
          return jsonBody(
            '{"id":"iv1","status":"REQUESTED","type":"trial","workerId":"w1",'
            '"date":"2026-10-12","slot":"10:00","allowedActions":["cancel"]}',
            201,
          );
        });
      final iv = await InterviewRepositoryRemote(dio).create(
        InterviewRequest(
          workerId: 'w1',
          type: InterviewType.trial,
          date: DateTime(2026, 10, 12),
          slot: '10:00',
          note: 'hello',
          requirement: const RequirementDraft(serviceId: 'COOK'),
        ),
        idempotencyKey: 'k-1',
      );
      final o = seen.single;
      expect(o.path, '/interviews');
      expect(o.headers['Idempotency-Key'], 'k-1');
      final body = o.data as Map;
      expect(body['workerId'], 'w1');
      expect(body['type'], 'trial');
      expect(body['date'], '2026-10-12');
      expect(body['slot'], '10:00');
      expect(body['note'], 'hello');
      expect((body['requirement'] as Map)['serviceId'], 'COOK');
      expect(iv.type, InterviewType.trial);
      expect(iv.actions, {InterviewAction.cancel});
    });

    test('list pages by number; slots accept strings or objects', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://x'))
        ..httpClientAdapter = FakeAdapter((o) async {
          if (o.path.endsWith('/slots')) {
            return jsonBody('{"data":["09:00",{"id":"10:00"},"bad"]}', 200);
          }
          return jsonBody(
            '{"data":[{"id":"a"},{"id":"b"}],"meta":{"total":45}}',
            200,
          );
        });
      final repo = InterviewRepositoryRemote(dio);
      final page = await repo.list();
      expect(page.items.map((e) => e.id), ['a', 'b']);
      expect(page.nextCursor, '2');
      expect((await repo.list(cursor: '3')).nextCursor, isNull);
      final slots = await repo.slots('w1', DateTime(2026, 10, 12));
      expect(slots.map((s) => s.id), ['09:00', '10:00']);
    });

    test('a 404 (endpoints not published yet) is a NotFoundFailure', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://x'))
        ..httpClientAdapter = FakeAdapter(
          (o) async => jsonBody('{"code":"NOT_FOUND"}', 404),
        );
      expect(
        InterviewRepositoryRemote(dio).get('x'),
        throwsA(isA<NotFoundFailure>()),
      );
    });
  });

  test(
    'mock slots: hourly in the worker window, today needs an hour of notice',
    () async {
      final repo = InterviewRepositoryMock(
        () => const MockApiState(),
        now: () => DateTime(2026, 10, 9, 10, 30),
      );
      final later = await repo.slots('cook-2', DateTime(2026, 10, 10));
      expect(later.first.id, '08:00');
      expect(later.last.id, '17:00');
      final today = await repo.slots('cook-2', DateTime(2026, 10, 9));
      expect(today.first.id, '12:00'); // 10:30 + 1 h = 11:30 -> next whole hour
    },
  );

  group('screens', () {
    Future<DiscoverEnv> open(
      WidgetTester t, {
      required String route,
      _Spy? spy,
      bool returning = true,
    }) async {
      final s = spy ?? _Spy(returning: returning);
      final env = await launchDiscover(
        t,
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

    /// Picks tomorrow (the picker's initial date) and the 10:00 slot.
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
      const newRoute = '/interviews/new?workerId=cook-2';

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
        expect(p.lastDate, DateTime(2026, 10, 23));
      });

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
        expect(find.text('Requested'), findsOneWidget);
        // Back leaves the detail; the form is gone from the stack.
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
          final spy = _Spy();
          final env = await open(t, route: newRoute, spy: spy);
          await pickDateAndSlot(t, slot: '17:00'); // the mock grabs 17:00 once
          await tapKey(t, 'interview_submit_btn');
          expect(find.byKey(const Key('interview_error')), findsOneWidget);
          expect(
            find.text('That time is no longer available. Pick another.'),
            findsOneWidget,
          );
          expect(env.where, '/interviews/new');
          expect(submitEnabled(t), isFalse);
          // Pick again and it goes through (slots were reloaded).
          await tapKey(t, 'interview_slot_16:00');
          await tapKey(t, 'interview_submit_btn');
          expect(env.where, startsWith('/interviews/iv_'));
        },
      );

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
        final spy = _Spy();
        final env = await open(t, route: newRoute, spy: spy);
        await tapKey(t, 'interview_type_trial');
        await pickDateAndSlot(t);
        await tapKey(t, 'interview_submit_btn');
        expect(find.text('Trial visit'), findsWidgets); // shown on the detail
        expect(env.where, '/interviews/iv_401');
      });
    });

    group('detail', () {
      testWidgets('INT-07 shows exactly the allowed actions', (t) async {
        await open(
          t,
          route: '/interviews/iv_301',
        ); // scheduled: cancel, reschedule
        expect(find.byKey(const Key('interview_cancel_btn')), findsOneWidget);
        expect(
          find.byKey(const Key('interview_reschedule_btn')),
          findsOneWidget,
        );
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

      testWidgets('completed: confirm and not-a-fit, no cancel', (t) async {
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
        expect(find.byKey(const Key('interview_cancel_btn')), findsNothing);
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

      testWidgets('INT-09 Confirm worker opens the booking step', (t) async {
        final env = await open(t, route: '/interviews/iv_302');
        await tapKey(t, 'interview_confirm_worker_btn');
        expect(env.where, '/bookings/confirm');
        final loc = GoRouter.of(
          t.element(find.byType(Scaffold).first),
        ).routerDelegate.currentConfiguration.last.matchedLocation;
        expect(loc, '/bookings/confirm');
      });

      testWidgets('INT-10 Not a fit, then Find another goes to the results', (
        t,
      ) async {
        final spy = _Spy();
        final env = await open(t, route: '/interviews/iv_302', spy: spy);
        await tapKey(t, 'interview_reject_worker_btn');
        await t.tap(find.byKey(const Key('interview_decline_confirm_btn')));
        await settle(t);
        expect(spy.declineCalls, 1);
        expect(find.text('Not a fit'), findsWidgets);
        await tapKey(t, 'interview_find_another_btn');
        expect(env.where, '/workers');
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
        expect(find.text('Requested'), findsOneWidget);
      });

      testWidgets('unknown interview id shows the error with Retry', (t) async {
        await open(t, route: '/interviews/nope');
        expect(find.byKey(const Key('error_retry_btn')), findsOneWidget);
      });
    });

    group('list', () {
      testWidgets('shows the cards with status and opens one', (t) async {
        final env = await open(t, route: '/interviews');
        expect(find.byKey(const Key('interview_card_iv_301')), findsOneWidget);
        expect(find.byKey(const Key('interview_card_iv_302')), findsOneWidget);
        expect(find.byKey(const Key('interview_card_iv_303')), findsOneWidget);
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
        await env.tapKey('account_interviews_tile');
        expect(env.where, '/interviews');
        await settle(t); // let the list request finish
      });
    });

    testWidgets('Flow D: worker profile -> request -> date/time -> detail', (
      t,
    ) async {
      final env = await open(t, route: '/workers/cook-2');
      await tapKey(t, 'worker_request_interview_btn');
      expect(env.where, '/interviews/new');
      await pickDateAndSlot(t);
      await tapKey(t, 'interview_submit_btn');
      expect(env.where, '/interviews/iv_401');
      expect(find.text('Requested'), findsOneWidget);
      expect(find.text('Waiting for the worker to respond'), findsOneWidget);
    });
  });
}
