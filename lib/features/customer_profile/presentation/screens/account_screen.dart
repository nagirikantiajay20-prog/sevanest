import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/core/widgets/labeled_field.dart';
import 'package:sevanest_customer/features/authentication/presentation/providers/auth_providers.dart';
import 'package:sevanest_customer/features/notifications/domain/push_service.dart';
import 'package:sevanest_customer/features/notifications/presentation/providers/push_providers.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// Entry points for modules 02 and 03 on the Account tab, plus Log out. Module 14 (account &
/// settings) extends this screen.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final yes = await confirmDialog(
      context,
      title: l10n.logoutConfirmTitle,
      body: l10n.logoutConfirmBody,
      confirmLabel: l10n.logout,
      cancelLabel: l10n.cancel,
      confirmKey: const Key('logout_confirm_btn'),
      destructive: true,
    );
    // Clearing the session makes the router redirect to /login.
    if (yes) await ref.read(logoutProvider)();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navAccount)),
      body: ListView(
        children: [
          ListTile(
            key: const Key('account_profile_tile'),
            leading: const Icon(Icons.person_outline),
            title: Text(l10n.profileTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.profile),
          ),
          ListTile(
            key: const Key('account_addresses_tile'),
            leading: const Icon(Icons.location_on_outlined),
            title: Text(l10n.addressesTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.addresses),
          ),
          ListTile(
            key: const Key('account_interviews_tile'),
            leading: const Icon(Icons.event_available_outlined),
            title: Text(l10n.accountInterviews),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.interviews),
          ),
          ListTile(
            key: const Key('account_transactions_tile'),
            leading: const Icon(Icons.receipt_long_outlined),
            title: Text(l10n.accountTransactions),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.transactions),
          ),
          ListTile(
            key: const Key('account_history_tile'),
            leading: const Icon(Icons.history),
            title: Text(l10n.accountHistory),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.serviceHistory),
          ),
          _NotificationsTile(),
          ListTile(
            key: const Key('account_support_tile'),
            leading: const Icon(Icons.headset_mic_outlined),
            title: Text(l10n.accountSupport),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.support),
          ),
          const Divider(),
          ListTile(
            key: const Key('account_logout_btn'),
            leading: const Icon(Icons.logout, color: AppColors.danger),
            title: Text(
              l10n.logout,
              style: const TextStyle(color: AppColors.danger),
            ),
            onTap: () => _logout(context, ref),
          ),
        ],
      ),
    );
  }
}

/// Notifications row: the centre, plus "Off" with a button to the system settings when the OS
/// permission was denied (docs/modules/13: the app works without it).
class _NotificationsTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final perm = ref.watch(pushPermissionProvider).value;
    final status = switch (perm) {
      PushPermission.granted => l10n.notifAccountOn,
      PushPermission.denied => l10n.notifAccountOff,
      PushPermission.notDetermined => l10n.notifAccountNotAsked,
      _ => null,
    };
    return ListTile(
      key: const Key('account_notifications_tile'),
      leading: Icon(
        perm == PushPermission.denied
            ? Icons.notifications_off_outlined
            : Icons.notifications_none,
      ),
      title: Text(l10n.notifAccountTitle),
      subtitle: status == null
          ? null
          : Text(status, key: const Key('account_notifications_status')),
      trailing: perm == PushPermission.denied
          ? OutlinedButton(
              key: const Key('notif_open_settings_btn'),
              onPressed: () => ref.read(pushServiceProvider).openSettings(),
              child: Text(l10n.notifOpenSettings),
            )
          : const Icon(Icons.chevron_right),
      onTap: () => context.push(Routes.notifications),
    );
  }
}
