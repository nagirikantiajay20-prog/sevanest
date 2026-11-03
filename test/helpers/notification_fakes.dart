// Fakes for the notification and push tests (never shipped).
import 'dart:async';

import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/features/notifications/domain/notification.dart';
import 'package:sevanest_customer/features/notifications/domain/push_service.dart';

/// In-memory inbox. [unreadFails] makes the badge fall back to the Home aggregate, which is what
/// the older tests expect.
class FakeNotificationRepository implements NotificationRepository {
  FakeNotificationRepository([List<AppNotification>? items])
    : items = items ?? [];

  List<AppNotification> items;
  Object? listFails;
  Object? markFails;
  Object? markAllFails;
  var unreadFails = true;
  Completer<void>? gate;
  Completer<void>? markGate;

  int listCalls = 0;
  int unreadCalls = 0;
  int markReadCalls = 0;
  int markAllCalls = 0;
  final readIds = <String>[];
  final registered = <({String token, String platform})>[];
  Object? registerFails;

  @override
  Future<NotificationPage> list({
    bool unreadOnly = false,
    String? cursor,
  }) async {
    listCalls++;
    await gate?.future;
    final f = listFails;
    if (f != null) throw f;
    return NotificationPage([
      for (final n in items)
        if (!unreadOnly || !n.isRead) n,
    ], null);
  }

  @override
  Future<void> markRead(String id) async {
    markReadCalls++;
    readIds.add(id);
    await markGate?.future;
    final f = markFails;
    if (f != null) throw f;
    items = [
      for (final n in items)
        n.id == id ? n.markedRead(DateTime(2026, 10, 9, 12)) : n,
    ];
  }

  final unreadIds = <String>[];

  @override
  Future<void> markUnread(String id) async {
    unreadIds.add(id);
    final f = markFails;
    if (f != null) throw f;
    items = [for (final n in items) n.id == id ? n.markedUnread() : n];
  }

  @override
  Future<void> markAllRead() async {
    markAllCalls++;
    final f = markAllFails;
    if (f != null) throw f;
    items = [for (final n in items) n.markedRead(DateTime(2026, 10, 9, 12))];
  }

  @override
  Future<int> unreadCount() async {
    unreadCalls++;
    if (unreadFails) throw const UnknownFailure();
    return items.where((n) => !n.isRead).length;
  }

  @override
  Future<void> registerDeviceToken({
    required String token,
    required String platform,
  }) async {
    final f = registerFails;
    if (f != null) throw f;
    registered.add((token: token, platform: platform));
  }

  int unregisterCalls = 0;

  @override
  Future<void> unregisterDeviceToken() async => unregisterCalls++;
}

AppNotification notif(
  String id, {
  String? title,
  String body = 'Body',
  String? type,
  String? entity,
  bool read = false,
  DateTime? at,
}) => AppNotification(
  id: id,
  event: 'EVENT',
  title: title ?? 'Title $id',
  body: body,
  target: type == null ? null : NotificationTarget(type, entity ?? 'e_$id'),
  readAt: read ? DateTime(2026, 10, 9, 9) : null,
  createdAt: at ?? DateTime(2026, 10, 9, 8),
);

/// Controllable push provider.
class FakePushService implements PushService {
  FakePushService({
    this.state = PushPermission.notDetermined,
    this.tokenValue = 'tok-1',
    this.allowResult = PushPermission.granted,
  });

  PushPermission state;
  String? tokenValue;

  /// What the OS dialog answers.
  PushPermission allowResult;
  PushMessage? initial;

  int startCalls = 0;
  int requestCalls = 0;
  int unregisterCalls = 0;
  int settingsCalls = 0;

  final foreground = StreamController<PushMessage>.broadcast();
  final opened = StreamController<PushMessage>.broadcast();
  final refresh = StreamController<String>.broadcast();

  @override
  Future<void> start() async => startCalls++;
  @override
  Future<PushPermission> permission() async => state;
  @override
  Future<PushPermission> requestPermission() async {
    requestCalls++;
    return state = allowResult;
  }

  @override
  Future<String?> token() async => tokenValue;
  @override
  Stream<String> get onTokenRefresh => refresh.stream;
  @override
  Stream<PushMessage> get onForeground => foreground.stream;
  @override
  Stream<PushMessage> get onOpened => opened.stream;
  @override
  Future<PushMessage?> initialMessage() async {
    final m = initial;
    initial = null;
    return m;
  }

  @override
  Future<void> unregister() async => unregisterCalls++;
  @override
  Future<void> openSettings() async => settingsCalls++;
  @override
  String get platform => 'ANDROID';
}
