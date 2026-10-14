import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/core/localization/failure_message.dart';
import 'package:sevanest_customer/core/widgets/async_value_view.dart';
import 'package:sevanest_customer/core/widgets/sn_badge.dart';
import 'package:sevanest_customer/core/widgets/sn_button.dart';
import 'package:sevanest_customer/core/widgets/sn_states.dart';
import 'package:sevanest_customer/features/booking/domain/booking.dart';
import 'package:sevanest_customer/features/booking/presentation/booking_labels.dart';
import 'package:sevanest_customer/features/booking/presentation/providers/booking_providers.dart';
import 'package:sevanest_customer/features/ratings/presentation/providers/rating_providers.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/engagement_labels.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/schedule_format.dart';
import 'package:sevanest_customer/features/worker_search/presentation/providers/worker_search_providers.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// `/services/history` (module doc 10.2), built on `GET /bookings` because the backend has no
/// history route. Sections follow the booking status; nothing is derived locally.
class ServiceHistoryScreen extends ConsumerWidget {
  const ServiceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final value = ref.watch(bookingListProvider);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('app_back_btn'),
          tooltip: l10n.back,
          icon: const Icon(Icons.chevron_left, size: 32),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(Routes.account),
        ),
        title: Text(l10n.historyTitle),
      ),
      body: AsyncValueView(
        value: value,
        onRetry: () => ref.invalidate(bookingListProvider),
        isEmpty: (s) => s.items.isEmpty,
        empty: SnEmptyState(
          title: l10n.historyEmptyTitle,
          message: l10n.historyEmptyBody,
        ),
        data: (s) {
          final ratings =
              ref.watch(myRatingsProvider).asData?.value ?? const {};
          final scale = ref.watch(ratingScaleMaxProvider).value ?? 5;
          final sections = [
            (
              'current',
              l10n.historySectionCurrent,
              s.items.where((b) => !bookingIsPast(b.status)),
            ),
            (
              'completed',
              l10n.historySectionCompleted,
              s.items.where((b) => b.status == BookingStatus.completed),
            ),
            (
              'cancelled',
              l10n.historySectionCancelled,
              s.items.where((b) => b.status == BookingStatus.cancelled),
            ),
            (
              'replaced',
              l10n.historySectionReplaced,
              s.items.where((b) => b.status == BookingStatus.replaced),
            ),
          ];
          return RefreshIndicator(
            onRefresh: () async {
              ref
                ..invalidate(myRatingsProvider)
                ..invalidate(bookingListProvider);
              try {
                await ref.read(bookingListProvider.future);
              } on Object {
                // shown by the view
              }
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                for (final (key, title, items) in sections)
                  if (items.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      child: Text(
                        title,
                        key: Key('history_section_$key'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    for (final b in items)
                      _Card(
                        booking: b,
                        score: ratings[b.id]?.score,
                        scale: scale,
                      ),
                  ],
                if (s.loadMoreError != null)
                  Text(failureMessage(l10n, s.loadMoreError!)),
                if (s.hasMore || s.isLoadingMore)
                  SnButton(
                    key: const Key('history_load_more_btn'),
                    label: l10n.attendanceLoadMore,
                    variant: SnButtonVariant.text,
                    isLoading: s.isLoadingMore,
                    onPressed: () =>
                        ref.read(bookingListProvider.notifier).loadMore(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.booking,
    required this.score,
    required this.scale,
  });
  final Booking booking;
  final int? score;
  final int scale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toString();
    final b = booking;
    final canRate = score == null && b.actions.contains(BookingAction.rate);
    return Card(
      child: InkWell(
        key: Key('history_card_${b.id}'),
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () =>
            context.push(Routes.path(Routes.bookingDetail, {'id': b.id})),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.sm,
                children: [
                  Text(
                    [
                      b.categoryName ?? b.categoryCode,
                      if (b.engagement != null)
                        engagementLabels(l10n, b.engagement!).name,
                    ].whereType<String>().join(' · '),
                    style: text.titleSmall,
                  ),
                  SnBadge(
                    label: bookingStatusLabel(l10n, b.status),
                    tone: bookingStatusTone(b.status),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                [
                  if (b.startDate != null) formatDate(b.startDate!, locale),
                  ?b.areaName,
                ].join(' · '),
                style: text.bodySmall,
              ),
              if (score != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Semantics(
                    label: l10n.historyRatedLabel(score!, scale),
                    child: Row(
                      key: Key('history_stars_${b.id}'),
                      children: [
                        for (var i = 1; i <= scale; i++)
                          Icon(
                            i <= score! ? Icons.star : Icons.star_border,
                            size: 18,
                            color: AppColors.amber,
                          ),
                      ],
                    ),
                  ),
                ),
              if (canRate)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    key: Key('history_rate_btn_${b.id}'),
                    icon: const Icon(Icons.star_border),
                    label: Text(l10n.historyRate),
                    onPressed: () =>
                        context.push(Routes.path(Routes.rating, {'id': b.id})),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
