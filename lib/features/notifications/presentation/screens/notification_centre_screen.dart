import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/localization/failure_message.dart';
import 'package:sevanest_customer/core/localization/time_format.dart';
import 'package:sevanest_customer/core/services/clock.dart';
import 'package:sevanest_customer/features/interview_trial/presentation/widgets/interview_detail_parts.dart'
    show OutlineAction;
import 'package:sevanest_customer/features/notifications/domain/notification.dart';
import 'package:sevanest_customer/features/notifications/domain/push_service.dart';
import 'package:sevanest_customer/features/notifications/presentation/providers/notification_providers.dart';
import 'package:sevanest_customer/features/notifications/presentation/providers/push_providers.dart';
import 'package:sevanest_customer/features/notifications/presentation/widgets/notification_parts.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_page.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_parts.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';
import 'package:sevanest_customer/shared/models/paged_state.dart';

/// `/notifications` (module doc 13.1, design: Find a Worker > Notifications): All / Unread,
/// newest first, grouped by day. Long-press a read card to mark it unread. NOT built, no backend
/// support: per-row "Delete" (BACKEND_REQUESTS 53).
class NotificationCentreScreen extends ConsumerStatefulWidget {
  const NotificationCentreScreen({super.key});

  @override
  ConsumerState<NotificationCentreScreen> createState() => _State();
}

