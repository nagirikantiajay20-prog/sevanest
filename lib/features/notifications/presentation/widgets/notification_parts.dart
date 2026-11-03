import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/core/localization/time_format.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart'
    show authSerif;
import 'package:sevanest_customer/features/notifications/domain/notification.dart';
import 'package:sevanest_customer/features/notifications/presentation/providers/notification_prefs.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_parts.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// Building blocks of the notification centre (design: Find a Worker > Notifications).

/// Icon, tile tint and stroke colour of a notification by its route type.
(IconData, Color, Color) notificationStyle(String? type) =>
    switch ((type ?? '').toLowerCase().replaceAll(RegExp(r'_update$'), '')) {
      'interview' || 'trial' => (
        Icons.event_available_rounded,
        const Color(0xFFD6EFEA),
        AppColors.teal,
      ),
      'booking' => (
        Icons.calendar_month_outlined,
        const Color(0xFFDBEAFE),
        const Color(0xFF1E40AF),
      ),
      'payment' || 'transaction' => (
        Icons.account_balance_wallet_outlined,
        const Color(0xFFFEF3C7),
        const Color(0xFF8A4B06),
      ),
      'replacement' || 'replacement_request' => (
        Icons.swap_horiz_rounded,
        const Color(0xFFFFE4E6),
        const Color(0xFF9F1239),
      ),
      'ticket' || 'support' || 'support_ticket' => (
        Icons.chat_bubble_outline_rounded,
        const Color(0xFFD6EFEA),
        AppColors.teal,
      ),
      _ => (Icons.notifications_none_rounded, const Color(0xFFE2E8F0), dsText),
    };

/// "TODAY" / "YESTERDAY" / date over a group of cards.
class NotificationDayHeader extends StatelessWidget {
  const NotificationDayHeader(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 20, 4, 0),
    child: Semantics(
      header: true,
      child: Text(
        label.toUpperCase(),
        style: AppText.body.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: dsMuted,
        ),
      ),
    ),
  );
}

