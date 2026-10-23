import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/core/widgets/sn_button.dart';
import 'package:sevanest_customer/features/booking/domain/booking.dart';
import 'package:sevanest_customer/features/booking/presentation/booking_labels.dart';
import 'package:sevanest_customer/features/replacement/presentation/providers/replacement_providers.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/schedule_format.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// On a booking that is part of a replacement: the open request (while the booking is
/// REPLACEMENT_REQUESTED) and the chain of bookings, oldest first, each linking to its own booking.
/// Nothing shows while loading, on error, or for a booking that was never replaced.
class ReplacementLinks extends ConsumerWidget {
  const ReplacementLinks({required this.booking, super.key});
  final Booking booking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toString();
    final b = booking;
    final inChain =
        b.status == BookingStatus.replacementRequested ||
        b.status == BookingStatus.replaced ||
        b.previousBookingId != null;
    if (!inChain) return const SizedBox.shrink();

    final open = b.status == BookingStatus.replacementRequested
        ? ref.watch(openReplacementProvider(b.id)).value
        : null;
    final chain = ref.watch(replacementChainProvider(b.id)).value ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (open != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: SnButton(
              key: const Key('booking_replacement_btn'),
              label: l10n.repViewRequest,
              variant: SnButtonVariant.deep,
              onPressed: () => context.push(
                Routes.path(Routes.replacementDetail, {'id': open.id}),
              ),
            ),
          ),
        if (chain.length > 1) ...[
          const SizedBox(height: AppSpacing.md),
          Text(l10n.repChainTitle, style: text.titleMedium),
          for (final e in chain)
            ListTile(
              key: Key('chain_entry_${e.bookingId}'),
              contentPadding: EdgeInsets.zero,
              title: Text(
                l10n.repChainEntry(
                  e.position,
                  bookingStatusLabel(l10n, e.status),
                ),
              ),
              subtitle: e.current
                  ? Text(l10n.repChainThis)
                  : e.startDate == null
                  ? null
                  : Text(formatDate(e.startDate!, locale)),
              trailing: e.current ? null : const Icon(Icons.chevron_right),
              onTap: e.current
                  ? null
                  : () => context.push(
                      Routes.path(Routes.bookingDetail, {'id': e.bookingId}),
                    ),
            ),
        ],
      ],
    );
  }
}
