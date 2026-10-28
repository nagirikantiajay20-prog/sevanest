// Module 13: notification repositories and the deep-link mapper. NOT-01 (the table, incl. an
// unknown type and a missing id), the Swagger shapes of `/notifications*` and `PUT /auth/device-token`.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/features/notifications/data/notification_repository_mock.dart';
import 'package:sevanest_customer/features/notifications/data/notification_repository_remote.dart';
import 'package:sevanest_customer/features/notifications/domain/notification.dart';

import '../../helpers/fakes.dart';

const _item =
    '{"id":"n1","event":"BOOKING_CONFIRMED","title":"Booking confirmed","body":"Your booking is confirmed.",'
    '"route":{"type":"booking","id":"b1"},"readAt":null,"createdAt":"2026-10-14T02:30:00.000Z"}';

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

  group('NOT-01 route mapper table', () {
    const id = '4c1f0a52-8f1e-4d0e-9a53-2b6a1c9d7e11';
    test('every notification type maps to one route', () {
      expect(routeForNotification('booking', id), '/bookings/$id');
      expect(routeForNotification('interview', id), '/interviews/$id');
      expect(routeForNotification('payment', id), '/payments/$id');
      expect(routeForNotification('replacement', id), '/replacements/$id');
      expect(routeForNotification('ticket', id), '/support/$id');
    });

    test('the module-doc spellings and case are accepted', () {
      expect(routeForNotification('booking_update', id), '/bookings/$id');
      expect(routeForNotification('INTERVIEW_UPDATE', id), '/interviews/$id');
      expect(routeForNotification('payment_update', id), '/payments/$id');
      expect(
        routeForNotification('replacement_update', id),
        '/replacements/$id',
      );
      expect(routeForNotification('ticket_update', id), '/support/$id');
      expect(routeForNotification('support', id), '/support/$id');
      expect(routeForNotification(' Booking ', id), '/bookings/$id');
    });

    test('an unknown type opens the centre', () {
      expect(routeForNotification('promo_banner', id), Routes.notifications);
      expect(routeForNotification('', id), Routes.notifications);
      expect(routeForNotification(null, id), Routes.notifications);
    });

    test('a missing, empty or odd id opens the centre and never crashes', () {
      expect(routeForNotification('booking', null), Routes.notifications);
      expect(routeForNotification('booking', ''), Routes.notifications);
      expect(routeForNotification('booking', '   '), Routes.notifications);
      expect(
        routeForNotification('booking', '../../etc'),
        Routes.notifications,
      );
      expect(routeForNotification('booking', 'a b'), Routes.notifications);
      expect(routeForNotification('booking', 'a/b?x=1'), Routes.notifications);
      // `new` is the "start" path of payments and tickets, never an entity.
      expect(routeForNotification('payment', 'new'), Routes.notifications);
      expect(routeForNotification('ticket', 'new'), Routes.notifications);
    });

    test('a push data map: route object, route string, or flat keys', () {
      expect(
        routeForPushData({
          'route': {'type': 'booking', 'id': id},
        }),
        '/bookings/$id',
      );
      expect(routeForPushData({'route': 'ticket:$id'}), '/support/$id');
      expect(
        routeForPushData({'type': 'interview_update', 'entityId': id}),
        '/interviews/$id',
      );
      expect(
        routeForPushData({'routeType': 'payment', 'routeId': id}),
        '/payments/$id',
      );
      expect(routeForPushData({}), Routes.notifications);
      expect(routeForPushData({'type': 'booking'}), Routes.notifications);
      expect(routeForPushData({'route': 5}), Routes.notifications);
    });

    test('an entity opens through /open (read fresh), the centre directly', () {
      expect(
        deepLinkLocation('/bookings/b1'),
        '/open?to=${Uri.encodeComponent('/bookings/b1')}',
      );
      expect(deepLinkLocation(Routes.notifications), Routes.notifications);
    });
  });

  group('remote notification repository', () {
    test('list parses the inbox shape and pages with meta.total', () async {
      final r = NotificationRepositoryRemote(
        dio(
          (_) async => jsonBody(
            '{"data":[$_item,{"id":"n2","event":"X","title":null,"body":"Hi","route":null,'
            '"readAt":"2026-10-14T03:00:00.000Z","createdAt":"2026-10-14T01:00:00.000Z"}],'
            '"meta":{"page":1,"limit":20,"total":30}}',
            200,
          ),
        ),
      );
      final p = await r.list();
      expect(p.items.length, 2);
      expect(p.items.first.title, 'Booking confirmed');
      expect(p.items.first.target!.type, 'booking');
      expect(p.items.first.isRead, isFalse);
      expect(p.items.last.title, isNull);
      expect(p.items.last.target, isNull);
      expect(p.items.last.isRead, isTrue);
      expect(p.nextCursor, '2');
      expect(seen.single.queryParameters, {'page': 1, 'limit': 20});
    });

    test('the Unread tab sends unreadOnly', () async {
      final r = NotificationRepositoryRemote(
        dio((_) async => jsonBody('{"data":[],"meta":{"total":0}}', 200)),
      );
      await r.list(unreadOnly: true);
      expect(seen.single.queryParameters['unreadOnly'], true);
    });

    test('a row without an id is skipped, never crashes', () async {
      final r = NotificationRepositoryRemote(
        dio(
          (_) async => jsonBody(
            '{"data":[{"title":"no id"},$_item],"meta":{"total":2}}',
            200,
          ),
        ),
      );
      expect((await r.list()).items.single.id, 'n1');
    });

    test('markRead and read-all call the Swagger routes', () async {
      final r = NotificationRepositoryRemote(
        dio((_) async => jsonBody('', 204)),
      );
      await r.markRead('n 1');
      expect(seen.last.method, 'POST');
      expect(seen.last.path, '/notifications/n%201/read');
      await r.markAllRead();
      expect(seen.last.path, '/notifications/read-all');
    });

    test('markRead 404 (unknown id) is a NotFoundFailure', () async {
      final r = NotificationRepositoryRemote(
        dio((_) async => jsonBody('{"code":"NOT_FOUND"}', 404)),
      );
      await expectLater(r.markRead('x'), throwsA(isA<NotFoundFailure>()));
    });

    test('unread-count is read from a bare number or an object', () async {
      for (final (body, want) in [
        ('7', 7),
        ('{"count":3}', 3),
        ('{"unread":2}', 2),
        ('{"unreadCount":5}', 5),
        ('{"data":{"count":4}}', 4),
        ('{}', 0),
        ('"x"', 0),
      ]) {
        final r = NotificationRepositoryRemote(
          dio((_) async => jsonBody(body, 200)),
        );
        expect(await r.unreadCount(), want, reason: body);
      }
      expect(seen.single.path, '/notifications/unread-count');
    });

    test('the device token is bound with PUT /auth/device-token', () async {
      final r = NotificationRepositoryRemote(
        dio((_) async => jsonBody('', 204)),
      );
      await r.registerDeviceToken(token: 'fcm-token-1', platform: 'ANDROID');
      expect(seen.single.method, 'PUT');
      expect(seen.single.path, '/auth/device-token');
      expect(seen.single.data, {'token': 'fcm-token-1', 'platform': 'ANDROID'});
    });

    test('a 401 is an UnauthorizedFailure', () async {
      final r = NotificationRepositoryRemote(
        dio((_) async => jsonBody('{}', 401)),
      );
      await expectLater(r.unreadCount(), throwsA(isA<UnauthorizedFailure>()));
    });
  });

  group('mock notification repository', () {
    test('three unread, then reading one and all', () async {
      final r = NotificationRepositoryMock(
        () => const MockApiState(returningUser: true),
        now: () => DateTime(2026, 10, 9, 10),
      );
      expect(await r.unreadCount(), 3);
      expect((await r.list(unreadOnly: true)).items.length, 3);
      await r.markRead('n1');
      expect(await r.unreadCount(), 2);
      await r.markAllRead();
      expect(await r.unreadCount(), 0);
      expect((await r.list()).items.length, 5);
      await expectLater(r.markRead('nope'), throwsA(isA<NotFoundFailure>()));
    });
  });
}
