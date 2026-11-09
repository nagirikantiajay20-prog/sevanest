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

  /// The only backend that exists today. It is the DEV backend: stg and prod must never use it.
  static const devApiUrl = 'https://sevanest-backend.onrender.com/api/v1';

  static const dev = AppConfig(
    env: AppEnv.dev,
    apiBaseUrl: devApiUrl,
    useMocks: false,
  );

  /// Automated tests only: seeded mock repositories and the local demo login. No flavor ships it.
  static const mock = AppConfig(
    env: AppEnv.dev,
    apiBaseUrl: devApiUrl,
    useMocks: true,
  );

  // stg and prod take their host at build time (`--dart-define=API_BASE_URL=https://...`). There
  // is deliberately NO default: until the backend team supplies the isolated hosts, those builds
  // fail validation at startup instead of silently talking to the dev backend.
  static const stg = AppConfig(
    env: AppEnv.stg,
    apiBaseUrl: String.fromEnvironment('API_BASE_URL'),
    useMocks: false,
  );
  static const prod = AppConfig(
    env: AppEnv.prod,
    apiBaseUrl: String.fromEnvironment('API_BASE_URL'),
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

  /// Why this config must not ship, or null when it is sound. Checked once at startup.
  String? get problem {
    final uri = Uri.tryParse(apiBaseUrl);
    if (env == AppEnv.dev) return null;
    if (useMocks) return 'mock repositories are enabled in ${env.name}';
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      return '${env.name} needs --dart-define=API_BASE_URL=https://<host>/api/v1';
    }
    if (apiBaseUrl == devApiUrl) {
      return '${env.name} points at the dev backend';
    }
    return null;
  }
}

final appConfigProvider = Provider<AppConfig>(
  (ref) => throw UnimplementedError(
    'appConfigProvider must be overridden in bootstrap',
  ),
);
