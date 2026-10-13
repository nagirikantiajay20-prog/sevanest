import 'package:sevanest_customer/core/widgets/sn_badge.dart';
import 'package:sevanest_customer/features/payment/domain/payment.dart';
import 'package:sevanest_customer/features/service_discovery/domain/budget.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// "₹499" or "₹499.50" from paise.
String paymentAmount(Payment p) {
  final paise = p.amountMinor % 100;
  final rupees = formatRupees(p.amountMinor ~/ 100);
  return paise == 0 ? rupees : '$rupees.${paise.toString().padLeft(2, '0')}';
}

String paymentStatusLabel(AppLocalizations l, PaymentStatus s) => switch (s) {
  PaymentStatus.created => l.txnStatusCreated,
  PaymentStatus.pending => l.txnStatusPending,
  PaymentStatus.succeeded => l.txnStatusSucceeded,
  PaymentStatus.failed => l.txnStatusFailed,
  PaymentStatus.refundPending => l.txnStatusRefundPending,
  PaymentStatus.refunded => l.txnStatusRefunded,
  PaymentStatus.refundFailed => l.txnStatusRefundFailed,
  PaymentStatus.unknown => l.txnStatusUnknown,
};

SnBadgeTone paymentStatusTone(PaymentStatus s) => switch (s) {
  PaymentStatus.succeeded || PaymentStatus.refunded => SnBadgeTone.success,
  PaymentStatus.pending ||
  PaymentStatus.created ||
  PaymentStatus.refundPending => SnBadgeTone.warning,
  PaymentStatus.failed || PaymentStatus.refundFailed => SnBadgeTone.error,
  PaymentStatus.unknown => SnBadgeTone.neutral,
};
