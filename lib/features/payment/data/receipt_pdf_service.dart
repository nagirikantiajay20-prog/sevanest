import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sevanest_customer/features/payment/data/receipt_pdf_builder.dart';
import 'package:sevanest_customer/features/payment/domain/receipt_document.dart';
import 'package:share_plus/share_plus.dart';

/// Builds, stores and shares receipt PDFs. Kept out of widgets and behind a provider so tests can
/// swap it. Files go to the app's external files folder (no storage permission needed on any
/// Android version) and are handed to the system share sheet, from which the customer can save
/// to Drive/Files or send them on.
class ReceiptPdfService {
  const ReceiptPdfService();

  /// Renders [doc] and writes it as [ReceiptDocument.fileName]; returns the saved file.
  Future<File> save(ReceiptDocument doc) async {
    final sans = await rootBundle.load('assets/fonts/Inter.ttf');
    final serif = await rootBundle.load('assets/fonts/SourceSerif4.ttf');
    Uint8List? logo;
    try {
      logo = (await rootBundle.load(
        'assets/branding/logo_full.png',
      )).buffer.asUint8List();
    } on Object {
      logo = null; // the wordmark text stands in
    }
    final bytes = await buildReceiptPdf(
      doc,
      sans: sans,
      serif: serif,
      logo: logo,
    );
    final dir =
        await getExternalStorageDirectory() ??
        await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${doc.fileName}');
    return file.writeAsBytes(bytes, flush: true);
  }

  Future<void> share(File file, String subject) => SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: 'application/pdf')],
      subject: subject,
    ),
  );
}
