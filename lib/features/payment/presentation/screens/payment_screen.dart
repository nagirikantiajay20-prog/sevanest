import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/core/analytics/telemetry.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/localization/failure_message.dart';
import 'package:sevanest_customer/core/widgets/labeled_field.dart';
import 'package:sevanest_customer/core/widgets/sn_button.dart';
import 'package:sevanest_customer/core/widgets/sn_card.dart';
import 'package:sevanest_customer/core/widgets/sn_header.dart';
import 'package:sevanest_customer/features/payment/domain/payment.dart';
import 'package:sevanest_customer/features/payment/presentation/payment_labels.dart';
import 'package:sevanest_customer/features/payment/presentation/providers/payment_providers.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';
import 'package:uuid/uuid.dart';

enum _Phase {
  loading,
  loadFailed,
  ready,
  paying,
  verifying,
  success,
  failed,
  pending,
  notPayable,
}

/// `/payments/:id` (module 09, screens 9.1 + 9.2). `id` is `new` with `?bookingId=` to start a
/// payment, or an existing payment id (recovery, "check again").
///
/// The SDK answer is only a hint: SUCCESS is shown when the backend says so. If an answer is
/// lost the payment is read again before anything is called a failure.
class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({this.paymentId, this.bookingId, super.key});
  final String? paymentId;
  final String? bookingId;

  @override
  ConsumerState<PaymentScreen> createState() => _State();
}

class _State extends ConsumerState<PaymentScreen> {
  _Phase _phase = _Phase.loading;
  Payment? _p;
  String? _error;
  bool _busy = false; // synchronous guard: a double tap pays once

  /// The SDK reported a payment, so this payment is "confirming" from now on, even if the server
  /// still shows its checkout (a `PENDING` payment with a checkout otherwise means "can pay").
  bool _confirming = false;

  /// Opened again from a stored id (app killed or left while the checkout was open): the customer
  /// may or may not have paid, so it reads "confirming" and offers Check again / Pay again.
  bool _resumed = false;

  /// A `CREATED` payment (gateway order not made yet) is started again once, not in a loop.
  bool _restarted = false;

  String get _bookingId => _p?.bookingId ?? widget.bookingId ?? '';

