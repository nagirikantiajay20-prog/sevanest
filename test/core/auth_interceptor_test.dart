import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/core/network/auth_interceptor.dart';

import '../helpers/fakes.dart';

void main() {
  late InMemorySessionStore store;
  late int refreshCalls;
  late int expired;
  late Dio dio;

  Dio build({required bool refreshWorks}) {
    final adapter = FakeAdapter((o) async {
      if (o.path == '/auth/token/refresh') {
        refreshCalls++;
        return refreshWorks
            ? jsonBody('{"accessToken":"new","refreshToken":"r2"}', 200)
            : jsonBody('{"message":"bad"}', 401);
      }
      final ok = o.headers['Authorization'] == 'Bearer new';
      return jsonBody(ok ? '{"ok":true}' : '{"message":"no"}', ok ? 200 : 401);
    });
    final d = Dio(BaseOptions(baseUrl: 'https://x.test'))
      ..httpClientAdapter = adapter;
    final refreshDio = Dio(BaseOptions(baseUrl: 'https://x.test'))
      ..httpClientAdapter = adapter;
    d.interceptors.add(
      AuthInterceptor(
        store: store,
        dio: d,
        refreshDio: refreshDio,
        onExpired: () async => expired++,
      ),
    );
    return d;
  }

  setUp(() {
    store = InMemorySessionStore((access: 'old', refresh: 'r1'));
    refreshCalls = 0;
    expired = 0;
  });

  test('3 parallel 401s trigger exactly one refresh, all succeed', () async {
    dio = build(refreshWorks: true);
    final res = await Future.wait([
      dio.get<dynamic>('/a'),
      dio.get<dynamic>('/b'),
      dio.get<dynamic>('/c'),
    ]);
    expect(res.map((r) => r.statusCode), everyElement(200));
    expect(refreshCalls, 1);
    expect((await store.read())!.access, 'new');
    expect(expired, 0);
  });

  test('failed refresh signals expiry and surfaces the 401', () async {
    dio = build(refreshWorks: false);
    await expectLater(
      dio.get<dynamic>('/a'),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'status',
          401,
        ),
      ),
    );
    expect(expired, 1);
  });

  test('auth endpoints never get a bearer or trigger refresh', () async {
    dio = build(refreshWorks: true);
    await expectLater(
      dio.post<dynamic>('/auth/otp/verify'),
      throwsA(isA<DioException>()),
    );
    expect(refreshCalls, 0);
  });
}
