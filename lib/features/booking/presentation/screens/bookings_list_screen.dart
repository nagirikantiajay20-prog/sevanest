import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/core/widgets/async_value_view.dart';
import 'package:sevanest_customer/core/widgets/sn_badge.dart';
import 'package:sevanest_customer/core/widgets/sn_button.dart';
import 'package:sevanest_customer/core/widgets/sn_states.dart';
import 'package:sevanest_customer/features/booking/domain/booking.dart';
import 'package:sevanest_customer/features/booking/presentation/booking_labels.dart';
import 'package:sevanest_customer/features/booking/presentation/booking_navigation.dart';
import 'package:sevanest_customer/features/booking/presentation/providers/booking_providers.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/schedule_format.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/paged_footer.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/worker_card.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';
import 'package:sevanest_customer/shared/models/paged_state.dart';

/// `/bookings` tab (module 08, screen 8.2): Current | Past.
class BookingsListScreen extends ConsumerStatefulWidget {
  const BookingsListScreen({super.key});

  @override
  ConsumerState<BookingsListScreen> createState() => _State();
}

class _State extends ConsumerState<BookingsListScreen> {
  final _scroll = ScrollController();
  bool _past = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 300) {
        ref.read(bookingListProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final notifier = ref.read(bookingListProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.bookingsTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SegmentedButton<bool>(
              key: const Key('bookings_tabs'),
              segments: [
                ButtonSegment(
                  value: false,
                  label: Text(
                    l10n.bookingsTabCurrent,
                    key: const Key('bookings_tab_current'),
                  ),
                ),
                ButtonSegment(
                  value: true,
                  label: Text(
                    l10n.bookingsTabPast,
                    key: const Key('bookings_tab_past'),
                  ),
                ),
              ],
              selected: {_past},
              onSelectionChanged: (s) => setState(() => _past = s.first),
            ),
          ),
          Expanded(
            child: AsyncValueView<PagedState<Booking>>(
              value: ref.watch(bookingListProvider),
              onRetry: notifier.refresh,
              // Empty only when this tab has nothing AND there is no further page to look in.
              isEmpty: (p) => _visible(p).isEmpty && !p.hasMore,
              empty: _past
                  ? SnEmptyState(title: l10n.bookingsPastEmpty)
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SnEmptyState(
                          title: l10n.bookingsEmptyTitle,
                          message: l10n.bookingsEmptyBody,
                          actionLabel: l10n.bookingsFind,
                          actionKey: const Key('bookings_empty_find_btn'),
                          onAction: () => context.push(Routes.discoverCategory),
                        ),
                      ],
                    ),
              data: (p) {
                final items = _visible(p);
                // The other tab may hold the rest of the page: keep loading until this one fills.
                loadMoreIfShort(_scroll, p, notifier.loadMore);
                return RefreshIndicator(
                  onRefresh: notifier.refresh,
                  child: ListView.separated(
                    controller: _scroll,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      0,
                      AppSpacing.md,
                      AppSpacing.md,
                    ),
                    itemCount: items.length + 1,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, i) {
                      if (i == items.length) {
                        return PagedFooter(
                          page: p,
                          onRetry: notifier.loadMore,
                          retryKey: const Key('bookings_load_more_retry_btn'),
                        );
                      }
                      return _BookingCard(items[i], locale);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Booking> _visible(PagedState<Booking> p) => [
    for (final b in p.items)
      if (bookingIsPast(b.status) == _past) b,
  ];
}

class _BookingCard extends StatelessWidget {
  const _BookingCard(this.booking, this.locale);
  final Booking booking;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final b = booking;
    final next = b.scheduledAt ?? b.startDate;
    return Card(
      key: Key('booking_card_${b.id}'),
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () =>
            context.push(Routes.path(Routes.bookingDetail, {'id': b.id})),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (b.worker != null) ...[
                    WorkerAvatar(b.worker!, radius: 22),
                    const SizedBox(width: AppSpacing.md),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b.categoryName ??
                              b.worker?.categories.firstOrNull ??
                              b.categoryCode ??
                              '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleMedium,
                        ),
                        if (next != null)
                          Text(formatDate(next, locale), style: text.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: SnBadge(
                  label: bookingStatusLabel(l10n, b.status),
                  tone: bookingStatusTone(b.status),
                ),
              ),
              if (b.actions.contains(BookingAction.pay)) ...[
                const SizedBox(height: AppSpacing.sm),
                SnButton(
                  key: Key('booking_card_pay_btn_${b.id}'),
                  label: l10n.bookingsPay,
                  onPressed: () => context.push(paymentStartPath(b.id)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
