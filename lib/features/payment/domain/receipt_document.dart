import 'package:sevanest_customer/core/storage/receipt_files.dart';

/// Everything the receipt PDF prints, already formatted and localised. Built from the same
/// backend data as the Receipt screen (see `buildReceiptDocument`), so the file and the screen
/// can never disagree. Pure data: no Flutter, no I/O.
class ReceiptDocument {
  const ReceiptDocument({
    required this.heading,
    required this.receiptNumber,
    required this.statusLabel,
    required this.amountLabel,
    required this.amount,
    required this.rows,
    required this.footer,
  });

  final String heading;
  final String receiptNumber;
  final String statusLabel;
  final String amountLabel;
  final String amount;

  /// Label / value pairs in print order; missing backend values are simply left out.
  final List<({String label, String value})> rows;
  final String footer;

  /// `SevaNest_Receipt_RCPT-XXXXXXXX.pdf`; anything unsafe in the number is replaced.
  String get fileName =>
      '$receiptFilePrefix${receiptNumber.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_')}.pdf';
}
