import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:sevanest_customer/features/payment/domain/receipt_document.dart';

/// Renders a [ReceiptDocument] to PDF bytes. Fonts and logo are passed in so this stays a pure
/// function (Inter carries the rupee sign, which the PDF built-in fonts lack).
Future<Uint8List> buildReceiptPdf(
  ReceiptDocument doc, {
  required ByteData sans,
  required ByteData serif,
  Uint8List? logo,
}) async {
  const navy = PdfColor.fromInt(0xFF1E3A5F);
  const teal = PdfColor.fromInt(0xFF0F766E);
  const muted = PdfColor.fromInt(0xFF64748B);
  const line = PdfColor.fromInt(0xFFE2E8F0);
  const wash = PdfColor.fromInt(0xFFF0FDFA);

  final sansFont = pw.Font.ttf(sans);
  final serifFont = pw.Font.ttf(serif);
  final logoImage = logo == null ? null : pw.MemoryImage(logo);

  pw.TextStyle sty(double size, PdfColor color, {pw.Font? font}) =>
      pw.TextStyle(font: font ?? sansFont, fontSize: size, color: color);

  final pdf = pw.Document(title: doc.fileName, author: 'SevaNest');
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(40, 40, 40, 36),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (logoImage != null)
                pw.SizedBox(height: 44, child: pw.Image(logoImage))
              else
                pw.Text('SevaNest', style: sty(26, navy, font: serifFont)),
              pw.Spacer(),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(doc.heading, style: sty(16, navy, font: serifFont)),
                  pw.SizedBox(height: 3),
                  pw.Text(doc.receiptNumber, style: sty(10.5, muted)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 22),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.fromLTRB(20, 18, 20, 18),
            decoration: pw.BoxDecoration(
              color: wash,
              borderRadius: pw.BorderRadius.circular(12),
              border: pw.Border.all(color: line),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(doc.amountLabel, style: sty(10.5, muted)),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        doc.amount,
                        style: sty(30, navy, font: serifFont),
                      ),
                    ],
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: pw.BoxDecoration(
                    color: teal,
                    borderRadius: pw.BorderRadius.circular(11),
                  ),
                  child: pw.Text(
                    doc.statusLabel,
                    style: sty(11, PdfColors.white),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 18),
          for (final (i, r) in doc.rows.indexed)
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 10),
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  top: i == 0
                      ? pw.BorderSide.none
                      : const pw.BorderSide(color: line),
                ),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(
                    width: 150,
                    child: pw.Text(r.label, style: sty(10.5, muted)),
                  ),
                  pw.Expanded(child: pw.Text(r.value, style: sty(11.5, navy))),
                ],
              ),
            ),
          pw.Spacer(),
          pw.Divider(color: line),
          pw.SizedBox(height: 6),
          pw.Text(doc.footer, style: sty(9, muted)),
        ],
      ),
    ),
  );
  return pdf.save();
}
