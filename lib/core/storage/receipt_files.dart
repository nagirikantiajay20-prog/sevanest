/// Every receipt PDF the app saves starts with this (see `ReceiptDocument.fileName`). Kept in a
/// pure Dart file so the receipt model stays free of Flutter and I/O, and the logout cleanup can
/// recognise the app's own files without touching anything else in the folder.
const receiptFilePrefix = 'SevaNest_Receipt_';
