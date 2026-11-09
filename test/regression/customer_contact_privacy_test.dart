// Customer phone visibility for workers: the worker-facing API (not this app) owns it. This pins
// the contract the app relies on, so a backend change that adds the field is noticed.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final spec =
      jsonDecode(
            File('docs/backend_openapi_2026-10-13.json').readAsStringSync(),
          )
          as Map<String, dynamic>;
  final schemas = (spec['components'] as Map)['schemas'] as Map;

  test(
    'worker booking view carries no customer contact (backend dependency)',
    () {
      final props =
          ((schemas['WorkerBookingView'] as Map)['properties'] as Map).keys;
      expect(
        props.where(
          (k) => RegExp(
            'mobile|phone|contact',
            caseSensitive: false,
          ).hasMatch('$k'),
        ),
        isEmpty,
      );
    },
  );

  test(
    'customer app has no worker-role screens or customer-number rendering',
    () {
      final hits = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where(
            (f) => RegExp(
              r'''["']/workers/me/|["']tel:|launchUrl.*tel''',
            ).hasMatch(f.readAsStringSync()),
          )
          .map((f) => f.path)
          .toList();
      expect(hits, isEmpty);
    },
  );
}
