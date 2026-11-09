import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/localization/failure_message.dart';
import 'package:sevanest_customer/core/widgets/labeled_field.dart';
import 'package:sevanest_customer/core/widgets/offline_banner.dart'
    show onlineProvider;
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart'
    show authSerif;
import 'package:sevanest_customer/features/booking/presentation/providers/booking_providers.dart';
import 'package:sevanest_customer/features/booking/presentation/widgets/booking_confirm_parts.dart'
    show ConfirmRows;
import 'package:sevanest_customer/features/interview_trial/presentation/widgets/interview_request_parts.dart'
    show RequestSection;
import 'package:sevanest_customer/features/payment/domain/payment.dart';
import 'package:sevanest_customer/features/payment/presentation/payment_labels.dart';
import 'package:sevanest_customer/features/payment/presentation/providers/payment_flow.dart';
import 'package:sevanest_customer/features/payment/presentation/widgets/payment_parts.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/engagement_labels.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/schedule_format.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_page.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_success_overlay.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// `/payments/:id` (module 09, screens 9.1 + 9.2). `id` is `new` with `?bookingId=` to start a
/// payment, or an existing payment id (recovery, "check again").
///
/// A view over [paymentFlowProvider], which owns the lifecycle: the SDK answer is only a hint,
/// SUCCESS is shown when the backend says so, and a lost answer or connection is never "failed".
class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({this.paymentId, this.bookingId, super.key});
  final String? paymentId;
  final String? bookingId;

  @override
  ConsumerState<PaymentScreen> createState() => _State();
}

class _State extends ConsumerState<PaymentScreen> {
  /// The flow outlives screens; until this one has asked it to open, show nothing of an old run.
  bool _opened = false;

  PaymentFlow get _flow => ref.read(paymentFlowProvider.notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        _flow.open(paymentId: widget.paymentId, bookingId: widget.bookingId),
      );
      setState(() => _opened = true);
    });
  }

  PaymentFlowState get _s => ref.read(paymentFlowProvider);
  String get _bookingId =>
      _s.payment?.bookingId ?? _s.bookingId ?? widget.bookingId ?? '';

  void _showCancelled() {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.payCancelledSnack),
          // Above the Pay bar, so the button stays tappable while it shows.
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        ),
      );
    _flow.clearNotice();
  }

  String _loadError(AppLocalizations l10n, Object e) =>
      e is ValidationFailure && e.code == 'FEE_NOT_CONFIGURED'
      ? l10n.payFeeNotConfigured
      : failureMessage(l10n, e);

  void _toBooking() =>
      context.go(Routes.path(Routes.bookingDetail, {'id': _bookingId}));

  Future<void> _back() async {
    final l10n = AppLocalizations.of(context);
    final phase = _s.phase;
    if (phase == PayPhase.paying || phase == PayPhase.verifying) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.payVerifyingWait)));
      return;
    }
    if (phase == PayPhase.ready) {
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
    final s = ref.watch(paymentFlowProvider);
    ref.listen(paymentFlowProvider.select((f) => f.notice), (_, n) {
      if (n == PayNotice.cancelled) _showCancelled();
    });
    final flow = _flow;
    final p = s.payment;
    final phase = _opened ? s.phase : PayPhase.loading;
    // Offline: either a status read just failed for lack of a connection, or the device says so.
    final offline = s.offline || ref.watch(onlineProvider).value == false;
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

    final Widget body = switch (phase) {
      PayPhase.loading => const Center(
        child: CircularProgressIndicator(key: Key('payment_loading')),
      ),
      PayPhase.loadFailed => PayResult(
        icon: Icons.error_outline_rounded,
        colors: bad,
        title: l10n.payFailedTitle,
        body: s.failure == null
            ? l10n.errorGeneric
            : _loadError(l10n, s.failure!),
        buttons: [
          PayButton(
            key: const Key('payment_load_retry_btn'),
            label: l10n.retry,
            onPressed: flow.reload,
          ),
          PayOutline(
            key: const Key('payment_close_btn'),
            label: l10n.payClose,
            onPressed: _back,
          ),
        ],
      ),
      PayPhase.notPayable => PayResult(
        icon: Icons.info_outline_rounded,
        colors: const [AppColors.teal, dsSky],
        title: l10n.payNotPayableTitle,
        body: l10n.payNotPayableBody,
        buttons: [viewBooking()],
      ),
      // The success card is the page overlay below.
      PayPhase.success => const SizedBox.shrink(),
      PayPhase.failed => PayResult(
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
            onPressed: flow.retry,
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
      PayPhase.pending => PayResult(
        icon: offline ? Icons.wifi_off_rounded : Icons.hourglass_top_rounded,
        colors: wait,
        title: offline ? l10n.payOfflineTitle : l10n.payPendingTitle,
        body: offline ? l10n.payOfflineBody : l10n.payPendingBody,
        buttons: [
          PayButton(
            key: const Key('payment_refresh_btn'),
            label: l10n.payRefresh,
            onPressed: flow.refresh,
          ),
          if (s.resumed && (p?.canPay ?? false))
            PayOutline(
              key: const Key('payment_pay_again_btn'),
              label: l10n.payAgain,
              onPressed: flow.payAgain,
            ),
          if (p != null)
            PayOutline(
              key: const Key('payment_view_transaction_btn'),
              label: l10n.payViewTransaction,
              onPressed: () => context.push(
                Routes.path(Routes.transactionDetail, {'id': p.id}),
              ),
            ),
          viewBooking(outline: true),
        ],
      ),
      PayPhase.verifying => PayResult(
        icon: Icons.lock_clock_rounded,
        colors: const [AppColors.teal, dsSky],
        title: l10n.payVerifying,
        body: l10n.payVerifyingWait,
        loading: true,
        buttons: const [],
      ),
      PayPhase.ready || PayPhase.paying => _ReadyBody(
        payment: p,
        bookingId: _bookingId,
        locale: locale,
      ),
    };

    final canPay = phase == PayPhase.ready || phase == PayPhase.paying;
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
        overlay: phase == PayPhase.success && p != null
            ? GlassSuccessOverlay(
                title: l10n.paySuccessTitle,
                // The booking is confirmed only when the backend says so.
                body: bookingIsConfirmed(s.bookingStatus)
                    ? l10n.paySuccessBody
                    : l10n.payBookingPendingBody,
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
                label: phase == PayPhase.paying
                    ? l10n.payButtonBusy
                    : l10n.payButton(paymentAmount(p)),
                loading: phase == PayPhase.paying,
                icon: Icons.lock_outline_rounded,
                onPressed: phase == PayPhase.ready ? flow.pay : null,
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
