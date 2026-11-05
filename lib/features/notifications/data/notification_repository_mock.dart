import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/features/notifications/domain/notification.dart';

/// In-memory inbox behind the dev mock toggle: three unread and two read (one unread for a brand
/// new customer, as Home shows).
class NotificationRepositoryMock implements NotificationRepository {
  NotificationRepositoryMock(this._state, {DateTime Function()? now})
    : _now = now ?? DateTime.now {
    final t = _now();
    AppNotification n(
      String id,
      String event,
      String title,
      String body,
      NotificationTarget? target,
      Duration ago, {
      bool read = false,
    }) => AppNotification(
      id: id,
      event: event,
      title: title,
      body: body,
      target: target,
      createdAt: t.subtract(ago),
      readAt: read ? t.subtract(ago) : null,
    );
    _items.addAll([
      n(
        'n1',
        'INTERVIEW_CONFIRMED',
        'Interview confirmed',
        'Your interview is confirmed.',
        const NotificationTarget('interview', 'iv_1'),
        const Duration(hours: 2),
      ),
      n(
        'n2',
        'PAYMENT_SUCCEEDED',
        'Payment successful',
        'We received your payment.',
        const NotificationTarget('payment', 'pay_1'),
        const Duration(hours: 3),
      ),
      n(
        'n3',
        'TICKET_REPLIED',
        'Support replied',
        'SevaNest Support replied to your ticket.',
        const NotificationTarget('ticket', 'tk_1042'),
        const Duration(hours: 4),
      ),
      n(
        'n4',
        'REPLACEMENT_APPROVED',
        'Alternatives ready',
        'Choose a replacement.',
        const NotificationTarget('replacement', 'rp_3104'),
        const Duration(days: 1),
        read: true,
      ),
      n(
        'n5',
        'SERVICE_COMPLETED',
        'Rate your experience',
        'Tell us how it went.',
        const NotificationTarget('booking', 'b_2048'),
        const Duration(days: 1, hours: 8),
        read: true,
      ),
    ]);
    if (!_returning()) _items.removeRange(1, _items.length);
  }

  final MockApiState Function() _state;
  final DateTime Function() _now;
  final _items = <AppNotification>[];

  bool _returning() => _state().returningUser;

  /// Writes that reached the "server".
  int markReadCalls = 0;
  int markAllCalls = 0;
  final tokens = <String>[];

  /// Staff send a notification.
  void add(AppNotification n) => _items.insert(0, n);

  int _index(String id) {
    final i = _items.indexWhere((n) => n.id == id);
    if (i < 0) throw const NotFoundFailure();
    return i;
  }

  @override
  Future<NotificationPage> list({bool unreadOnly = false, String? cursor}) =>
      mockCall(
        _state(),
        () => NotificationPage([
          for (final n in _items)
            if (!unreadOnly || !n.isRead) n,
        ], null),
      );

  @override
  Future<void> markRead(String id) => mockCall(_state(), () {
    final i = _index(id);
    markReadCalls++;
    _items[i] = _items[i].markedRead(_now());
  });

  @override
  Future<void> markUnread(String id) => mockCall(_state(), () {
    final i = _index(id);
    _items[i] = _items[i].markedUnread();
  });

  @override
  Future<void> markAllRead() => mockCall(_state(), () {
    markAllCalls++;
    for (var i = 0; i < _items.length; i++) {
      _items[i] = _items[i].markedRead(_now());
    }
  });

  @override
  Future<int> unreadCount() =>
      mockCall(_state(), () => _items.where((n) => !n.isRead).length);

  @override
  Future<void> registerDeviceToken({
    required String token,
    required String platform,
  }) => mockCall(_state(), () => tokens.add(token));

  @override
  Future<void> ack(String notificationId, String deliveryStatus) async {}

  @override
  Future<void> unregisterDeviceToken() =>
      mockCall(_state(), () => tokens.clear());
}
