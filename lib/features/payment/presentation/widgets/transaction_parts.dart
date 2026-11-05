import 'package:flutter/material.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart'
    show authSerif;
import 'package:sevanest_customer/features/booking/domain/booking.dart';
import 'package:sevanest_customer/features/interview_trial/presentation/widgets/interview_detail_parts.dart'
    show DashedRule;
import 'package:sevanest_customer/features/payment/domain/payment.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_page.dart'
    show SheenSweep;
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_parts.dart'
    show GlassAvatar;

/// Building blocks of "Transactions" (design 9.3) and "Receipt" (9.4).

const _teal = AppColors.teal;

/// Accent bar, badge background and badge text of a payment status.
({Color bar, Color bg, Color fg}) txnTone(PaymentStatus s) => switch (s) {
  PaymentStatus.succeeded => (
    bar: _teal,
    bg: AppColors.tealD6EFEA,
    fg: AppColors.teal0B5A53,
  ),
  PaymentStatus.pending ||
  PaymentStatus.created ||
  PaymentStatus.refundPending => (
    bar: AppColors.amber,
    bg: AppColors.warnBg,
    fg: AppColors.orange8A4B06,
  ),
  PaymentStatus.refunded => (
    bar: AppColors.blue600,
    bg: AppColors.blue100,
    fg: AppColors.blue800,
  ),
  PaymentStatus.failed || PaymentStatus.refundFailed => (
    bar: AppColors.rose600,
    bg: AppColors.rose100,
    fg: AppColors.rose800,
  ),
  PaymentStatus.unknown => (bar: dsMuted, bg: AppColors.hairline, fg: dsText),
};

/// "House Maid · Sunita K." from the booking, or [fallback] while it has not loaded.
String paymentTitle(Booking? b, String fallback) {
  final parts = [?b?.categoryName, ?b?.identity?.displayName];
  return parts.isEmpty ? fallback : parts.join(' · ');
}

/// Coloured status pill with its dot.
class TxnBadge extends StatelessWidget {
  const TxnBadge({required this.label, required this.status, super.key});
  final String label;
  final PaymentStatus status;

  @override
  Widget build(BuildContext context) {
    final t = txnTone(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: t.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: t.fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppText.body.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: t.fg,
            ),
          ),
        ],
      ),
    );
  }
}

/// Filter pills: the selected one is navy.
class TxnFilterChips extends StatelessWidget {
  const TxnFilterChips({
    required this.labels,
    required this.selected,
    required this.keyOf,
    required this.onChanged,
    super.key,
  });
  final List<String> labels;
  final int selected;
  final Key Function(int) keyOf;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final (i, l) in labels.indexed) ...[
        if (i > 0) const SizedBox(width: 8),
        Expanded(
          child: Semantics(
            button: true,
            selected: i == selected,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              decoration: BoxDecoration(
                color: i == selected ? dsNavy : AppColors.whiteA80xCC,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: i == selected ? dsNavy : dsNavy.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  key: keyOf(i),
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => onChanged(i),
                  child: SizedBox(
                    height: 44,
                    child: Center(
                      child: Text(
                        l,
                        style: AppText.body.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: i == selected ? AppColors.surface : dsNavy,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ],
  );
}

/// Glass "Total paid" strip.
class TxnTotalCard extends StatelessWidget {
  const TxnTotalCard({required this.label, required this.amount, super.key});
  final String label;
  final String amount;

  @override
  Widget build(BuildContext context) => DiscoverGlass(
    radius: 24,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppText.body.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: dsMuted,
                  ),
                ),
                Text(amount, style: authSerif(26, 1.1)),
              ],
            ),
          ),
          const Icon(
            Icons.account_balance_wallet_outlined,
            size: 30,
            color: _teal,
          ),
        ],
      ),
    ),
  );
}

/// "OCTOBER 2026" group heading.
class TxnMonthHeader extends StatelessWidget {
  const TxnMonthHeader(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 20, 2, 0),
    child: Semantics(
      header: true,
      child: Text(
        text.toUpperCase(),
        style: AppText.body.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: dsMuted,
        ),
      ),
    ),
  );
}

