import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/core/config/app_config.dart';
import 'package:sevanest_customer/core/network/auth_interceptor.dart';
import 'package:sevanest_customer/core/network/get_retry_interceptor.dart';
import 'package:sevanest_customer/core/network/offline_write_guard.dart';
import 'package:sevanest_customer/core/network/safe_log_interceptor.dart';
import 'package:sevanest_customer/core/session/auth_state.dart';
import 'package:sevanest_customer/core/storage/secure_session_store.dart';

const _connectTimeout = Duration(seconds: 15);
const _receiveTimeout = Duration(seconds: 30);
const _sendTimeout = Duration(seconds: 30);

/// For the pre-signed photo upload clients (no base URL, no bearer token). Without these a
/// stalled upload would spin forever. Sending a photo gets a longer window than an API call.
BaseOptions uploadBaseOptions() => BaseOptions(
  connectTimeout: _connectTimeout,
  sendTimeout: const Duration(seconds: 90),
  receiveTimeout: _receiveTimeout,
);

BaseOptions _baseOptions(AppConfig config) => BaseOptions(
  baseUrl: config.apiBaseUrl,
  connectTimeout: _connectTimeout,
  receiveTimeout: _receiveTimeout,
  sendTimeout: _sendTimeout,
  headers: {'Accept': 'application/json'},
);

final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  final dio = Dio(_baseOptions(config));
  dio.interceptors.add(OfflineWriteGuard());
  dio.interceptors.add(
    AuthInterceptor(
      store: ref.read(sessionStoreProvider),
      dio: dio,
      refreshDio: Dio(_baseOptions(config)),
      onExpired: () => ref.read(authProvider.notifier).signOut(),
    ),
  );
  // After auth: a 401 is refreshed there first; this only ever re-sends GET/HEAD.
  dio.interceptors.add(GetRetryInterceptor(dio: dio));
  if (!config.isProd) dio.interceptors.add(SafeLogInterceptor());
  return dio;
});
