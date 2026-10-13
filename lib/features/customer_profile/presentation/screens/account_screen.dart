import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/core/widgets/labeled_field.dart';
import 'package:sevanest_customer/features/authentication/presentation/providers/auth_providers.dart';
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
