import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/core/analytics/telemetry.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/widgets/offline_banner.dart';
import 'package:sevanest_customer/features/booking/domain/booking.dart';
import 'package:sevanest_customer/features/booking/presentation/providers/booking_providers.dart';
import 'package:sevanest_customer/features/payment/domain/payment.dart';
import 'package:sevanest_customer/features/payment/presentation/providers/payment_providers.dart';
import 'package:uuid/uuid.dart';

enum PayPhase {
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

/// Calls [onResume] whenever the app returns to the foreground.
class _ResumeObserver with WidgetsBindingObserver {
  _ResumeObserver(this.onResume);
  final VoidCallback onResume;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) onResume();
  }
}

/// One-shot message for the screen to show (and clear).
enum PayNotice { cancelled }

/// A booking counts as confirmed only when the backend says so. Payment status and booking
/// status are separate: a SUCCEEDED payment can sit beside a booking that is not confirmed yet.
bool bookingIsConfirmed(BookingStatus? s) =>
    s == BookingStatus.confirmed || s == BookingStatus.active;

class PaymentFlowState {
  const PaymentFlowState({
    this.phase = PayPhase.loading,
    this.payment,
    this.failure,
    this.offline = false,
    this.resumed = false,
    this.bookingStatus,
    this.notice,
    this.bookingId,
  });

  final PayPhase phase;
  final Payment? payment;

  /// Why the payment could not be loaded ([PayPhase.loadFailed]).
  final Object? failure;

  /// The last status read failed for lack of a connection: the payment is not judged, only unread.
  final bool offline;

  /// Opened again after the checkout may have been paid: reads "confirming", offers Pay again.
  final bool resumed;

  /// The booking as the backend reports it after a payment; null until read.
  final BookingStatus? bookingStatus;
  final PayNotice? notice;
  final String? bookingId;

  PaymentFlowState copyWith({
    PayPhase? phase,
    Payment? payment,
    Object? failure,
    bool clearFailure = false,
    bool? offline,
    bool? resumed,
    BookingStatus? bookingStatus,
    bool clearBooking = false,
    PayNotice? notice,
    bool clearNotice = false,
    String? bookingId,
  }) => PaymentFlowState(
    phase: phase ?? this.phase,
    payment: payment ?? this.payment,
    failure: clearFailure ? null : failure ?? this.failure,
    offline: offline ?? this.offline,
    resumed: resumed ?? this.resumed,
    bookingStatus: clearBooking ? null : bookingStatus ?? this.bookingStatus,
    notice: clearNotice ? null : notice ?? this.notice,
    bookingId: bookingId ?? this.bookingId,
  );
}

/// The one place that drives a payment: create/resume, open the gateway, verify with the backend,
/// poll while unresolved, recover after the app was closed, and read the booking separately.
/// Screens only show [PaymentFlowState] and forward taps.
///
/// Riverpod pauses a provider nobody listens to, and with it the connectivity listener below, so
/// [PaymentRecoveryHost] keeps this provider listened to for the life of the app.
///
/// Rules it keeps: the backend decides (the SDK answer is a hint); a timeout, a lost connection or
/// a local timer never means "failed"; an unresolved payment is never paid again on its own; one
/// request of each kind at a time; every timer is cancelled on settle and on dispose.
class PaymentFlow extends Notifier<PaymentFlowState> {
  static const _uuid = Uuid();

  String? _paymentId;
  bool _fresh = true;
  String? _startKey; // reused while the outcome of a start is unknown
  String? _verifyKey; // reused for every re-send of the same SDK payload
  PaymentPaid?
  _unverified; // in memory only; the backend webhook covers a killed app
  bool _confirming = false; // the SDK reported a payment: never "can pay" again
  bool _restarted = false;
  bool _busy = false; // a start / gateway / verify is running
  bool _checking = false; // a status read is running
  bool _disposed = false;
  int _pollIndex = 0;
  Timer? _timer;

  @override
  PaymentFlowState build() {
    final life = _ResumeObserver(_wake);
    WidgetsBinding.instance.addObserver(life);
    ref
      ..onDispose(() {
        _disposed = true;
        _timer?.cancel();
        WidgetsBinding.instance.removeObserver(life);
      })
      ..listen(onlineProvider, (prev, next) {
        if (prev?.value == false && next.value == true) _wake();
      });
    return const PaymentFlowState();
  }

  String _key() => _uuid.v4();

  PaymentRepository get _repo => ref.read(paymentRepositoryProvider);
  PendingPaymentStore get _store => ref.read(pendingPaymentStoreProvider);

  void _emit(PaymentFlowState s) {
    if (_disposed) return;
    state = s;
    ref.invalidate(unconfirmedPaymentProvider);
  }

  void clearNotice() {
    if (!_disposed && state.notice != null) {
      state = state.copyWith(clearNotice: true);
    }
  }

