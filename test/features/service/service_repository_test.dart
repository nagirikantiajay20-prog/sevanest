// Module 10: attendance and rating repositories against the shapes of the 2026-10-13 OpenAPI.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/features/active_service/data/attendance_repository_mock.dart';
import 'package:sevanest_customer/features/active_service/data/attendance_repository_remote.dart';
import 'package:sevanest_customer/features/active_service/domain/attendance.dart';
import 'package:sevanest_customer/features/ratings/data/rating_repository_mock.dart';
import 'package:sevanest_customer/features/ratings/data/rating_repository_remote.dart';
import 'package:sevanest_customer/features/ratings/domain/rating.dart';

import '../../helpers/fakes.dart';

String _att(String date, String status, [String? note]) =>
    '{"id":"a-$date","bookingId":"b1","date":"$date","status":"$status",'
    '"note":${note == null ? 'null' : '"$note"'},"recordedBy":"WORKER",'
    '"updatedAt":"2026-10-13T09:00:00Z"}';

const _rating =
    '{"id":"r1","bookingId":"b1","score":8,"review":"Very punctual",'
    '"status":"VISIBLE","createdAt":"2026-10-13T09:00:00Z"}';

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

  group('attendance remote', () {
    test(
      'page reads the customer route and builds the next page cursor',
      () async {
        final repo = AttendanceRepositoryRemote(
          dio(
            (o) async => jsonBody(
              '{"data":[${_att('2026-10-13', 'PRESENT')},'
              '${_att('2026-10-12', 'ABSENT', 'Sick')},'
              '${_att('2026-10-11', 'SOMETHING_NEW')}],'
              '"meta":{"page":1,"limit":20,"total":45}}',
              200,
            ),
          ),
        );
        final p = await repo.page('b 1');
        expect(seen.single.method, 'GET');
        expect(seen.single.path, '/attendance/bookings/b%201');
        expect(seen.single.queryParameters, {'page': 1, 'limit': 20});
        expect(p.items.map((e) => e.status), [
          AttendanceStatus.present,
          AttendanceStatus.absent,
          AttendanceStatus.unknown,
        ]);
        expect(p.items[1].note, 'Sick');
        expect(p.items[0].note, isNull);
        expect(p.items[0].date, '2026-10-13');
        expect(p.nextCursor, '2');
      },
    );

    test('the last page has no cursor; cursor 3 asks for page 3', () async {
      final repo = AttendanceRepositoryRemote(
        dio(
          (o) async => jsonBody(
            '{"data":[${_att('2026-10-01', 'PRESENT')}],'
            '"meta":{"page":3,"limit":20,"total":41}}',
            200,
          ),
        ),
      );
      final p = await repo.page('b1', cursor: '3');
      expect(seen.single.queryParameters['page'], 3);
      expect(p.nextCursor, isNull);
    });

    test('rows without a date are skipped, not crashed on', () async {
      final repo = AttendanceRepositoryRemote(
        dio(
          (o) async => jsonBody(
            '{"data":[{"id":"x","status":"PRESENT"},${_att('2026-10-01', 'PRESENT')}],'
            '"meta":{"page":1,"limit":20,"total":2}}',
            200,
          ),
        ),
      );
      expect((await repo.page('b1')).items, hasLength(1));
    });

    test('summary sends the month and parses the counts', () async {
      final repo = AttendanceRepositoryRemote(
        dio(
          (o) async => jsonBody(
            '{"bookingId":"b1","month":"2026-10","from":"2026-10-01","to":"2026-10-31",'
            '"daysInMonth":31,"present":9,"absent":1,"exception":2,"recorded":12}',
            200,
          ),
        ),
      );
      final s = await repo.summary('b1', '2026-10');
      expect(seen.single.path, '/attendance/bookings/b1/summary');
      expect(seen.single.queryParameters, {'month': '2026-10'});
      expect((s.present, s.absent, s.exception), (9, 1, 2));
    });

    test('404 and 403 map to failures', () async {
      for (final (code, type) in [
        (404, isA<NotFoundFailure>()),
        (403, isA<ForbiddenFailure>()),
      ]) {
        final repo = AttendanceRepositoryRemote(
          dio((o) async => jsonBody('{"code":"X","message":"x"}', code)),
        );
        await expectLater(repo.page('b1'), throwsA(type));
      }
    });
  });

  group('attendance mock', () {
    test('seeds the active booking only, and honours the empty mode', () async {
      final now = DateTime(2026, 10, 9, 10);
      final repo = AttendanceRepositoryMock(
        () => const MockApiState(),
        now: () => now,
      );
      final p = await repo.page('bk_2048');
      expect(p.items.first.date, '2026-10-09');
      expect(p.items.map((e) => e.status), contains(AttendanceStatus.absent));
      expect((await repo.page('bk_1900')).items, isEmpty);
      final s = await repo.summary('bk_2048', '2026-10');
      expect((s.present, s.absent), (2, 1));
      final empty = AttendanceRepositoryMock(
        () => const MockApiState(mode: MockMode.empty),
        now: () => now,
      );
      expect((await empty.page('bk_2048')).items, isEmpty);
    });
  });

  group('rating remote', () {
    test(
      'submit posts bookingId + score + review with an Idempotency-Key',
      () async {
        final repo = RatingRepositoryRemote(
          dio((o) async => jsonBody(_rating, 201)),
        );
        final r = await repo.submit(
          'b1',
          score: 8,
          review: '  Very punctual ',
          idempotencyKey: 'key-12345678',
        );
        expect(seen.single.method, 'POST');
        expect(seen.single.path, '/ratings');
        expect(seen.single.data, {
          'bookingId': 'b1',
          'score': 8,
          'review': 'Very punctual',
        });
        expect(seen.single.headers['Idempotency-Key'], 'key-12345678');
        expect((r.id, r.score, r.review), ('r1', 8, 'Very punctual'));
      },
    );

    test('an empty comment is not sent', () async {
      final repo = RatingRepositoryRemote(
        dio((o) async => jsonBody(_rating, 201)),
      );
      await repo.submit(
        'b1',
        score: 3,
        review: '   ',
        idempotencyKey: 'k-1234567',
      );
      expect(seen.single.data, {'bookingId': 'b1', 'score': 3});
    });

    test('forBooking: a rating, or null on 404', () async {
      var repo = RatingRepositoryRemote(
        dio((o) async => jsonBody(_rating, 200)),
      );
      expect((await repo.forBooking('b1'))?.score, 8);
      expect(seen.single.path, '/ratings/bookings/b1');
      repo = RatingRepositoryRemote(
        dio((o) async => jsonBody('{"code":"NOT_FOUND","message":"x"}', 404)),
      );
      expect(await repo.forBooking('b1'), isNull);
    });

    test('forBooking does not hide other failures', () async {
      final repo = RatingRepositoryRemote(
        dio((o) async => jsonBody('{"code":"X","message":"x"}', 500)),
      );
      await expectLater(repo.forBooking('b1'), throwsA(isA<ServerFailure>()));
    });

    test('mine pages with 50 per page', () async {
      final repo = RatingRepositoryRemote(
        dio(
          (o) async => jsonBody(
            '{"data":[$_rating],"meta":{"page":1,"limit":50,"total":120}}',
            200,
          ),
        ),
      );
      final p = await repo.mine();
      expect(seen.single.queryParameters, {'page': 1, 'limit': 50});
      expect(p.items.single.bookingId, 'b1');
      expect(p.nextCursor, '2');
    });

    test('the documented errors keep their code', () async {
      Future<Object> thrown(int status, String code) async {
        final repo = RatingRepositoryRemote(
          dio((o) async => jsonBody('{"code":"$code","message":"x"}', status)),
        );
        try {
          await repo.submit('b1', score: 4, idempotencyKey: 'k-1234567');
        } on Object catch (e) {
          return e;
        }
        fail('should have thrown');
      }

      expect(
        (await thrown(409, 'RATING_ALREADY_EXISTS') as ConflictFailure).code,
        'RATING_ALREADY_EXISTS',
      );
      expect(
        (await thrown(422, 'RATING_NOT_ELIGIBLE') as ValidationFailure).code,
        'RATING_NOT_ELIGIBLE',
      );
      expect(
        (await thrown(400, 'RATING_SCORE_OUT_OF_SCALE') as ValidationFailure)
            .code,
        'RATING_SCORE_OUT_OF_SCALE',
      );
    });

    test('Rating.fromJson tolerates a missing review and a wrapped body', () {
      final r = Rating.fromJson({
        'data': {'id': 'r', 'bookingId': 'b', 'score': 5, 'review': null},
      });
      expect(r?.review, isNull);
      expect(Rating.fromJson({'id': 'r'}), isNull);
    });
  });

  group('rating mock', () {
    test(
      'once per booking, scale enforced, same key answers the same',
      () async {
        final repo = RatingRepositoryMock(() => const MockApiState());
        final a = await repo.submit('b1', score: 4, idempotencyKey: 'k1');
        expect(
          (await repo.submit('b1', score: 4, idempotencyKey: 'k1')).id,
          a.id,
        );
        await expectLater(
          repo.submit('b1', score: 5, idempotencyKey: 'k2'),
          throwsA(isA<ConflictFailure>()),
        );
        await expectLater(
          repo.submit('b2', score: 6, idempotencyKey: 'k3'),
          throwsA(isA<ValidationFailure>()),
        );
        expect((await repo.forBooking('b1'))?.score, 4);
        expect(await repo.forBooking('b2'), isNull);
      },
    );
  });
}