class _State extends ConsumerState<NotificationCentreScreen>
    with WidgetsBindingObserver {
  var _unreadTab = false;
  var _markingAll = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refresh());
      unawaited(ref.read(pushPermissionProvider.notifier).refresh());
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(notificationUnreadProvider);
    await ref.read(notificationListProvider(_unreadTab).notifier).refresh();
  }

  Future<void> _markAll() async {
    if (_markingAll) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _markingAll = true);
    try {
      await markAllNotificationsRead(ref);
    } on Object catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(plainFailureMessage(l10n, e))));
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  Future<void> _markUnread(AppNotification n) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    try {
      await markNotificationUnread(ref, n);
      messenger.showSnackBar(SnackBar(content: Text(l10n.notifMarkedUnread)));
    } on Object catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(plainFailureMessage(l10n, e))),
      );
    }
  }

  void _open(AppNotification n) {
    unawaited(markNotificationRead(ref, n));
    final t = n.target;
    if (t == null) return;
    context.push(deepLinkLocation(routeForNotification(t.type, t.id)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // A push arrived, or the app came back: read the list again.
    ref.listen(notificationTickProvider, (_, _) => unawaited(_refresh()));
    final unread = ref.watch(notificationUnreadProvider).value ?? 0;
    final list = ref.watch(notificationListProvider(_unreadTab));
    final perm = ref.watch(pushPermissionProvider).value;
    return FindGlassPage(
      title: l10n.notifTitle,
      backLabel: l10n.back,
      onBack: () => context.canPop() ? context.pop() : context.go(Routes.home),
      trailing: GlassCircleButton(
        key: const Key('notif_settings_btn'),
        icon: Icons.tune_rounded,
        tooltip: l10n.notifSettingsTitle,
        onPressed: () => showNotificationSettings(context),
      ),
      headerBottom: NotificationTabs(
        unreadTab: _unreadTab,
        unread: unread,
        onChanged: (v) => setState(() => _unreadTab = v),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _body(l10n, list, perm, unread),
      ),
    );
  }

  Widget _body(
    AppLocalizations l10n,
    AsyncValue<PagedState<AppNotification>> list,
    PushPermission? perm,
    int unread,
  ) {
    final banners = <Widget>[
      if (list.hasValue && list.hasError && list.error is NetworkFailure)
        NotificationBanner(
          key: const Key('notif_offline_banner'),
          icon: Icons.wifi_off_rounded,
          title: l10n.notifOfflineBanner,
          actionLabel: l10n.retry,
          actionKey: const Key('notif_offline_retry_btn'),
          onAction: _refresh,
        ),
      if (perm == PushPermission.denied)
        NotificationBanner(
          key: const Key('notif_off_banner'),
          icon: Icons.notifications_off_outlined,
          title: l10n.notifOffTitle,
          body: l10n.notifOffBody,
          actionLabel: l10n.notifOpenSettings,
          actionKey: const Key('notif_open_settings_btn'),
          onAction: () => ref.read(pushServiceProvider).openSettings(),
        ),
    ];
    // A full-page state (error / empty) under any banners.
    Widget page(Widget state) => Column(
      children: [
        if (banners.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(children: banners),
          ),
        Expanded(child: state),
      ],
    );

    if (list.hasError && !list.hasValue) {
      return page(
        KeyedSubtree(
          key: const Key('notif_error'),
          child: GlassEmpty(
            icon: Icons.error_outline_rounded,
            iconColor: AppColors.danger,
            discColors: const [AppColors.rose100, AppColors.surface],
            title: l10n.notifErrTitle,
            body: l10n.notifErrBody,
            actionLabel: l10n.tkNewTryAgain,
            actionKey: const Key('error_retry_btn'),
            onAction: _refresh,
          ),
        ),
      );
    }
    if (!list.hasValue) return const NotificationSkeleton();
    final state = list.requireValue;
    final items = state.items;
    if (items.isEmpty) {
      return page(
        _unreadTab
            ? GlassEmpty(
                key: const Key('notif_unread_empty'),
                icon: Icons.check_circle_outline_rounded,
                iconColor: AppColors.teal,
                discColors: const [AppColors.pillActive, AppColors.surface],
                title: l10n.notifUnreadEmptyTitle,
                body: l10n.notifUnreadEmptyBody,
                actionLabel: l10n.notifViewAll,
                actionKey: const Key('notif_view_all_btn'),
                onAction: () => setState(() => _unreadTab = false),
              )
            : GlassEmpty(
                key: const Key('notif_empty'),
                icon: Icons.notifications_none_rounded,
                iconColor: AppColors.teal,
                discColors: const [AppColors.pillActive, AppColors.surface],
                title: l10n.notifEmptyTitle,
                body: l10n.notifEmptyBody,
                actionLabel: l10n.backToHome,
                actionKey: const Key('notif_home_btn'),
                onAction: () => context.go(Routes.home),
              ),
      );
    }
    final now = ref.read(nowProvider)();
    final children = <Widget>[
      ...banners,
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 6, 0, 0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                unread == 0
                    ? l10n.notifNoUnread
                    : l10n.notifUnreadCount(unread),
                style: AppText.body.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: dsText,
                ),
              ),
            ),
            MarkAllButton(
              onPressed: unread == 0 || _markingAll ? null : _markAll,
            ),
          ],
        ),
      ),
    ];
    DateTime? last;
    for (final n in items) {
      if (last == null || !sameDay(last, n.createdAt)) {
        children.add(NotificationDayHeader(dayHeader(l10n, n.createdAt, now)));
        last = n.createdAt;
      }
      children.add(
        NotificationCard(
          notification: n,
          now: now,
          onTap: () => _open(n),
          onLongPress: n.isRead ? () => _markUnread(n) : null,
        ),
      );
    }
    if (state.isLoadingMore) {
      children.add(
        const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    } else if (state.loadMoreError != null || state.hasMore) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: OutlineAction(
            key: const Key('notif_more_btn'),
            label: l10n.supLoadMore,
            onPressed: () => ref
                .read(notificationListProvider(_unreadTab).notifier)
                .loadMore(),
          ),
        ),
      );
    } else if (_unreadTab) {
      children.add(
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            key: const Key('notif_caught_up'),
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                size: 18,
                color: AppColors.teal,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.notifCaughtUp,
                style: AppText.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: dsText,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return ListView(
      key: const Key('notif_list'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
      children: [
        for (final (i, c) in children.indexed)
          DiscoverRise(delayMs: 40.0 * i.clamp(0, 8), child: c),
      ],
    );
  }
}
