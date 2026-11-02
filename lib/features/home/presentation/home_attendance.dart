import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/features/home/domain/home_data.dart';
import 'package:sevanest_customer/features/home/presentation/home_widgets.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// "Today's attendance" for the active booking's worker (`todayAttendance`). Hidden when null.
class HomeAttendance extends StatelessWidget {
  const HomeAttendance({required this.attendance, super.key});
  final TodayAttendance? attendance;

  @override
  Widget build(BuildContext context) {
    final a = attendance;
    if (a == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final (icon, color, label) = switch (a.status) {
      HomeAttendanceStatus.arrived => (
        Icons.check_circle_rounded,
        AppColors.success,
        a.arrivedAt == null
            ? l10n.homeStageActive
            : l10n.homeAttendanceArrived(
                DateFormat('h:mm a').format(a.arrivedAt!),
              ),
      ),
      HomeAttendanceStatus.notArrived => (
        Icons.schedule_rounded,
        AppColors.amber,
        l10n.homeAttendanceNotArrived,
      ),
      HomeAttendanceStatus.absent => (
        Icons.cancel_rounded,
        AppColors.danger,
        l10n.homeAttendanceAbsent,
      ),
      HomeAttendanceStatus.leave => (
        Icons.beach_access_rounded,
        AppColors.teal,
        l10n.homeAttendanceLeave,
      ),
      HomeAttendanceStatus.exception => (
        Icons.error_outline_rounded,
        AppColors.danger,
        l10n.homeAttendanceException,
      ),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: HomeCard(
        radius: 22,
        child: Row(
          key: const Key('home_attendance'),
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.tealWash,
              foregroundImage: a.photoUrl == null
                  ? null
                  : NetworkImage(a.photoUrl!),
              onForegroundImageError: a.photoUrl == null ? null : (_, _) {},
              child: Text(
                a.workerName.isEmpty ? '' : a.workerName[0].toUpperCase(),
                style: AppText.heading.copyWith(color: AppColors.teal),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.homeAttendanceTitle, style: AppText.meta),
                  Text(
                    a.workerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.card.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.end,
                style: AppText.label.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
