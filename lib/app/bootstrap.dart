import 'package:flutter/widgets.dart';
import 'package:sevanest_customer/app/app.dart';
import 'package:sevanest_customer/app/session_reset_host.dart';
import 'package:sevanest_customer/core/config/app_config.dart';

Future<void> bootstrap(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase / Crashlytics init is added in Step 10.3 once Firebase projects exist.
  runApp(
    SessionResetHost(
      overrides: [appConfigProvider.overrideWithValue(config)],
      child: const SevaNestApp(),
    ),
  );
}
