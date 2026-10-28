import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppEnv { dev, stg, prod }

/// Client-safe configuration only. Never put secrets here (AGENTS §53, §73).
class AppConfig {
  const AppConfig({
    required this.env,
    required this.apiBaseUrl,
    required this.useMocks,
    this.workerAppUrl = const String.fromEnvironment('WORKER_APP_URL'),
  });

  // The deployed backend is the only host that exists today, so stg and prod use it too until real hosts are set up.
  static const dev = AppConfig(
    env: AppEnv.dev,
    apiBaseUrl: 'https://sevanest-backend.onrender.com/api/v1',
    useMocks: false,
  );

  /// Automated tests only: seeded mock repositories and the local demo login. No flavor ships it.
  static const mock = AppConfig(
    env: AppEnv.dev,
    apiBaseUrl: 'https://sevanest-backend.onrender.com/api/v1',
    useMocks: true,
  );
  static const stg = AppConfig(
    env: AppEnv.stg,
    apiBaseUrl: 'https://sevanest-backend.onrender.com/api/v1',
    useMocks: false,
  );
  static const prod = AppConfig(
    env: AppEnv.prod,
    apiBaseUrl: 'https://sevanest-backend.onrender.com/api/v1',
    useMocks: false,
  );

  final AppEnv env;
  final String apiBaseUrl;

  /// Mock repositories are for automated tests only ([mock]).
  final bool useMocks;

  /// Deep link / store URL of the separate SevaNest Worker app (`--dart-define=WORKER_APP_URL=...`).
  /// Empty until the worker app has one; the splash then says so instead of opening nothing.
  final String workerAppUrl;

  bool get isProd => env == AppEnv.prod;
}

final appConfigProvider = Provider<AppConfig>(
  (ref) => throw UnimplementedError(
    'appConfigProvider must be overridden in bootstrap',
  ),
);
