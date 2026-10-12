import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/app/app.dart';
import 'package:sevanest_customer/core/config/app_config.dart';

Future<void> bootstrap(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase / Crashlytics init is added in Step 10.3 once Firebase projects exist.
  runApp(
    ProviderScope(
      // Failures surface as error states with a user-driven Retry; no hidden auto-retries (AGENTS §65).
      retry: (_, _) => null,
      overrides: [appConfigProvider.overrideWithValue(config)],
      child: const SevaNestApp(),
    ),
  );
}
