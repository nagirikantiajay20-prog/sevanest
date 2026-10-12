import 'package:dio/dio.dart';
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
List<Map<String, dynamic>> listOf(Object? body) {
  final raw = body is List
      ? body
      : body is Map
      ? (body['items'] ?? body['data'])
      : null;
  return raw is List
      ? raw.whereType<Map<String, dynamic>>().toList()
      : const [];
}
