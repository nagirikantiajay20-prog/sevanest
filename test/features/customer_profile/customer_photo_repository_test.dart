import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/features/customer_profile/data/customer_photo_repository_remote.dart';
import 'package:sevanest_customer/features/customer_profile/domain/customer_photo.dart';

import '../../helpers/fakes.dart';

void main() {
  test(
    'upload asks for a link, PUTs the bytes without auth, then confirms',
    () async {
      final calls = <String>[];
      Object? askBody;
      final api = Dio(BaseOptions(baseUrl: 'https://api.test/v1'))
        ..httpClientAdapter = FakeAdapter((o) async {
          calls.add('${o.method} ${o.path}');
          if (o.method == 'POST' && o.path == '/customers/me/photo') {
            askBody = o.data;
            return jsonBody(
              '{"photoId":"p1","url":"https://files.test/up","method":"PUT",'
              '"expiresAt":"2030-01-01T00:00:00Z","contentType":"image/png","maxBytes":5}',
              201,
            );
          }
          return jsonBody('{}', 200);
        });
      final uploader = Dio()
        ..httpClientAdapter = FakeAdapter((o) async {
          calls.add('${o.method} ${o.uri}');
          expect(o.headers.containsKey('Authorization'), isFalse);
          expect(o.headers[Headers.contentTypeHeader], 'image/png');
          return jsonBody('{}', 200);
        });
      final photo = PickedPhoto.fromBytes(
        Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 1, 2]),
      );
      await CustomerPhotoRepositoryRemote(
        api,
        uploader: uploader,
      ).upload(photo);
      expect(photo.contentType, 'image/png');
      expect(askBody, {'contentType': 'image/png', 'sizeBytes': 6});
      expect(calls, [
        'POST /customers/me/photo',
        'PUT https://files.test/up',
        'POST /customers/me/photo/p1/confirm',
      ]);
    },
  );

  test('current is null on 404 and the link on 200', () async {
    var found = false;
    final api = Dio(BaseOptions(baseUrl: 'https://api.test/v1'))
      ..httpClientAdapter = FakeAdapter(
        (o) async => found
            ? jsonBody('{"url":"https://img.test/a","expiresAt":"x"}', 200)
            : jsonBody('{"code":"NOT_FOUND","message":"none"}', 404),
      );
    final repo = CustomerPhotoRepositoryRemote(api);
    expect(await repo.current(), isNull);
    found = true;
    expect((await repo.current())?.url, 'https://img.test/a');
  });
}
