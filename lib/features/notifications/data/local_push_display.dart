import 'dart:async';
import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sevanest_customer/features/notifications/domain/push_service.dart';

/// Foreground heads-up notification on the same channel the backend and the manifest use.
class LocalPushDisplay implements PushDisplay {
  final _plugin = FlutterLocalNotificationsPlugin();
  final _tap = StreamController<PushMessage>.broadcast();
  Future<bool>? _ready;
  var _seq = 0;

  Future<bool> _init() => _ready ??= () async {
    try {
      final ok = await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_stat_notification'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (r) {
          final p = r.payload;
          if (p == null) return;
          try {
            final j = jsonDecode(p) as Map<String, dynamic>;
            _tap.add(
              PushMessage(
                title: j['t'] as String?,
                body: j['b'] as String?,
                data: Map<String, dynamic>.from(j['d'] as Map),
              ),
            );
          } on Object {
            // unreadable payload: nothing to open
          }
        },
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              'sevanest_high_importance',
              'SevaNest alerts',
              importance: Importance.max,
            ),
          );
      return ok ?? false;
    } on Object {
      return false;
    }
  }();

  @override
  Future<bool> show(PushMessage m) async {
    if (!await _init()) return false;
    try {
      await _plugin.show(
        id: ++_seq,
        title: m.title,
        body: m.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'sevanest_high_importance',
            'SevaNest alerts',
            importance: Importance.max,
            priority: Priority.high,
            icon: 'ic_stat_notification',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode({'t': m.title, 'b': m.body, 'd': m.data}),
      );
      return true;
    } on Object {
      return false;
    }
  }

  @override
  Stream<PushMessage> get onTap => _tap.stream;
}
