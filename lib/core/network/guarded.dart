import 'package:dio/dio.dart';
import 'package:sevanest_customer/core/analytics/telemetry.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/network/error_mapper.dart';

/// Runs a request and rethrows any [DioException] as an `AppFailure` (AGENTS §61).
Future<Response<dynamic>> guarded(
  Future<Response<dynamic>> Function() call,
) async {
  try {
    return await call();
  } on DioException catch (e) {
    throw mapDioError(e);
  }
}

/// Reads a list from either a bare array or a wrapper object (`items` / `data`).
///
/// A valid empty list (`[]`, `{items: []}`, `{data: []}`) returns `[]`. Anything else that is
/// not a list (null, a string, a wrapper without a list, wrong types) is a broken API contract
/// and throws [ServerFailure]: it must never be shown as "nothing here". Individual rows that
/// are not objects are still skipped, so one bad row cannot blank a whole screen.
List<Map<String, dynamic>> listOf(Object? body) {
  final raw = body is List
      ? body
      : body is Map
      ? (body['items'] ?? body['data'])
      : null;
  if (raw is! List) {
    // Only the shape is reported, never the body (it may hold personal data).
    telemetry.nonFatal(
      Exception('malformed list response: ${body.runtimeType}'),
      null,
    );
    throw const ServerFailure();
  }
  return raw.whereType<Map<String, dynamic>>().toList();
}
