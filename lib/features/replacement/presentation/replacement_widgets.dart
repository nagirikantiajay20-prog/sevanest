import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/core/widgets/sn_badge.dart';
import 'package:sevanest_customer/features/booking/domain/booking.dart';
import 'package:sevanest_customer/features/booking/presentation/booking_labels.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/engagement_labels.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/schedule_format.dart';
import 'package:sevanest_customer/features/worker_profile/presentation/providers/worker_profile_providers.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/worker_card.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// The engagement being replaced (design screens 25 / 26). The backend sends no worker name, so the
/// title is the category and the line under it is the engagement and the booking reference.
/// [tag] is the "Current engagement" label that keeps the previous engagement visible.
class ReplacementBookingCard extends ConsumerWidget {
  const ReplacementBookingCard({required this.booking, this.tag, super.key});
  final Booking booking;
  final String? tag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toString();
    final b = booking;
    final worker =
        b.worker ??
        (b.workerId == null
            ? null
            : ref.watch(workerDetailProvider(b.workerId!)).value);
    final title = b.categoryName ?? b.categoryCode ?? '';
    return Card(
      key: const Key('replacement_booking_card'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (worker != null)
              WorkerAvatar(worker)
            else
              const CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.hairline,
                child: Icon(Icons.person_outline),
              ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: text.titleMedium),
                  Text(
                    [
                      if (b.engagement != null)
                        engagementLabels(l10n, b.engagement!).name,
                      '#${b.reference}',
                    ].join(' · '),
                    style: text.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SnBadge(
                        label: tag ?? bookingStatusLabel(l10n, b.status),
                        tone: tag != null
                            ? SnBadgeTone.neutral
                            : bookingStatusTone(b.status),
                      ),
                      if (b.startDate != null)
                        Text(
                          l10n.serviceSince(formatDate(b.startDate!, locale)),
                          style: text.bodySmall,
                        ),
                    ],
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

/// A rounded notice with an icon and a title (status banners, offline, error).
class ReplacementNotice extends StatelessWidget {
  const ReplacementNotice({
    required this.icon,
    required this.title,
    this.body,
    this.color,
    this.iconColor,
    this.trailing,
    super.key,
  });
  final IconData icon;
  final String title;
  final String? body;
  final Color? color;
  final Color? iconColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? AppColors.warnBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.surface,
              child: Icon(icon, color: iconColor ?? AppColors.warn),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: text.titleMedium),
                  if (body != null) Text(body!, style: text.bodyMedium),
                  ?trailing,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
