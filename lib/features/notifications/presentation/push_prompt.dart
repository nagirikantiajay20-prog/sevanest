import 'package:sevanest_customer/features/notifications/presentation/providers/push_providers.dart';

/// Asks for notification permission AFTER a first meaningful action, never at launch. There is no
/// custom dialog: the only prompt is the operating system's, shown at most once. Denied or
/// unavailable permission is never asked again here; Account and the centre show "Notifications
/// off" with a button to the system settings.
Future<void> askForPushAfterAction(PushController controller) async {
  if (await controller.shouldAsk()) await controller.allow();
}
