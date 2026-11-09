import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/app/router/app_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/core/session/auth_state.dart';
import 'package:sevanest_customer/features/booking/presentation/providers/booking_providers.dart';
import 'package:sevanest_customer/features/home/presentation/providers/home_providers.dart';
import 'package:sevanest_customer/features/interview_trial/presentation/providers/interview_providers.dart';
import 'package:sevanest_customer/features/notifications/domain/notification.dart';
import 'package:sevanest_customer/features/notifications/domain/push_service.dart';
import 'package:sevanest_customer/features/notifications/presentation/providers/notification_prefs.dart';
import 'package:sevanest_customer/features/notifications/presentation/providers/notification_providers.dart';
import 'package:sevanest_customer/features/notifications/presentation/providers/push_providers.dart';
import 'package:sevanest_customer/features/notifications/presentation/push_prompt.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// Push plumbing above the router (docs/modules/13):
///  * starts the push service (no permission dialog) and binds the token once signed in;
///  * foreground message -> an in-app banner and fresh unread count, never an automatic jump;
///  * tap from the background or a cold start -> the deep link, after sign-in if need be.
/// A payload is a hint only: `/open` reads the entity fresh before the real screen opens.
class PushHost extends ConsumerStatefulWidget {
  const PushHost({required this.child, super.key});
  final Widget child;

  @override
  ConsumerState<PushHost> createState() => _State();
}

