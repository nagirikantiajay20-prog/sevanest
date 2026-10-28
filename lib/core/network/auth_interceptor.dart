import 'dart:async';

import 'package:dio/dio.dart';
import 'package:sevanest_customer/core/storage/secure_session_store.dart';

/// Placeholder tokens of the dev-flavor local login (`AuthRepositoryDemo`). The backend cannot
/// refresh them, so a 401 on one must not end the session.
const demoTokenPrefix = 'demo-';

const _retriedKey = 'auth_retried';
const _authPathPrefix = '/auth/';
// Endpoints that must NOT carry a bearer token. Everything else under /auth/ (logout,
// sessions, device-token) is authenticated.
const _publicAuthPaths = [
  '/auth/otp/',
  '/auth/token/refresh',
  '/auth/admin/login',
];

/// Attaches the bearer token and, on 401, refreshes ONCE (shared by concurrent requests) then retries.
/// If refresh fails the session is considered expired and [onExpired] is invoked.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.store,
    required this.dio,
    required this.refreshDio,
    required this.onExpired,
  });

  final SessionStore store;

  /// Client used to retry the original request (has this interceptor).
  final Dio dio;

  /// Bare client for the refresh call (no interceptors → no loops).
  final Dio refreshDio;
  final Future<void> Function() onExpired;

  Future<String?>? _refreshing;

  bool _isAuthCall(RequestOptions o) => o.path.startsWith(_authPathPrefix);
  bool _isPublicAuthCall(RequestOptions o) =>
      _publicAuthPaths.any(o.path.startsWith);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isPublicAuthCall(options)) {
      final tokens = await store.read();
      if (tokens != null) {
        options.headers['Authorization'] = 'Bearer ${tokens.access}';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final req = err.requestOptions;
    if (err.response?.statusCode != 401 ||
        _isAuthCall(req) ||
        req.extra[_retriedKey] == true) {
      return handler.next(err);
    }

    final current = await store.read();
    if (current != null && current.refresh.startsWith(demoTokenPrefix)) {
      return handler.next(err);
    }

    final newAccess = await (_refreshing ??= _refresh().whenComplete(
      () => _refreshing = null,
    ));
    if (newAccess == null) {
      await onExpired();
      return handler.next(err);
    }

    req.headers['Authorization'] = 'Bearer $newAccess';
    req.extra[_retriedKey] = true;
    try {
      handler.resolve(await dio.fetch<dynamic>(req));
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  /// POST /auth/token/refresh {refreshToken}. Verified live: single-use rotation, response has
  /// `accessToken` + `refreshToken`; reusing an old token answers 401 REFRESH_TOKEN_INVALID and
  /// revokes the session.
  Future<String?> _refresh() async {
    try {
      final tokens = await store.read();
      if (tokens == null) return null;
      final res = await refreshDio.post<Map<String, dynamic>>(
        '${_authPathPrefix}token/refresh',
        data: {'refreshToken': tokens.refresh},
      );
      final body = res.data;
      final access = body?['accessToken'] as String?;
      final refresh = body?['refreshToken'] as String?;
      if (access == null || refresh == null) return null;
      await store.write(access: access, refresh: refresh);
      return access;
    } on DioException {
      return null;
    }
  }
}
