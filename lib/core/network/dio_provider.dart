import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/core/config/app_config.dart';
import 'package:sevanest_customer/core/network/auth_interceptor.dart';
import 'package:sevanest_customer/core/network/safe_log_interceptor.dart';
import 'package:sevanest_customer/core/session/auth_state.dart';
import 'package:sevanest_customer/core/storage/secure_session_store.dart';

const _connectTimeout = Duration(seconds: 15);
const _receiveTimeout = Duration(seconds: 30);

BaseOptions _baseOptions(AppConfig config) => BaseOptions(
  baseUrl: config.apiBaseUrl,
  connectTimeout: _connectTimeout,
  receiveTimeout: _receiveTimeout,
  headers: {'Accept': 'application/json'},
);

final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  final dio = Dio(_baseOptions(config));
  dio.interceptors.add(
    AuthInterceptor(
      store: ref.read(sessionStoreProvider),
      dio: dio,
      refreshDio: Dio(_baseOptions(config)),
      onExpired: () => ref.read(authProvider.notifier).signOut(),
    ),
  );
  if (!config.isProd) dio.interceptors.add(SafeLogInterceptor());
  return dio;
});
