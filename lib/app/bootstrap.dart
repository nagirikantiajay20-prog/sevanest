import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:sevanest_customer/app/app.dart';
import 'package:sevanest_customer/app/session_reset_host.dart';
import 'package:sevanest_customer/core/analytics/telemetry.dart';
import 'package:sevanest_customer/core/config/app_config.dart';

Future<void> bootstrap(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();
  // Crashlytics + Analytics run in stg and prod only; dev stays silent. A Firebase failure never blocks launch.
  if (config.env != AppEnv.dev) {
    try {
      await Firebase.initializeApp();
      telemetry = const FirebaseTelemetry();
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    } on Object {
      telemetry = const NoopTelemetry();
    }
  }
  runApp(
    SessionResetHost(
      overrides: [appConfigProvider.overrideWithValue(config)],
      child: const SevaNestApp(),
    ),
  );
}
