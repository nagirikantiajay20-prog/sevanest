import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/core/localization/failure_message.dart';
import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/core/services/clock.dart';
import 'package:sevanest_customer/core/widgets/async_value_view.dart';
import 'package:sevanest_customer/core/widgets/sn_badge.dart';
import 'package:sevanest_customer/core/widgets/sn_button.dart';
import 'package:sevanest_customer/core/widgets/sn_card.dart';
import 'package:sevanest_customer/core/widgets/sn_header.dart';
import 'package:sevanest_customer/core/widgets/sn_states.dart';
import 'package:sevanest_customer/features/booking/domain/booking.dart';
import 'package:sevanest_customer/features/booking/presentation/booking_labels.dart';
import 'package:sevanest_customer/features/booking/presentation/providers/booking_providers.dart';
import 'package:sevanest_customer/features/booking/presentation/widgets/hire_again_button.dart';
import 'package:sevanest_customer/features/ratings/domain/rating.dart';
import 'package:sevanest_customer/features/ratings/presentation/providers/rating_providers.dart';
import 'package:sevanest_customer/features/service_discovery/domain/budget.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/engagement_labels.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/catalog_providers.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/schedule_format.dart';
import 'package:sevanest_customer/features/worker_search/presentation/providers/worker_search_providers.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';
import 'package:sevanest_customer/shared/models/paged_state.dart';

/// `/services/history` (module doc 10.2) on `GET /customers/me/booking-history`, filtered by year,
/// service, status and a search text. Sections follow the booking status; nothing is derived locally.
class ServiceHistoryScreen extends ConsumerStatefulWidget {
  const ServiceHistoryScreen({super.key});

  @override
  ConsumerState<ServiceHistoryScreen> createState() => _State();
}

class _State extends ConsumerState<ServiceHistoryScreen> {
  var _filter = const HistoryFilter();
  final _search = TextEditingController();

  /// The server filters by one status, so "current" is offered as each of its states.
  static const _statuses = [
    BookingStatus.active,
    BookingStatus.replacementRequested,
    BookingStatus.confirmed,
    BookingStatus.pendingPayment,
    BookingStatus.interviewTrialScheduled,
    BookingStatus.interviewTrialCompleted,
    BookingStatus.matched,
    BookingStatus.newRequest,
    BookingStatus.completed,
    BookingStatus.cancelled,
    BookingStatus.replaced,
  ];

  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _set(HistoryFilter f) => setState(() => _filter = f);

