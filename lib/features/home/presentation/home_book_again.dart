import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/core/widgets/sn_avatar.dart';
import 'package:sevanest_customer/features/booking/domain/booking.dart';
import 'package:sevanest_customer/features/booking/presentation/providers/booking_providers.dart';
import 'package:sevanest_customer/features/booking/presentation/widgets/hire_again_button.dart';
import 'package:sevanest_customer/features/home/presentation/home_widgets.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

const _maxCards = 5;

/// "Book again": workers from finished bookings the backend still lets the customer rebook
/// (`rebook` in `allowedActions`), one card per worker. Hidden while loading, on error or when
/// there is nothing to rebook.
class HomeBookAgain extends ConsumerWidget {
  const HomeBookAgain({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(bookingListProvider).value?.items ?? const [];
    final seen = <String>{};
    final again = [
      for (final b in items)
        if (b.actions.contains(BookingAction.rebook) &&
            b.worker?.name != null &&
            seen.add(b.workerId ?? b.id))
          b,
    ].take(_maxCards).toList();
    if (again.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 0, 2, 12),
            child: Semantics(
              header: true,
              child: Text(
                l10n.homeBookAgain,
                style: AppText.title.copyWith(fontSize: 18),
              ),
            ),
          ),
          SizedBox(
            height: 122,
            child: ListView.separated(
              key: const Key('home_book_again'),
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: again.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) =>
                  SizedBox(width: 250, child: _Card(booking: again[i])),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final name = booking.worker!.name!;
    return HomeCard(
      radius: 22,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          SnAvatar(name: name, size: 52, round: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.card.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  booking.categoryName ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body.copyWith(
                    fontSize: 12,
                    color: AppColors.slate,
                  ),
                ),
                const SizedBox(height: 8),
                HireAgainButton(bookingId: booking.id, compact: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
