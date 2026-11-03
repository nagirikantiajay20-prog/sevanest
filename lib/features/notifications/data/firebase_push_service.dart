import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sevanest_customer/features/notifications/domain/push_service.dart';

/// Background handler: top level, no UI work. FCM shows the system notification itself; the app
/// only needs to be able to start Firebase.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } on Object {
    // no Firebase config in this build
  }
}

PushMessage _fromRemote(RemoteMessage m) => PushMessage(
  id: m.messageId,
  title: m.notification?.title,
  body: m.notification?.body,
  data: Map<String, dynamic>.from(m.data),
);

/// FCM through `firebase_messaging`. When `Firebase.initializeApp()` fails (no config in a build)
/// this service stays inert and reports [PushPermission.unavailable], so the app builds and runs
/// without Firebase.
class FirebasePushService implements PushService {
  FirebasePushService();

  Future<bool>? _ready;
  final _foreground = StreamController<PushMessage>.broadcast();
  final _opened = StreamController<PushMessage>.broadcast();
  final _refresh = StreamController<String>.broadcast();

  Future<bool> _init() => _ready ??= () async {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      FirebaseMessaging.onMessage
          .map(_fromRemote)
          .listen(_foreground.add, onError: (Object _) {});
      FirebaseMessaging.onMessageOpenedApp
          .map(_fromRemote)
          .listen(_opened.add, onError: (Object _) {});
      FirebaseMessaging.instance.onTokenRefresh.listen(
        _refresh.add,
        onError: (Object _) {},
      );
      return true;
    } on Object {
      return false;
    }
  }();

  PushPermission _map(AuthorizationStatus s) => switch (s) {
    AuthorizationStatus.authorized ||
    AuthorizationStatus.provisional => PushPermission.granted,
    AuthorizationStatus.denied ||
    AuthorizationStatus.deniedPermanently => PushPermission.denied,
    AuthorizationStatus.notDetermined => PushPermission.notDetermined,
  };

  @override
  Future<void> start() async {
    await _init();
  }

  @override
  Future<PushPermission> permission() async {
    if (!await _init()) return PushPermission.unavailable;
    try {
      final s = await FirebaseMessaging.instance.getNotificationSettings();
      return _map(s.authorizationStatus);
    } on Object {
      return PushPermission.unavailable;
    }
  }

  @override
  Future<PushPermission> requestPermission() async {
    if (!await _init()) return PushPermission.unavailable;
    try {
      // iOS provisional authorisation is not used (docs/modules/13).
      final s = await FirebaseMessaging.instance.requestPermission();
      return _map(s.authorizationStatus);
    } on Object {
      return PushPermission.unavailable;
    }
  }

  @override
  Future<String?> token() async {
    if (!await _init()) return null;
    try {
      return await FirebaseMessaging.instance.getToken();
    } on Object {
      return null;
    }
  }

  @override
  Stream<String> get onTokenRefresh => _refresh.stream;
  @override
  Stream<PushMessage> get onForeground => _foreground.stream;
  @override
  Stream<PushMessage> get onOpened => _opened.stream;

  @override
  Future<PushMessage?> initialMessage() async {
    if (!await _init()) return null;
    try {
      final m = await FirebaseMessaging.instance.getInitialMessage();
      return m == null ? null : _fromRemote(m);
    } on Object {
      return null;
    }
  }

  @override
  Future<void> unregister() async {
    if (!await _init()) return;
    try {
      await FirebaseMessaging.instance.deleteToken();
    } on Object {
      // best effort
    }
  }

  @override
  Future<void> openSettings() async {
    await Geolocator.openAppSettings();
  }

  @override
  String get platform => Platform.isIOS ? 'IOS' : 'ANDROID';
}
