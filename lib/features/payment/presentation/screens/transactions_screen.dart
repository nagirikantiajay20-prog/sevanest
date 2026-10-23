import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/core/widgets/async_value_view.dart';
import 'package:sevanest_customer/core/widgets/sn_badge.dart';
import 'package:sevanest_customer/core/widgets/sn_card.dart';
import 'package:sevanest_customer/core/widgets/sn_chip.dart';
import 'package:sevanest_customer/core/widgets/sn_header.dart';
import 'package:sevanest_customer/core/widgets/sn_states.dart';
import 'package:sevanest_customer/features/payment/domain/payment.dart';
import 'package:sevanest_customer/features/payment/presentation/payment_labels.dart';
import 'package:sevanest_customer/features/payment/presentation/providers/payment_providers.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/schedule_format.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/paged_footer.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';
import 'package:sevanest_customer/shared/models/paged_state.dart';

/// `/transactions` (module 09, screen 9.3): the customer's payments, newest first. The backend
/// has no `/transactions` route; this is `GET /payments`.
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
    final labels = {
      TransactionFilter.all: l10n.txnFilterAll,
      TransactionFilter.paid: l10n.txnFilterPaid,
      TransactionFilter.refunded: l10n.txnFilterRefunded,
    };
    return Scaffold(
      backgroundColor: AppColors.canvasCool,
      body: Column(
        children: [
          SnHeader(
            title: l10n.transactionsTitle,
            onBack: () =>
                context.canPop() ? context.pop() : context.go(Routes.account),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final f in TransactionFilter.values)
                  SnChip(
                    key: Key('txn_filter_${f.name}'),
                    label: labels[f]!,
                    selected: filter == f,
                    onTap: () =>
                        ref.read(transactionFilterProvider.notifier).set(f),
                  ),
              ],
            ),
          ),
          Expanded(
            child: AsyncValueView<PagedState<Payment>>(
              value: ref.watch(transactionListProvider),
              onRetry: notifier.refresh,
              isEmpty: (p) => p.items.isEmpty,
              empty: SnEmptyState(
                title: l10n.transactionsEmpty,
                message: l10n.transactionsEmptyBody,
              ),
              data: (p) => RefreshIndicator(
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
                  itemCount: p.items.length + 1,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (_, i) => i == p.items.length
                      ? PagedFooter(
                          page: p,
                          onRetry: notifier.loadMore,
                          retryKey: const Key('txn_load_more_retry_btn'),
                        )
                      : _Row(p.items[i], locale),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.p, this.locale);
  final Payment p;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final when = p.paidAt ?? p.createdAt;
    return SnCard(
      key: Key('txn_row_${p.id}'),
      onTap: () =>
          context.push(Routes.path(Routes.transactionDetail, {'id': p.id})),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.txnRowTitle, style: AppText.card),
                if (when != null)
                  Text(formatDate(when, locale), style: AppText.meta),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(paymentAmount(p), style: AppText.card),
              const SizedBox(height: AppSpacing.xs),
              SnBadge(
                label: paymentStatusLabel(l10n, p.status),
                tone: paymentStatusTone(p.status),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// `/transactions/:id` (module 09, screen 9.4): the receipt, rendered from
/// `GET /payments/{id}/receipt` once the payment has succeeded (there is no PDF yet) and from the
/// payment itself otherwise or when the receipt cannot be read.
class TransactionDetailScreen extends ConsumerWidget {
  const TransactionDetailScreen({required this.paymentId, super.key});
  final String paymentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    return Scaffold(
      backgroundColor: AppColors.canvasCool,
      body: Column(
        children: [
          SnHeader(
            title: l10n.receiptTitle,
            onBack: () => context.canPop()
                ? context.pop()
                : context.go(Routes.transactions),
          ),
          Expanded(
            child: AsyncValueView<Payment>(
              value: ref.watch(paymentProvider(paymentId)),
              onRetry: () => ref.invalidate(paymentProvider(paymentId)),
              data: (p) {
                final r = p.wasPaid
                    ? ref.watch(receiptProvider(paymentId)).value
                    : null;
                final paidAt = r?.paidAt ?? p.paidAt;
                final method = paymentMethodText(
                  l10n,
                  r?.paymentMethod ?? p.paymentMethod,
                  r?.paymentMethodDetail ?? p.paymentMethodDetail,
                );
                final reference = r?.gatewayReference ?? p.gatewayReference;
                final refundedAt = r?.refundedAt ?? p.refundedAt;
                Widget row(String label, Widget v) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 130,
                        child: Text(label, style: AppText.meta),
                      ),
                      Expanded(child: v),
                    ],
                  ),
                );
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        paymentAmount(p),
                        key: const Key('txn_amount'),
                        style: AppText.display,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: SnBadge(
                          label: paymentStatusLabel(l10n, p.status),
                          tone: paymentStatusTone(p.status),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SnCard(
                        child: Column(
                          children: [
                            row(
                              l10n.txnReceiptRow,
                              Text(
                                r?.receiptNumber ??
                                    p.receiptNumber ??
                                    l10n.txnNoReceipt,
                              ),
                            ),
                            if (paidAt != null)
                              row(
                                l10n.txnPaidOnRow,
                                Text(
                                  '${formatDate(paidAt, locale)}, ${formatTime(paidAt.toLocal().hour * 60 + paidAt.toLocal().minute)}',
                                ),
                              ),
                            if (method != null)
                              row(
                                l10n.txnMethodRow,
                                Text(method, key: const Key('txn_method')),
                              ),
                            if (reference != null)
                              row(
                                l10n.txnReferenceRow,
                                SelectableText(
                                  reference,
                                  key: const Key('txn_reference'),
                                ),
                              ),
                            if (refundedAt != null)
                              row(
                                l10n.txnRefundedOnRow,
                                Text(formatDate(refundedAt, locale)),
                              ),
                          ],
                        ),
                      ),
                      if (p.wasRefunded) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          l10n.txnRefundNote,
                          key: const Key('txn_refund_note'),
                          style: AppText.bodyLarge,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      TextButton(
                        key: const Key('txn_booking_link'),
                        onPressed: () => context.push(
                          Routes.path(Routes.bookingDetail, {
                            'id': p.bookingId,
                          }),
                        ),
                        child: Text(l10n.payViewBooking),
                      ),
                      TextButton(
                        key: const Key('txn_support_btn'),
                        onPressed: () => context.push(
                          '${Routes.supportNew}?paymentId=${Uri.encodeComponent(p.id)}',
                        ),
                        child: Text(l10n.txnNeedHelp),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
