import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/core/config/app_config.dart';
import 'package:sevanest_customer/core/widgets/labeled_field.dart';
import 'package:sevanest_customer/features/authentication/presentation/providers/auth_providers.dart';
import 'package:sevanest_customer/features/customer_profile/domain/customer_profile.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/providers/account_providers.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/providers/customer_profile_providers.dart';
import 'package:sevanest_customer/features/notifications/domain/push_service.dart';
import 'package:sevanest_customer/features/notifications/presentation/providers/push_providers.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// "+91 ••••••0002": the country code and the last four digits only.
String maskMobile(String? mobile) {
  final digits = (mobile ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.length < 4) return '';
  return '+91 ${'•' * 6}${digits.substring(digits.length - 4)}';
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  return parts.take(2).map((p) => p[0].toUpperCase()).join();
}

/// Screen 33. Every row is a plain push / tab switch to a screen another module owns; Log out
/// resets the whole app. Delete account stays hidden until the policy exists (OPEN_QUESTIONS #18).
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
      confirmKey: const Key('account_logout_confirm_btn'),
      cancelKey: const Key('account_logout_cancel_btn'),
      destructive: true,
    );
    // Clears the session and every provider; the app restarts on /login.
    if (yes) await ref.read(logoutProvider)();
  }

  Future<void> _openLegal(
    BuildContext context,
    WidgetRef ref,
    String? url,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final unavailable = AppLocalizations.of(context).accountLegalUnavailable;
    final opened = url != null && await ref.read(openInAppBrowserProvider)(url);
    if (!opened) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            key: const Key('account_legal_unavailable'),
            content: Text(unavailable),
          ),
        );
    }
  }

  void _about(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.accountAbout,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.accountVersion(appVersionLabel),
                key: const Key('account_about_version'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final config = ref.watch(accountConfigProvider).value;
    final perm = ref.watch(pushPermissionProvider).value;
    final denied = perm == PushPermission.denied;

    Widget row(
      String key,
      IconData icon,
      String title,
      VoidCallback onTap, {
      String? subtitle,
      Key? subtitleKey,
    }) => ListTile(
      key: Key(key),
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle, key: subtitleKey),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );

    final notifStatus = switch (perm) {
      PushPermission.granted => l10n.notifAccountOn,
      PushPermission.denied => l10n.notifAccountOff,
      PushPermission.notDetermined => l10n.notifAccountNotAsked,
      _ => null,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navAccount)),
      body: ListView(
        children: [
          _Header(profile: ref.watch(profileProvider).value),
          row(
            'account_profile_btn',
            Icons.person_outline,
            l10n.profileTitle,
            () => context.push(Routes.profile),
          ),
          row(
            'account_addresses_btn',
            Icons.location_on_outlined,
            l10n.addressesTitle,
            () => context.push(Routes.addresses),
          ),
          row(
            'account_favourites_btn',
            Icons.favorite_border,
            l10n.accountShortlist,
            () => context.go(Routes.favourites),
          ),
          row(
            'account_bookings_btn',
            Icons.receipt_long_outlined,
            l10n.accountBookings,
            () => context.go(Routes.bookings),
          ),
          row(
            'account_interviews_btn',
            Icons.event_available_outlined,
            l10n.accountInterviews,
            () => context.push(Routes.interviews),
          ),
          row(
            'account_history_btn',
            Icons.history,
            l10n.accountHistory,
            () => context.push(Routes.serviceHistory),
          ),
          row(
            'account_transactions_btn',
            Icons.payments_outlined,
            l10n.accountTransactions,
            () => context.push(Routes.transactions),
          ),
          row(
            'account_support_btn',
            Icons.headset_mic_outlined,
            l10n.accountSupport,
            () => context.push(Routes.support),
          ),
          row(
            'account_notifications_btn',
            denied
                ? Icons.notifications_off_outlined
                : Icons.notifications_none,
            l10n.notifAccountTitle,
            () => context.push(Routes.notifications),
            subtitle: notifStatus,
            subtitleKey: const Key('account_notifications_status'),
          ),
          if (denied)
            ListTile(
              title: Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton(
                  key: const Key('notif_open_settings_btn'),
                  onPressed: () => ref.read(pushServiceProvider).openSettings(),
                  child: Text(l10n.notifOpenSettings),
                ),
              ),
            ),
          // Hidden while only English is enabled (V1).
          if (config != null && config.languages.length > 1)
            row(
              'account_language_btn',
              Icons.language,
              l10n.accountLanguage,
              () => context.push(Routes.profile),
            ),
          const Divider(),
          row(
            'account_terms_btn',
            Icons.description_outlined,
            l10n.accountTerms,
            () => _openLegal(context, ref, config?.termsUrl),
          ),
          row(
            'account_privacy_btn',
            Icons.privacy_tip_outlined,
            l10n.accountPrivacy,
            () => _openLegal(context, ref, config?.privacyUrl),
          ),
          row(
            'account_about_btn',
            Icons.info_outline,
            l10n.accountAbout,
            () => _about(context),
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

class _Header extends StatelessWidget {
  const _Header({required this.profile});

  final CustomerProfile? profile;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    if (p == null) return const SizedBox(height: AppSpacing.lg);
    final mobile = maskMobile(p.mobile);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          CircleAvatar(
            key: const Key('account_avatar'),
            radius: 28,
            child: Text(_initials(p.name)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  key: const Key('account_name'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (mobile.isNotEmpty)
                  Text(mobile, key: const Key('account_mobile')),
                // Read-only, backend-supplied status shown as-is (AGENTS §27).
                if (p.verificationStatus != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Chip(
                      key: const Key('account_verification_chip'),
                      label: Text(p.verificationStatus!),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
