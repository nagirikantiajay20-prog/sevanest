import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/localization/failure_message.dart';
import 'package:sevanest_customer/core/localization/time_format.dart';
import 'package:sevanest_customer/core/services/clock.dart';
import 'package:sevanest_customer/core/widgets/sn_button.dart';
import 'package:sevanest_customer/features/notifications/domain/notification.dart';
import 'package:sevanest_customer/features/notifications/domain/push_service.dart';
import 'package:sevanest_customer/features/notifications/presentation/providers/notification_prefs.dart';
import 'package:sevanest_customer/features/notifications/presentation/providers/notification_providers.dart';
import 'package:sevanest_customer/features/notifications/presentation/providers/push_providers.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';
import 'package:sevanest_customer/shared/models/paged_state.dart';

IconData _iconFor(String? type) =>
    switch ((type ?? '').toLowerCase().replaceAll(RegExp(r'_update$'), '')) {
      'booking' => Icons.event_available_outlined,
      'interview' || 'trial' => Icons.event_available_outlined,
      'payment' || 'transaction' => Icons.credit_card_outlined,
      'replacement' || 'replacement_request' => Icons.autorenew,
      'ticket' || 'support' || 'support_ticket' => Icons.chat_bubble_outline,
      _ => Icons.notifications_none,
    };

