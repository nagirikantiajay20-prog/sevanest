// The live `/interviews` repository against the OpenAPI of 2026-10-13: booking first, then the
// interview; worker and requirement from the booking; confirm / not a fit only after completion.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/features/addresses/domain/address.dart';
import 'package:sevanest_customer/features/booking/data/booking_repository_remote.dart';
import 'package:sevanest_customer/features/interview_trial/data/interview_repository_remote.dart';
import 'package:sevanest_customer/features/interview_trial/domain/interview.dart';
import 'package:sevanest_customer/features/service_discovery/domain/catalog.dart';
import 'package:sevanest_customer/features/service_discovery/domain/requirement_draft.dart';
import 'package:sevanest_customer/features/worker_search/data/worker_search_repository_mock.dart';

import '../../helpers/fakes.dart';

String interviewJson({
  String status = 'REQUESTED',
  String actions = '"cancel","reschedule"',
  String proposedAt = 'null',
}) =>
    '{"id":"iv1","bookingId":"bk1","type":"TRIAL","status":"$status",'
    '"preferredAt":"2026-11-03T04:30:00.000Z","scheduledAt":null,'
    '"proposedAt":$proposedAt,"note":"Mornings","allowedActions":[$actions],'
    '"timeline":[{"title":"Requested","state":"done","at":"2026-11-01T05:00:00Z"},'
    '{"title":"Answer","state":"current","at":null}]}';

const bookingJson =
    '{"id":"bk1","status":"MATCHED","workerId":"w1","category":{"code":"COOK","name":"Cook"},'
    '"area":{"id":"a1","name":"Madhapur","city":"Hyderabad"},"engagement":"PART_TIME"}';

