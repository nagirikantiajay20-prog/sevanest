import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/core/services/clock.dart';
import 'package:sevanest_customer/core/session/auth_state.dart';
import 'package:sevanest_customer/features/notifications/data/firebase_push_service.dart';
import 'package:sevanest_customer/features/notifications/data/local_push_display.dart';
import 'package:sevanest_customer/features/notifications/domain/push_service.dart';
import 'package:sevanest_customer/features/notifications/presentation/providers/notification_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// FCM in stg / prod (and in dev when switched on); nothing in dev mock mode. A build without
/// Firebase config files falls back to a no-op inside [FirebasePushService].
final pushServiceProvider = Provider<PushService>(
  (ref) => ref.watch(mockApiProvider.select((s) => s.live))
      ? FirebasePushService()
      : const NoopPushService(),
);

/// System heads-up for foreground pushes (FCM draws none itself). Nothing in dev mock mode.
final pushDisplayProvider = Provider<PushDisplay>(
  (ref) => ref.watch(mockApiProvider.select((s) => s.live))
      ? LocalPushDisplay()
      : const NoopPushDisplay(),
);

/// Days to wait before the pre-prompt is offered again after "Not now" (docs/modules/13: "ask
/// again after N days/config").
final pushReaskDaysProvider = Provider<int>((ref) => 3);

/// When "Not now" was last chosen. Only a time is stored, never a token.
class PushPromptStore {
  static const _key = 'push_prompt_later_until';

  Future<DateTime?> laterUntil() async {
    final ms = (await SharedPreferences.getInstance()).getInt(_key);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> setLaterUntil(DateTime t) async =>
      (await SharedPreferences.getInstance()).setInt(
        _key,
        t.millisecondsSinceEpoch,
      );
}

final pushPromptStoreProvider = Provider<PushPromptStore>(
  (ref) => PushPromptStore(),
);

/// What the OS permission is now; the Account row and the centre banner read it.
class PushPermissionNotifier extends AsyncNotifier<PushPermission> {
  @override
  Future<PushPermission> build() => ref.read(pushServiceProvider).permission();

  Future<void> refresh() async {
    state = AsyncData(await ref.read(pushServiceProvider).permission());
  }
}

final pushPermissionProvider =
    AsyncNotifierProvider<PushPermissionNotifier, PushPermission>(
      PushPermissionNotifier.new,
    );

/// Token lifecycle (docs/modules/13): register after sign-in once permission is granted, again
/// when FCM rotates the token, drop it on logout. A failed write is not retried in a loop: the
/// next sign-in, resume or token refresh tries again.
class PushController {
  PushController(this._ref);
  final Ref _ref;

  String? _registered;

  /// Writes run one after the other, so sign-in and the first launch cannot bind the same token
  /// twice.
  Future<void> _queue = Future<void>.value();

  PushService get _service => _ref.read(pushServiceProvider);

  /// `PUT /auth/device-token` when signed in, permission is granted and the token is new.
  Future<void> registerIfAllowed([String? fresh]) {
    final run = _queue.then((_) => _register(fresh));
    _queue = run;
    return run;
  }

  Future<void> _register(String? fresh) async {
    if (_ref.read(authProvider) != AuthStatus.authenticated) return;
    try {
      if (await _service.permission() != PushPermission.granted) return;
      final token = fresh ?? await _service.token();
      if (token == null || token.isEmpty || token == _registered) return;
      await _ref
          .read(notificationRepositoryProvider)
          .registerDeviceToken(token: token, platform: _service.platform);
      _registered = token;
    } on Object {
      // best effort; tried again on the next sign-in, resume or refresh
    }
  }

  /// A new session needs the token bound again.
  void forget() => _registered = null;

  /// Logout: drop the device token before the session is cleared (best effort).
  Future<void> unregister() async {
    forget();
    try {
      await _ref.read(notificationRepositoryProvider).unregisterDeviceToken();
    } on Object {
      // best effort: the server drops a dead token on its own
    }
    try {
      await _service.unregister();
    } on Object {
      // the local session is cleared regardless
    }
  }

  /// True when the pre-prompt should be shown now: permission not asked yet and "Not now" was
  /// not chosen within the re-ask window.
  Future<bool> shouldAsk() async {
    if (await _service.permission() != PushPermission.notDetermined) {
      return false;
    }
    final until = await _ref.read(pushPromptStoreProvider).laterUntil();
    return until == null || !_ref.read(nowProvider)().isBefore(until);
  }

  Future<void> defer() => _ref
      .read(pushPromptStoreProvider)
      .setLaterUntil(
        _ref
            .read(nowProvider)()
            .add(Duration(days: _ref.read(pushReaskDaysProvider))),
      );

  /// The pre-prompt's Allow: the OS dialog, then bind the token if it was granted.
  Future<PushPermission> allow() async {
    final result = await _service.requestPermission();
    if (result == PushPermission.granted) await registerIfAllowed();
    _ref.invalidate(pushPermissionProvider);
    return result;
  }
}

final pushControllerProvider = Provider<PushController>(PushController.new);
