// Colours live in lib/app/theme/tokens.dart (AppColors). This keeps raw colour literals from
// creeping back into feature code after the 2026-11-06 token migration.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('no raw Color literals or Colors.white outside tokens.dart', () {
    final raw = RegExp(r'Color\(\s*0x[0-9A-Fa-f]{8}|\bColors\.white\b(?!\d)');
    final offenders = <String>[];
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final path = f.path.replaceAll(r'\', '/');
      if (path.contains('/l10n/gen/') ||
          path.endsWith('app/theme/tokens.dart')) {
        continue;
      }
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (raw.hasMatch(lines[i]) && !lines[i].trimLeft().startsWith('//')) {
          offenders.add('$path:${i + 1}');
        }
      }
    }
    expect(offenders, isEmpty, reason: 'use AppColors tokens: $offenders');
  });

  test('a multi-line Color( literal is caught too', () {
    final src = File(
      'lib/features/authentication/presentation/screens/splash_screen.dart',
    ).readAsStringSync();
    expect(RegExp(r'Color\(\s*\n\s*0x').hasMatch(src), isFalse);
  });
}