/// One notification: tinted icon tile, title, body, time and the rose unread dot.
class NotificationCard extends StatelessWidget {
  const NotificationCard({
    required this.notification,
    required this.now,
    required this.onTap,
    this.onLongPress,
    super.key,
  });
  final AppNotification notification;
  final DateTime now;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final n = notification;
    final unread = !n.isRead;
    final (icon, tint, stroke) = notificationStyle(n.target?.type);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: DiscoverGlass(
        radius: 22,
        borderColor: unread
            ? AppColors.teal.withValues(alpha: 0.35)
            : const Color(0xEBFFFFFF),
        gradient: LinearGradient(
          begin: const Alignment(-0.6, -1),
          end: const Alignment(0.6, 1),
          colors: unread
              ? const [Color(0xF2FFFFFF), Color(0xD9ECF8F6)]
              : const [Color(0xB3FFFFFF), Color(0x61FFFFFF)],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            key: Key('notification_row_${n.id}'),
            borderRadius: BorderRadius.circular(22),
            onTap: onTap,
            onLongPress: onLongPress,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: tint,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, size: 22, color: stroke),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          n.title ?? l10n.notifFallbackTitle,
                          style: AppText.body.copyWith(
                            fontSize: 15.5,
                            height: 1.3,
                            fontWeight: FontWeight.w800,
                            color: dsNavy,
                          ),
                        ),
                        if (n.body.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              n.body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.body.copyWith(
                                fontSize: 14,
                                height: 1.4,
                                color: dsText,
                              ),
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          timeAgo(l10n, n.createdAt, now),
                          style: AppText.body.copyWith(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: dsMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (unread)
                    Semantics(
                      label: l10n.notifTabUnread,
                      child: Container(
                        key: Key('notification_dot_${n.id}'),
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(top: 6, left: 4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE11D48),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Teal "Mark all read" pill; faded while nothing is unread.
class MarkAllButton extends StatelessWidget {
  const MarkAllButton({required this.onPressed, super.key});
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: onPressed == null ? 0.45 : 1,
    child: TextButton(
      key: const Key('notif_mark_all_btn'),
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        backgroundColor: AppColors.teal.withValues(alpha: 0.12),
        foregroundColor: const Color(0xFF0B5A53),
        disabledForegroundColor: const Color(0xFF0B5A53),
        shape: const StadiumBorder(),
        textStyle: AppText.body.copyWith(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
        ),
      ),
      child: Text(AppLocalizations.of(context).notifMarkAll),
    ),
  );
}

/// All / Unread switch under the title; Unread carries the count.
class NotificationTabs extends StatelessWidget {
  const NotificationTabs({
    required this.unreadTab,
    required this.unread,
    required this.onChanged,
    super.key,
  });
  final bool unreadTab;
  final int unread;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 0),
      child: Row(
        children: [
          _TabPill(
            key: const Key('notif_tab_all'),
            label: l10n.notifTabAll,
            selected: !unreadTab,
            onTap: () => onChanged(false),
          ),
          const SizedBox(width: 8),
          _TabPill(
            key: const Key('notif_tab_unread'),
            label: l10n.notifTabUnread,
            count: unread,
            selected: unreadTab,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.count = 0,
    super.key,
  });
  final String label;
  final bool selected;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : dsNavy;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? dsNavy : const Color(0xB3FFFFFF),
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? dsNavy : dsNavy.withValues(alpha: 0.14),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 40),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppText.body.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
                if (count > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    key: const Key('notif_unread_count'),
                    constraints: const BoxConstraints(minWidth: 20),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE11D48),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$count',
                      style: AppText.body.copyWith(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Five frosted placeholders while the first page loads.
class NotificationSkeleton extends StatelessWidget {
  const NotificationSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    label: AppLocalizations.of(context).loading,
    child: ListView.builder(
      key: const Key('notif_loading'),
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      itemCount: 5,
      itemBuilder: (_, _) => const Padding(
        padding: EdgeInsets.only(top: 10),
        child: DiscoverGlass(radius: 22, child: SizedBox(height: 84)),
      ),
    ),
  );
}

/// Amber strip over the list: offline (with Retry) or push permission off (with Open settings).
class NotificationBanner extends StatelessWidget {
  const NotificationBanner({
    required this.icon,
    required this.title,
    required this.actionLabel,
    required this.actionKey,
    required this.onAction,
    this.body,
    super.key,
  });
  final IconData icon;
  final String title;
  final String? body;
  final String actionLabel;
  final Key actionKey;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.warnBg.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.warnLine),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.warn),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppText.body.copyWith(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: dsNavy,
                    ),
                  ),
                  if (body != null)
                    Text(
                      body!,
                      style: AppText.body.copyWith(
                        fontSize: 13.5,
                        color: dsText,
                      ),
                    ),
                ],
              ),
            ),
            TextButton(
              key: actionKey,
              onPressed: onAction,
              style: TextButton.styleFrom(foregroundColor: AppColors.teal),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Per-category switches for the in-app alerts (see [notificationCategories]).
void showNotificationSettings(BuildContext context) =>
    showGlassSheet<void>(context, builder: (_) => const _SettingsSheet());

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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.notifSettingsTitle, style: authSerif(22, 1.2)),
        const SizedBox(height: 8),
        Text(
          l10n.notifSettingsBody,
          style: AppText.body.copyWith(fontSize: 14.5, color: dsText),
        ),
        for (final c in notificationCategories)
          SwitchListTile(
            key: Key('notif_pref_$c'),
            contentPadding: EdgeInsets.zero,
            title: Text(
              labels[c]!,
              style: AppText.body.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: dsNavy,
              ),
            ),
            value: !muted.contains(c),
            onChanged: (v) => ref
                .read(mutedCategoriesProvider.notifier)
                .setEnabled(c, enabled: v),
          ),
      ],
    );
  }
}
