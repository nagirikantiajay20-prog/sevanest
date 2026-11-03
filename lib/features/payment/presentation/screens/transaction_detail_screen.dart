import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/core/widgets/async_value_view.dart';
import 'package:sevanest_customer/features/booking/domain/booking.dart';
import 'package:sevanest_customer/features/booking/presentation/providers/booking_providers.dart';
import 'package:sevanest_customer/features/payment/domain/payment.dart';
import 'package:sevanest_customer/features/payment/presentation/payment_labels.dart';
import 'package:sevanest_customer/features/payment/presentation/providers/payment_providers.dart';
import 'package:sevanest_customer/features/payment/presentation/widgets/payment_parts.dart';
import 'package:sevanest_customer/features/payment/presentation/widgets/transaction_parts.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/engagement_labels.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/schedule_format.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_page.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// `/transactions/:id` (module 09, screen 9.4): the receipt, rendered from
/// `GET /payments/{id}/receipt` once the payment has succeeded (there is no PDF yet) and from the
/// payment itself otherwise or when the receipt cannot be read. The bottom button copies the
/// receipt details as text, since there is no file to download.
class TransactionDetailScreen extends ConsumerStatefulWidget {
  const TransactionDetailScreen({required this.paymentId, super.key});
  final String paymentId;

  @override
  ConsumerState<TransactionDetailScreen> createState() => _DetailState();
}

