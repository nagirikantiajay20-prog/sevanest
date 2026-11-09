import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/app/router/app_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/core/session/auth_state.dart';
import 'package:sevanest_customer/core/widgets/offline_banner.dart';
import 'package:sevanest_customer/features/booking/presentation/providers/booking_providers.dart';
import 'package:sevanest_customer/features/home/presentation/providers/home_providers.dart';
import 'package:sevanest_customer/features/payment/domain/payment.dart';
import 'package:sevanest_customer/features/payment/presentation/providers/payment_flow.dart';
import 'package:sevanest_customer/features/payment/presentation/providers/payment_providers.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// App-kill / resume recovery (module 09): if a payment id is stored, read the payment. A settled
/// one is cleared, the booking and lists are refreshed, and the customer is told; one still being
/// confirmed gets a "View" shortcut to its payment screen. Sits above the router.
class PaymentRecoveryHost extends ConsumerStatefulWidget {
  const PaymentRecoveryHost({required this.child, super.key});
  final Widget child;

  @override
  ConsumerState<PaymentRecoveryHost> createState() => _State();
}

class _State extends ConsumerState<PaymentRecoveryHost>
    with WidgetsBindingObserver {
  bool _running = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_recover()));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_recover());
  }

  Future<void> _recover() async {
    if (_running) return;
    _running = true;
    try {
      // Nothing to read without a signed-in customer.
      if (ref.read(authProvider) != AuthStatus.authenticated) return;
      final store = ref.read(pendingPaymentStoreProvider);
      final id = await store.read();
      if (id == null || !mounted) return;
      // A payment screen that is open on this payment is already driving it.
      final router = ref.read(appRouterProvider);
      final here = router.routerDelegate.currentConfiguration.uri.path;
      if (here.startsWith('/payments/')) return;
      final Payment p;
      try {
        p = await ref.read(paymentRepositoryProvider).get(id);
      } on Object {
        return; // try again on the next resume; the id stays stored
      }
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      final messenger = ScaffoldMessenger.of(context);
      if (p.isSettled || p.status == PaymentStatus.created) {
        await store.clear();
        ref
          ..invalidate(unconfirmedPaymentProvider)
          ..invalidate(bookingListProvider)
          ..invalidate(homeProvider)
          ..invalidate(transactionListProvider)
          ..invalidate(bookingProvider(p.bookingId));
        // CREATED = opened but never paid; nothing to report.
        if (p.status == PaymentStatus.created) return;
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                p.wasPaid ? l10n.payRecoveredPaid : l10n.payRecoveredFailed,
              ),
              action: SnackBarAction(
                label: l10n.payRecoveredView,
                onPressed: () => router.push(
                  Routes.path(Routes.bookingDetail, {'id': p.bookingId}),
                ),
              ),
            ),
          );
      } else {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(l10n.payRecoveredPending),
              action: SnackBarAction(
                label: l10n.payRecoveredView,
                onPressed: () =>
                    router.push(Routes.path(Routes.payment, {'id': p.id})),
              ),
            ),
          );
      }
    } finally {
      _running = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // The first check may run before the session is restored: look again once signed in.
    ref
      // Keeps the payment flow (its connectivity and resume hooks) alive between screens.
      ..listen(paymentFlowProvider, (_, _) {})
      ..listen(authProvider, (_, s) {
        if (s == AuthStatus.authenticated) unawaited(_recover());
      })
      // Connection back: look at an unresolved payment again (never pays again by itself).
      ..listen(onlineProvider, (prev, next) {
        if (prev?.value == false && next.value == true) unawaited(_recover());
      });
    return widget.child;
  }
}