class _State extends ConsumerState<PushHost> with WidgetsBindingObserver {
  final _subs = <StreamSubscription<Object?>>[];
  String? _pending;
  var _asked = false;
  final _acked = <String>{};
  PushMessage? _banner;
  var _bannerSeq = 0;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_start()));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bannerTimer?.cancel();
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    super.dispose();
  }

  Future<void> _start() async {
    final service = ref.read(pushServiceProvider);
    unawaited(
      ref.read(mutedCategoriesProvider.future),
    ); // warm, so the banner check is sync
    await service.start();
    if (!mounted) return;
    _subs
      ..add(service.onForeground.listen(_onForeground))
      ..add(
        service.onOpened.listen((m) {
          _ack(m, 'TAPPED');
          _request(routeForPushData(m.data));
        }),
      )
      ..add(
        ref.read(pushDisplayProvider).onTap.listen((m) {
          _ack(m, 'TAPPED');
          _request(routeForPushData(m.data));
        }),
      )
      ..add(
        service.onTokenRefresh.listen(
          (t) =>
              unawaited(ref.read(pushControllerProvider).registerIfAllowed(t)),
        ),
      );
    final first = await service.initialMessage();
    if (first != null) {
      _ack(first, 'TAPPED');
      _request(routeForPushData(first.data));
    }
    if (ref.read(authProvider) == AuthStatus.authenticated) {
      unawaited(ref.read(pushControllerProvider).registerIfAllowed());
      _askOnce();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (ref.read(authProvider) != AuthStatus.authenticated) return;
    ref.invalidate(notificationUnreadProvider);
    _refreshBookings();
    // The customer may have changed the permission in the system settings.
    unawaited(ref.read(pushPermissionProvider.notifier).refresh());
    unawaited(ref.read(pushControllerProvider).registerIfAllowed());
  }

  /// A push means a booking or interview probably changed: lists and Home read again, so the
  /// status is right without a restart (open detail screens listen to the tick instead).
  void _refreshBookings() => ref
    ..invalidate(bookingListProvider)
    ..invalidate(interviewListProvider)
    ..invalidate(homeProvider);

  /// Delivery telemetry for a push that carries `notificationId`; never blocks or throws.
  void _ack(PushMessage m, String status) {
    final id = m.data['notificationId'];
    if (id is! String || id.isEmpty) return;
    if (!_acked.add('$id:$status')) return; // one event per notification
    unawaited(
      ref
          .read(notificationRepositoryProvider)
          .ack(id, status)
          .catchError((_) {}),
    );
  }

  Future<void> _onForeground(PushMessage m) async {
    if (ref.read(authProvider) != AuthStatus.authenticated || !mounted) return;
    _refreshBookings();
    _ack(m, 'RECEIVED');
    ref
      ..invalidate(notificationUnreadProvider)
      ..invalidate(notificationListProvider(false))
      ..invalidate(notificationListProvider(true));
    // Screens showing a ticket, booking or replacement read it again.
    ref.read(notificationTickProvider.notifier).bump();
    final muted = ref.read(mutedCategoriesProvider).value ?? const <String>{};
    if (!bannerAllowed(muted, routeForPushData(m.data))) return;
    // System heads-up first; DISPLAYED only once the OS took it. The in-app banner is the fallback.
    if (await ref.read(pushDisplayProvider).show(m)) {
      _ack(m, 'DISPLAYED');
      return;
    }
    if (!mounted) return;
    _bannerTimer?.cancel();
    setState(() {
      _banner = m;
      _bannerSeq++;
    });
    _bannerTimer = Timer(const Duration(seconds: 6), _hideBanner);
  }

  void _hideBanner() {
    _bannerTimer?.cancel();
    if (mounted && _banner != null) setState(() => _banner = null);
  }

  /// A target to open: now if the customer is signed in with a complete profile, otherwise as soon
  /// as they are (the sign-in comes first, then the target).
  void _request(String route) {
    _pending = route;
    _flush();
  }

  bool get _ready =>
      ref.read(authProvider) == AuthStatus.authenticated &&
      ref.read(profileCompleteProvider) == true;

  /// Once per sign-in, when the customer reaches Home: the permission pre-prompt (the same one the
  /// interview request offers; it stays silent if already decided or deferred).
  void _askOnce() {
    if (_asked || _pending != null || !_ready) return;
    _asked = true;
    WidgetsBinding.instance
      ..addPostFrameCallback((_) {
        final c = ref
            .read(appRouterProvider)
            .routerDelegate
            .navigatorKey
            .currentState
            ?.overlay
            ?.context;
        if (mounted && c != null && c.mounted) {
          unawaited(askForPushAfterAction(ref.read(pushControllerProvider)));
        }
      })
      ..scheduleFrame();
  }

  void _flush() {
    final route = _pending;
    if (route == null || !_ready) return;
    _pending = null;
    // After the frame that settles any redirect (sign-in -> Home). A post-frame callback does not
    // schedule a frame by itself, so ask for one.
    WidgetsBinding.instance
      ..addPostFrameCallback((_) {
        if (mounted) _navigate(route);
      })
      ..scheduleFrame();
  }

  void _navigate(String route) {
    final router = ref.read(appRouterProvider);
    final here = router.routerDelegate.currentConfiguration.uri.path;
    const shell = {
      Routes.home,
      Routes.bookings,
      Routes.favourites,
      Routes.account,
    };
    // A cold start has nothing under the target: Back goes Home, not out of the app.
    if (!shell.contains(here)) router.go(Routes.home);
    unawaited(router.push<Object?>(deepLinkLocation(route)));
  }

  @override
  Widget build(BuildContext context) {
    ref
      ..listen(authProvider, (prev, next) {
        if (next == AuthStatus.authenticated) {
          unawaited(ref.read(pushControllerProvider).registerIfAllowed());
          _flush();
          _askOnce();
        } else {
          _asked = false;
          ref.read(pushControllerProvider).forget();
          _hideBanner();
        }
      })
      ..listen(profileCompleteProvider, (_, _) {
        _flush();
        _askOnce();
      });
    final banner = _banner;
    return Stack(
      children: [
        widget.child,
        if (banner != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: _Banner(
                  key: Key('notif_banner_$_bannerSeq'),
                  message: banner,
                  onTap: () {
                    _hideBanner();
                    _ack(banner, 'TAPPED');
                    _request(routeForPushData(banner.data));
                  },
                  onClose: _hideBanner,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.message,
    required this.onTap,
    required this.onClose,
    super.key,
  });
  final PushMessage message;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Material(
      color: AppColors.surface,
      elevation: 6,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Semantics(
          button: true,
          label: l10n.notifBannerOpen,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.tealSoft,
                  child: Icon(
                    Icons.notifications_outlined,
                    color: AppColors.teal,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.title ?? l10n.notifFallbackTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleMedium,
                      ),
                      if (message.body != null)
                        Text(
                          message.body!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodyMedium,
                        ),
                    ],
                  ),
                ),
                IconButton(
                  key: const Key('notif_banner_close_btn'),
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
