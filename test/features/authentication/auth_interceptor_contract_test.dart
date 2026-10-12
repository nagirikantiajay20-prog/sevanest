// UNIT tests (mocked HTTP): token handling against the documented auth contract.
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/core/network/auth_interceptor.dart';

import '../../helpers/fakes.dart';

void main() {
  late InMemorySessionStore store;
  late List<RequestOptions> seen;
  late int expired;

  Dio build(AdapterHandler handler) {
    seen = [];
    final adapter = FakeAdapter((o) {
      seen.add(o);
      return handler(o);
    });
    final d = Dio(BaseOptions(baseUrl: 'https://x.test/api/v1'))
      ..httpClientAdapter = adapter;
    final refreshDio = Dio(BaseOptions(baseUrl: 'https://x.test/api/v1'))
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
    store = InMemorySessionStore((access: 'old', refresh: 'ref-1'));
    expired = 0;
  });

  test(
    'logout / device-token are authenticated; OTP + refresh are not',
    () async {
      final dio = build((o) async => jsonBody('{}', 200));
      await dio.post<dynamic>('/auth/logout');
      await dio.put<dynamic>('/auth/device-token');
      await dio.post<dynamic>('/auth/otp/request');
      await dio.post<dynamic>('/auth/otp/verify');
      await dio.post<dynamic>('/auth/token/refresh');
      final bearer = {for (final o in seen) o.path: o.headers['Authorization']};
      expect(bearer['/auth/logout'], 'Bearer old');
      expect(bearer['/auth/device-token'], 'Bearer old');
      expect(bearer['/auth/otp/request'], isNull);
      expect(bearer['/auth/otp/verify'], isNull);
      expect(bearer['/auth/token/refresh'], isNull);
    },
  );

  test(
    '401 -> refresh via /auth/token/refresh, rotated tokens stored, request retried',
    () async {
      final dio = build((o) async {
        if (o.path == '/auth/token/refresh') {
          return jsonBody(
            '{"accessToken":"new","refreshToken":"ref-2","tokenType":"Bearer","expiresIn":900}',
            200,
          );
        }
        final ok = o.headers['Authorization'] == 'Bearer new';
        return jsonBody(
          ok ? '{"ok":true}' : '{"code":"UNAUTHENTICATED"}',
          ok ? 200 : 401,
        );
      });
      final res = await dio.get<dynamic>('/customers/me');
      expect(res.statusCode, 200);
      final refresh = seen.singleWhere((o) => o.path == '/auth/token/refresh');
      expect(refresh.method, 'POST');
      expect(jsonDecode(jsonEncode(refresh.data)), {'refreshToken': 'ref-1'});
      expect(await store.read(), (access: 'new', refresh: 'ref-2'));
    },
  );

  test(
    'REFRESH_TOKEN_INVALID (reused/expired) ends the session once',
    () async {
      final dio = build((o) async {
        if (o.path == '/auth/token/refresh') {
          return jsonBody('{"code":"REFRESH_TOKEN_INVALID"}', 401);
        }
        return jsonBody('{"code":"UNAUTHENTICATED"}', 401);
      });
      await expectLater(
        dio.get<dynamic>('/customers/me'),
        throwsA(isA<DioException>()),
      );
      expect(expired, 1);
      // No retry loop: one original call + one refresh attempt.
      expect(seen.map((o) => o.path), ['/customers/me', '/auth/token/refresh']);
    },
  );

  test(
    'OTP endpoints are never auto-retried (an OTP request sends an SMS)',
    () async {
      final dio = build((o) async => jsonBody('{"code":"X"}', 503));
      await expectLater(
        dio.post<dynamic>('/auth/otp/request'),
        throwsA(isA<DioException>()),
      );
      expect(seen, hasLength(1));
    },
  );
}
