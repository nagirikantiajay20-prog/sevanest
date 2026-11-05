import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/core/config/app_config.dart';
import 'package:sevanest_customer/features/authentication/presentation/providers/auth_providers.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart';
import 'package:sevanest_customer/features/customer_profile/domain/customer_profile.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/providers/account_providers.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/providers/customer_profile_providers.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/screens/account_deletion_screen.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/widgets/account_parts.dart';
import 'package:sevanest_customer/features/notifications/domain/push_service.dart';
import 'package:sevanest_customer/features/notifications/presentation/providers/push_providers.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_page.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_parts.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

export 'package:sevanest_customer/features/customer_profile/presentation/widgets/account_parts.dart'
    show maskMobile;

/// Screen 33 (design: Find a Worker > Account). Every row is a plain push / tab switch to a
/// screen another module owns; Log out resets the whole app. Delete account stays hidden until
/// the policy exists (OPEN_QUESTIONS #18).
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final yes = await showGlassConfirm(
      context,
      title: l10n.logoutConfirmTitle,
      body: l10n.logoutConfirmBody,
      confirmLabel: l10n.logout,
      keepLabel: l10n.accountStayLoggedIn,
      confirmKey: const Key('account_logout_confirm_btn'),
      keepKey: const Key('account_logout_cancel_btn'),
      destructive: true,
    );
    // Clears the session and every provider; the app restarts on /login.
    if (yes) await ref.read(logoutProvider)();
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final yes = await showGlassConfirm(
      context,
      title: l10n.deleteTitle,
      body: l10n.deleteConfirmBody,
      confirmLabel: l10n.deleteConfirmButton,
      keepLabel: l10n.cancel,
      confirmKey: const Key('account_delete_confirm_btn'),
      keepKey: const Key('account_delete_cancel_btn'),
      destructive: true,
    );
    if (!yes || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await requestAccountDeletion(ref);
    } on Object {
      messenger.showSnackBar(SnackBar(content: Text(l10n.deleteFailed)));
      return;
    }
    if (!context.mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const AccountDeletionScreen()),
    );
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final config = ref.watch(accountConfigProvider).value;
    final perm = ref.watch(pushPermissionProvider).value;
    final denied = perm == PushPermission.denied;
    // The floating nav pill sits over the page (Scaffold extendBody).
    final navClear = MediaQuery.paddingOf(context).bottom + 16;
    final version = ref.watch(appVersionProvider).value;

    Widget row(
      String key,
      IconData icon,
      String title,
      VoidCallback onTap, {
      String? subtitle,
      Key? subtitleKey,
    }) => KeyedSubtree(
      key: Key(key),
      child: AccountRow(
        icon: icon,
        title: title,
        onTap: onTap,
        subtitle: subtitle,
        subtitleKey: subtitleKey,
      ),
    );

    final notifStatus = switch (perm) {
      PushPermission.granted => l10n.notifAccountOn,
      PushPermission.denied => l10n.notifAccountOff,
      PushPermission.notDetermined => l10n.notifAccountNotAsked,
      _ => null,
    };

    return FindGlassPage(
      title: l10n.navAccount,
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 12, 16, navClear),
        children: [
          AccountHeaderCard(
            profile: ref.watch(profileProvider).value,
            onEdit: () => context.push(Routes.profile),
          ),
          if (denied)
            AccountNotifWarning(
              onTurnOn: () => ref.read(pushServiceProvider).openSettings(),
            ),
          AccountSection(
            label: l10n.accountSectionActivity,
            delayMs: 120,
            rows: [
              row(
                'account_bookings_btn',
                Icons.calendar_month_outlined,
                l10n.accountBookings,
                () => context.go(Routes.bookings),
              ),
              row(
                'account_favourites_btn',
                Icons.favorite_border_rounded,
                l10n.accountShortlist,
                () => context.go(Routes.favourites),
              ),
              row(
                'account_interviews_btn',
                Icons.event_available_outlined,
                l10n.accountInterviews,
                () => context.push(Routes.interviews),
              ),
              row(
                'account_history_btn',
                Icons.history_rounded,
                l10n.accountHistory,
                () => context.push(Routes.serviceHistory),
              ),
            ],
          ),
          AccountSection(
            label: l10n.accountSectionDetails,
            delayMs: 200,
            rows: [
              row(
                'account_transactions_btn',
                Icons.account_balance_wallet_outlined,
                l10n.accountTransactions,
                () => context.push(Routes.transactions),
              ),
              row(
                'account_addresses_btn',
                Icons.location_on_outlined,
                l10n.myAddressesTitle,
                () => context.push(Routes.addresses),
              ),
              // Hidden while only English is enabled (V1).
              if (config != null && config.languages.length > 1)
                row(
                  'account_language_btn',
                  Icons.language_rounded,
                  l10n.accountLanguage,
                  () => showGlassSheet<void>(
                    context,
                    builder: (_) => _LanguageSheet(codes: config.languages),
                  ),
                ),
            ],
          ),
          AccountSection(
            label: l10n.accountSectionHelp,
            delayMs: 280,
            rows: [
              row(
                'account_support_btn',
                Icons.help_outline_rounded,
                l10n.accountSupport,
                () => context.push(Routes.support),
              ),
              row(
                'account_notifications_btn',
                denied
                    ? Icons.notifications_off_outlined
                    : Icons.notifications_none_rounded,
                l10n.notifAccountTitle,
                () => context.push(Routes.notifications),
                subtitle: notifStatus,
                subtitleKey: const Key('account_notifications_status'),
              ),
              if (!ref.watch(appConfigProvider).isProd)
                row(
                  'account_push_diag_btn',
                  Icons.bug_report_outlined,
                  l10n.pushDiagEntry,
                  () => context.push(Routes.devPushDiagnostics),
                ),
              row(
                'account_terms_btn',
                Icons.description_outlined,
                l10n.accountTerms,
                () => _openLegal(context, ref, config?.termsUrl),
              ),
              row(
                'account_privacy_btn',
                Icons.shield_outlined,
                l10n.accountPrivacy,
                () => _openLegal(context, ref, config?.privacyUrl),
              ),
              row(
                'account_about_btn',
                Icons.info_outline_rounded,
                l10n.accountAbout,
                () => showGlassSheet<void>(
                  context,
                  builder: (_) => const _AboutSheet(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          DiscoverRise(
            delayMs: 340,
            child: Column(
              children: [
                if (ref.watch(accountDeletionEnabledProvider)) ...[
                  KeyedSubtree(
                    key: const Key('account_delete_btn'),
                    child: AccountDangerButton(
                      icon: Icons.delete_outline_rounded,
                      label: l10n.accountDelete,
                      onPressed: () => _delete(context, ref),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                KeyedSubtree(
                  key: const Key('account_logout_btn'),
                  child: AccountDangerButton(
                    icon: Icons.logout_rounded,
                    label: l10n.logout,
                    onPressed: () => _logout(context, ref),
                  ),
                ),
                if (version != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text(
                      'SevaNest · ${l10n.accountVersion(version)}',
                      textAlign: TextAlign.center,
                      style: AppText.body.copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: dsMuted,
                      ),
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

class _AboutSheet extends ConsumerWidget {
  const _AboutSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final version = ref.watch(appVersionProvider).value;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.accountAbout, style: authSerif(24, 1.15)),
        const SizedBox(height: 10),
        Text(
          l10n.accountAboutTagline,
          style: AppText.body.copyWith(
            fontSize: 15.5,
            height: 1.55,
            color: dsText,
          ),
        ),
        if (version != null)
          Container(
            key: const Key('account_about_version'),
            margin: const EdgeInsets.only(top: 14),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: dsNavy.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final t in [l10n.accountVersionLabel, version])
                  Text(
                    t,
                    style: AppText.body.copyWith(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: dsNavy,
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        SizedBox(
          height: 54,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: dsNavy,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: AppText.body.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text(MaterialLocalizations.of(context).closeButtonLabel),
          ),
        ),
      ],
    );
  }
}

/// The languages `GET /app-config` enables. Picking one saves `preferredLanguage` on the profile
/// (the same PATCH the profile screen uses) and updates the shared profile state.
class _LanguageSheet extends ConsumerWidget {
  const _LanguageSheet({required this.codes});

  final List<String> codes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).value;
    final messenger = ScaffoldMessenger.of(context);
    final failed = AppLocalizations.of(context).accountLanguageFailed;
    Future<void> pick(String code) async {
      Navigator.of(context).pop();
      if (profile == null || code == profile.preferredLanguage) return;
      final saved = await ref
          .read(profileFormProvider.notifier)
          .submit(
            create: false,
            name: profile.name,
            email: profile.email,
            preferredLanguage: code,
          );
      if (saved == null) {
        messenger.showSnackBar(SnackBar(content: Text(failed)));
        return;
      }
      // PATCH may not echo mobile / verification: keep what we know.
      ref
          .read(profileProvider.notifier)
          .replace(
            CustomerProfile(
              name: saved.name,
              email: saved.email,
              preferredLanguage: saved.preferredLanguage,
              mobile: saved.mobile ?? profile.mobile,
              verificationStatus:
                  saved.verificationStatus ?? profile.verificationStatus,
            ),
          );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final l in profileLanguages.where((l) => codes.contains(l.code)))
          ListTile(
            key: Key('account_language_${l.code}'),
            title: Text(
              l.label,
              style: AppText.body.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: dsNavy,
              ),
            ),
            trailing: l.code == profile?.preferredLanguage
                ? const Icon(Icons.check_rounded, color: dsNavy)
                : null,
            onTap: profile == null ? null : () => pick(l.code),
          ),
      ],
    );
  }
}
