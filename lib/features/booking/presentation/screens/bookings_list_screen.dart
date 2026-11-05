import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/core/widgets/async_value_view.dart';
import 'package:sevanest_customer/features/booking/domain/booking.dart';
import 'package:sevanest_customer/features/booking/presentation/booking_labels.dart';
import 'package:sevanest_customer/features/booking/presentation/booking_navigation.dart';
import 'package:sevanest_customer/features/booking/presentation/providers/booking_providers.dart';
import 'package:sevanest_customer/features/booking/presentation/widgets/booking_list_parts.dart';
import 'package:sevanest_customer/features/interview_trial/presentation/widgets/interview_list_parts.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/engagement_labels.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/schedule_format.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_page.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_parts.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/paged_footer.dart';
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

  List<Booking> _visible(PagedState<Booking> p, {required bool past}) => [
    for (final b in p.items)
      if (bookingIsPast(b.status) == past) b,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(bookingListProvider.notifier);
    return FindGlassPage(
      title: l10n.bookingsTitle,
      body: AsyncValueView<PagedState<Booking>>(
        value: ref.watch(bookingListProvider),
        onRetry: notifier.refresh,
        data: (p) {
          // The other tab may hold the rest of the page: keep loading until this one fills.
          loadMoreIfShort(_scroll, p, notifier.loadMore);
          final items = _visible(p, past: _past);
          return RefreshIndicator(
            onRefresh: notifier.refresh,
            child: ListView(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
              children: [
                DiscoverRise(
                  delayMs: 0,
                  child: InterviewSegments(
                    selected: _past ? 1 : 0,
                    labels: [l10n.bookingsTabCurrent, l10n.bookingsTabPast],
                    counts: [
                      _visible(p, past: false).length,
                      _visible(p, past: true).length,
                    ],
                    tabKey: (i) => Key(
                      i == 0 ? 'bookings_tab_current' : 'bookings_tab_past',
                    ),
                    onChanged: (i) => setState(() => _past = i == 1),
                  ),
                ),
                // Empty only when this tab has nothing AND there is no further page to look in.
                if (items.isEmpty && !p.hasMore)
                  SizedBox(
                    height: 440,
                    child: GlassEmpty(
                      icon: Icons.event_note_rounded,
                      iconColor: AppColors.teal,
                      discColors: const [
                        AppColors.pillActive,
                        AppColors.surface,
                      ],
                      title: _past
                          ? l10n.bookingsPastEmpty
                          : l10n.bookingsEmptyTitle,
                      body: l10n.bookingsEmptyBody,
                      actionLabel: l10n.bookingsFind,
                      actionKey: const Key('bookings_empty_find_btn'),
                      actionIcon: Icons.search_rounded,
                      onAction: () => context.push(Routes.discoverCategory),
                    ),
                  ),
                for (final (i, b) in items.indexed)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: DiscoverRise(
                      delayMs: 80.0 + 60 * i.clamp(0, 5),
                      child: _Tile(b),
                    ),
                  ),
                PagedFooter(
                  page: p,
                  onRetry: notifier.loadMore,
                  retryKey: const Key('bookings_load_more_retry_btn'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(this.booking);
  final Booking booking;

  /// Payment state the backend's status implies; nothing before a worker is confirmed.
  String? _payment(AppLocalizations l10n) => switch (booking.status) {
    BookingStatus.pendingPayment => l10n.bookingPayUnpaid,
    BookingStatus.confirmed ||
    BookingStatus.active ||
    BookingStatus.replacementRequested ||
    BookingStatus.replaced ||
    BookingStatus.completed => l10n.bookingPayPaid,
    _ => null,
  };

  String? _date(AppLocalizations l10n, String locale) {
    final b = booking;
    final cancelled = b.timeline
        .where((e) => e.status == BookingStatus.cancelled)
        .lastOrNull
        ?.at;
    final String? text = switch (b.status) {
      BookingStatus.cancelled =>
        cancelled == null
            ? null
            : l10n.bookingCancelledOn(formatDate(cancelled, locale)),
      _ when b.startDate == null => null,
      _ when bookingIsPast(b.status) => l10n.bookingStartedOn(
        formatDate(b.startDate!, locale),
      ),
      _ => l10n.bookingStartsOn(formatDate(b.startDate!, locale)),
    };
    return text;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final b = booking;
    final name = b.identity?.displayName ?? b.worker?.title;
    final service =
        b.categoryName ??
        b.worker?.categories.firstOrNull ??
        b.categoryCode ??
        '';
    final kind = [
      service,
      if (b.engagement != null) engagementLabels(l10n, b.engagement!).name,
    ].where((s) => s.isNotEmpty).join(' · ');
    final date = _date(l10n, locale);
    final payment = _payment(l10n);
    final pay = b.actions.contains(BookingAction.pay);
    // No worker yet (new request): the service leads instead of a blank title.
    final title = name ?? (service.isEmpty ? '#${b.reference}' : service);
    return InterviewTile(
      key: Key('booking_card_${b.id}'),
      titleKey: Key('booking_card_worker_${b.id}'),
      title: title,
      initials: b.identity?.initials ?? b.worker?.initials,
      photoUrl: b.identity?.photoUrl ?? b.worker?.photoUrl,
      gradient: avatarGradientFor(b.workerId ?? b.id),
      subtitle: name == null ? '#${b.reference}' : kind,
      statusLabel: bookingStatusLabel(l10n, b.status),
      look: bookingLook(b.status),
      onTap: () =>
          context.push(Routes.path(Routes.bookingDetail, {'id': b.id})),
      footer: date == null && payment == null && !pay
          ? null
          : BookingTileFooter(
              date: date,
              payment: payment,
              payLabel: l10n.bookingsPay,
              payKey: Key('booking_card_pay_btn_${b.id}'),
              onPay: pay ? () => context.push(paymentStartPath(b.id)) : null,
            ),
    );
  }
}
