import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Funnel events and non-fatal errors. Never pass PII (names, numbers, addresses, ids of people).
abstract class Telemetry {
  const Telemetry();
  void event(String name, [Map<String, Object> params = const {}]);
  void nonFatal(Object error, StackTrace? stack);
}

/// Dev builds and any run where Firebase failed to start.
class NoopTelemetry extends Telemetry {
  const NoopTelemetry();
  @override
  void event(String name, [Map<String, Object> params = const {}]) {}
  @override
  void nonFatal(Object error, StackTrace? stack) {}
}

class FirebaseTelemetry extends Telemetry {
  const FirebaseTelemetry();
  @override
  void event(String name, [Map<String, Object> params = const {}]) {
    FirebaseAnalytics.instance
        .logEvent(name: name, parameters: params)
        .ignore();
  }

  @override
  void nonFatal(Object error, StackTrace? stack) {
    FirebaseCrashlytics.instance.recordError(error, stack).ignore();
  }
}

/// Swapped in `bootstrap` for stg and prod. A plain global so non-widget code (the error mapper)
/// can report without a ref.
Telemetry telemetry = const NoopTelemetry();

/// Funnel event names.
abstract final class TelemetryEvent {
  static const signIn = 'sign_in';
  static const search = 'worker_search';
  static const interviewRequest = 'interview_request';
  static const paymentSuccess = 'payment_success';
}
