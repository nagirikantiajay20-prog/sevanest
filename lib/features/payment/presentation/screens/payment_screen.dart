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
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart'
    show authSerif;
import 'package:sevanest_customer/features/booking/presentation/providers/booking_providers.dart';
import 'package:sevanest_customer/features/booking/presentation/widgets/booking_confirm_parts.dart'
    show ConfirmRows;
import 'package:sevanest_customer/features/interview_trial/presentation/widgets/interview_request_parts.dart'
    show RequestSection;
import 'package:sevanest_customer/features/payment/domain/payment.dart';
import 'package:sevanest_customer/features/payment/presentation/payment_labels.dart';
import 'package:sevanest_customer/features/payment/presentation/providers/payment_providers.dart';
import 'package:sevanest_customer/features/payment/presentation/widgets/payment_parts.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/engagement_labels.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/schedule_format.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_page.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_success_overlay.dart';
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
        ..showSnackBar(
          SnackBar(
            content: Text(l10n.payCancelledSnack),
            // Above the Pay bar, so the button stays tappable while it shows.
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          ),
        );
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final p = _p;
    const bad = [AppColors.rose700, AppColors.redF43F5E];
    const wait = [AppColors.warnIcon, AppColors.amber];

    Widget viewBooking({bool outline = false}) => outline
        ? PayOutline(
            key: const Key('payment_view_booking_btn'),
            label: l10n.payViewBooking,
            onPressed: _toBooking,
          )
        : PayButton(
            key: const Key('payment_view_booking_btn'),
            label: l10n.payViewBooking,
            onPressed: _toBooking,
          );

    final Widget body = switch (_phase) {
      _Phase.loading => const Center(
        child: CircularProgressIndicator(key: Key('payment_loading')),
      ),
      _Phase.loadFailed => PayResult(
        icon: Icons.error_outline_rounded,
        colors: bad,
        title: l10n.payFailedTitle,
        body: _error ?? l10n.errorGeneric,
        buttons: [
          PayButton(
            key: const Key('payment_load_retry_btn'),
            label: l10n.retry,
            onPressed: () => _load(fresh: widget.paymentId == null),
          ),
          PayOutline(
            key: const Key('payment_close_btn'),
            label: l10n.payClose,
            onPressed: _back,
          ),
        ],
      ),
      _Phase.notPayable => PayResult(
        icon: Icons.info_outline_rounded,
        colors: const [AppColors.teal, dsSky],
        title: l10n.payNotPayableTitle,
        body: l10n.payNotPayableBody,
        buttons: [viewBooking()],
      ),
      // The success card is the page overlay below.
      _Phase.success => const SizedBox.shrink(),
      _Phase.failed => PayResult(
        icon: Icons.close_rounded,
        colors: bad,
        title: l10n.payFailedTitle,
        body: p?.failureReason ?? l10n.payFailedBody,
        extra: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            l10n.payFailedDebitNote,
            key: const Key('payment_debit_note'),
            textAlign: TextAlign.center,
            style: AppText.meta,
          ),
        ),
        buttons: [
          PayButton(
            key: const Key('payment_retry_btn'),
            label: l10n.payRetry,
            danger: true,
            // Starts the same booking's payment again; a booking is never created twice.
            onPressed: () => _load(fresh: true),
          ),
          PayOutline(
            key: const Key('payment_support_btn'),
            label: l10n.payGetHelp,
            onPressed: () => context.push(
              '${Routes.supportNew}?paymentId=${Uri.encodeComponent(p?.id ?? '')}',
            ),
          ),
          PayOutline(
            key: const Key('payment_close_btn'),
            label: l10n.payClose,
            quiet: true,
            onPressed: _toBooking,
          ),
        ],
      ),
      _Phase.pending => PayResult(
        icon: Icons.hourglass_top_rounded,
        colors: wait,
        title: l10n.payPendingTitle,
        body: l10n.payPendingBody,
        buttons: [
          PayButton(
            key: const Key('payment_refresh_btn'),
            label: l10n.payRefresh,
            onPressed: _refresh,
          ),
          if (_resumed && (p?.canPay ?? false))
            PayOutline(
              key: const Key('payment_pay_again_btn'),
              label: l10n.payAgain,
              onPressed: _payAgain,
            ),
          viewBooking(outline: true),
        ],
      ),
      _Phase.verifying => PayResult(
        icon: Icons.lock_clock_rounded,
        colors: const [AppColors.teal, dsSky],
        title: l10n.payVerifying,
        body: l10n.payVerifyingWait,
        loading: true,
        buttons: const [],
      ),
      _Phase.ready || _Phase.paying => _ReadyBody(
        payment: p,
        bookingId: _bookingId,
        locale: locale,
      ),
    };

    final canPay = _phase == _Phase.ready || _phase == _Phase.paying;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_back());
      },
      child: FindGlassPage(
        title: l10n.payTitle,
        backLabel: l10n.back,
        onBack: _back,
        body: body,
        overlay: _phase == _Phase.success && p != null
            ? GlassSuccessOverlay(
                title: l10n.paySuccessTitle,
                body: l10n.paySuccessBody,
                rows: [
                  (l10n.payAmountPaid, paymentAmount(p)),
                  if (p.receiptNumber != null)
                    (l10n.payReceiptRow, p.receiptNumber!),
                  (l10n.txnStatusRow, paymentStatusLabel(l10n, p.status)),
                ],
                ctaKey: const Key('payment_view_booking_btn'),
                ctaLabel: l10n.payViewBooking,
                onPressed: _toBooking,
                secondary: PayOutline(
                  key: const Key('payment_receipt_btn'),
                  label: l10n.payViewReceipt,
                  onPressed: () => context.push(
                    Routes.path(Routes.transactionDetail, {'id': p.id}),
                  ),
                ),
              )
            : null,
        bottom: canPay && p != null
            ? PayButton(
                key: const Key('payment_pay_btn'),
                label: _phase == _Phase.paying
                    ? l10n.payButtonBusy
                    : l10n.payButton(paymentAmount(p)),
                loading: _phase == _Phase.paying,
                icon: Icons.lock_outline_rounded,
                onPressed: _phase == _Phase.ready ? _pay : null,
              )
            : null,
      ),
    );
  }
}

