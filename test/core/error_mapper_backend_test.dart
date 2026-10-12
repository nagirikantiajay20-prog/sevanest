import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/network/error_mapper.dart';

DioException _http(int status, Object? body, [Map<String, List<String>>? h]) {
  final req = RequestOptions(path: '/x');
  return DioException(
    requestOptions: req,
    type: DioExceptionType.badResponse,
    response: Response(
      requestOptions: req,
      statusCode: status,
      data: body,
      headers: Headers.fromMap(h ?? {}),
    ),
  );
}

void main() {
  test('429 without any hint -> retryAfterSeconds null', () {
    final f = mapDioError(_http(429, {'code': 'RATE_LIMITED'}));
    expect(f, isA<RateLimitedFailure>());
    expect((f as RateLimitedFailure).retryAfterSeconds, isNull);
  });

  test('429 ignores zero / negative / garbage hints', () {
    for (final v in [0, -5, 'abc']) {
      final f = mapDioError(
        _http(429, {
          'details': [
            {'retryAfterSeconds': v},
          ],
        }),
      );
      expect((f as RateLimitedFailure).retryAfterSeconds, isNull);
    }
  });

  test('legacy fieldErrors map still works', () {
    final f = mapDioError(
      _http(400, {
        'fieldErrors': {'name': 'required'},
      }),
    );
    expect((f as ValidationFailure).fieldErrors['name'], 'required');
  });
}
