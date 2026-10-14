import 'package:flutter/material.dart';
import 'package:sevanest_customer/features/notifications/presentation/providers/push_providers.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// The pre-prompt (docs/modules/13): asked AFTER a first meaningful action (the first interview
/// request), never at launch. Allow opens the OS dialog; "Not now" asks again after the re-ask
/// window. Denied or unavailable permission is never asked again here: Account and the centre
/// show "Notifications off" with a button to the system settings.
Future<void> askForPushAfterAction(
  BuildContext context,
  PushController controller,
) async {
  if (!await controller.shouldAsk() || !context.mounted) return;
  final l10n = AppLocalizations.of(context);
  final allow = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      key: const Key('notif_prompt'),
      icon: const Icon(Icons.notifications_active_outlined),
      title: Text(l10n.notifPromptTitle),
      content: Text(l10n.notifPromptBody),
      actions: [
        TextButton(
          key: const Key('notif_prompt_later_btn'),
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.notifPromptLater),
        ),
        FilledButton(
          key: const Key('notif_prompt_allow_btn'),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l10n.notifPromptAllow),
        ),
      ],
    ),
  );
  if (allow ?? false) {
    await controller.allow();
  } else {
    await controller.defer();
  }
}
