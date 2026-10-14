// Module 12: support and safety repositories, models and the status mapper against the shapes of
// the 2026-10-13 OpenAPI (`/support/*`, `/safety/*`). SUP-01, SUP-06.
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/core/widgets/sn_badge.dart';
import 'package:sevanest_customer/features/support/data/support_repository_mock.dart';
import 'package:sevanest_customer/features/support/data/support_repository_remote.dart';
import 'package:sevanest_customer/features/support/domain/support.dart';
import 'package:sevanest_customer/features/support/presentation/support_labels.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations_en.dart';

import '../../helpers/fakes.dart';

const _cat = '{"id":"c1","code":"PAYMENT","name":"Payment or refund"}';

String _ticket(
  String status, {
  String? booking = 'b1',
  String? resolution,
  String history = '[]',
  String extra = '',
}) =>
    '{"id":"tk_abcdef123","category":$_cat,"bookingId":${booking == null ? 'null' : '"$booking"'},'
    '"description":"Charged twice\\nfor my booking","status":"$status",'
    '"resolution":${resolution == null ? 'null' : '"$resolution"'},"dueAt":null,'
    '"createdAt":"2026-10-14T02:30:00.000Z","closedAt":null,"history":$history$extra}';

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

  group('SUP status mapper', () {
    test('every backend status, case-insensitive, and an unknown one', () {
      expect(ticketStatusFrom('OPEN'), TicketStatus.open);
      expect(ticketStatusFrom('in_progress'), TicketStatus.inProgress);
      expect(ticketStatusFrom('ESCALATED'), TicketStatus.escalated);
      expect(ticketStatusFrom('CLOSED'), TicketStatus.closed);
      expect(ticketStatusFrom('WAITING_ON_CUSTOMER'), TicketStatus.unknown);
      expect(ticketStatusFrom(null), TicketStatus.unknown);
    });

    test('labels never show a raw code; ESCALATED reads In progress', () {
      expect(ticketStatusLabel(l, TicketStatus.open), 'Open');
      expect(ticketStatusLabel(l, TicketStatus.inProgress), 'In progress');
      expect(ticketStatusLabel(l, TicketStatus.escalated), 'In progress');
      expect(ticketStatusLabel(l, TicketStatus.closed), 'Closed');
      expect(ticketStatusLabel(l, TicketStatus.unknown), 'Updated');
      expect(ticketStatusTone(TicketStatus.escalated), SnBadgeTone.success);
    });

    test('only open states accept replies', () {
      expect(ticketAcceptsReplies(TicketStatus.open), isTrue);
      expect(ticketAcceptsReplies(TicketStatus.escalated), isTrue);
      expect(ticketAcceptsReplies(TicketStatus.closed), isFalse);
      expect(ticketAcceptsReplies(TicketStatus.unknown), isFalse);
    });
  });

  group('SUP-06 ticket model', () {
    test('reads the Swagger shape and ignores internal fields', () {
      final t = Ticket.fromJson(
        jsonDecode(
          _ticket(
            'IN_PROGRESS',
            history:
                '[{"type":"STATUS","fromStatus":"OPEN","toStatus":"IN_PROGRESS","createdAt":"2026-10-14T03:00:00.000Z"}]',
            extra:
                ',"priority":"URGENT","assignedToUserId":"staff1","escalationReason":"vip","internalNote":"call back"',
          ),
        ),
      )!;
      expect(t.id, 'tk_abcdef123');
      expect(t.reference, 'TK-DEF123');
      expect(t.category.name, 'Payment or refund');
      expect(t.bookingId, 'b1');
      expect(t.status, TicketStatus.inProgress);
      expect(t.history.single.to, TicketStatus.inProgress);
      expect(t.title(), 'Charged twice');
      // The model has nowhere to keep them.
      expect(t.toString(), isNot(contains('URGENT')));
    });

    test('a body without an id or a category is not a ticket', () {
      expect(Ticket.fromJson({'description': 'x'}), isNull);
      expect(Ticket.fromJson({'id': 'x'}), isNull);
      expect(Ticket.fromJson('nope'), isNull);
    });

    test('long first lines are cut and updatedAt is the latest change', () {
      final t = Ticket(
        id: 'abc',
        category: const SupportCategory(id: 'c', code: 'X', name: 'X'),
        description: 'a' * 200,
        status: TicketStatus.open,
        createdAt: DateTime(2026, 10, 14, 8),
        history: [TicketEvent(at: DateTime(2026, 10, 14, 9))],
      );
      expect(t.title(20).length, 20);
      expect(t.title(20).endsWith('…'), isTrue);
      expect(t.updatedAt, DateTime(2026, 10, 14, 9));
    });

    test('messages: author mapping and tolerant parsing', () {
      final m = TicketMessage.fromJson({
        'id': 'm1',
        'from': 'ADMIN',
        'body': 'Hello',
        'createdAt': '2026-10-14T03:00:00.000Z',
      })!;
      expect(m.from, MessageAuthor.admin);
      expect(m.isMine, isFalse);
      expect(
        TicketMessage.fromJson({'id': 'm', 'from': 'X', 'body': 'b'})!.from,
        MessageAuthor.unknown,
      );
      expect(TicketMessage.fromJson({'id': 'm'}), isNull);
    });

    test('safety category is recognised by the backend code', () {
      expect(
        const SupportCategory(id: '1', code: 'SAFETY', name: 'x').isSafety,
        isTrue,
      );
      expect(
        const SupportCategory(id: '1', code: 'PAYMENT', name: 'x').isSafety,
        isFalse,
      );
    });
  });

  group('SUP-01 remote support repository', () {
    test('categories parse', () async {
      final r = SupportRepositoryRemote(
        dio((_) async => jsonBody('[$_cat,{"id":"c2","code":"X"}]', 200)),
      );
      final list = await r.categories();
      expect(list.single.id, 'c1'); // the one without a name is skipped
      expect(seen.single.path, '/support/categories');
    });

    test('create sends category, description, booking and the key', () async {
      final r = SupportRepositoryRemote(
        dio((_) async => jsonBody(_ticket('OPEN'), 201)),
      );
      final t = await r.create(
        categoryId: 'c1',
        description: '  Charged twice  ',
        bookingId: 'b1',
        idempotencyKey: 'key-1',
      );
      expect(t.status, TicketStatus.open);
      final o = seen.single;
      expect(o.method, 'POST');
      expect(o.path, '/support/tickets');
      expect(o.headers['Idempotency-Key'], 'key-1');
      expect(o.data, {
        'categoryId': 'c1',
        'description': 'Charged twice',
        'bookingId': 'b1',
      });
    });

    test('create without a booking sends no bookingId', () async {
      final r = SupportRepositoryRemote(
        dio((_) async => jsonBody(_ticket('OPEN', booking: null), 201)),
      );
      await r.create(
        categoryId: 'c1',
        description: 'Something is wrong here',
        idempotencyKey: 'k',
      );
      expect((seen.single.data as Map).containsKey('bookingId'), isFalse);
    });

    test('list pages with meta.total', () async {
      final r = SupportRepositoryRemote(
        dio(
          (_) async => jsonBody(
            '{"data":[${_ticket('OPEN')}],"meta":{"page":1,"limit":20,"total":45}}',
            200,
          ),
        ),
      );
      final p = await r.list();
      expect(p.items.single.id, 'tk_abcdef123');
      expect(p.nextCursor, '2');
      expect(seen.single.queryParameters, {'page': 1, 'limit': 20});
      final last = await r.list(cursor: '3');
      expect(last.nextCursor, isNull);
    });

    test('get reads the ticket with its history', () async {
      final r = SupportRepositoryRemote(
        dio((_) async => jsonBody(_ticket('CLOSED', resolution: 'Fixed'), 200)),
      );
      final t = await r.get('tk_abcdef123');
      expect(t.status, TicketStatus.closed);
      expect(t.resolution, 'Fixed');
      expect(seen.single.path, '/support/tickets/tk_abcdef123');
    });

    test('messages page and post body', () async {
      final r = SupportRepositoryRemote(
        dio((o) async {
          if (o.method == 'GET') {
            return jsonBody(
              '{"data":[{"id":"m1","from":"CUSTOMER","body":"Hi","createdAt":"2026-10-14T03:00:00.000Z"}],'
              '"meta":{"page":1,"limit":20,"total":1}}',
              200,
            );
          }
          return jsonBody(
            '{"id":"m2","from":"CUSTOMER","body":"Thanks","createdAt":"2026-10-14T04:00:00.000Z"}',
            201,
          );
        }),
      );
      final page = await r.messages('t1');
      expect(page.items.single.isMine, isTrue);
      expect(page.nextCursor, isNull);
      expect(seen.single.path, '/support/tickets/t1/messages');
      final m = await r.post('t1', '  Thanks ', idempotencyKey: 'k2');
      expect(m.body, 'Thanks');
      expect(seen.last.method, 'POST');
      expect(seen.last.headers['Idempotency-Key'], 'k2');
      expect(seen.last.data, {'body': 'Thanks'});
    });

    test('errors map to failures with the backend code', () async {
      Future<Object?> run(int status, String body) async {
        final r = SupportRepositoryRemote(
          dio((_) async => jsonBody(body, status)),
        );
        try {
          await r.post('t', 'x', idempotencyKey: 'k');
        } on Object catch (e) {
          return e;
        }
        return null;
      }

      expect(await run(404, '{"code":"NOT_FOUND"}'), isA<NotFoundFailure>());
      final closed = await run(
        409,
        '{"code":"TICKET_CLOSED","message":"closed"}',
      );
      expect(closed, isA<ConflictFailure>());
      expect((closed! as ConflictFailure).code, 'TICKET_CLOSED');
      expect(await run(401, '{}'), isA<UnauthorizedFailure>());
    });

    test(
      'an unreadable body is an UnknownFailure, never a fake ticket',
      () async {
        final r = SupportRepositoryRemote(
          dio((_) async => jsonBody('{}', 201)),
        );
        await expectLater(
          r.create(categoryId: 'c', description: 'x', idempotencyKey: 'k'),
          throwsA(isA<UnknownFailure>()),
        );
      },
    );
  });

  group('SUP-10/11 remote safety repository', () {
    test('report sends the reason code, note and alsoBlock', () async {
      final r = SafetyRepositoryRemote(
        dio(
          (_) async => jsonBody(
            '{"id":"r1","reasonCode":"THEFT","createdAt":"2026-10-14T03:00:00.000Z"}',
            201,
          ),
        ),
      );
      await r.report(
        workerId: 'w1',
        reason: ReportReason.theft,
        note: ' took cash ',
        alsoBlock: true,
        idempotencyKey: 'k1',
      );
      expect(seen.single.path, '/safety/reports');
      expect(seen.single.headers['Idempotency-Key'], 'k1');
      expect(seen.single.data, {
        'workerId': 'w1',
        'reasonCode': 'THEFT',
        'note': 'took cash',
        'alsoBlock': true,
      });
    });

    test(
      'a booking names the worker only when there is no worker id',
      () async {
        final r = SafetyRepositoryRemote(dio((_) async => jsonBody('{}', 201)));
        await r.report(
          bookingId: 'b1',
          reason: ReportReason.other,
          idempotencyKey: 'k',
        );
        expect(seen.single.data, {'bookingId': 'b1', 'reasonCode': 'OTHER'});
        await r.report(
          workerId: 'w1',
          bookingId: 'b1',
          reason: ReportReason.other,
          idempotencyKey: 'k',
        );
        expect((seen.last.data as Map).containsKey('bookingId'), isFalse);
      },
    );

    test('every reason code is one of the Swagger enum values', () {
      expect(ReportReason.values.map((r) => r.code).toSet(), {
        'HARASSMENT',
        'THEFT',
        'SAFETY_CONCERN',
        'MISCONDUCT',
        'FRAUD',
        'NO_SHOW',
        'OTHER',
      });
    });

    test('block, list and lift', () async {
      final r = SafetyRepositoryRemote(
        dio((o) async {
          if (o.method == 'DELETE') return jsonBody('', 204);
          if (o.method == 'GET') {
            return jsonBody(
              '[{"id":"blk1","workerId":"w1","createdAt":"2026-10-14T03:00:00.000Z"}]',
              200,
            );
          }
          return jsonBody(
            '{"id":"blk1","workerId":"w1","createdAt":"2026-10-14T03:00:00.000Z"}',
            200,
          );
        }),
      );
      final b = await r.block(workerId: 'w1', idempotencyKey: 'k');
      expect(b.id, 'blk1');
      expect(seen.single.path, '/safety/blocks');
      expect(seen.single.data, {'workerId': 'w1'});
      expect((await r.blocks()).single.workerId, 'w1');
      await r.unblock('blk1');
      expect(seen.last.method, 'DELETE');
      expect(seen.last.path, '/safety/blocks/blk1');
    });

    test(
      '404 for a worker with no relationship, 409 for a staff block',
      () async {
        Future<Object?> run(
          int status,
          String code,
          Future<void> Function(SafetyRepositoryRemote) f,
        ) async {
          final r = SafetyRepositoryRemote(
            dio((_) async => jsonBody('{"code":"$code"}', status)),
          );
          try {
            await f(r);
          } on Object catch (e) {
            return e;
          }
          return null;
        }

        expect(
          await run(
            404,
            'NOT_FOUND',
            (r) => r.block(workerId: 'w', idempotencyKey: 'k'),
          ),
          isA<NotFoundFailure>(),
        );
        final e = await run(409, 'BLOCK_ADMIN_APPLIED', (r) => r.unblock('b'));
        expect((e! as ConflictFailure).code, 'BLOCK_ADMIN_APPLIED');
      },
    );
  });

  group('mock repositories (dev toggle)', () {
    test('a ticket is created once per key and stays open', () async {
      final r = SupportRepositoryMock(() => const MockApiState());
      final a = await r.create(
        categoryId: 'c2',
        description: 'Charged twice for a booking',
        idempotencyKey: 'k1',
      );
      final b = await r.create(
        categoryId: 'c2',
        description: 'Charged twice for a booking',
        idempotencyKey: 'k1',
      );
      expect(a.id, b.id);
      expect(r.created, 1);
      expect(a.status, TicketStatus.open);
      expect((await r.list()).items.first.id, a.id);
    });

    test('posting to a closed ticket answers TICKET_CLOSED', () async {
      final r = SupportRepositoryMock(() => const MockApiState());
      final t = await r.create(
        categoryId: 'c1',
        description: 'Something is wrong here',
        idempotencyKey: 'k1',
      );
      r.close(t.id, 'Fixed');
      await expectLater(
        r.post(t.id, 'hello', idempotencyKey: 'k2'),
        throwsA(
          isA<ConflictFailure>().having((e) => e.code, 'code', 'TICKET_CLOSED'),
        ),
      );
    });

    test('block is harmless to repeat and can be lifted', () async {
      final r = SafetyRepositoryMock(() => const MockApiState());
      final a = await r.block(workerId: 'w1', idempotencyKey: 'k');
      final b = await r.block(workerId: 'w1', idempotencyKey: 'k');
      expect(a.id, b.id);
      expect((await r.blocks()).length, 1);
      await r.unblock(a.id);
      expect(await r.blocks(), isEmpty);
    });
  });
}