  /// Opens `/payments/new?bookingId=` ([paymentId] null) or an existing payment.
  Future<void> open({String? paymentId, String? bookingId}) async {
    // The gateway or a verification is running: keep that attempt.
    if (_busy) return;
    _timer?.cancel();
    _paymentId = paymentId;
    _fresh = paymentId == null;
    _confirming = false;
    _restarted = false;
    _unverified = null;
    _verifyKey = null;
    _emit(PaymentFlowState(bookingId: bookingId));
    await _load();
  }

  /// "Try again" on a load error.
  Future<void> reload() => _busy ? Future.value() : _load();

  /// "Try again" after the backend confirmed a failure: a new payment, with a new key.
  Future<void> retry() async {
    if (_busy || state.phase != PayPhase.failed) return;
    _fresh = true;
    _startKey = null;
    _confirming = false;
    _restarted = false;
    _unverified = null;
    _verifyKey = null;
    await _load();
  }

  Future<void> _load() async {
    _timer?.cancel();
    _emit(state.copyWith(phase: PayPhase.loading, clearFailure: true));
    _busy = true;
    try {
      final Payment p;
      if (_fresh) {
        final key = _startKey ??= _key();
        p = await _repo.start(state.bookingId ?? '', idempotencyKey: key);
        _startKey = null;
      } else {
        p = await _repo.get(_paymentId!);
      }
      _busy = false;
      await _show(p);
    } on ConflictFailure catch (e) {
      _busy = false;
      _startKey = null;
      if (e.code == 'BOOKING_NOT_PAYABLE') {
        // Already paid, cancelled, or not at the payment step: show what the server holds now.
        refreshAfterPayment(ref, state.bookingId ?? '');
        _emit(state.copyWith(phase: PayPhase.notPayable));
      } else {
        _emit(state.copyWith(phase: PayPhase.loadFailed, failure: e));
      }
    } on Object catch (e) {
      _busy = false;
      // Unknown outcome (offline, timeout, 5xx): keep the key so a retry cannot double-create.
      if (e is ValidationFailure) _startKey = null;
      var bookingId = state.bookingId;
      if (!_fresh && (bookingId == null || bookingId.isEmpty)) {
        bookingId = await _store.readBookingId();
      }
      _emit(
        state.copyWith(
          phase: PayPhase.loadFailed,
          failure: e,
          offline: isOffline(e),
          bookingId: bookingId,
        ),
      );
    } finally {
      _busy = false;
    }
  }

  /// Puts a payment from the server on screen.
  Future<void> _show(Payment p) async {
    if (_disposed) return;
    final id = p.bookingId;
    _emit(state.copyWith(payment: p, bookingId: id, offline: false));
    if (p.wasPaid) {
      await _settle(p);
    } else if (p.status == PaymentStatus.failed) {
      _timer?.cancel();
      await _store.clear();
      _emit(state.copyWith(phase: PayPhase.failed));
    } else if (_confirming) {
      _unresolved();
    } else if (p.canPay) {
      // The checkout was opened earlier and its result never seen (back, app closed): the
      // customer may have paid. Confirm before offering the checkout again.
      if (await _store.read() == p.id) {
        _confirming = true;
        _emit(state.copyWith(resumed: true));
        _unresolved();
      } else {
        _emit(state.copyWith(phase: PayPhase.ready));
      }
    } else if (p.status == PaymentStatus.created && !_restarted) {
      // The gateway order does not exist yet: `POST /payments` again makes it.
      _restarted = true;
      _fresh = true;
      await _load();
    } else {
      _unresolved();
    }
  }

  void _unresolved() {
    final wasPending = state.phase == PayPhase.pending;
    _emit(state.copyWith(phase: PayPhase.pending));
    if (!wasPending) _pollIndex = 0;
    _schedule();
  }

  Future<void> _settle(Payment p) async {
    _timer?.cancel();
    _unverified = null;
    await _store.clear();
    if (_disposed) return;
    telemetry.event(TelemetryEvent.paymentSuccess);
    final status = await _readBooking(p.bookingId);
    refreshAfterPayment(ref, p.bookingId);
    _pollIndex = 0;
    _emit(state.copyWith(phase: PayPhase.success, bookingStatus: status));
    _schedule(); // keeps looking while the booking is not confirmed
  }

  Future<BookingStatus?> _readBooking(String id) async {
    try {
      return (await ref
              .read(bookingRepositoryProvider)
              .get(id)
              .timeout(const Duration(seconds: 8)))
          .status;
    } on Object {
      return null; // unknown, never "confirmed"
    }
  }

  /// A payment tap. Only from [PayPhase.ready]; the guard is synchronous, so a double tap pays once.
  Future<void> pay() async {
    final p = state.payment;
    if (_busy || p == null || state.phase != PayPhase.ready) return;
    _busy = true;
    try {
      _emit(state.copyWith(phase: PayPhase.paying));
      await _store.write(
        p.id,
        bookingId: p.bookingId,
        status: paymentStatusCode(p.status),
      );
      PaymentOutcome out;
      try {
        out = await ref.read(paymentServiceProvider).pay(p);
      } on Object {
        out = const PaymentSdkFailed();
      }
      switch (out) {
        case PaymentPaid():
          _confirming = true;
          _unverified = out;
          _verifyKey = _key();
          _emit(state.copyWith(phase: PayPhase.verifying));
          await _check();
        case PaymentCancelled():
          await _noPayment(p, cancelled: true);
        case PaymentSdkFailed():
          await _noPayment(p, cancelled: false);
      }
    } finally {
      _busy = false;
    }
  }

