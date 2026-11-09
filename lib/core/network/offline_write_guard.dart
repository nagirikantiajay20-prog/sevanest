import 'dart:io' show SocketException;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

/// Single choke point for "writes need internet". Every POST/PUT/PATCH/DELETE through the app's
/// [Dio] is refused here, before any token read or network call, when the device has no network.
/// Nothing is queued or replayed: the caller gets a [DioException] that `mapDioError` turns into
/// `NetworkFailure(offline: true)`, and its form state is untouched so the customer can retry.
///
/// Connectivity is only a pre-check (a device on Wi-Fi may still not reach the API); timeouts
/// and connection errors from the real request are still handled by the error mapper.
class OfflineWriteGuard extends Interceptor {
  OfflineWriteGuard({Future<bool> Function()? isOnline})
    : _isOnline = isOnline ?? deviceHasNetwork;

  final Future<bool> Function() _isOnline;

  static const _reads = {'GET', 'HEAD', 'OPTIONS'};

  /// Best-effort cleanup calls: logout must still be able to finish locally while offline.
  static const _exempt = ['/auth/logout', '/auth/device-token'];

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final isWrite = !_reads.contains(options.method.toUpperCase());
    if (isWrite &&
        !_exempt.any(options.path.startsWith) &&
        !await _isOnline()) {
      return handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: const SocketException('offline'),
          message: 'offline',
        ),
        true,
      );
    }
    handler.next(options);
  }
}

/// True when any network interface is up. Unreadable (no plugin, as in unit tests) counts as
/// online, so a failure here can never block a write that would have worked.
Future<bool> deviceHasNetwork() async {
  try {
    final r = await Connectivity().checkConnectivity();
    return r.any((e) => e != ConnectivityResult.none);
  } on Object {
    return true;
  }
}
