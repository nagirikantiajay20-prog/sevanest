import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';

const _attemptKey = 'get_retry_attempt';

/// Bounded retry for READS only. GET/HEAD are safe to repeat; every other method is never
/// retried here (a repeated booking, payment or cancellation is not acceptable).
///
/// Retries transient failures only: timeouts, dropped connections, 502/503/504, and 429 when the
/// server asks for a short wait (`Retry-After` <= [maxRetryAfter]; a longer wait is surfaced to
/// the caller as a rate-limit failure instead of stalling the screen). Exponential backoff with
/// jitter. 401/403/4xx never retry (auth refresh lives in `AuthInterceptor`), nor does a
/// cancelled request, so an outdated search cannot be revived.
class GetRetryInterceptor extends Interceptor {
  GetRetryInterceptor({
    required this.dio,
    this.maxRetries = 2,
    this.baseDelay = const Duration(milliseconds: 400),
    this.maxRetryAfter = const Duration(seconds: 5),
    Future<void> Function(Duration)? delay,
    double Function()? random,
  }) : _delay = delay ?? Future<void>.delayed,
       _random = random ?? Random().nextDouble;

  /// Client that re-sends the request (runs the whole interceptor chain again).
  final Dio dio;
  final int maxRetries;
  final Duration baseDelay;
  final Duration maxRetryAfter;
  final Future<void> Function(Duration) _delay;
  final double Function() _random;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final req = err.requestOptions;
    final attempt = (req.extra[_attemptKey] as int?) ?? 0;
    final wait = _retryDelay(err, attempt);
    if (wait == null) return handler.next(err);

    await _delay(wait);
    req.extra[_attemptKey] = attempt + 1;
    try {
      handler.resolve(await dio.fetch<dynamic>(req));
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  /// Null = do not retry.
  Duration? _retryDelay(DioException err, int attempt) {
    final method = err.requestOptions.method.toUpperCase();
    if (method != 'GET' && method != 'HEAD') return null;
    if (attempt >= maxRetries) return null;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return _backoff(attempt);
      case DioExceptionType.badResponse:
        final status = err.response?.statusCode;
        if (status == 502 || status == 503 || status == 504) {
          return _backoff(attempt);
        }
        if (status == 429) {
          final secs = int.tryParse(
            err.response?.headers.value('retry-after') ?? '',
          );
          if (secs == null || secs < 0) return null;
          final asked = Duration(seconds: secs);
          return asked <= maxRetryAfter ? asked : null;
        }
        return null;
      // cancel, badCertificate, unknown, transformTimeout: never retried.
      // ignore: no_default_cases
      default:
        return null;
    }
  }

  Duration _backoff(int attempt) {
    final exp = baseDelay.inMilliseconds * pow(2, attempt);
    final jitter = exp * 0.25 * _random();
    return Duration(milliseconds: (exp + jitter).round());
  }
}