  /// Cancelled or failed inside the SDK (or the customer came back from a UPI app without a
  /// result): the server is still the judge, and a payment it cannot show is not "failed".
  Future<void> _noPayment(Payment p, {required bool cancelled}) async {
    final q = await _read(p.id);
    if (_disposed) return;
    if (q == null) {
      // Could not ask: keep the attempt, say so, check again when we can.
      _confirming = true;
      _emit(state.copyWith(phase: PayPhase.pending, resumed: true));
      _pollIndex = 0;
      _schedule();
    } else if (!q.canPay && q.status != PaymentStatus.created) {
      await _show(q); // paid anyway, failed, or still being confirmed
    } else if (cancelled) {
      await _store.clear();
      _emit(
        state.copyWith(
          payment: q,
          phase: PayPhase.ready,
          notice: PayNotice.cancelled,
        ),
      );
    } else {
      // The SDK reported an error but the backend has not failed it: it may still land (a UPI
      // app can return without a result). Confirm, and let the customer retry on the same order.
      _confirming = true;
      _emit(state.copyWith(payment: q, resumed: true));
      _unresolved();
    }
  }

  Future<Payment?> _read(String id) async {
    try {
      final p = await _repo.get(id);
      if (!_disposed && state.offline) {
        state = state.copyWith(offline: false);
      }
      return p;
    } on NetworkFailure catch (e) {
      // A timeout is not "offline": the status stays unresolved and reads as pending.
      if (!_disposed && isOffline(e)) state = state.copyWith(offline: true);
      return null;
    } on Object {
      return null;
    }
  }

  /// "Check again": one status read now, and the schedule restarts.
  Future<void> refresh() async {
    _pollIndex = 0;
    await _check();
    _schedule();
  }

  /// Customer says it was not paid: back to the checkout (same order).
  void payAgain() {
    final p = state.payment;
    if (p == null || _busy) return;
    _confirming = false;
    _timer?.cancel();
    _emit(state.copyWith(resumed: false, phase: PayPhase.ready));
  }

  /// One status read. If an SDK result has not reached the backend yet it is sent again with the
  /// same idempotency key; otherwise the payment is read. Overlapping calls are dropped.
  Future<void> _check() async {
    final p = state.payment;
    if (_checking || p == null) return;
    _checking = true;
    try {
      if (state.phase == PayPhase.success) {
        final status = await _readBooking(p.bookingId);
        if (!_disposed) {
          state = state.copyWith(bookingStatus: status);
          if (bookingIsConfirmed(status)) refreshAfterPayment(ref, p.bookingId);
        }
        return;
      }
      Payment? latest;
      final sdk = _unverified;
      if (sdk != null) {
        try {
          latest = await _repo.verify(
            p.id,
            providerPaymentId: sdk.providerPaymentId,
            signature: sdk.signature,
            idempotencyKey: _verifyKey ??= _key(),
          );
          _unverified = null;
        } on ValidationFailure {
          // PAYMENT_VERIFICATION_FAILED: the signature was refused and nothing changed.
          _unverified = null;
          latest = await _read(p.id);
          if (!(latest?.isSettled ?? false)) {
            await _store.clear();
            _emit(state.copyWith(phase: PayPhase.failed));
            return;
          }
        } on Object {
          // A lost answer or a repeat in flight: the payment may well have gone through.
          latest = await _read(p.id);
        }
      } else {
        latest = await _read(p.id);
      }
      if (_disposed) return;
      if (latest == null) {
        if (state.phase != PayPhase.pending) {
          _emit(state.copyWith(phase: PayPhase.pending));
        }
        return; // unread, not failed
      }
      await _show(latest);
    } finally {
      _checking = false;
    }
  }

  bool get _waiting =>
      state.phase == PayPhase.pending ||
      (state.phase == PayPhase.success &&
          !bookingIsConfirmed(state.bookingStatus));

  void _schedule() {
    final delays = ref.read(paymentPollDelaysProvider);
    if (_disposed ||
        !_waiting ||
        (_timer?.isActive ?? false) ||
        _pollIndex >= delays.length) {
      return;
    }
    _timer = Timer(delays[_pollIndex++], () async {
      await _check();
      _schedule();
    });
  }

  /// The app came back to the foreground or the connection returned.
  void _wake() {
    if (_disposed || _busy || !_waiting) return;
    _pollIndex = 0;
    _timer?.cancel();
    unawaited(_check().then((_) => _schedule()));
  }
}

final paymentFlowProvider = NotifierProvider<PaymentFlow, PaymentFlowState>(
  PaymentFlow.new,
);
