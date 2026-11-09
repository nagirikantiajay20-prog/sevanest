// STATIC checks of platform and CI configuration (audit follow-up). They read the files as text;
// they prove the settings are present, not how a device behaves (that needs an emulator).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  group('Android manifest', () {
    final manifest = _read('android/app/src/main/AndroidManifest.xml');

    test('turns off Flutter deep-link routing for the exported activity', () {
      expect(
        RegExp(
          r'<meta-data\s+android:name="flutter_deeplinking_enabled"\s+android:value="false"',
        ).hasMatch(manifest),
        isTrue,
      );
    });

    test('the only exported component is the launcher, with no URL filters', () {
      expect('android:exported="true"'.allMatches(manifest), hasLength(1));
      expect('<intent-filter>'.allMatches(manifest), hasLength(1));
      expect(manifest, contains('android.intent.action.MAIN'));
      expect(
        manifest,
        isNot(
          contains('android.intent.action.VIEW"/>\n                <category'),
        ),
      );
      expect(manifest, isNot(contains('android.intent.category.BROWSABLE')));
      // <queries> may mention VIEW for tel/mailto, but the activity declares no <data>.
      final activity = manifest.substring(
        manifest.indexOf('<activity'),
        manifest.indexOf('</activity>'),
      );
      expect(activity, isNot(contains('<data')));
    });

    test(
      'keeps backups off and cleartext traffic unset (platform default: blocked)',
      () {
        expect(manifest, contains('android:allowBackup="false"'));
        expect(manifest, isNot(contains('usesCleartextTraffic="true"')));
        expect(manifest, isNot(contains('android:debuggable')));
      },
    );
  });

  group('iOS Info.plist', () {
    final plist = _read('ios/Runner/Info.plist');

    test('turns off Flutter deep-link routing and declares no URL scheme', () {
      expect(
        RegExp(
          r'<key>FlutterDeepLinkingEnabled</key>\s*<false/>',
        ).hasMatch(plist),
        isTrue,
      );
      expect(plist, isNot(contains('CFBundleURLTypes')));
      expect(plist, isNot(contains('NSAllowsArbitraryLoads')));
    });
  });

  group('CI workflow', () {
    // Comments explain the choices and may name the things the workflow avoids.
    final ci = _read(
      '.github/workflows/ci.yml',
    ).split('\n').where((l) => !l.trimLeft().startsWith('#')).join('\n');

    test('runs with a read-only token and no secrets', () {
      expect(
        RegExp(
          r'^permissions:\s*\n\s+contents: read\s*$',
          multiLine: true,
        ).hasMatch(ci),
        isTrue,
      );
      expect(ci, isNot(contains('secrets.')));
      expect(ci, isNot(contains('write')));
    });

    test('uses pull_request, never pull_request_target or workflow_run', () {
      expect(ci, contains('pull_request:'));
      expect(ci, isNot(contains('pull_request_target')));
      expect(ci, isNot(contains('workflow_run')));
    });

    test('does not keep the checkout credentials around', () {
      expect(ci, contains('persist-credentials: false'));
    });
  });
}
