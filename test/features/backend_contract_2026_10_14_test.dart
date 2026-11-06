// What the backend added on 2026-10-14: LATE / LEAVE attendance with check-in / out times and the
// scheduled window, booking history + summary, `rebook`, `rating` and worker identity on bookings,
// customer attendance exceptions. Bodies follow the backend's message; routes are asserted.
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/features/active_service/data/attendance_repository_remote.dart';
import 'package:sevanest_customer/features/active_service/domain/attendance.dart';
import 'package:sevanest_customer/features/booking/data/booking_repository_remote.dart';
import 'package:sevanest_customer/features/booking/domain/booking.dart';
import 'package:sevanest_customer/features/ratings/presentation/providers/rating_providers.dart';
import 'package:sevanest_customer/features/worker_search/presentation/providers/worker_search_providers.dart';

import '../helpers/fakes.dart';

const _worker =
    '{"displayName":"Ramesh K.","initials":"RK","photo":{"url":"https://img/x?sig=1",'
    '"largeUrl":"https://img/xl?sig=1","expiresAt":"2026-10-14T12:00:00Z","cacheKey":"ph_9"}}';

void main() {
  late List<RequestOptions> seen;

  Dio dio(Future<ResponseBody> Function(RequestOptions) h) {
    seen = [];
    return Dio(BaseOptions(baseUrl: 'http://x'))
      ..httpClientAdapter = FakeAdapter((o) async {
        seen.add(o);
        return h(o);
      });
  }

  group('booking JSON', () {
    test('worker identity, rating and allowedActions', () {
      final b = Booking.fromJson({
        'id': 'b1',
        'status': 'COMPLETED',
        'workerId': 'w1',
        'worker': {
          'displayName': 'Ramesh K.',
          'initials': 'RK',
          'photo': {'url': 'https://img/x', 'cacheKey': 'ph_9'},
        },
        'rating': {'id': 'r1', 'score': 4, 'review': 'Good'},
        'allowedActions': ['rebook', 'receipt'],
      })!;
      expect(b.identity!.displayName, 'Ramesh K.');
      expect(b.identity!.initials, 'RK');
      expect(b.identity!.photoUrl, 'https://img/x');
      expect(b.identity!.cacheKey, 'ph_9');
      expect(b.workerId, 'w1');
      expect(b.ratingScore, 4);
      expect(b.ratingReview, 'Good');
      expect(b.actions, {BookingAction.rebook, BookingAction.receipt});
    });

    test('a null photo and a null rating are fine', () {
      final b = Booking.fromJson({
        'id': 'b1',
        'status': 'ACTIVE',
        'worker': {'displayName': 'Sita D.', 'initials': 'SD', 'photo': null},
        'rating': null,
        'allowedActions': <String>[],
      })!;
      expect(b.identity!.photoUrl, isNull);
      expect(b.ratingScore, isNull);
    });

    test('an empty allowedActions wins over the state model', () {
      // COMPLETED but already rated, or REPLACED: no "rate" must appear.
      final done = Booking.fromJson({
        'id': 'b1',
        'status': 'COMPLETED',
        'allowedActions': <String>[],
      })!;
      expect(done.actions, isEmpty);
      final replaced = Booking.fromJson({
        'id': 'b2',
        'status': 'REPLACED',
        'allowedActions': <String>[],
      })!;
      expect(replaced.actions.contains(BookingAction.rate), isFalse);
    });

    test('without allowedActions the state model still applies', () {
      final b = Booking.fromJson({'id': 'b1', 'status': 'COMPLETED'})!;
      expect(b.actions, contains(BookingAction.rate));
      expect(b.actions, isNot(contains(BookingAction.rebook)));
    });

    test('Hire again only with rebook; unknown actions are ignored', () {
      final b = Booking.fromJson({
        'id': 'b1',
        'status': 'COMPLETED',
        'allowedActions': ['rate', 'something-new'],
      })!;
      expect(b.actions, {BookingAction.rate});
    });
  });

  group('history', () {
    test('sends the filters and pages by number', () async {
      final repo = BookingRepositoryRemote(
        dio(
          (o) async => jsonBody(
            '{"data":[{"id":"b1","status":"COMPLETED","worker":$_worker,"workerId":"w1",'
            '"rating":{"id":"r","score":5},"allowedActions":["rebook"]}],"meta":{"total":45}}',
            200,
          ),
        ),
      );
      final page = await repo.history(
        const HistoryFilter(
          year: 2026,
          category: 'COOK',
          search: ' ramesh ',
          status: BookingStatus.completed,
        ),
      );
      expect(seen.single.path, '/customers/me/booking-history');
      expect(seen.single.queryParameters, {
        'year': 2026,
        'category': 'COOK',
        'search': 'ramesh',
        'status': 'COMPLETED',
        'page': 1,
        'limit': 20,
      });
      expect(page.items.single.ratingScore, 5);
      expect(page.items.single.identity!.displayName, 'Ramesh K.');
      expect(page.nextCursor, '2');
    });

    test('no filters sends only the page', () async {
      final repo = BookingRepositoryRemote(
        dio((o) async => jsonBody('{"data":[],"meta":{"total":0}}', 200)),
      );
      await repo.history(const HistoryFilter());
      expect(seen.single.queryParameters, {'page': 1, 'limit': 20});
    });

    test('summary converts paise to rupees and sends the same filters', () async {
      final repo = BookingRepositoryRemote(
        dio(
          (o) async => jsonBody(
            '{"totalServices":9,"distinctWorkers":7,"totalSpentMinor":1250000,"currency":"INR"}',
            200,
          ),
        ),
      );
      final s = await repo.historySummary(const HistoryFilter(year: 2026));
      expect(seen.single.path, '/customers/me/booking-history/summary');
      expect(seen.single.queryParameters, {'year': 2026});
      expect(s.totalServices, 9);
      expect(s.distinctWorkers, 7);
      expect(s.totalSpent, 12500);
      expect(s.currency, 'INR');
    });
  });

  group('same-day start date payload', () {
    final today = DateTime(2026, 10, 9);

    test('POST /bookings sends today as the India calendar date', () async {
      final repo = BookingRepositoryRemote(
        dio((o) async => jsonBody('{"id":"b2","status":"NEW_REQUEST"}', 201)),
      );
      await repo.create(
        BookingRequest(
          category: 'COOK',
          areaId: 'a1',
          addressId: 'ad1',
          startDate: today,
        ),
        idempotencyKey: 'k-today',
      );
      expect((seen.single.data as Map)['startDate'], '2026-10-09');
    });

    test('confirm-worker sends the chosen date unchanged', () async {
      final repo = BookingRepositoryRemote(
        dio((o) async => jsonBody('{"id":"b1","status":"NEW_REQUEST"}', 200)),
      );
      await repo.confirmWorker('b1', today);
      expect(seen.first.path, '/bookings/b1/confirm-worker');
      expect((seen.first.data as Map)['startDate'], '2026-10-09');
    });
  });

  group('rebook', () {
    test('POST /bookings/rebook (not /bookings/{id}/rebook)', () async {
      final repo = BookingRepositoryRemote(
        dio((o) async => jsonBody('{"id":"b2","status":"NEW_REQUEST"}', 201)),
      );
      final b = await repo.rebook('b 1', startDate: DateTime(2026, 11, 3));
      expect(seen.single.method, 'POST');
      expect(seen.single.path, '/bookings/rebook');
      expect(seen.single.data, {'bookingId': 'b 1', 'startDate': '2026-11-03'});
      expect(b.id, 'b2');
    });

    test('startDate is left out when not given', () async {
      final repo = BookingRepositoryRemote(
        dio((o) async => jsonBody('{"id":"b2","status":"NEW_REQUEST"}', 201)),
      );
      await repo.rebook('b1');
      expect(seen.single.data, {'bookingId': 'b1'});
    });
  });

  group('attendance', () {
    test('LATE and LEAVE parse, with check-in / out times', () {
      final late = AttendanceEntry.fromJson({
        'id': 'a1',
        'date': '2026-10-09',
        'status': 'LATE',
        'checkInAt': '2026-10-09T02:45:00.000Z',
        'checkOutAt': null,
      })!;
      expect(late.status, AttendanceStatus.late);
      expect(late.checkInAt, DateTime.utc(2026, 10, 9, 2, 45).toLocal());
      expect(late.checkOutAt, isNull);
      expect(
        AttendanceEntry.fromJson({
          'date': '2026-10-10',
          'status': 'LEAVE',
        })!.status,
        AttendanceStatus.leave,
      );
      expect(
        AttendanceEntry.fromJson({
          'date': '2026-10-10',
          'status': 'HALF_DAY',
        })!.status,
        AttendanceStatus.unknown,
      );
    });

    test(
      'summary reads late, leave, the scheduled window and the worker',
      () async {
        final repo = AttendanceRepositoryRemote(
          dio(
            (o) async => jsonBody(
              '{"month":"2026-10","present":10,"absent":1,"late":2,"leave":3,"exception":0,'
              '"scheduledWindow":{"from":"08:00","to":"12:00"},"worker":$_worker}',
              200,
            ),
          ),
        );
        final s = await repo.summary('b1', '2026-10');
        expect(seen.single.path, '/attendance/bookings/b1/summary');
        expect(s.late, 2);
        expect(s.leave, 3);
        expect(s.scheduledFrom, '08:00');
        expect(s.scheduledTo, '12:00');
        expect(s.worker!.cacheKey, 'ph_9');
      },
    );

    test('an older summary without the new fields still reads', () async {
      final repo = AttendanceRepositoryRemote(
        dio(
          (o) async => jsonBody(
            '{"month":"2026-10","present":1,"absent":0,"exception":0}',
            200,
          ),
        ),
      );
      final s = await repo.summary('b1', '2026-10');
      expect(s.late, 0);
      expect(s.scheduledFrom, isNull);
      expect(s.worker, isNull);
    });

    test('raising an exception posts date and note with a key', () async {
      final repo = AttendanceRepositoryRemote(
        dio(
          (o) async => jsonBody(
            '{"id":"a9","date":"2026-10-09","status":"EXCEPTION","note":"No show","recordedBy":"CUSTOMER"}',
            201,
          ),
        ),
      );
      final e = await repo.raiseException(
        'b1',
        date: '2026-10-09',
        note: 'No show',
        idempotencyKey: 'key-12345678',
      );
      expect(seen.single.method, 'POST');
      expect(seen.single.path, '/attendance/bookings/b1/exceptions');
      expect(seen.single.data, {'date': '2026-10-09', 'note': 'No show'});
      expect(seen.single.headers['Idempotency-Key'], 'key-12345678');
      expect(e.status, AttendanceStatus.exception);
    });

    test('409 when the day already has an entry', () async {
      final repo = AttendanceRepositoryRemote(
        dio((o) async => jsonBody('{"code":"ATTENDANCE_EXISTS"}', 409)),
      );
      await expectLater(
        repo.raiseException(
          'b1',
          date: '2026-10-09',
          note: 'x',
          idempotencyKey: 'key-12345678',
        ),
        throwsA(isA<ConflictFailure>()),
      );
    });
  });

  group('reference data', () {
    Future<int> reviewMax(Map<String, Object?> data) async {
      final c = ProviderContainer(
        overrides: [referenceDataProvider.overrideWith((ref) async => data)],
      );
      addTearDown(c.dispose);
      await c.read(referenceDataProvider.future);
      return c.read(ratingReviewMaxProvider);
    }

    test('ratingReviewMax is read, 300 when missing', () async {
      expect(await reviewMax({'ratingReviewMax': 120}), 120);
      expect(await reviewMax({}), 300);
      expect(await reviewMax({'ratingReviewMax': 0}), 300);
    });
  });
}