/// One payment: coloured edge bar, who and when, status pill, amount.
class TxnTile extends StatelessWidget {
  const TxnTile({
    required this.title,
    required this.meta,
    required this.amount,
    required this.status,
    required this.statusLabel,
    required this.onTap,
    super.key,
  });
  final String title;
  final String meta;
  final String amount;
  final PaymentStatus status;
  final String statusLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tone = txnTone(status);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: DiscoverGlass(
        radius: 22,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 14,
                  bottom: 14,
                  width: 4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: tone.bar,
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(4),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: AppText.body.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                height: 1.25,
                                color: dsNavy,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              meta,
                              style: AppText.body.copyWith(
                                fontSize: 13,
                                color: dsMuted,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TxnBadge(label: statusLabel, status: status),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        amount,
                        style: authSerif(21, 1.2).copyWith(
                          color: status == PaymentStatus.failed
                              ? AppColors.slate400
                              : dsNavy,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Top half of the receipt: navy ticket with the worker, status, amount and what it was for.
class ReceiptHero extends StatelessWidget {
  const ReceiptHero({
    required this.name,
    required this.gradient,
    required this.statusLabel,
    required this.status,
    required this.amount,
    required this.subtitle,
    this.amountKey,
    super.key,
  });
  final String name;
  final List<Color> gradient;
  final String statusLabel;
  final PaymentStatus status;
  final String amount;
  final String subtitle;
  final Key? amountKey;

  @override
  Widget build(BuildContext context) {
    final refund =
        status == PaymentStatus.refunded ||
        status == PaymentStatus.refundPending ||
        status == PaymentStatus.refundFailed;
    final tone = txnTone(status);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            dsNavy,
            refund ? AppColors.blue800 : AppColors.actionDeepTeal,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: dsNavy.withValues(alpha: 0.3),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GlassAvatar(
                    title: name,
                    gradient: gradient,
                    size: 52,
                    fontSize: 18,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.body.copyWith(
                            fontSize: 16,
                            height: 1.25,
                            fontWeight: FontWeight.w700,
                            color: AppColors.surface,
                          ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.body.copyWith(
                              fontSize: 13.5,
                              height: 1.3,
                              fontWeight: FontWeight.w500,
                              color: AppColors.surface.withValues(alpha: 0.82),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: tone.bg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_rounded, size: 14, color: tone.fg),
                            const SizedBox(width: 4),
                            Text(
                              statusLabel,
                              style: AppText.body.copyWith(
                                fontSize: 12.5,
                                height: 1.2,
                                fontWeight: FontWeight.w700,
                                color: tone.fg,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 128),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            amount,
                            key: amountKey,
                            style: authSerif(
                              30,
                              1,
                            ).copyWith(color: AppColors.surface),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SheenSweep(periodMs: 5000, band: 0.3),
          ],
        ),
      ),
    );
  }
}

/// One receipt line: teal icon disc, label over value, optional "Copy" pill.
class ReceiptRow {
  const ReceiptRow(
    this.icon,
    this.label,
    this.value, {
    this.note,
    this.onCopy,
    this.copyLabel,
    this.copyHint,
    this.valueKey,
  });
  final IconData icon;
  final String label;
  final String value;
  final String? note;
  final VoidCallback? onCopy;
  final String? copyLabel;
  final String? copyHint;
  final Key? valueKey;
}

/// Bottom half of the receipt: perforated glass strip holding [rows] split by dashed rules.
class ReceiptBody extends StatelessWidget {
  const ReceiptBody({required this.rows, super.key});
  final List<ReceiptRow> rows;

  static const _ivory = AppColors.grayF7F4EE;

  @override
  Widget build(BuildContext context) {
    Widget notch(bool left) => Positioned(
      top: 1,
      left: left ? -11 : null,
      right: left ? null : -11,
      child: Container(
        width: 20,
        height: 20,
        decoration: const BoxDecoration(color: _ivory, shape: BoxShape.circle),
      ),
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        DiscoverGlass(
          corners: const BorderRadius.vertical(bottom: Radius.circular(30)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 8, 4),
            child: Column(
              children: [
                for (final (i, r) in rows.indexed) ...[
                  if (i == 0)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 0),
                      child: SizedBox.shrink(),
                    )
                  else
                    const DashedRule(),
                  _RowTile(r),
                ],
              ],
            ),
          ),
        ),
        const Positioned(top: 11, left: 18, right: 18, child: DashedRule()),
        notch(true),
        notch(false),
      ],
    );
  }
}

class _RowTile extends StatelessWidget {
  const _RowTile(this.r);
  final ReceiptRow r;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: AppColors.pillActive,
            shape: BoxShape.circle,
          ),
          child: Icon(r.icon, size: 16, color: _teal),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                r.label,
                style: AppText.body.copyWith(
                  fontSize: 12.5,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                  color: dsMuted,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                r.value,
                key: r.valueKey,
                style: AppText.body.copyWith(
                  fontSize: 15,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: dsNavy,
                ),
              ),
              if (r.note != null)
                Text(
                  r.note!,
                  style: AppText.body.copyWith(
                    fontSize: 13,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                    color: dsMuted,
                  ),
                ),
            ],
          ),
        ),
        // Fixed 40px slot so every value column ends at the same x, with or without Copy.
        SizedBox(
          width: 40,
          height: 40,
          child: r.onCopy == null
              ? null
              : IconButton(
                  onPressed: r.onCopy,
                  tooltip: r.copyLabel,
                  padding: EdgeInsets.zero,
                  color: _teal,
                  icon: const Icon(Icons.copy_rounded, size: 18),
                ),
        ),
      ],
    ),
  );
}

/// Blue "Refund on its way" box under the receipt.
class ReceiptRefundBox extends StatelessWidget {
  const ReceiptRefundBox({required this.title, required this.body, super.key});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('txn_refund_note'),
    width: double.infinity,
    margin: const EdgeInsets.only(top: 14),
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
    decoration: BoxDecoration(
      color: AppColors.blue100,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: AppColors.blue800.withValues(alpha: 0.3),
        width: 1.5,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppText.body.copyWith(
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
            color: AppColors.blue1E3A8A,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          body,
          style: AppText.body.copyWith(
            fontSize: 14.5,
            height: 1.45,
            color: AppColors.blue1E3A8A,
          ),
        ),
      ],
    ),
  );
}
