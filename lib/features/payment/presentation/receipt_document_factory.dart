import 'package:intl/intl.dart';
import 'package:sevanest_customer/features/booking/domain/booking.dart';
import 'package:sevanest_customer/features/payment/domain/payment.dart';
import 'package:sevanest_customer/features/payment/domain/receipt_document.dart';
import 'package:sevanest_customer/features/payment/presentation/payment_labels.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/engagement_labels.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/schedule_format.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// "Wed, 4 Nov, 4:05 PM": how the Receipt screen shows when the payment happened.
String receiptPaidText(DateTime paidAt, String locale) {
  final t = paidAt.toLocal();
  return '${formatDate(t, locale)}, ${formatTime(t.hour * 60 + t.minute)}';
}

/// The PDF's content, from the same payment / receipt / booking the screen renders. Returns null
/// when there is nothing to print: the payment has not been paid, or no receipt number exists.
/// Values the backend did not send are left out rather than invented.
ReceiptDocument? buildReceiptDocument(
  AppLocalizations l10n,
  String locale, {
  required Payment payment,
  Receipt? receipt,
  Booking? booking,
}) {
  final number = receipt?.receiptNumber ?? payment.receiptNumber;
  if (!payment.wasPaid || number == null) return null;
  final amountMinor = receipt?.amountMinor ?? payment.amountMinor;
  final paidAt = receipt?.paidAt ?? payment.paidAt;
  final method = paymentMethodText(
    l10n,
    receipt?.paymentMethod ?? payment.paymentMethod,
    receipt?.paymentMethodDetail ?? payment.paymentMethodDetail,
  );
  final reference = receipt?.gatewayReference ?? payment.gatewayReference;
  final engagement = booking?.engagement == null
      ? null
      : engagementLabels(l10n, booking!.engagement!).name;
  final start = booking?.startDate;
  final rows = <({String label, String value})>[
    (label: l10n.txnReceiptRow, value: number),
    (label: l10n.pdfStatusRow, value: paymentStatusLabel(l10n, payment.status)),
    if (booking?.identity?.displayName != null)
      (label: l10n.pdfWorkerRow, value: booking!.identity!.displayName),
    if (booking?.categoryName != null)
      (label: l10n.pdfServiceRow, value: booking!.categoryName!),
    if (paidAt != null)
      (
        label: l10n.txnPaidOnRow,
        value: DateFormat(
          'd MMM yyyy, h:mm a',
          locale,
        ).format(paidAt.toLocal()),
      ),
    if (method != null) (label: l10n.txnMethodRow, value: method),
    if (reference != null) (label: l10n.txnReferenceRow, value: reference),
    if (engagement != null) (label: l10n.pdfBookingTypeRow, value: engagement),
    if (start != null)
      (
        label: l10n.pdfStartDateRow,
        value: DateFormat('EEE, d MMM yyyy', locale).format(start),
      ),
  ];
  return ReceiptDocument(
    heading: l10n.pdfReceiptHeading,
    receiptNumber: number,
    statusLabel: paymentStatusLabel(l10n, payment.status),
    amountLabel: l10n.pdfTotalPaid,
    amount: minorAmount(amountMinor),
    rows: rows,
    footer: l10n.pdfFooter,
  );
}