void main() {
  late List<RequestOptions> seen;
  late String bookingBody;

  InterviewRepositoryRemote repo(
    Future<ResponseBody> Function(RequestOptions) h,
  ) {
    final dio = Dio(BaseOptions(baseUrl: 'http://x'))
      ..httpClientAdapter = FakeAdapter((o) async {
        seen.add(o);
        return h(o);
      });
    return InterviewRepositoryRemote(
      dio,
      BookingRepositoryRemote(dio),
      WorkerSearchRepositoryMock(() => const MockApiState(returningUser: true)),
      areaIdFor: (d) async => 'a1',
    );
  }

  setUp(() {
    seen = [];
    bookingBody = bookingJson;
  });

  Future<ResponseBody> routes(RequestOptions o) async {
    if (o.path == '/bookings' && o.method == 'POST') {
      return jsonBody(bookingJson, 201);
    }
    if (o.path.startsWith('/bookings/')) return jsonBody(bookingBody, 200);
    if (o.path == '/interviews' && o.method == 'POST') {
      return jsonBody(interviewJson(), 201);
    }
    return jsonBody(interviewJson(), 200);
  }

  final requirement = RequirementDraft(
    serviceId: 'COOK',
    engagement: EngagementType.partTime,
    address: const Address(
      id: 'ad1',
      line: '1 Road',
      area: 'Madhapur',
      city: 'Hyderabad',
      pincode: '500081',
    ),
    startDate: DateTime(2026, 11, 5),
  );

  test('create: the booking first (own key), then the interview', () async {
    final r = repo(routes);
    final iv = await r.create(
      InterviewRequest(
        workerId: 'cook-1',
        type: InterviewType.trial,
        date: DateTime(2026, 11, 3),
        slot: '10:00',
        requirement: requirement,
        note: 'Mornings',
      ),
      idempotencyKey: 'k1',
    );
    final posts = seen.where((o) => o.method == 'POST').toList();
    expect(posts.map((o) => o.path), ['/bookings', '/interviews']);
    expect(posts[0].headers['Idempotency-Key'], 'k1-booking');
    expect((posts[0].data as Map)['workerId'], 'cook-1');
    // A flexible requirement still sends the hours window the backend requires.
    expect((posts[0].data as Map)['availableFrom'], isNotNull);
    expect((posts[0].data as Map)['availableTo'], isNotNull);
    expect(posts[1].headers['Idempotency-Key'], startsWith('k1-interview-'));
    final body = posts[1].data as Map;
    expect(body['bookingId'], 'bk1');
    expect(body['type'], 'TRIAL');
    expect(body['note'], 'Mornings');
    expect(DateTime.parse(body['preferredAt'] as String).isUtc, isTrue);
    expect(iv.id, 'iv1');
    expect(iv.bookingId, 'bk1');
    expect(iv.workerId, 'w1');
    expect(iv.requirement?.serviceId, 'COOK');
    expect(iv.actions, {InterviewAction.cancel, InterviewAction.reschedule});
    expect(iv.timeline.map((e) => e.title), ['Requested', 'Answer']);
  });

  InterviewRequest req(InterviewType t, String slot, {int day = 7}) =>
      InterviewRequest(
        workerId: 'cook-1',
        type: t,
        date: DateTime(2026, 11, day),
        slot: slot,
        requirement: requirement,
      );

  test('trial 7 Nov 4 PM goes out as 16:00 India time (10:30 UTC)', () async {
    await repo(
      routes,
    ).create(req(InterviewType.trial, '16:00'), idempotencyKey: 'k');
    final body =
        seen
                .lastWhere((o) => o.method == 'POST' && o.path == '/interviews')
                .data
            as Map;
    expect(body['type'], 'TRIAL');
    expect(body['preferredAt'], '2026-11-07T10:30:00.000Z');
    // Round trip: the backend's instant reads back as the same wall time.
    final iv = Interview.fromJson({
      'id': 'x',
      'preferredAt': body['preferredAt'],
    })!;
    expect((iv.date, iv.slot), (DateTime(2026, 11, 7), '16:00'));
  });

  test(
    'interview: type INTERVIEW, booking payload independent of the slot',
    () async {
      await repo(
        routes,
      ).create(req(InterviewType.interview, '18:00'), idempotencyKey: 'k');
      final posts = seen.where((o) => o.method == 'POST').toList();
      expect((posts[1].data as Map)['type'], 'INTERVIEW');
      expect((posts[1].data as Map)['bookingId'], 'bk1');
      final booking = posts[0].data as Map;
      expect(booking['workerId'], 'cook-1');
      // The booking carries the requirement's hours, never the interview time.
      expect('$booking', isNot(contains('18:00')));
      expect(booking['startDate'], '2026-11-05');
    },
  );

  test(
    'retry after the interview step failed: one booking, same key',
    () async {
      var fail = true;
      final r = repo((o) async {
        if (o.path == '/interviews' && o.method == 'POST' && fail) {
          return jsonBody('{"code":"X"}', 503);
        }
        return routes(o);
      });
      final q = req(InterviewType.trial, '16:00');
      await expectLater(r.create(q, idempotencyKey: 'k'), throwsA(anything));
      fail = false;
      await r.create(q, idempotencyKey: 'k');
      final posts = seen.where((o) => o.method == 'POST').toList();
      expect(posts.where((o) => o.path == '/bookings'), hasLength(1));
      final keys = posts
          .where((o) => o.path == '/interviews')
          .map((o) => o.headers['Idempotency-Key'])
          .toList();
      expect(keys, hasLength(2));
      expect(keys[0], keys[1]);
    },
  );

  test('a changed time after a failure is a new interview request', () async {
    final r = repo(routes);
    await r.create(req(InterviewType.trial, '16:00'), idempotencyKey: 'k');
    await r.create(req(InterviewType.trial, '17:00'), idempotencyKey: 'k');
    final keys = seen
        .where((o) => o.method == 'POST' && o.path == '/interviews')
        .map((o) => o.headers['Idempotency-Key'])
        .toSet();
    expect(keys, hasLength(2));
    expect(
      seen.where((o) => o.method == 'POST' && o.path == '/bookings'),
      hasLength(1),
    );
  });

  test('backend refusal WORKER_NOT_ELIGIBLE surfaces with its code', () async {
    final r = repo(
      (o) async => o.path == '/bookings'
          ? jsonBody(
              '{"code":"WORKER_NOT_ELIGIBLE","message":"The worker is not available for this requirement."}',
              422,
            )
          : routes(o),
    );
    await expectLater(
      r.create(req(InterviewType.trial, '16:00'), idempotencyKey: 'k'),
      throwsA(
        isA<ValidationFailure>().having(
          (e) => e.code,
          'code',
          'WORKER_NOT_ELIGIBLE',
        ),
      ),
    );
    expect(seen.where((o) => o.path == '/interviews'), isEmpty);
  });

  test(
    'get: confirm / not a fit only once the booking awaits the decision',
    () async {
      final r = repo(
        (o) async => o.path.startsWith('/bookings/')
            ? jsonBody(bookingBody, 200)
            : jsonBody(interviewJson(status: 'COMPLETED', actions: ''), 200),
      );
      var iv = await r.get('iv1');
      expect(iv.status, InterviewStatus.completed);
      expect(iv.actions, isEmpty);
      bookingBody = bookingJson.replaceFirst(
        'MATCHED',
        'INTERVIEW_TRIAL_COMPLETED',
      );
      iv = await r.get('iv1');
      expect(iv.actions, {InterviewAction.confirm, InterviewAction.decline});
    },
  );

  test('actions hit the documented routes with an Idempotency-Key', () async {
    final r = repo(routes);
    await r.reschedule(
      'iv1',
      DateTime(2026, 11, 4),
      '11:00',
      idempotencyKey: 'k2',
    );
    await r.cancel('iv1', reason: 'Plans changed');
    await r.complete('iv1');
    await r.answerProposal('iv1', accept: true);
    await r.answerProposal('iv1', accept: false);
    final posts = seen
        .where((o) => o.method == 'POST' && o.path.startsWith('/interviews'))
        .toList();
    expect(posts.map((o) => o.path), [
      '/interviews/iv1/reschedule',
      '/interviews/iv1/cancel',
      '/interviews/iv1/complete',
      '/interviews/iv1/accept-proposal',
      '/interviews/iv1/reject-proposal',
    ]);
    expect(
      posts.every((o) => '${o.headers['Idempotency-Key']}'.isNotEmpty),
      isTrue,
    );
    expect(posts[0].headers['Idempotency-Key'], 'k2');
    expect((posts[0].data as Map)['preferredAt'], isA<String>());
    expect((posts[1].data as Map)['reason'], 'Plans changed');
    expect((posts[2].data as Map)['outcomeNote'], isNotEmpty);
  });

  test('not a fit reopens matching on the booking', () async {
    await repo(routes).decline('iv1');
    expect(
      seen.any(
        (o) => o.method == 'POST' && o.path == '/bookings/bk1/reopen-matching',
      ),
      isTrue,
    );
  });

  test('list pages by number and keeps the proposed time', () async {
    final item = interviewJson(
      status: 'RESCHEDULE_PROPOSED',
      actions: '"accept-proposal","reject-proposal"',
      proposedAt: '"2026-11-04T06:30:00Z"',
    );
    final r = repo(
      (o) async => jsonBody(
        '{"data":[$item],"meta":{"page":1,"limit":20,"total":45}}',
        200,
      ),
    );
    final page = await r.list();
    expect(page.nextCursor, '2');
    final iv = page.items.single;
    expect(iv.status, InterviewStatus.rescheduleProposed);
    expect(iv.proposedAt, isNotNull);
    expect(iv.actions, {
      InterviewAction.acceptProposal,
      InterviewAction.rejectProposal,
    });
    expect((await r.list(cursor: '3')).nextCursor, isNull);
    expect(seen.last.queryParameters['page'], 3);
  });

  test('slots reads the day, keeps valid times; a 400 is a failure', () async {
    final r = repo((o) async {
      if (o.queryParameters['date'] == '2026-12-31') {
        return jsonBody('{"code":"VALIDATION_FAILED"}', 400);
      }
      return jsonBody(
        '{"date":"2026-11-03","slotMinutes":60,"horizonDays":14,"slots":["09:00","10:00","bad"]}',
        200,
      );
    });
    final slots = await r.slots('w1', DateTime(2026, 11, 3));
    expect(slots.map((s) => s.id), ['09:00', '10:00']);
    expect(seen.single.path, '/search/workers/w1/slots');
    expect(seen.single.queryParameters['date'], '2026-11-03');
    await expectLater(
      r.slots('w1', DateTime(2026, 12, 31)),
      throwsA(isA<AppFailure>()),
    );
  });
}
