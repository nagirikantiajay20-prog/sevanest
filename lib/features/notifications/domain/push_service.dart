/// OS notification permission as the app needs to know it.
enum PushPermission {
  /// No push provider is configured in this build (no Firebase files): nothing can be asked.
  unavailable,
  notDetermined,
  granted,
  denied,
}

/// A push message as the app sees it; `data` is the payload (a hint only: the screen it opens
/// reads the entity fresh).
class PushMessage {
  const PushMessage({this.id, this.title, this.body, this.data = const {}});
  final String? id;
  final String? title;
  final String? body;
  final Map<String, dynamic> data;
}

/// Everything the app needs from FCM, behind one interface so tests use a fake and a build without
/// Firebase config runs with [NoopPushService]. Nothing here logs a token or a message body.
abstract interface class PushService {
  /// Prepares the provider and the message streams. Never asks for permission.
  Future<void> start();

  Future<PushPermission> permission();

  /// Shows the OS permission dialog (only the pre-prompt's Allow calls this).
  Future<PushPermission> requestPermission();

  /// The FCM registration token, or null when there is none.
  Future<String?> token();

  Stream<String> get onTokenRefresh;

  /// A message that arrived while the app is in the foreground (no automatic navigation).
  Stream<PushMessage> get onForeground;

  /// The customer tapped a notification while the app was in the background.
  Stream<PushMessage> get onOpened;

  /// The notification that launched the app from a terminated state, once.
  Future<PushMessage?> initialMessage();

  /// Drops the device token (logout), so the server cannot reach this device with the old one.
  Future<void> unregister();

  /// Opens the app's page in the system settings.
  Future<void> openSettings();

  /// `ANDROID` or `IOS` (`RegisterDeviceTokenDto.platform`).
  String get platform;
}

/// Used when Firebase is not configured (no `google-services.json` / `GoogleService-Info.plist`)
/// and in dev mock mode. The app runs normally; there are just no pushes.
class NoopPushService implements PushService {
  const NoopPushService();

  @override
  Future<void> start() async {}
  @override
  Future<PushPermission> permission() async => PushPermission.unavailable;
  @override
  Future<PushPermission> requestPermission() async =>
      PushPermission.unavailable;
  @override
  Future<String?> token() async => null;
  @override
  Stream<String> get onTokenRefresh => const Stream.empty();
  @override
  Stream<PushMessage> get onForeground => const Stream.empty();
  @override
  Stream<PushMessage> get onOpened => const Stream.empty();
  @override
  Future<PushMessage?> initialMessage() async => null;
  @override
  Future<void> unregister() async {}
  @override
  Future<void> openSettings() async {}
  @override
  String get platform => 'ANDROID';
}
