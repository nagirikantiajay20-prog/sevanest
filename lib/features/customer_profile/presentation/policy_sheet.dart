import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/providers/account_providers.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// Cancellation and refund text from `GET /app-config` -> `policy`. Callers show the entry point
/// only when `!policy.isEmpty`; a null section is left out.
Future<void> showPolicySheet(
  BuildContext context,
  WidgetRef ref,
  PolicyConfig policy,
) {
  final l10n = AppLocalizations.of(context);
  final open = ref.read(openInAppBrowserProvider);
  Widget section(String title, String? text, String? url) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        if (text != null) Text(text),
        if (url != null)
          TextButton(
            onPressed: () => open(url),
            child: Text(l10n.policyReadMore),
          ),
      ],
    ),
  );
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => SafeArea(
      child: SingleChildScrollView(
        key: const Key('policy_sheet'),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (policy.cancellationText != null ||
                policy.cancellationUrl != null)
              section(
                l10n.policyCancellationTitle,
                policy.cancellationText,
                policy.cancellationUrl,
              ),
            if (policy.refundText != null || policy.refundUrl != null)
              section(
                l10n.policyRefundTitle,
                policy.refundText,
                policy.refundUrl,
              ),
          ],
        ),
      ),
    ),
  );
}
