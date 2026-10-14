import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/features/payment/presentation/providers/payment_providers.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// "We're still confirming your last payment" with a View shortcut, for Home (any booking) and a
/// booking's detail ([bookingId]: only that booking's payment). Empty when nothing is unconfirmed.
class PendingPaymentBanner extends ConsumerWidget {
  const PendingPaymentBanner({this.bookingId, super.key});
  final String? bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(unconfirmedPaymentProvider).value;
    if (p == null || (bookingId != null && p.bookingId != bookingId)) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        key: const Key('pending_payment_banner'),
        padding: const EdgeInsets.only(left: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.warnBg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.amber.withValues(alpha: .3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.hourglass_top, color: AppColors.warn),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(l10n.payRecoveredPending)),
            TextButton(
              key: const Key('pending_payment_view_btn'),
              onPressed: () =>
                  context.push(Routes.path(Routes.payment, {'id': p.id})),
              child: Text(l10n.payRecoveredView),
            ),
          ],
        ),
      ),
    );
  }
}
