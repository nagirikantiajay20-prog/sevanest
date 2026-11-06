import 'dart:io';

import 'package:flutter/services.dart';

/// Widget tests draw with the Ahem box font, which is about 1.7x wider than Inter, so wrapping and
/// truncation checks only mean something once the app's real fonts are loaded. Call from `setUpAll`.
Future<void> loadRealFonts() async {
  for (final (family, file) in [
    ('Inter', 'Inter.ttf'),
    ('SourceSerif4', 'SourceSerif4.ttf'),
  ]) {
    final bytes = await File('assets/fonts/$file').readAsBytes();
    await (FontLoader(
      family,
    )..addFont(Future.value(ByteData.view(bytes.buffer)))).load();
  }
}