/// "Pay the booking fee": heading, amount card, who and when, and the methods on offer. The
/// worker and start date come from the booking when it has loaded; the page works without them.
class _ReadyBody extends ConsumerWidget {
  const _ReadyBody({
    required this.payment,
    required this.bookingId,
    required this.locale,
  });
  final Payment? payment;
  final String bookingId;
  final String locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final p = payment;
    final b = bookingId.isEmpty
        ? null
        : ref.watch(bookingProvider(bookingId)).value;
    final name = b?.identity?.displayName;
    final service = [
      ?b?.categoryName,
      if (b?.engagement != null) engagementLabels(l10n, b!.engagement!).name,
    ].join(' · ');
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        DiscoverRise(
          delayMs: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(l10n.payHeading, style: authSerif(30, 1.15)),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.paySub,
                  style: AppText.body.copyWith(
                    fontSize: 15,
                    height: 1.45,
                    color: dsText,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        DiscoverRise(
          delayMs: 100,
          child: PayAmountCard(
            label: l10n.payAmountLabel,
            amount: p == null ? '' : paymentAmount(p),
            amountKey: const Key('payment_amount'),
          ),
        ),
        if (b != null && name != null)
          RequestSection(
            title: l10n.bookingDetailTitle,
            delayMs: 180,
            child: Column(
              children: [
                PayWorkerLine(
                  name: name,
                  subtitle: service,
                  gradient: avatarGradientFor(b.workerId ?? b.id),
                ),
                const SizedBox(height: 12),
                ConfirmRows(
                  rows: [
                    if (b.startDate != null)
                      (l10n.payStartsRow, formatDate(b.startDate!, locale)),
                    (l10n.txnReferenceRow, b.reference),
                  ],
                ),
              ],
            ),
          ),
        RequestSection(
          title: l10n.payPayWith,
          delayMs: 260,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PayMethodTile(
                icon: Icons.smartphone_rounded,
                title: l10n.txnMethodUpi,
                note: l10n.payMethodUpiNote,
                badge: l10n.payFastest,
              ),
              PayMethodTile(
                icon: Icons.credit_card_rounded,
                title: l10n.payMethodCardTitle,
                note: l10n.payMethodCardNote,
              ),
              PayMethodTile(
                icon: Icons.account_balance_rounded,
                title: l10n.txnMethodNetbanking,
                note: l10n.payMethodNetNote,
              ),
              PayMethodTile(
                icon: Icons.account_balance_wallet_outlined,
                title: l10n.txnMethodWallet,
                note: l10n.payMethodWalletNote,
              ),
              PaySecureNote(l10n.paySecureNote),
            ],
          ),
        ),
      ],
    );
  }
}
