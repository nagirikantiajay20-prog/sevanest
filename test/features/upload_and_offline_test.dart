import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/features/addresses/presentation/widgets/home_photo_field.dart';
import 'package:sevanest_customer/features/booking/domain/booking.dart';

Uint8List _png(int len) {
  final b = Uint8List(len);
  b.setAll(0, [0x89, 0x50, 0x4E, 0x47]);
  return b;
}

void main() {
  group('photo rules shared by profile and home photo', () {
    test('JPEG and PNG signatures pass', () {
      expect(checkPhoto(_png(100)), PhotoCheck.ok);
      expect(
        checkPhoto(Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 1])),
        PhotoCheck.ok,
      );
    });
    test('wrong format, empty and tiny files are rejected', () {
      expect(checkPhoto(Uint8List(0)), PhotoCheck.badFormat);
      expect(checkPhoto(Uint8List.fromList([1, 2, 3])), PhotoCheck.badFormat);
      // GIF header renamed .jpg
      expect(
        checkPhoto(Uint8List.fromList([0x47, 0x49, 0x46, 0x38, 0x39])),
        PhotoCheck.badFormat,
      );
    });
    test('5 MB is the boundary', () {
      expect(checkPhoto(_png(maxHomePhotoBytes)), PhotoCheck.ok);
      expect(checkPhoto(_png(maxHomePhotoBytes + 1)), PhotoCheck.tooBig);
    });
  });

  test('timeout is not offline; real connection loss is', () {
    expect(isOffline(const NetworkFailure()), isTrue);
    expect(isOffline(const NetworkFailure(null, true)), isFalse);
    expect(isOffline(const ServerFailure()), isFalse);
    expect(isOffline(null), isFalse);
  });

  test('history search: spaces are not sent, text is trimmed', () {
    expect(
      const HistoryFilter(search: '   ').query.containsKey('search'),
      false,
    );
    expect(const HistoryFilter(search: ' ramesh ').query['search'], 'ramesh');
  });
}
