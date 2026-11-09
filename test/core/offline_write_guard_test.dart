import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/network/error_mapper.dart';
import 'package:sevanest_customer/core/network/offline_write_guard.dart';

/// Records what reached the "network" (the adapter) so we can prove nothing was sent.
class _Recorder implements HttpClientAdapter {
  final sent = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    sent.add('${options.method} ${options.path}');
    return ResponseBody.fromString(
      '{}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _dio({required bool online, required _Recorder rec}) =>
    Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = rec
      ..interceptors.add(OfflineWriteGuard(isOnline: () async => online));

void main() {
  for (final method in ['POST', 'PUT', 'PATCH', 'DELETE']) {
    test(
      'offline: $method is refused, never sent, mapped to offline failure',
      () async {
        final rec = _Recorder();
        final dio = _dio(online: false, rec: rec);
        try {
          await dio.request<dynamic>(
            '/bookings',
            options: Options(method: method),
          );
          fail('should have thrown');
        } on DioException catch (e) {
          final f = mapDioError(e);
          expect(f, isA<NetworkFailure>());
          expect((f as NetworkFailure).offline, isTrue);
        }
        expect(rec.sent, isEmpty);
      },
    );
  }

  test('offline: GET still goes through (reads are not blocked)', () async {
    final rec = _Recorder();
    await _dio(online: false, rec: rec).get<dynamic>('/bookings');
    expect(rec.sent, ['GET /bookings']);
  });

  test('offline: logout and device-token cleanup are exempt', () async {
    final rec = _Recorder();
    final dio = _dio(online: false, rec: rec);
    await dio.post<dynamic>('/auth/logout');
    await dio.delete<dynamic>('/auth/device-token');
    expect(rec.sent, ['POST /auth/logout', 'DELETE /auth/device-token']);
  });

  test('online: writes are sent once, no replay after reconnect', () async {
    final rec = _Recorder();
    var online = false;
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = rec
      ..interceptors.add(OfflineWriteGuard(isOnline: () async => online));
    await expectLater(
      dio.post<dynamic>('/payments'),
      throwsA(isA<DioException>()),
    );
    online = true;
    expect(rec.sent, isEmpty); // nothing queued while offline
    await dio.post<dynamic>('/payments');
    expect(rec.sent, ['POST /payments']);
  });
}