/// `/notifications` (module doc 13.1, design screen 32): All / Unread, newest first, grouped by
/// day. NOT built, no backend support: the per-row "Mark as unread" /
/// "Delete" actions (BACKEND_REQUESTS 53).
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

  void _open(AppNotification n) {
    unawaited(markNotificationRead(ref, n));
    final t = n.target;
    if (t == null) return;
    context.push(deepLinkLocation(routeForNotification(t.type, t.id)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    // A push arrived, or the app came back: read the list again.
    ref.listen(notificationTickProvider, (_, _) => unawaited(_refresh()));
    final unread = ref.watch(notificationUnreadProvider).value ?? 0;
    final list = ref.watch(notificationListProvider(_unreadTab));
    final perm = ref.watch(pushPermissionProvider).value;
    return Scaffold(
      backgroundColor: AppColors.fieldBg,
      appBar: AppBar(
        leading: IconButton(
          key: const Key('app_back_btn'),
          tooltip: l10n.back,
          icon: const Icon(Icons.chevron_left, size: 32),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(Routes.home),
        ),
        title: Text(
          l10n.notifTitle,
          style: text.headlineSmall?.copyWith(
            color: AppColors.navy,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            key: const Key('notif_settings_btn'),
            tooltip: l10n.notifSettingsTitle,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              builder: (_) => const _SettingsSheet(),
            ),
          ),
          TextButton(
            key: const Key('notif_mark_all_btn'),
            onPressed: unread == 0 || _markingAll ? null : _markAll,
            child: Text(l10n.notifMarkAll),
          ),
        ],
      ),
      body: Column(
        children: [
          Material(
            color: AppColors.surface,
            child: Row(
              children: [
                _Tab(
                  key: const Key('notif_tab_all'),
                  label: l10n.notifTabAll,
                  selected: !_unreadTab,
                  onTap: () => setState(() => _unreadTab = false),
                ),
                _Tab(
                  key: const Key('notif_tab_unread'),
                  label: l10n.notifTabUnread,
                  count: unread,
                  selected: _unreadTab,
                  onTap: () => setState(() => _unreadTab = true),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: _body(l10n, text, list, perm),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(
    AppLocalizations l10n,
    TextTheme text,
    AsyncValue<PagedState<AppNotification>> list,
    PushPermission? perm,
  ) {
    final off = perm == PushPermission.denied;
    final offBanner = off
        ? Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _OffBanner(
              onOpen: () => ref.read(pushServiceProvider).openSettings(),
            ),
          )
        : null;
    if (list.hasError && !list.hasValue) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          ?offBanner,
          Card(
            key: const Key('notif_error'),
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 32,
                    backgroundColor: Color(0xFFFEE2E2),
                    child: Icon(
                      Icons.error_outline,
                      size: 32,
                      color: AppColors.danger,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.notifErrTitle,
                    style: text.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(l10n.notifErrBody, style: text.bodyMedium),
                  const SizedBox(height: AppSpacing.md),
                  SnButton(
                    key: const Key('error_retry_btn'),
                    label: l10n.tkNewTryAgain,
                    variant: SnButtonVariant.secondary,
                    onPressed: _refresh,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
    if (!list.hasValue) {
      return Semantics(
        label: l10n.loading,
        child: ListView.separated(
          key: const Key('notif_loading'),
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: 5,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (_, _) => DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.hairline),
            ),
            child: const SizedBox(height: 100),
          ),
        ),
      );
    }
    final state = list.requireValue;
    final items = state.items;
    final stale = list.hasError && list.error is NetworkFailure;
    final now = ref.read(nowProvider)();
    final children = <Widget>[
      if (stale)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: _OfflineBanner(onRetry: _refresh),
        ),
      ?offBanner,
    ];
    if (items.isEmpty) {
      children.add(
        _unreadTab
            ? _Empty(
                key: const Key('notif_unread_empty'),
                title: l10n.notifUnreadEmptyTitle,
                body: l10n.notifUnreadEmptyBody,
                icon: Icons.check_circle_outline,
                action: TextButton(
                  key: const Key('notif_view_all_btn'),
                  onPressed: () => setState(() => _unreadTab = false),
                  child: Text(l10n.notifViewAll),
                ),
              )
            : _Empty(
                key: const Key('notif_empty'),
                title: l10n.notifEmptyTitle,
                body: l10n.notifEmptyBody,
                icon: Icons.notifications_none,
              ),
      );
    } else {
      DateTime? last;
      for (final n in items) {
        if (last == null || !sameDay(last, n.createdAt)) {
          children.add(
            Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.sm,
                bottom: AppSpacing.sm,
              ),
              child: Text(
                dayHeader(l10n, n.createdAt, now),
                style: text.titleMedium?.copyWith(color: AppColors.navy),
              ),
            ),
          );
          last = n.createdAt;
        }
        children.add(_Row(notification: n, now: now, onTap: () => _open(n)));
      }
      if (state.isLoadingMore) {
        children.add(
          const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      } else if (state.loadMoreError != null || state.hasMore) {
        children.add(
          SnButton(
            key: const Key('notif_more_btn'),
            label: l10n.supLoadMore,
            variant: SnButtonVariant.secondary,
            onPressed: () => ref
                .read(notificationListProvider(_unreadTab).notifier)
                .loadMore(),
          ),
        );
      } else if (_unreadTab) {
        children.add(
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              key: const Key('notif_caught_up'),
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 18,
                  color: AppColors.success,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(l10n.notifCaughtUp),
              ],
            ),
          ),
        );
      }
    }
    return ListView(
      key: const Key('notif_list'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.md),
      children: children,
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
    super.key,
  });
  final String label;
  final bool selected;
  final int? count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.teal : AppColors.ink;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: kMinTapTarget),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? AppColors.teal : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (count != null && count! > 0) ...[
              const SizedBox(width: AppSpacing.sm),
              Container(
                key: const Key('notif_unread_count'),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.teal),
                ),
                child: Text('$count', style: const TextStyle(fontSize: 12)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.notification,
    required this.now,
    required this.onTap,
  });
  final AppNotification notification;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final n = notification;
    final unread = !n.isRead;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: unread ? const Color(0xFFF0FDFA) : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(
            color: unread ? const Color(0xFFB7E4DC) : AppColors.hairline,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('notification_row_${n.id}'),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: unread ? AppColors.teal : Colors.transparent,
                  width: 4,
                ),
              ),
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: unread
                      ? Colors.white
                      : const Color(0xFFE6F7F4),
                  child: Icon(_iconFor(n.target?.type), color: AppColors.teal),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        n.title ?? l10n.notifFallbackTitle,
                        style: text.titleMedium?.copyWith(
                          fontWeight: unread
                              ? FontWeight.w800
                              : FontWeight.w500,
                        ),
                      ),
                      if (n.body.isNotEmpty)
                        Text(
                          n.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodyMedium,
                        ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Text(
                            timeAgo(l10n, n.createdAt, now),
                            style: text.bodySmall,
                          ),
                          if (unread) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Container(
                              key: Key('notification_new_${n.id}'),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.lg,
                                ),
                                border: Border.all(color: AppColors.teal),
                              ),
                              child: Text(
                                l10n.notifNew,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (unread)
                  Container(
                    key: Key('notification_dot_${n.id}'),
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.amber,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({
    required this.title,
    required this.body,
    required this.icon,
    this.action,
    super.key,
  });
  final String title;
  final String body;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: const Color(0xFFDCFCE7),
              child: Icon(icon, size: 32, color: AppColors.success),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: text.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xs),
            Text(body, style: text.bodyMedium, textAlign: TextAlign.center),
            ?action,
          ],
        ),
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      key: const Key('notif_offline_banner'),
      decoration: BoxDecoration(
        color: AppColors.warnBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            const Icon(Icons.wifi_off, color: AppColors.warn),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(l10n.notifOfflineBanner)),
            TextButton(
              key: const Key('notif_offline_retry_btn'),
              onPressed: onRetry,
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown on the centre and Account when the OS permission is denied.
class _OffBanner extends StatelessWidget {
  const _OffBanner({required this.onOpen});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return DecoratedBox(
      key: const Key('notif_off_banner'),
      decoration: BoxDecoration(
        color: AppColors.warnBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.notifications_off_outlined, color: AppColors.warn),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.notifOffTitle, style: text.titleMedium),
                  Text(l10n.notifOffBody, style: text.bodyMedium),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton(
                    key: const Key('notif_open_settings_btn'),
                    onPressed: onOpen,
                    child: Text(l10n.notifOpenSettings),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Per-category switches for the in-app alerts (see [notificationCategories]).
class _SettingsSheet extends ConsumerWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final muted = ref.watch(mutedCategoriesProvider).value ?? const {};
    final labels = {
      'bookings': l10n.notifCatBookings,
      'payments': l10n.notifCatPayments,
      'replacements': l10n.notifCatReplacements,
      'support': l10n.notifCatSupport,
    };
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              l10n.notifSettingsTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(l10n.notifSettingsBody),
          ),
          for (final c in notificationCategories)
            SwitchListTile(
              key: Key('notif_pref_$c'),
              title: Text(labels[c]!),
              value: !muted.contains(c),
              onChanged: (v) => ref
                  .read(mutedCategoriesProvider.notifier)
                  .setEnabled(c, enabled: v),
            ),
        ],
      ),
    );
  }
}
