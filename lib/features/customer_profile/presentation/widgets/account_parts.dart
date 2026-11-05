import 'package:flutter/material.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart';
import 'package:sevanest_customer/features/customer_profile/domain/customer_profile.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/widgets/profile_photo_avatar.dart';
import 'package:sevanest_customer/features/interview_trial/presentation/widgets/interview_detail_parts.dart'
    show DashedRule;
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_page.dart'
    show SheenSweep;
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

const _danger = AppColors.rose700;
const _mint = AppColors.tealD6EFEA;
const _mintInk = AppColors.teal0B5A53;

/// "+91 ••••••0002": the country code and the last four digits only.
String maskMobile(String? mobile) {
  final digits = (mobile ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.length < 4) return '';
  return '+91 ${'•' * 6}${digits.substring(digits.length - 4)}';
}

/// Navy profile card at the top of Account: avatar, name, masked mobile, status chip and an Edit
/// pill. The whole card opens My profile.
class AccountHeaderCard extends StatelessWidget {
  const AccountHeaderCard({
    required this.profile,
    required this.onEdit,
    super.key,
  });

  final CustomerProfile? profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = profile;
    final mobile = maskMobile(p?.mobile);
    return DiscoverRise(
      delayMs: 0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [dsNavy, AppColors.actionDeepTeal],
          ),
          boxShadow: [
            BoxShadow(
              color: dsNavy.withValues(alpha: 0.32),
              blurRadius: 38,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Material(
            type: MaterialType.transparency,
            child: Stack(
              children: [
                InkWell(
                  key: const Key('account_profile_btn'),
                  onTap: onEdit,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        if (p != null) ...[
                          ProfilePhotoAvatar(
                            key: const Key('account_avatar'),
                            radius: 32,
                            initials: profileInitials(p.name),
                            gradient: const [AppColors.teal, dsSky],
                          ),
                          const SizedBox(width: 14),
                        ],
                        Expanded(
                          child: p == null
                              ? const SizedBox.shrink()
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.name,
                                      key: const Key('account_name'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: authSerif(
                                        23,
                                        1.2,
                                      ).copyWith(color: AppColors.surface),
                                    ),
                                    if (mobile.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          mobile,
                                          key: const Key('account_mobile'),
                                          style: AppText.body.copyWith(
                                            fontSize: 14,
                                            color: AppColors.surface,
                                          ),
                                        ),
                                      ),
                                    // Read-only, backend-supplied status shown as-is (AGENTS 27).
                                    if (p.verificationStatus != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Chip(
                                          key: const Key(
                                            'account_verification_chip',
                                          ),
                                          avatar: const Icon(
                                            Icons.check_rounded,
                                            size: 13,
                                            color: _mintInk,
                                          ),
                                          label: Text(p.verificationStatus!),
                                          labelStyle: AppText.body.copyWith(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                            color: _mintInk,
                                          ),
                                          backgroundColor: _mint,
                                          side: BorderSide.none,
                                          shape: const StadiumBorder(),
                                          visualDensity: VisualDensity.compact,
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),
                                  ],
                                ),
                        ),
                        const SizedBox(width: 8),
                        _EditPill(
                          label: p == null
                              ? l10n.accountEditProfile
                              : l10n.edit,
                        ),
                      ],
                    ),
                  ),
                ),
                const SheenSweep(
                  periodMs: 5000,
                  band: 0.3,
                  peak: AppColors.whiteA16x29,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditPill extends StatelessWidget {
  const _EditPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    height: 36,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: AppColors.surface.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: AppColors.surface.withValues(alpha: 0.4)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.edit_outlined, size: 13, color: AppColors.surface),
        const SizedBox(width: 5),
        Text(
          label,
          style: AppText.body.copyWith(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: AppColors.surface,
          ),
        ),
      ],
    ),
  );
}

/// Amber "Notifications are off" strip with a button that opens the OS settings.
class AccountNotifWarning extends StatelessWidget {
  const AccountNotifWarning({required this.onTurnOn, super.key});
  final VoidCallback onTurnOn;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const ink = AppColors.orange7A4A06;
    return DiscoverRise(
      delayMs: 60,
      child: Container(
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
        decoration: BoxDecoration(
          color: AppColors.warnBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.warn.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.notifications_off_outlined, size: 22, color: ink),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.accountNotifWarn,
                style: AppText.body.copyWith(
                  fontSize: 13.5,
                  height: 1.4,
                  color: ink,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              key: const Key('notif_open_settings_btn'),
              onPressed: onTurnOn,
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 44),
                backgroundColor: AppColors.surface,
                foregroundColor: ink,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: AppText.body.copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: Text(l10n.accountNotifTurnOn),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small uppercase label over a frosted group of [rows], separated by dashed rules.
class AccountSection extends StatelessWidget {
  const AccountSection({
    required this.label,
    required this.rows,
    required this.delayMs,
    super.key,
  });

  final String label;
  final List<Widget> rows;
  final double delayMs;

  @override
  Widget build(BuildContext context) => DiscoverRise(
    delayMs: delayMs,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 22, 4, 8),
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
        DiscoverGlass(
          radius: 26,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0) const DashedRule(),
                  rows[i],
                ],
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

/// One tappable line: mint icon tile, bold title (+ optional status line) and a chevron.
class AccountRow extends StatelessWidget {
  const AccountRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.subtitleKey,
    super.key,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final String? subtitle;
  final Key? subtitleKey;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.pillActive,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: AppColors.teal),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppText.body.copyWith(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: dsNavy,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      key: subtitleKey,
                      style: AppText.body.copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: dsMuted,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 22, color: dsMuted),
          ],
        ),
      ),
    ),
  );
}

/// Full-width white button with a red outline (Log out, Delete account).
class AccountDangerButton extends StatelessWidget {
  const AccountDangerButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onPressed,
    icon: Icon(icon, size: 19),
    label: Text(label),
    style: OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(54),
      foregroundColor: _danger,
      backgroundColor: AppColors.surface.withValues(alpha: 0.8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      side: BorderSide(color: _danger.withValues(alpha: 0.4), width: 1.5),
      textStyle: AppText.body.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