  @override
  void initState() {
    super.initState();
    // After the first frame: _load reads the localizations, which initState cannot.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(_load(fresh: widget.paymentId == null)),
    );
  }

  String _key() => const Uuid().v4();

  void _set(_Phase p, {String? error}) {
    if (!mounted) return;
    setState(() {
      _phase = p;
      _error = error;
    });
    // The stored id changes with the phases; Home and the booking show a banner from it.
    ref.invalidate(unconfirmedPaymentProvider);
  }

  /// Resumed payment, and the customer says it was not paid: back to the checkout.
  void _payAgain() {
    _confirming = false;
    _resumed = false;
    final p = _p;
    if (p != null) unawaited(_show(p));
  }

  /// Starts (or resumes) the payment of the booking, or reads an existing one.
  Future<void> _load({required bool fresh, bool restart = false}) async {
    final l10n = AppLocalizations.of(context);
    if (!restart) {
      _confirming = false;
      _resumed = false;
      _restarted = false;
    }
    _set(_Phase.loading);
    final repo = ref.read(paymentRepositoryProvider);
    try {
      final p = fresh
          ? await repo.start(_bookingId, idempotencyKey: _key())
          : await repo.get(widget.paymentId!);
      if (!fresh &&
          p.canPay &&
          await ref.read(pendingPaymentStoreProvider).read() == p.id) {
        _confirming = true;
        _resumed = true;
      }
      await _show(p);
    } on ConflictFailure catch (e) {
      if (e.code == 'BOOKING_NOT_PAYABLE') {
        // Already paid, cancelled, or not at the payment step: show what the server holds now.
        if (mounted) refreshAfterPayment(ref, _bookingId);
        _set(_Phase.notPayable);
      } else {
        _set(_Phase.loadFailed, error: failureMessage(l10n, e));
      }
    } on ValidationFailure catch (e) {
      _set(
        _Phase.loadFailed,
        error: e.code == 'FEE_NOT_CONFIGURED'
            ? l10n.payFeeNotConfigured
            : failureMessage(l10n, e),
      );
    } on Object catch (e) {
      _set(_Phase.loadFailed, error: failureMessage(l10n, e));
    }
  }

  /// Puts a payment from the server on screen.
  Future<void> _show(Payment p) async {
    if (!mounted) return;
    _p = p;
    if (p.wasPaid) {
      telemetry.event(TelemetryEvent.paymentSuccess);
      await _paid(p);
    } else if (p.status == PaymentStatus.failed) {
      await ref.read(pendingPaymentStoreProvider).clear();
      _set(_Phase.failed);
    } else if (_confirming) {
      _set(_Phase.pending);
    } else if (p.canPay) {
      _set(_Phase.ready);
    } else if (p.status == PaymentStatus.created && !_restarted) {
      // The gateway order does not exist yet: `POST /payments` again makes it.
      _restarted = true;
      await _load(fresh: true, restart: true);
    } else {
      _set(_Phase.pending);
    }
  }

  Future<void> _paid(Payment p) async {
    await ref.read(pendingPaymentStoreProvider).clear();
    if (!mounted) return;
    refreshAfterPayment(ref, p.bookingId);
    _set(_Phase.success);
  }

  Future<Payment?> _tryGet(String id) async {
    try {
      return await ref.read(paymentRepositoryProvider).get(id);
    } on Object {
      return null;
    }
  }

  Future<void> _pay() async {
    final p = _p;
    if (_busy || p == null || _phase != _Phase.ready) return;
    _busy = true;
    try {
      _set(_Phase.paying);
      await ref.read(pendingPaymentStoreProvider).write(p.id);
      PaymentOutcome out;
      try {
        out = await ref.read(paymentServiceProvider).pay(p);
      } on Object {
        out = const PaymentSdkFailed();
      }
      switch (out) {
        case PaymentPaid():
          _confirming = true;
          await _verify(p, out);
        case PaymentCancelled():
          await _noPayment(p, cancelled: true);
        case PaymentSdkFailed():
          await _noPayment(p, cancelled: false);
      }
    } finally {
      _busy = false;
    }
  }

  /// The SDK said the customer paid: ask the server, then wait for a settled answer.
  Future<void> _verify(Payment p, PaymentPaid out) async {
    _set(_Phase.verifying);
    Payment? latest;
    try {
      latest = await ref
          .read(paymentRepositoryProvider)
          .verify(
            p.id,
            providerPaymentId: out.providerPaymentId,
            signature: out.signature,
            idempotencyKey: _key(),
          );
    } on ValidationFailure {
      // PAYMENT_VERIFICATION_FAILED: the signature was refused and nothing changed.
      latest = await _tryGet(p.id);
      if (!(latest?.isSettled ?? false)) {
        await ref.read(pendingPaymentStoreProvider).clear();
        _set(_Phase.failed);
        return;
      }
    } on Object {
      // A lost answer or a repeat in flight: the payment may well have gone through.
      latest = await _tryGet(p.id);
    }
    var cur = latest;
    final delays = ref.read(paymentPollDelaysProvider);
    for (var i = 0; i < delays.length && !(cur?.isSettled ?? false); i++) {
      await Future<void>.delayed(delays[i]);
      if (!mounted) return;
      cur = await _tryGet(p.id) ?? cur;
    }
    if (!mounted) return;
    if (cur == null || !cur.isSettled) {
      _p = cur ?? p;
      _set(_Phase.pending); // still confirming: never "failed", never "success"
    } else {
      await _show(cur);
    }
  }

  /// Cancelled or failed inside the SDK: the server is still the judge.
  Future<void> _noPayment(Payment p, {required bool cancelled}) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final q = await _tryGet(p.id);
    if (!mounted) return;
    if (q != null && !q.canPay && q.status != PaymentStatus.created) {
      await _show(q); // paid anyway, failed, or still confirming
      return;
    }
    await ref.read(pendingPaymentStoreProvider).clear();
    if (cancelled) {
      _set(_Phase.ready);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.payCancelledSnack)));
    } else {
      _set(_Phase.failed);
    }
  }

  Future<void> _refresh() async {
    final p = _p;
    if (_busy || p == null) return;
    _busy = true;
    try {
      final q = await _tryGet(p.id);
      if (q != null) await _show(q);
    } finally {
      _busy = false;
    }
  }

  void _toBooking() =>
      context.go(Routes.path(Routes.bookingDetail, {'id': _bookingId}));

  Future<void> _back() async {
    final l10n = AppLocalizations.of(context);
    if (_phase == _Phase.paying || _phase == _Phase.verifying) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.payVerifyingWait)));
      return;
    }
    if (_phase == _Phase.ready) {
      final leave = await confirmDialog(
        context,
        title: l10n.payLeaveTitle,
        body: l10n.payLeaveBody,
        confirmLabel: l10n.payLeaveConfirm,
        cancelLabel: l10n.payLeaveStay,
        confirmKey: const Key('payment_leave_confirm_btn'),
      );
      if (!leave || !mounted) return;
    }
    if (_bookingId.isEmpty) {
      context.go(Routes.bookings);
    } else {
      _toBooking();
    }
  }

  Widget _result({
    required IconData icon,
    required Color color,
    required String title,
    required String body,
    required List<Widget> buttons,
    Widget? extra,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: Icon(icon, size: 44, color: color),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: AppText.title, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text(body, style: AppText.bodyLarge, textAlign: TextAlign.center),
            ?extra,
            const SizedBox(height: AppSpacing.lg),
            for (final b in buttons) ...[
              b,
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final p = _p;

    SnButton viewBooking() => SnButton(
      key: const Key('payment_view_booking_btn'),
      label: l10n.payViewBooking,
      variant: SnButtonVariant.deep,
      onPressed: _toBooking,
    );

    final Widget body = switch (_phase) {
      _Phase.loading => const Center(
        child: CircularProgressIndicator(key: Key('payment_loading')),
      ),
      _Phase.loadFailed => _result(
        icon: Icons.error_outline,
        color: scheme.error,
        title: l10n.payFailedTitle,
        body: _error ?? l10n.errorGeneric,
        buttons: [
          SnButton(
            key: const Key('payment_load_retry_btn'),
            label: l10n.retry,
            onPressed: () => _load(fresh: widget.paymentId == null),
          ),
          SnButton(
            key: const Key('payment_close_btn'),
            label: l10n.payClose,
            variant: SnButtonVariant.secondary,
            onPressed: _back,
          ),
        ],
      ),
      _Phase.notPayable => _result(
        icon: Icons.info_outline,
        color: scheme.primary,
        title: l10n.payNotPayableTitle,
        body: l10n.payNotPayableBody,
        buttons: [viewBooking()],
      ),
      _Phase.success => _result(
        icon: Icons.check_circle,
        color: scheme.primary,
        title: l10n.paySuccessTitle,
        body: l10n.paySuccessBody,
        extra: p == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: SnCard(
                  child: Column(
                    children: [
                      Text(
                        paymentAmount(p),
                        key: const Key('payment_success_amount'),
                        style: AppText.title,
                      ),
                      if (p.receiptNumber != null)
                        Text(
                          l10n.payReceiptNumber(p.receiptNumber!),
                          style: AppText.body,
                        ),
                    ],
                  ),
                ),
              ),
        buttons: [
          viewBooking(),
          if (p != null)
            SnButton(
              key: const Key('payment_receipt_btn'),
              label: l10n.payViewReceipt,
              variant: SnButtonVariant.secondary,
              onPressed: () => context.push(
                Routes.path(Routes.transactionDetail, {'id': p.id}),
              ),
            ),
        ],
      ),
      _Phase.failed => _result(
        icon: Icons.cancel_outlined,
        color: scheme.error,
        title: l10n.payFailedTitle,
        body: p?.failureReason ?? l10n.payFailedBody,
        extra: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Text(
            l10n.payFailedDebitNote,
            key: const Key('payment_debit_note'),
            textAlign: TextAlign.center,
            style: AppText.meta,
          ),
        ),
        buttons: [
          SnButton(
            key: const Key('payment_retry_btn'),
            label: l10n.payRetry,
            // Starts the same booking's payment again; a booking is never created twice.
            onPressed: () => _load(fresh: true),
          ),
          SnButton(
            key: const Key('payment_support_btn'),
            label: l10n.payGetHelp,
            variant: SnButtonVariant.secondary,
            onPressed: () => context.push(
              '${Routes.supportNew}?paymentId=${Uri.encodeComponent(p?.id ?? '')}',
            ),
          ),
          SnButton(
            key: const Key('payment_close_btn'),
            label: l10n.payClose,
            variant: SnButtonVariant.text,
            onPressed: _toBooking,
          ),
        ],
      ),
      _Phase.pending => _result(
        icon: Icons.hourglass_top,
        color: scheme.tertiary,
        title: l10n.payPendingTitle,
        body: l10n.payPendingBody,
        buttons: [
          SnButton(
            key: const Key('payment_refresh_btn'),
            label: l10n.payRefresh,
            onPressed: _refresh,
          ),
          if (_resumed && (p?.canPay ?? false))
            SnButton(
              key: const Key('payment_pay_again_btn'),
              label: l10n.payAgain,
              variant: SnButtonVariant.secondary,
              onPressed: _payAgain,
            ),
          SnButton(
            key: const Key('payment_view_booking_btn'),
            label: l10n.payViewBooking,
            variant: SnButtonVariant.secondary,
            onPressed: _toBooking,
          ),
        ],
      ),
      _Phase.verifying => _result(
        icon: Icons.lock_clock,
        color: scheme.primary,
        title: l10n.payVerifying,
        body: l10n.payVerifyingWait,
        buttons: const [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(key: Key('payment_verifying')),
          ),
        ],
      ),
      _Phase.ready || _Phase.paying => SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.payHeading, style: AppText.title),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.paySub, style: AppText.bodyLarge),
            const SizedBox(height: AppSpacing.lg),
            SnCard(
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.payAmountLabel, style: AppText.meta),
                    Text(
                      p == null ? '' : paymentAmount(p),
                      key: const Key('payment_amount'),
                      style: AppText.display,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    };

    final canPay = _phase == _Phase.ready || _phase == _Phase.paying;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_back());
      },
      child: Scaffold(
        backgroundColor: AppColors.canvasCool,
        body: Column(
          children: [
            SnHeader(title: l10n.payTitle, onBack: _back),
            Expanded(child: body),
          ],
        ),
        bottomNavigationBar: canPay && p != null
            ? DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  boxShadow: AppShadows.floating,
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: SnButton(
                      key: const Key('payment_pay_btn'),
                      label: l10n.payButton(paymentAmount(p)),
                      loadingLabel: l10n.payButtonBusy,
                      isLoading: _phase == _Phase.paying,
                      variant: SnButtonVariant.deep,
                      onPressed: _phase == _Phase.ready ? _pay : null,
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
