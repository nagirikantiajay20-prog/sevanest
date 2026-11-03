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
import 'package:sevanest_customer/features/booking/domain/booking.dart';
import 'package:sevanest_customer/features/booking/presentation/booking_labels.dart';
import 'package:sevanest_customer/features/booking/presentation/providers/booking_providers.dart';
import 'package:sevanest_customer/features/ratings/domain/rating.dart';
import 'package:sevanest_customer/features/ratings/presentation/providers/rating_providers.dart';
import 'package:sevanest_customer/features/service_discovery/domain/budget.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/catalog_providers.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/features/service_history/presentation/widgets/history_parts.dart';
import 'package:sevanest_customer/features/support/presentation/widgets/support_glass_parts.dart';
import 'package:sevanest_customer/features/worker_search/presentation/providers/worker_search_providers.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_page.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_parts.dart';
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

  Future<void> _refresh() async {
    final f = _filter;
    ref
      ..invalidate(myRatingsProvider)
      ..invalidate(historySummaryProvider(f))
      ..invalidate(historyProvider(f));
    try {
      await ref.read(historyProvider(f).future);
    } on Object {
      // shown by the view
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final value = ref.watch(historyProvider(_filter));
    return FindGlassPage(
      title: l10n.historyTitle,
      backLabel: l10n.back,
      onBack: () =>
          context.canPop() ? context.pop() : context.go(Routes.account),
      // The search box and the filters stay put while a new filter loads.
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
          children: [..._controls(l10n), ..._results(l10n, value)],
        ),
      ),
    );
  }

  /// Search, the three filters and the totals line.
  List<Widget> _controls(AppLocalizations l10n) {
    final f = _filter;
    final summary = ref.watch(historySummaryProvider(f)).asData?.value;
    final categories = ref.watch(categoriesProvider).value ?? const [];
    final year = ref.read(nowProvider)().year;
    return [
      Padding(
        padding: const EdgeInsets.only(top: 6),
        child: HistorySearchField(
          controller: _search,
          hint: l10n.historySearchHint,
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
        padding: const EdgeInsets.only(top: 10),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: 8,
            children: [
              HistoryFilterPill<int>(
                key: const Key('history_year_filter'),
                label: l10n.historyFilterYear,
                value: f.year,
                items: [for (var y = year; y > year - 5; y--) (y, '$y')],
                onChanged: (v) => _set(f.copyWith(year: () => v)),
              ),
              HistoryFilterPill<String>(
                key: const Key('history_category_filter'),
                label: l10n.historyFilterCategory,
                value: f.category,
                items: [for (final c in categories) (c.id, c.name)],
                onChanged: (v) => _set(f.copyWith(category: () => v)),
              ),
              HistoryFilterPill<BookingStatus>(
                key: const Key('history_status_filter'),
                label: l10n.historyFilterStatus,
                value: f.status,
                items: [
                  for (final s in _statuses) (s, bookingStatusLabel(l10n, s)),
                ],
                onChanged: (v) => _set(f.copyWith(status: () => v)),
              ),
            ],
          ),
        ),
      ),
      if (summary != null)
        SupportSection(
          child: Text(
            l10n.historySummaryLine(
              summary.totalServices,
              summary.distinctWorkers,
              summary.currency == 'INR'
                  ? formatRupees(summary.totalSpent)
                  : '${summary.currency} ${summary.totalSpent}',
            ),
            key: const Key('history_summary'),
            style: AppText.body.copyWith(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: dsNavy,
            ),
          ),
        ),
    ];
  }

  List<Widget> _results(
    AppLocalizations l10n,
    AsyncValue<PagedState<Booking>> value,
  ) {
    final f = _filter;
    if (!value.hasValue) {
      if (!value.hasError) {
        return [
          Semantics(
            label: l10n.loading,
            container: true,
            child: Column(
              key: const Key('glass_loading'),
              children: [
                for (var i = 0; i < 3; i++)
                  Container(
                    height: 92,
                    margin: const EdgeInsets.only(top: 14),
                    decoration: BoxDecoration(
                      color: const Color(0x99FFFFFF),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
              ],
            ),
          ),
        ];
      }
      return [
        SupportSection(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  failureMessage(l10n, value.error!),
                  style: AppText.body.copyWith(fontSize: 14.5, color: dsText),
                ),
              ),
              TextButton(
                key: const Key('error_retry_btn'),
                onPressed: () => ref.invalidate(historyProvider(f)),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ];
    }
    final s = value.requireValue;
    final filtered =
        f.year != null ||
        f.category != null ||
        f.status != null ||
        f.search.trim().isNotEmpty;
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
        s.items.where(
          (b) =>
              b.status == BookingStatus.cancelled ||
              b.status == BookingStatus.replaced,
        ),
      ),
    ];
    return [
      if (s.items.isEmpty)
        filtered
            ? SupportSection(
                child: Text(
                  l10n.historyNoMatch,
                  key: const Key('history_no_match'),
                  style: AppText.body.copyWith(fontSize: 15, color: dsText),
                ),
              )
            : SizedBox(
                height: 420,
                child: GlassEmpty(
                  icon: Icons.history_rounded,
                  iconColor: AppColors.teal,
                  discColors: const [Color(0xFFE2EEEC), Colors.white],
                  title: l10n.historyEmptyTitle,
                  body: l10n.historyEmptyBody,
                  actionLabel: l10n.repFindWorker,
                  actionKey: const Key('history_find_btn'),
                  onAction: () => context.go(Routes.discoverCategory),
                ),
              ),
      for (final (key, title, items) in sections)
        if (items.isNotEmpty) ...[
          HistoryHeading(title, key: Key('history_section_$key')),
          for (final b in items)
            HistoryCard(
              booking: b,
              score: b.ratingScore ?? mine[b.id]?.score,
              scale: scale,
            ),
        ],
      if (s.loadMoreError != null)
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Text(failureMessage(l10n, s.loadMoreError!)),
        ),
      if (s.hasMore || s.isLoadingMore)
        TextButton(
          key: const Key('history_load_more_btn'),
          onPressed: s.isLoadingMore
              ? null
              : () => ref.read(historyProvider(f).notifier).loadMore(),
          child: s.isLoadingMore
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                )
              : Text(l10n.attendanceLoadMore),
        ),
    ];
  }
}