  Widget _drop<T>(
    String key,
    String label,
    T? value,
    List<(T, String)> items,
    void Function(T?) onChanged,
  ) {
    final l10n = AppLocalizations.of(context);
    return DropdownButton<T?>(
      key: Key(key),
      value: value,
      onChanged: onChanged,
      items: [
        DropdownMenuItem<T?>(child: Text('$label: ${l10n.historyFilterAll}')),
        for (final (v, t) in items)
          DropdownMenuItem<T?>(value: v, child: Text(t)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = _filter;
    final value = ref.watch(historyProvider(f));
    final summary = ref.watch(historySummaryProvider(f)).asData?.value;
    final categories = ref.watch(categoriesProvider).value ?? const [];
    final year = ref.read(nowProvider)().year;
    return Scaffold(
      backgroundColor: AppColors.canvasCool,
      body: Column(
        children: [
          SnHeader(
            title: l10n.historyTitle,
            onBack: () =>
                context.canPop() ? context.pop() : context.go(Routes.account),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              0,
            ),
            child: TextField(
              key: const Key('history_search_field'),
              controller: _search,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l10n.historySearchHint,
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (v) {
                _debounce?.cancel();
                _debounce = Timer(
                  const Duration(milliseconds: 400),
                  () => _set(_filter.copyWith(search: v)),
                );
              },
              onSubmitted: (v) {
                _debounce?.cancel();
                _set(f.copyWith(search: v));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                spacing: AppSpacing.md,
                children: [
                  _drop<int>(
                    'history_year_filter',
                    l10n.historyFilterYear,
                    f.year,
                    [for (var y = year; y > year - 5; y--) (y, '$y')],
                    (v) => _set(f.copyWith(year: () => v)),
                  ),
                  _drop<String>(
                    'history_category_filter',
                    l10n.historyFilterCategory,
                    f.category,
                    [for (final c in categories) (c.id, c.name)],
                    (v) => _set(f.copyWith(category: () => v)),
                  ),
                  _drop<BookingStatus>(
                    'history_status_filter',
                    l10n.historyFilterStatus,
                    f.status,
                    [
                      for (final s in _statuses)
                        (s, bookingStatusLabel(l10n, s)),
                    ],
                    (v) => _set(f.copyWith(status: () => v)),
                  ),
                ],
              ),
            ),
          ),
          if (summary != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                0,
              ),
              child: SnCard(
                tinted: true,
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    l10n.historySummaryLine(
                      summary.totalServices,
                      summary.distinctWorkers,
                      summary.currency == 'INR'
                          ? formatRupees(summary.totalSpent)
                          : '${summary.currency} ${summary.totalSpent}',
                    ),
                    key: const Key('history_summary'),
                    style: AppText.card,
                  ),
                ),
              ),
            ),
          Expanded(child: _list(l10n, value)),
        ],
      ),
    );
  }

  Widget _list(AppLocalizations l10n, AsyncValue<PagedState<Booking>> value) {
    final f = _filter;
    final filtered =
        f.year != null ||
        f.category != null ||
        f.status != null ||
        f.search.trim().isNotEmpty;
    return AsyncValueView(
      value: value,
      onRetry: () => ref.invalidate(historyProvider(f)),
      isEmpty: (s) => s.items.isEmpty,
      empty: SnEmptyState(
        title: filtered ? l10n.historyNoMatch : l10n.historyEmptyTitle,
        message: filtered ? '' : l10n.historyEmptyBody,
      ),
      data: (s) {
        final scale = ref.watch(ratingScaleMaxProvider).value ?? 5;
        // The live backend sends `rating` on each booking. The dev mock does not, so it reads the
        // mock ratings instead.
        final live = ref.watch(mockApiProvider.select((m) => m.live));
        final mine = live
            ? const <String, Rating>{}
            : ref.watch(myRatingsProvider).asData?.value ?? const {};
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
              ..invalidate(historySummaryProvider(f))
              ..invalidate(historyProvider(f));
            try {
              await ref.read(historyProvider(f).future);
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
                      style: AppText.heading,
                    ),
                  ),
                  for (final b in items)
                    _Card(
                      booking: b,
                      score: b.ratingScore ?? mine[b.id]?.score,
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
                      ref.read(historyProvider(f).notifier).loadMore(),
                ),
            ],
          ),
        );
      },
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
    final locale = Localizations.localeOf(context).toString();
    final b = booking;
    final canRate = score == null && b.actions.contains(BookingAction.rate);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: SnCard(
        key: Key('history_card_${b.id}'),
        onTap: () =>
            context.push(Routes.path(Routes.bookingDetail, {'id': b.id})),
        child: SizedBox(
          width: double.infinity,
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
                    style: AppText.card,
                  ),
                  SnBadge(
                    label: bookingStatusLabel(l10n, b.status),
                    tone: bookingStatusTone(b.status),
                  ),
                ],
              ),
              if (b.identity != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    b.identity!.displayName,
                    key: Key('history_worker_${b.id}'),
                    style: AppText.bodyLarge,
                  ),
                ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                [
                  if (b.startDate != null) formatDate(b.startDate!, locale),
                  ?b.areaName,
                ].join(' · '),
                style: AppText.meta,
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
              if (b.actions.contains(BookingAction.rebook))
                Align(
                  alignment: Alignment.centerLeft,
                  child: HireAgainButton(
                    bookingId: b.id,
                    variant: SnButtonVariant.text,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
