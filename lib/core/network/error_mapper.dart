import 'package:dio/dio.dart';
import 'package:sevanest_customer/core/analytics/telemetry.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';

/// Backend error shape (observed live): { code, message, details?: [{field, messages[]}], requestId }.
/// 429 carries `details[0].retryAfterSeconds` (Swagger) and may carry a Retry-After header.
AppFailure mapDioError(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return const NetworkFailure();
    case DioExceptionType.cancel:
      return const UnknownFailure('cancelled');
    default:
      break;
  }

  final status = e.response?.statusCode;
  final data = e.response?.data;
  final body = data is Map<String, dynamic> ? data : const <String, dynamic>{};
  final failure = _byStatus(status, body, e);
  // Only unexpected outcomes are reported, and only their status: no bodies, no PII.
  if (failure is ServerFailure || failure is UnknownFailure) {
    telemetry.nonFatal(
      Exception('${failure.runtimeType} status=$status'),
      null,
    );
  }
  return failure;
}

AppFailure _byStatus(int? status, Map<String, dynamic> body, DioException e) {
  final message = body['message'] as String?;
  return switch (status) {
    400 || 422 => ValidationFailure(
      message,
      _fieldErrors(body['details'] ?? body['fieldErrors']),
      body['code'] as String?,
    ),
    401 => UnauthorizedFailure(message),
    403 => ForbiddenFailure(message),
    404 || 410 => NotFoundFailure(message),
    409 => ConflictFailure(message, body['code'] as String?),
    429 => RateLimitedFailure(message, _retryAfter(e.response, body)),
    final int s when s >= 500 => ServerFailure(message),
    _ => UnknownFailure(message),
  };
}

Map<String, String> _fieldErrors(Object? raw) {
  if (raw is Map) {
    return {for (final e in raw.entries) '${e.key}': '${e.value}'};
  }
  if (raw is List) {
    return {
      for (final d in raw.whereType<Map<dynamic, dynamic>>())
        if (d['field'] is String && d['messages'] is List)
          if ((d['messages'] as List).isNotEmpty)
            d['field'] as String: '${(d['messages'] as List).first}',
    };
  }
  return const {};
}

int? _retryAfter(Response<dynamic>? res, Map<String, dynamic> body) {
  final header = int.tryParse(res?.headers.value('retry-after') ?? '');
  if (header != null && header > 0) return header;
  final details = body['details'];
  if (details is List && details.isNotEmpty && details.first is Map) {
    final v = (details.first as Map)['retryAfterSeconds'];
    if (v is num && v > 0) return v.toInt();
  }
  return null;
}
