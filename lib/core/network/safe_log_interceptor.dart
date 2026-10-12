import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Dev-only. Logs method, path, status and timing ONLY — never headers, query or bodies,
/// so OTP, tokens, KYC and payment data cannot leak (AGENTS §72).
class SafeLogInterceptor extends Interceptor {
  static const _startKey = 'log_start_ms';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startKey] = DateTime.now().millisecondsSinceEpoch;
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _log(response.requestOptions, response.statusCode);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log(err.requestOptions, err.response?.statusCode, error: err.type.name);
    handler.next(err);
  }

  void _log(RequestOptions o, int? status, {String? error}) {
    final start = o.extra[_startKey] as int?;
    final ms = start == null
        ? '?'
        : '${DateTime.now().millisecondsSinceEpoch - start}';
    debugPrint('[api] ${o.method} ${o.path} → ${status ?? error} (${ms}ms)');
  }
}
