import 'package:sevanest_customer/app/router/routes.dart';

/// `InboxItemView.route`: the deep link `{type, id}` of a notification.
class NotificationTarget {
  const NotificationTarget(this.type, this.id);
  final String type;
  final String id;
}

String? _s(Object? v) => v is String && v.trim().isNotEmpty ? v.trim() : null;

/// `InboxItemView`. Title and body are the wording staff configured for the event; the app shows
/// them as sent. A missing title reads "Update".
class AppNotification {
  const AppNotification({
    required this.id,
    required this.event,
    required this.body,
    required this.createdAt,
    this.title,
    this.target,
    this.readAt,
  });

  final String id;
  final String event;
  final String? title;
  final String body;
  final NotificationTarget? target;
  final DateTime? readAt;
  final DateTime createdAt;

  bool get isRead => readAt != null;

  AppNotification markedRead(DateTime at) => AppNotification(
    id: id,
    event: event,
    title: title,
    body: body,
    target: target,
    readAt: readAt ?? at,
    createdAt: createdAt,
  );

  AppNotification markedUnread() => AppNotification(
    id: id,
    event: event,
    title: title,
    body: body,
    target: target,
    createdAt: createdAt,
  );

  static AppNotification? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = _s(json['id']);
    if (id == null) return null;
    final r = json['route'];
    final t = r is Map ? _s(r['type']) : null;
    final rid = r is Map ? _s(r['id']) : null;
    DateTime? d(Object? v) {
      final x = v is String ? DateTime.tryParse(v) : null;
      return x != null && x.isUtc ? x.toLocal() : x;
    }

    return AppNotification(
      id: id,
      event: _s(json['event']) ?? '',
      title: _s(json['title']),
      body: json['body'] is String ? json['body'] as String : '',
      target: t == null || rid == null ? null : NotificationTarget(t, rid),
      readAt: d(json['readAt']),
      createdAt: d(json['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class NotificationPage {
  const NotificationPage(this.items, this.nextCursor);
  final List<AppNotification> items;
  final String? nextCursor;
}

/// `/notifications*` and `PUT /auth/device-token` of the deployed backend.
abstract interface class NotificationRepository {
  /// `GET /notifications`, newest first.
  Future<NotificationPage> list({bool unreadOnly = false, String? cursor});

  /// `POST /notifications/{id}/read` (404 for an unknown id or someone else's).
  Future<void> markRead(String id);

  /// `POST /notifications/{id}/unread`.
  Future<void> markUnread(String id);

  /// `POST /notifications/read-all`.
  Future<void> markAllRead();

  /// `GET /notifications/unread-count`.
  Future<int> unreadCount();

  /// `PUT /auth/device-token`: binds the push token to the current session.
  Future<void> registerDeviceToken({
    required String token,
    required String platform,
  });

  /// `DELETE /auth/device-token`: unbinds the push token of the current session only.
  Future<void> unregisterDeviceToken();
}

/// An id that can go into a path: the backend's ids are uuids or short tokens.
final _idPattern = RegExp(r'^[A-Za-z0-9_-]{1,64}$');

/// THE one place a notification or push payload becomes a route (docs/modules/13). The payload is
/// only a hint: the screen it opens reads the entity fresh. Unknown type, or a missing or odd id,
/// opens the centre. `*_update` and `*_id` spellings are accepted because the push payload keys
/// are not published yet (BACKEND_REQUESTS 52).
String routeForNotification(String? type, String? id) {
  final t = (type ?? '')
      .trim()
      .toLowerCase()
      .replaceAll('-', '_')
      .replaceAll(RegExp(r'_update$'), '');
  final i = id?.trim();
  // `new` is the "start a payment / ticket" path, never an entity id.
  if (i == null || i == 'new' || !_idPattern.hasMatch(i)) {
    return Routes.notifications;
  }
  return switch (t) {
    'booking' => Routes.path(Routes.bookingDetail, {'id': i}),
    'interview' || 'trial' => Routes.path(Routes.interviewDetail, {'id': i}),
    'payment' || 'transaction' => Routes.path(Routes.payment, {'id': i}),
    'replacement' ||
    'replacement_request' => Routes.path(Routes.replacementDetail, {'id': i}),
    'ticket' ||
    'support' ||
    'support_ticket' => Routes.path(Routes.supportDetail, {'id': i}),
    _ => Routes.notifications,
  };
}

/// A push `data` map -> route. The backend sends flat `routeType` + `routeId`; `route` as
/// `{type, id}` (or `type:id`) and `type` + `entityId` / `id` are still read.
String routeForPushData(Map<String, dynamic> data) {
  final route = data['route'];
  if (route is String) {
    final parts = route.split(':');
    if (parts.length == 2) {
      return routeForNotification(parts[0], parts[1]);
    }
  }
  if (route is Map) {
    return routeForNotification(
      _s(route['type']),
      _s(route['id']) ?? _s(route['entityId']),
    );
  }
  return routeForNotification(
    _s(data['routeType']) ?? _s(data['type']),
    _s(data['routeId']) ?? _s(data['entityId']) ?? _s(data['id']),
  );
}

/// Where to navigate for [route] from [routeForNotification]: the centre directly, any entity
/// through `/open` so it is read fresh (and a missing one says so).
String deepLinkLocation(String route) => route == Routes.notifications
    ? route
    : '${Routes.open}?to=${Uri.encodeComponent(route)}';
