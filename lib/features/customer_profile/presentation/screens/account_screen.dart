import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// Entry points for module 02 on the Account tab. Module 14 (account & settings) extends this screen.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
        ],
      ),
    );
  }
}
