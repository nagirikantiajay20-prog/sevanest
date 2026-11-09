// UNIT tests: what a finished session removes from the device (audit follow-up).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/core/storage/account_data_cleaner.dart';
import 'package:sevanest_customer/core/storage/receipt_files.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory dir;

  setUp(() {
    SharedPreferences.setMockInitialValues({
      requirementDraftPrefKey: '{"serviceId":"cook"}',
      'device_id': 'abc',
      'notif_muted_categories': ['promo'],
      'pending_payment_id': 'p1',
    });
    dir = Directory.systemTemp.createTempSync('sn_cleaner_');
    addTearDown(() => dir.deleteSync(recursive: true));
  });

  AccountDataCleaner cleaner({
    Future<List<Directory>> Function()? dirs,
    void Function()? images,
    Future<SharedPreferences> Function()? prefs,
  }) => AccountDataCleaner(
    prefs: prefs ?? SharedPreferences.getInstance,
    receiptDirectories: dirs ?? () async => [dir],
    clearImages: images ?? () {},
  );

  test(
    'clear removes the draft, own receipts and cached images only',
    () async {
      File('${dir.path}/${receiptFilePrefix}RCPT-1.pdf').writeAsStringSync('x');
      File('${dir.path}/${receiptFilePrefix}RCPT-2.pdf').writeAsStringSync('x');
      File('${dir.path}/photo.pdf').writeAsStringSync('keep');
      File(
        '${dir.path}/${receiptFilePrefix}notes.txt',
      ).writeAsStringSync('keep');
      var imagesCleared = 0;

      await cleaner(images: () => imagesCleared++).clear();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(requirementDraftPrefKey), isNull);
      // Unrelated and non-account preferences are untouched.
      expect(prefs.getString('device_id'), 'abc');
      expect(prefs.getStringList('notif_muted_categories'), ['promo']);
      expect(prefs.getString('pending_payment_id'), 'p1');
      final left = dir.listSync().map((e) => e.uri.pathSegments.last).toSet();
      expect(left, {'photo.pdf', '${receiptFilePrefix}notes.txt'});
      expect(imagesCleared, 1);
    },
  );

  test('clearDraft touches nothing but the draft', () async {
    File('${dir.path}/${receiptFilePrefix}RCPT-1.pdf').writeAsStringSync('x');
    var imagesCleared = 0;

    await cleaner(images: () => imagesCleared++).clearDraft();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(requirementDraftPrefKey), isNull);
    expect(dir.listSync(), hasLength(1));
    expect(imagesCleared, 0);
  });

  test('a failing step never throws and the other steps still run', () async {
    File('${dir.path}/${receiptFilePrefix}RCPT-1.pdf').writeAsStringSync('x');
    var imagesCleared = 0;

    await cleaner(
      prefs: () => throw StateError('prefs unavailable'),
      images: () => imagesCleared++,
    ).clear();

    expect(dir.listSync(), isEmpty);
    expect(imagesCleared, 1);

    await cleaner(
      dirs: () => throw StateError('no storage'),
      images: () => throw StateError('no binding'),
    ).clear(); // must complete without throwing
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(requirementDraftPrefKey), isNull);
  });

  test('a missing receipt folder is fine', () async {
    final gone = Directory('${dir.path}/missing');
    await cleaner(dirs: () async => [gone]).clear();
    expect(gone.existsSync(), isFalse);
  });
}
