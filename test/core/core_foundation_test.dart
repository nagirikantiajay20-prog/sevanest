import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/core/config/app_config.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/network/error_mapper.dart';

DioException _http(int status, [Map<String, dynamic>? body]) {
  final req = RequestOptions(path: '/x');
  return DioException(
    requestOptions: req,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: req, statusCode: status, data: body),
  );
}

void main() {
  group('AppConfig', () {
    test('no shipped flavor uses mocks (only the test config)', () {
      expect(AppConfig.mock.useMocks, isTrue);
      expect(AppConfig.dev.useMocks, isFalse);
      expect(AppConfig.stg.useMocks, isFalse);
      expect(AppConfig.prod.useMocks, isFalse);
    });

    test('prod base url is https', () {
      expect(AppConfig.prod.apiBaseUrl, startsWith('https://'));
    });
  });

  group('mapDioError', () {
    test('status codes map to failures', () {
      expect(mapDioError(_http(401)), isA<UnauthorizedFailure>());
      expect(mapDioError(_http(403)), isA<ForbiddenFailure>());
      expect(mapDioError(_http(404)), isA<NotFoundFailure>());
      expect(mapDioError(_http(409)), isA<ConflictFailure>());
      expect(mapDioError(_http(429)), isA<RateLimitedFailure>());
      expect(mapDioError(_http(503)), isA<ServerFailure>());
    });

    test('400 carries field errors', () {
      final f =
          mapDioError(
                _http(400, {
                  'message': 'bad',
                  'fieldErrors': {'email': 'Invalid'},
                }),
              )
              as ValidationFailure;
      expect(f.fieldErrors['email'], 'Invalid');
    });

    test('timeout maps to network failure', () {
      final e = DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.connectionTimeout,
      );
      expect(mapDioError(e), isA<NetworkFailure>());
    });
  });
}
