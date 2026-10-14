import 'package:dio/dio.dart';
import 'package:sevanest_customer/core/network/guarded.dart';
import 'package:sevanest_customer/features/notifications/domain/notification.dart';

/// `/notifications*` and `PUT /auth/device-token`. Paging is `page` / `limit` with `meta.total`.
class NotificationRepositoryRemote implements NotificationRepository {
  NotificationRepositoryRemote(this._dio);
  final Dio _dio;

  static const pageSize = 20;

  @override
  Future<NotificationPage> list({
    bool unreadOnly = false,
    String? cursor,
  }) async {
    final page = int.tryParse(cursor ?? '') ?? 1;
    final res = await guarded(
      () => _dio.get<dynamic>(
        '/notifications',
        queryParameters: {
          'page': page,
          'limit': pageSize,
          if (unreadOnly) 'unreadOnly': true,
        },
      ),
    );
    final body = res.data;
    final meta = body is Map ? body['meta'] : null;
    final total = meta is Map && meta['total'] is num
        ? (meta['total'] as num).toInt()
        : 0;
    return NotificationPage([
      for (final m in listOf(body)) ?AppNotification.fromJson(m),
    ], page * pageSize < total ? '${page + 1}' : null);
  }

  @override
  Future<void> markRead(String id) async {
    await guarded(
      () =>
          _dio.post<dynamic>('/notifications/${Uri.encodeComponent(id)}/read'),
    );
  }

  @override
  Future<void> markAllRead() async {
    await guarded(() => _dio.post<dynamic>('/notifications/read-all'));
  }

  /// The Swagger publishes no body for the count; a bare number, or an object with the number
  /// under `count` / `unread` / `unreadCount` / `data`, is read. Anything else is 0.
  @override
  Future<int> unreadCount() async {
    final res = await guarded(
      () => _dio.get<dynamic>('/notifications/unread-count'),
    );
    return parseUnreadCount(res.data);
  }

  @override
  Future<void> registerDeviceToken({
    required String token,
    required String platform,
  }) async {
    await guarded(
      () => _dio.put<dynamic>(
        '/auth/device-token',
        data: {'token': token, 'platform': platform},
      ),
    );
  }

  @override
  Future<void> unregisterDeviceToken() async {
    await guarded(() => _dio.delete<dynamic>('/auth/device-token'));
  }
}

int parseUnreadCount(Object? body) {
  if (body is num) return body.toInt();
  if (body is Map) {
    for (final k in ['count', 'unread', 'unreadCount', 'data']) {
      final v = body[k];
      if (v is num) return v.toInt();
      if (v is Map) return parseUnreadCount(v);
    }
  }
  return 0;
}
