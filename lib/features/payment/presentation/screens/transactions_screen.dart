import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/core/widgets/async_value_view.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart'
    show authSerif;
import 'package:sevanest_customer/features/booking/presentation/providers/booking_providers.dart';
import 'package:sevanest_customer/features/payment/domain/payment.dart';
import 'package:sevanest_customer/features/payment/presentation/payment_labels.dart';
import 'package:sevanest_customer/features/payment/presentation/providers/payment_providers.dart';
import 'package:sevanest_customer/features/payment/presentation/widgets/transaction_parts.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/schedule_format.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_page.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_parts.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/paged_footer.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';
import 'package:sevanest_customer/shared/models/paged_state.dart';

/// `/transactions` (module 09, screen 9.3): the customer's payments, newest first, grouped by
/// month. The backend has no `/transactions` route; this is `GET /payments`.
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _State();
}

class _State extends ConsumerState<TransactionsScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 300) {
        ref.read(transactionListProvider.notifier).loadMore();
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
    final notifier = ref.read(transactionListProvider.notifier);
    final filter = ref.watch(transactionFilterProvider);
    return FindGlassPage(
      title: l10n.transactionsTitle,
      backLabel: l10n.back,
      onBack: () =>
          context.canPop() ? context.pop() : context.go(Routes.account),
      body: AsyncValueView<PagedState<Payment>>(
        value: ref.watch(transactionListProvider),
        onRetry: notifier.refresh,
        isEmpty: (p) =>
            p.items.isEmpty && filter == TransactionFilter.all && !p.hasMore,
        empty: GlassEmpty(
          icon: Icons.account_balance_wallet_outlined,
          iconColor: AppColors.teal,
          discColors: const [AppColors.pillActive, AppColors.surface],
          title: l10n.transactionsEmpty,
          body: l10n.transactionsEmptyBody,
          actionLabel: l10n.bookingsFind,
          actionKey: const Key('txn_empty_find_btn'),
          onAction: () => context.push(Routes.discoverCategory),
        ),
        data: (p) => RefreshIndicator(
          onRefresh: notifier.refresh,
          child: ListView(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
            children: [
              DiscoverRise(
                delayMs: 0,
                child: TxnFilterChips(
                  labels: [
                    l10n.txnFilterAll,
                    l10n.txnFilterPaid,
                    l10n.txnFilterRefunded,
                  ],
                  selected: filter.index,
                  keyOf: (i) =>
                      Key('txn_filter_${TransactionFilter.values[i].name}'),
                  onChanged: (i) => ref
                      .read(transactionFilterProvider.notifier)
                      .set(TransactionFilter.values[i]),
                ),
              ),
              ..._list(context, l10n, locale, p, filter, notifier),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _list(
    BuildContext context,
    AppLocalizations l10n,
    String locale,
    PagedState<Payment> p,
    TransactionFilter filter,
    TransactionListNotifier notifier,
  ) {
    if (p.items.isEmpty) {
      // A filter with no match: say so, the chips stay to switch back.
      return [
        const SizedBox(height: 60),
        Center(child: Text(l10n.transactionsEmpty, style: authSerif(22, 1.2))),
      ];
    }
    // The total is only honest when every page is loaded.
    final paid = p.items
        .where((x) => x.status == PaymentStatus.succeeded)
        .fold<int>(0, (a, x) => a + x.amountMinor);
    final out = <Widget>[];
    if (filter != TransactionFilter.refunded && !p.hasMore) {
      out.add(
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: DiscoverRise(
            delayMs: 60,
            child: TxnTotalCard(
              label: l10n.txnTotalPaid,
              amount: minorAmount(paid),
            ),
          ),
        ),
      );
    }
    String? month;
    for (final x in p.items) {
      final when = (x.paidAt ?? x.createdAt)?.toLocal();
      final m = when == null ? '' : DateFormat.yMMMM(locale).format(when);
      if (m != month) {
        month = m;
        if (m.isNotEmpty) out.add(TxnMonthHeader(m));
      }
      out.add(_Row(x, locale));
    }
    out.add(
      PagedFooter(
        page: p,
        onRetry: notifier.loadMore,
        retryKey: const Key('txn_load_more_retry_btn'),
      ),
    );
    return out;
  }
}

class _Row extends ConsumerWidget {
  const _Row(this.p, this.locale);
  final Payment p;
  final String locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final when = p.paidAt ?? p.createdAt;
    // Who it was for comes from the booking; the generic title shows until it loads.
    final booking = ref.watch(bookingProvider(p.bookingId)).value;
    final method = p.paymentMethod == null
        ? null
        : paymentMethodLabel(l10n, p.paymentMethod!);
    return KeyedSubtree(
      key: Key('txn_row_${p.id}'),
      child: TxnTile(
        title: paymentTitle(booking, l10n.txnRowTitle),
        meta: [if (when != null) formatDate(when, locale), ?method].join(' · '),
        amount: paymentAmount(p),
        status: p.status,
        statusLabel: paymentStatusLabel(l10n, p.status),
        onTap: () =>
            context.push(Routes.path(Routes.transactionDetail, {'id': p.id})),
      ),
    );
  }
}
