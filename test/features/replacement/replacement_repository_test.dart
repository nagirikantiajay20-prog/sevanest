// Module 11: replacement repositories, models and the status mapper against the shapes of the
// 2026-10-13 OpenAPI (`/replacement-requests`, `/bookings/{id}/replacement-chain`). REP-06.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/core/widgets/sn_badge.dart';
import 'package:sevanest_customer/features/booking/domain/booking.dart';
import 'package:sevanest_customer/features/replacement/data/replacement_repository_mock.dart';
import 'package:sevanest_customer/features/replacement/data/replacement_repository_remote.dart';
import 'package:sevanest_customer/features/replacement/domain/replacement.dart';
import 'package:sevanest_customer/features/replacement/presentation/replacement_labels.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations_en.dart';

import '../../helpers/fakes.dart';

String _view(
  String status, {
  String? remarks,
  String? newBooking,
  String extra = '',
}) =>
    '{"id":"rp_1234567","bookingId":"b1","status":"$status","reason":"Not arriving on time",'
    '"notes":null,"decisionRemarks":${remarks == null ? 'null' : '"$remarks"'},'
    '"replacementBookingId":${newBooking == null ? 'null' : '"$newBooking"'},'
    '"createdAt":"2026-10-09T14:45:00.000Z","decidedAt":null,"completedAt":null$extra}';

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

  final l = AppLocalizationsEn();

  group('REP-06 status mapper', () {
    test('every backend status, case-insensitive, and an unknown one', () {
      expect(replacementStatusFrom('REQUESTED'), ReplacementStatus.requested);
      expect(replacementStatusFrom('approved'), ReplacementStatus.approved);
      expect(replacementStatusFrom('REJECTED'), ReplacementStatus.rejected);
      expect(replacementStatusFrom('CANCELLED'), ReplacementStatus.cancelled);
      expect(replacementStatusFrom('CANCELED'), ReplacementStatus.cancelled);
      expect(replacementStatusFrom('COMPLETED'), ReplacementStatus.completed);
      expect(replacementStatusFrom('ON_HOLD'), ReplacementStatus.unknown);
      expect(replacementStatusFrom(null), ReplacementStatus.unknown);
    });

    test('labels never show a raw code; unknown reads "Updated"', () {
      expect(
        {
          for (final s in ReplacementStatus.values)
            replacementStatusLabel(l, s),
        },
        {
          'Under review',
          'Approved',
          'Not approved',
          'Cancelled',
          'Completed',
          'Updated',
        },
      );
      expect(
        replacementStatusTone(ReplacementStatus.unknown),
        SnBadgeTone.neutral,
      );
    });

    test('only requested and approved are open (withdrawable)', () {
      for (final s in ReplacementStatus.values) {
        expect(
          replacementIsOpen(s),
          s == ReplacementStatus.requested || s == ReplacementStatus.approved,
        );
      }
    });

    test('a reason the app sent is localized, the customer words stay', () {
      expect(
        replacementReasonText(l, 'Work quality is not good'),
        'Work quality is not good',
      );
      expect(replacementReasonText(l, 'He broke a plate'), 'He broke a plate');
      expect(
        ReplacementReason.fromText(' safety or trust concern '),
        ReplacementReason.safety,
      );
    });
  });

  group('model', () {
    test('parses the Swagger ReplacementView', () {
      final r = Replacement.fromJson({
        'id': 'rp_1234567',
        'bookingId': 'b1',
        'status': 'COMPLETED',
        'reason': 'Other',
        'notes': 'x',
        'decisionRemarks': 'Approved by Priya',
        'replacementBookingId': 'b2',
        'createdAt': '2026-10-09T14:45:00.000Z',
        'decidedAt': '2026-10-09T16:00:00.000Z',
        'completedAt': '2026-10-10T05:00:00.000Z',
      })!;
      expect(r.status, ReplacementStatus.completed);
      expect(r.replacementBookingId, 'b2');
      expect(r.decisionRemarks, 'Approved by Priya');
      expect(r.createdAt, isNotNull);
      expect(r.alternatives, isEmpty);
      expect(r.reference, '234567'.toUpperCase());
    });

    test(
      'alternatives are read when sent, in either shape; none otherwise',
      () {
        final r = Replacement.fromJson({
          'id': 'r1',
          'bookingId': 'b1',
          'status': 'APPROVED',
          'reason': 'x',
          'alternatives': [
            {
              'workerId': 'w1',
              'categories': <Object>[],
              'serviceAreas': <Object>[],
            },
            {
              'worker': {'workerId': 'w2'},
            },
            {'nothing': true},
          ],
        })!;
        expect(r.alternatives.map((w) => w.id), ['w1', 'w2']);
      },
    );

    test(
      'an object without an id is no request; an unknown status is kept',
      () {
        expect(Replacement.fromJson({'status': 'REQUESTED'}), isNull);
        expect(Replacement.fromJson('x'), isNull);
        expect(
          Replacement.fromJson({'id': 'r1', 'status': 'NEW_THING'})!.status,
          ReplacementStatus.unknown,
        );
      },
    );

    test('the chain entry follows ChainEntryView', () {
      final e = ChainEntry.fromJson({
        'bookingId': 'b2',
        'position': 2,
        'status': 'MATCHED',
        'replacesBookingId': 'b1',
        'startDate': '2026-11-01',
        'createdAt': '2026-10-09T14:45:00.000Z',
        'current': true,
      })!;
      expect(e.position, 2);
      expect(e.status, BookingStatus.matched);
      expect(e.current, isTrue);
      expect(e.startDate, DateTime(2026, 11));
      expect(ChainEntry.fromJson({'position': 1}), isNull);
    });
  });

  group('remote', () {
    test('create posts the Swagger body with one Idempotency-Key', () async {
      final repo = ReplacementRepositoryRemote(
        dio((o) async => jsonBody(_view('REQUESTED'), 201)),
      );
      final r = await repo.create(
        bookingId: 'b1',
        reason: ' Other ',
        notes: ' it broke ',
        idempotencyKey: 'key-12345678',
      );
      expect(seen.single.method, 'POST');
      expect(seen.single.path, '/replacement-requests');
      expect(seen.single.headers['Idempotency-Key'], 'key-12345678');
      expect(seen.single.data, {
        'bookingId': 'b1',
        'reason': 'Other',
        'notes': 'it broke',
      });
      expect(r.status, ReplacementStatus.requested);
    });

    test('empty notes are not sent', () async {
      final repo = ReplacementRepositoryRemote(
        dio((o) async => jsonBody(_view('REQUESTED'), 201)),
      );
      await repo.create(
        bookingId: 'b1',
        reason: 'Frequent absences',
        notes: '  ',
        idempotencyKey: 'key-12345678',
      );
      expect((seen.single.data as Map).containsKey('notes'), isFalse);
    });

    test('list pages 20 at a time and builds the next cursor', () async {
      final repo = ReplacementRepositoryRemote(
        dio(
          (o) async => jsonBody(
            '{"data":[${_view('APPROVED')}],"meta":{"page":1,"limit":20,"total":45}}',
            200,
          ),
        ),
      );
      final p = await repo.list();
      expect(seen.single.path, '/replacement-requests');
      expect(seen.single.queryParameters, {'page': 1, 'limit': 20});
      expect(p.items.single.status, ReplacementStatus.approved);
      expect(p.nextCursor, '2');
      final last = await repo.list(cursor: '3');
      expect(seen.last.queryParameters['page'], 3);
      expect(last.nextCursor, isNull);
    });

    test('get, cancel and select use the request id routes', () async {
      final repo = ReplacementRepositoryRemote(
        dio((o) async => jsonBody(_view('COMPLETED', newBooking: 'b2'), 200)),
      );
      await repo.get('rp 1');
      expect(seen.last.method, 'GET');
      expect(seen.last.path, '/replacement-requests/rp%201');
      await repo.cancel('rp1', idempotencyKey: 'key-12345678');
      expect(seen.last.method, 'POST');
      expect(seen.last.path, '/replacement-requests/rp1/cancel');
      expect(seen.last.headers['Idempotency-Key'], 'key-12345678');
      final r = await repo.select('rp1', 'w9', idempotencyKey: 'key-22222222');
      expect(seen.last.path, '/replacement-requests/rp1/select');
      expect(seen.last.data, {'workerId': 'w9'});
      expect(r.replacementBookingId, 'b2');
    });

    test('the chain is read oldest first from the booking route', () async {
      final repo = ReplacementRepositoryRemote(
        dio(
          (o) async => jsonBody(
            '[{"bookingId":"b1","position":1,"status":"REPLACED","replacesBookingId":null,'
            '"startDate":"2026-10-01","createdAt":"2026-10-01T00:00:00Z","current":false},'
            '{"bookingId":"b2","position":2,"status":"MATCHED","replacesBookingId":"b1",'
            '"startDate":null,"createdAt":"2026-10-10T00:00:00Z","current":true}]',
            200,
          ),
        ),
      );
      final c = await repo.chain('b2');
      expect(seen.single.path, '/bookings/b2/replacement-chain');
      expect(c.map((e) => e.bookingId), ['b1', 'b2']);
      expect(c.last.current, isTrue);
    });

    test(
      'an unreadable success body is an unknown failure, not a crash',
      () async {
        final repo = ReplacementRepositoryRemote(
          dio((o) async => jsonBody('{}', 200)),
        );
        await expectLater(repo.get('x'), throwsA(isA<UnknownFailure>()));
      },
    );

    test('the documented errors keep their code', () async {
      Future<Object> thrown(int status, String code) async {
        final repo = ReplacementRepositoryRemote(
          dio((o) async => jsonBody('{"code":"$code","message":"x"}', status)),
        );
        try {
          await repo.create(
            bookingId: 'b1',
            reason: 'Other',
            idempotencyKey: 'key-12345678',
          );
        } on Object catch (e) {
          return e;
        }
        fail('should have thrown');
      }

      expect(
        (await thrown(422, 'REPLACEMENT_NOT_ELIGIBLE') as ValidationFailure)
            .code,
        'REPLACEMENT_NOT_ELIGIBLE',
      );
      expect(
        await thrown(409, 'REPLACEMENT_REQUESTED'),
        isA<ConflictFailure>(),
      );
      expect(await thrown(404, 'NOT_FOUND'), isA<NotFoundFailure>());
      expect(await thrown(403, 'FORBIDDEN'), isA<ForbiddenFailure>());
    });
  });

  group('mock', () {
    test(
      'one open request per booking; the same key returns the first',
      () async {
        final repo = ReplacementRepositoryMock(
          () => const MockApiState(),
          autoApprove: false,
        );
        final a = await repo.create(
          bookingId: 'b1',
          reason: 'Other',
          idempotencyKey: 'key-1',
        );
        final again = await repo.create(
          bookingId: 'b1',
          reason: 'Other',
          idempotencyKey: 'key-1',
        );
        expect(again.id, a.id);
        expect(repo.created, 1);
        await expectLater(
          repo.create(bookingId: 'b1', reason: 'x', idempotencyKey: 'key-2'),
          throwsA(isA<ConflictFailure>()),
        );
      },
    );

    test(
      'approve attaches alternatives, select completes, withdraw cancels',
      () async {
        final repo = ReplacementRepositoryMock(
          () => const MockApiState(),
          autoApprove: false,
        );
        final a = await repo.create(
          bookingId: 'b1',
          reason: 'Other',
          idempotencyKey: 'key-1',
        );
        expect((await repo.get(a.id)).alternatives, isEmpty);
        repo.approve(a.id);
        final ready = await repo.get(a.id);
        expect(ready.alternatives, hasLength(3));
        repo.unavailable.add('cook-2');
        await expectLater(
          repo.select(a.id, 'cook-2', idempotencyKey: 'k'),
          throwsA(isA<ConflictFailure>()),
        );
        final done = await repo.select(a.id, 'cook-5', idempotencyKey: 'k');
        expect(done.status, ReplacementStatus.completed);
        expect(done.replacementBookingId, isNotNull);
        final b = await repo.create(
          bookingId: 'b2',
          reason: 'Other',
          idempotencyKey: 'key-3',
        );
        expect(
          (await repo.cancel(b.id, idempotencyKey: 'k')).status,
          ReplacementStatus.cancelled,
        );
      },
    );
  });
}
