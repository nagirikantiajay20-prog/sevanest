// Network images: a failed or expired link must never throw into the UI, and decode sizes stay bounded.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/features/addresses/presentation/widgets/home_photo_field.dart';

import '../helpers/fakes.dart';

void main() {
  testWidgets(
    'a failing photo link shows the broken-image icon, not an error',
    (t) async {
      await t.pumpWidget(
        testApp(
          SingleChildScrollView(
            child: HomePhotoField(
              photo: null,
              url: 'https://img.example.test/expired.jpg',
              enabled: true,
              onPicked: (_) {},
              onRemoved: () {},
            ),
          ),
        ),
      );
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await t.pumpAndSettle();
      expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );

  group('source guards for every network image in lib', () {
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .map((f) => (f.path, f.readAsStringSync()))
        .toList();

    test('Image.network always has an errorBuilder', () {
      for (final (path, src) in files) {
        for (final m in RegExp(r'Image\.network\(').allMatches(src)) {
          final call = src.substring(
            m.start,
            (m.start + 500).clamp(0, src.length),
          );
          expect(call, contains('errorBuilder'), reason: path);
        }
      }
    });

    test('a DecorationImage over a NetworkImage ignores load errors', () {
      for (final (path, src) in files) {
        for (final m in RegExp(r'DecorationImage\(').allMatches(src)) {
          final call = src.substring(
            m.start,
            (m.start + 400).clamp(0, src.length),
          );
          if (call.contains('NetworkImage')) {
            expect(call, contains('onError'), reason: path);
          }
        }
      }
    });

    test('avatars and cards decode network photos at display size', () {
      for (final (path, src) in files) {
        for (final m in RegExp(r'[^e]NetworkImage\(').allMatches(src)) {
          final before = src
              .substring((m.start - 120).clamp(0, src.length), m.start + 1)
              .replaceAll(RegExp(r'\s'), '');
          // CachedNetworkImageProvider and ResizeImage(NetworkImage( are fine; a bare provider is
          // allowed only for the customer's own profile photo (a short-lived private link).
          if (before.contains('ResizeImage(')) continue;
          expect(
            path,
            contains('profile_photo_avatar'),
            reason: '$path: unbounded NetworkImage',
          );
        }
      }
    });
  });
}