class _DetailState extends ConsumerState<TransactionDetailScreen> {
  Future<void> _copy(String text, String done) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: text));
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(done)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final value = ref.watch(paymentProvider(widget.paymentId));
    final p = value.value;
    final r = p != null && p.wasPaid
        ? ref.watch(receiptProvider(widget.paymentId)).value
        : null;
    final booking = p == null
        ? null
        : ref.watch(bookingProvider(p.bookingId)).value;
    final receiptNo = r?.receiptNumber ?? p?.receiptNumber;
    final reference = r?.gatewayReference ?? p?.gatewayReference;
    final paidAt = (r?.paidAt ?? p?.paidAt)?.toLocal();
    final paidText = paidAt == null
        ? null
        : '${formatDate(paidAt, locale)}, '
              '${formatTime(paidAt.hour * 60 + paidAt.minute)}';
    final method = p == null
        ? null
        : paymentMethodText(
            l10n,
            r?.paymentMethod ?? p.paymentMethod,
            r?.paymentMethodDetail ?? p.paymentMethodDetail,
          );
    final refundedAt = r?.refundedAt ?? p?.refundedAt;

    return FindGlassPage(
      title: l10n.receiptTitle,
      backLabel: l10n.back,
      onBack: () =>
          context.canPop() ? context.pop() : context.go(Routes.transactions),
      body: AsyncValueView<Payment>(
        value: value,
        onRetry: () => ref.invalidate(paymentProvider(widget.paymentId)),
        data: (p) => RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(paymentProvider(widget.paymentId)),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
            child: Column(
              children: [
                DiscoverRise(
                  delayMs: 0,
                  child: Column(
                    children: [
                      ReceiptHero(
                        name:
                            booking?.identity?.displayName ?? l10n.txnRowTitle,
                        gradient: avatarGradientFor(booking?.workerId ?? p.id),
                        status: p.status,
                        statusLabel: paymentStatusLabel(l10n, p.status),
                        amount: paymentAmount(p),
                        amountKey: const Key('txn_amount'),
                        subtitle: paymentTitle(booking, ''),
                      ),
                      ReceiptBody(
                        rows: [
                          ReceiptRow(
                            Icons.receipt_long_outlined,
                            l10n.txnReceiptRow,
                            receiptNo ?? l10n.txnNoReceipt,
                            onCopy: receiptNo == null
                                ? null
                                : () => _copy(receiptNo, l10n.txnCopied),
                            copyLabel: l10n.txnCopy,
                          ),
                          if (paidText != null)
                            ReceiptRow(
                              Icons.calendar_today_outlined,
                              l10n.txnPaidOnRow,
                              paidText,
                            ),
                          if (method != null)
                            ReceiptRow(
                              Icons.smartphone_rounded,
                              l10n.txnMethodRow,
                              method,
                              valueKey: const Key('txn_method'),
                            ),
                          if (reference != null)
                            ReceiptRow(
                              Icons.tag_rounded,
                              l10n.txnReferenceRow,
                              reference,
                              valueKey: const Key('txn_reference'),
                              onCopy: () => _copy(reference, l10n.txnCopied),
                              copyLabel: l10n.txnCopy,
                            ),
                          if (refundedAt != null)
                            ReceiptRow(
                              Icons.undo_rounded,
                              l10n.txnRefundedOnRow,
                              formatDate(refundedAt, locale),
                            ),
                          if (booking != null)
                            ReceiptRow(
                              Icons.home_outlined,
                              l10n.txnBookingRow,
                              [
                                ?booking.categoryName,
                                if (booking.engagement != null)
                                  engagementLabels(
                                    l10n,
                                    booking.engagement!,
                                  ).name,
                              ].join(' · '),
                              note: booking.startDate == null
                                  ? null
                                  : '${l10n.payStartsRow} '
                                        '${formatDate(booking.startDate!, locale)}',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (p.wasRefunded)
                  DiscoverRise(
                    delayMs: 80,
                    child: ReceiptRefundBox(
                      title: l10n.txnRefundTitle(paymentAmount(p)),
                      body: '${l10n.txnRefundBody} ${l10n.txnRefundNote}',
                    ),
                  ),
                const SizedBox(height: 14),
                DiscoverRise(
                  delayMs: 160,
                  child: _LinkButton(
                    key: const Key('txn_booking_link'),
                    label: l10n.payViewBooking,
                    trailing: Icons.chevron_right_rounded,
                    onTap: () => context.push(
                      Routes.path(Routes.bookingDetail, {'id': p.bookingId}),
                    ),
                  ),
                ),
                DiscoverRise(
                  delayMs: 220,
                  child: _LinkButton(
                    key: const Key('txn_support_btn'),
                    label: l10n.txnNeedHelp,
                    quiet: true,
                    onTap: () => context.push(
                      '${Routes.supportNew}?paymentId=${Uri.encodeComponent(p.id)}',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottom: p == null
          ? null
          : PayButton(
              key: const Key('txn_copy_receipt_btn'),
              label: l10n.txnCopyReceipt,
              icon: Icons.copy_rounded,
              onPressed: () => _copy(
                _summary(
                  l10n,
                  locale,
                  p,
                  receiptNo,
                  paidText,
                  method,
                  reference,
                  booking,
                ),
                l10n.txnReceiptCopied,
              ),
            ),
    );
  }

  String _summary(
    AppLocalizations l10n,
    String locale,
    Payment p,
    String? receiptNo,
    String? paidText,
    String? method,
    String? reference,
    Booking? booking,
  ) => [
    '${l10n.receiptTitle}: ${paymentAmount(p)} (${paymentStatusLabel(l10n, p.status)})',
    if (booking != null) paymentTitle(booking, ''),
    if (receiptNo != null) '${l10n.txnReceiptRow}: $receiptNo',
    if (paidText != null) '${l10n.txnPaidOnRow}: $paidText',
    if (method != null) '${l10n.txnMethodRow}: $method',
    if (reference != null) '${l10n.txnReferenceRow}: $reference',
  ].where((e) => e.isNotEmpty).join('\n');
}

/// Full-width pill link under the receipt; [quiet] is a plain teal text link.
class _LinkButton extends StatelessWidget {
  const _LinkButton({
    required this.label,
    required this.onTap,
    this.trailing,
    this.quiet = false,
    super.key,
  });
  final String label;
  final VoidCallback onTap;
  final IconData? trailing;
  final bool quiet;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: quiet ? const Color(0xFF0F766E) : dsNavy,
          backgroundColor: quiet ? Colors.transparent : const Color(0xCCFFFFFF),
          side: quiet
              ? BorderSide.none
              : BorderSide(color: dsNavy.withValues(alpha: 0.22), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(child: Text(label, textAlign: TextAlign.center)),
            if (trailing != null) Icon(trailing, size: 20),
          ],
        ),
      ),
    ),
  );
}
