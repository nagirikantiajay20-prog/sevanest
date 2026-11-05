import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sevanest_customer/features/payment/data/receipt_pdf_builder.dart';
import 'package:sevanest_customer/features/payment/domain/payment.dart';
import 'package:sevanest_customer/features/payment/domain/receipt_document.dart';
import 'package:sevanest_customer/features/payment/presentation/receipt_document_factory.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

ByteData _font(String name) =>
    ByteData.sublistView(File('assets/fonts/$name').readAsBytesSync());

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppLocalizations l10n;
  setUpAll(() async {
    await initializeDateFormatting('en');
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  Payment payment({PaymentStatus status = PaymentStatus.succeeded}) => Payment(
    id: 'pay_1',
    bookingId: 'bk_1',
    status: status,
    amountMinor: 149950,
    receiptNumber: 'RCPT-00012345',
    paidAt: DateTime.utc(2026, 11, 4, 10, 35),
    paymentMethod: PaymentMethod.upi,
    paymentMethodDetail: 'ab***@okhdfc',
    gatewayReference: 'pay_QX12abCD34',
  );

  group('buildReceiptDocument', () {
    test('carries the receipt data and a safe file name', () {
      final doc = buildReceiptDocument(l10n, 'en', payment: payment())!;
      expect(doc.receiptNumber, 'RCPT-00012345');
      expect(doc.fileName, 'SevaNest_Receipt_RCPT-00012345.pdf');
      expect(doc.amount, '₹1,499.50');
      expect(doc.statusLabel, l10n.txnStatusSucceeded);
      final values = doc.rows.map((r) => r.value);
      expect(values, contains('pay_QX12abCD34'));
      expect(values, contains('UPI · ab***@okhdfc'));
    });

    test('the receipt endpoint wins over the payment where both exist', () {
      const r = Receipt(
        receiptNumber: 'RCPT-9',
        paymentId: 'pay_1',
        bookingId: 'bk_1',
        amountMinor: 50000,
        gatewayReference: 'pay_FROM_RECEIPT',
      );
      final doc = buildReceiptDocument(
        l10n,
        'en',
        payment: payment(),
        receipt: r,
      )!;
      expect(doc.receiptNumber, 'RCPT-9');
      expect(doc.amount, '₹500');
      expect(doc.rows.map((e) => e.value), contains('pay_FROM_RECEIPT'));
    });

    test('nothing to print before payment or without a receipt number', () {
      expect(
        buildReceiptDocument(
          l10n,
          'en',
          payment: payment(status: PaymentStatus.pending),
        ),
        isNull,
      );
      expect(
        buildReceiptDocument(
          l10n,
          'en',
          payment: const Payment(
            id: 'p',
            bookingId: 'b',
            status: PaymentStatus.succeeded,
            amountMinor: 100,
          ),
        ),
        isNull,
      );
    });

    test('a refunded payment still has its receipt', () {
      expect(
        buildReceiptDocument(
          l10n,
          'en',
          payment: payment(status: PaymentStatus.refunded),
        ),
        isNotNull,
      );
    });

    test('missing backend values are omitted, not invented', () {
      final doc = buildReceiptDocument(
        l10n,
        'en',
        payment: const Payment(
          id: 'p',
          bookingId: 'b',
          status: PaymentStatus.succeeded,
          amountMinor: 100,
          receiptNumber: 'RCPT-1',
        ),
      )!;
      expect(doc.rows.map((r) => r.label), [
        l10n.txnReceiptRow,
        l10n.pdfStatusRow,
      ]);
    });
  });

  group('buildReceiptPdf', () {
    test('renders a valid PDF with Inter and Source Serif', () async {
      final doc = buildReceiptDocument(l10n, 'en', payment: payment())!;
      final bytes = await buildReceiptPdf(
        doc,
        sans: _font('Inter.ttf'),
        serif: _font('SourceSerif4.ttf'),
        logo: File('assets/branding/logo_full.png').readAsBytesSync(),
      );
      expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
      expect(bytes.length, greaterThan(5000));
      final out = Platform.environment['RECEIPT_PDF_OUT'];
      if (out != null) File(out).writeAsBytesSync(bytes);
    });

    test('file name strips unsafe characters', () {
      const doc = ReceiptDocument(
        heading: 'h',
        receiptNumber: 'RCPT/../1 2',
        statusLabel: 's',
        amountLabel: 'a',
        amount: '₹1',
        rows: [],
        footer: 'f',
      );
      expect(doc.fileName, 'SevaNest_Receipt_RCPT_.._1_2.pdf');
    });
  });
}
