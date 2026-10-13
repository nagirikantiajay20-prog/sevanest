import 'package:dio/dio.dart';

/// `PaymentView.status` (Swagger 2026-10-13). A refunded payment keeps its own status, so the
/// refund states are statuses here, not a separate field. Unknown codes read "Updated".
enum PaymentStatus {
  created,
  pending,
  succeeded,
  failed,
  refundPending,
  refunded,
  refundFailed,
  unknown,
}

PaymentStatus paymentStatusFrom(Object? code) =>
    switch (code is String ? code.toUpperCase() : null) {
      'CREATED' => PaymentStatus.created,
      'PENDING' => PaymentStatus.pending,
      'SUCCEEDED' => PaymentStatus.succeeded,
      'FAILED' => PaymentStatus.failed,
      'REFUND_PENDING' => PaymentStatus.refundPending,
      'REFUNDED' => PaymentStatus.refunded,
      'REFUND_FAILED' => PaymentStatus.refundFailed,
      _ => PaymentStatus.unknown,
    };

String paymentStatusCode(PaymentStatus s) => switch (s) {
  PaymentStatus.created => 'CREATED',
  PaymentStatus.pending => 'PENDING',
  PaymentStatus.succeeded => 'SUCCEEDED',
  PaymentStatus.failed => 'FAILED',
  PaymentStatus.refundPending => 'REFUND_PENDING',
  PaymentStatus.refunded => 'REFUNDED',
  PaymentStatus.refundFailed => 'REFUND_FAILED',
  PaymentStatus.unknown => '',
};

class Payment {
  const Payment({
    required this.id,
    required this.bookingId,
    required this.status,
    required this.amountMinor,
    this.currency = 'INR',
    this.receiptNumber,
    this.paidAt,
    this.createdAt,
    this.checkout,
  });

  final String id;
  final String bookingId;
  final PaymentStatus status;

  /// Paise.
  final int amountMinor;
  final String currency;
  final String? receiptNumber;
  final DateTime? paidAt;
  final DateTime? createdAt;

  /// Public gateway data from `POST /payments` (not documented by the backend; passed on as is).
  final Map<String, dynamic>? checkout;

  /// Nothing more will happen to the money without the customer (or support) acting.
  bool get isSettled =>
      status == PaymentStatus.succeeded ||
      status == PaymentStatus.failed ||
      wasRefunded;

  /// The customer paid (a later refund does not undo that).
  bool get wasPaid => status == PaymentStatus.succeeded || wasRefunded;

  bool get wasRefunded =>
      status == PaymentStatus.refundPending ||
      status == PaymentStatus.refunded ||
      status == PaymentStatus.refundFailed;

  static Payment? fromJson(Object? j) {
    if (j is! Map) return null;
    final id = j['id'];
    final booking = j['bookingId'];
    if (id is! String || booking is! String) return null;
    final co = j['checkout'];
    final receipt = j['receiptNumber'];
    return Payment(
      id: id,
      bookingId: booking,
      status: paymentStatusFrom(j['status']),
      amountMinor: j['amountMinor'] is num
          ? (j['amountMinor'] as num).toInt()
          : 0,
      currency: j['currency'] is String ? j['currency'] as String : 'INR',
      receiptNumber: receipt is String ? receipt : null,
      paidAt: DateTime.tryParse('${j['paidAt']}'),
      createdAt: DateTime.tryParse('${j['createdAt']}'),
      checkout: co is Map ? Map<String, dynamic>.from(co) : null,
    );
  }
}

class PaymentPage {
  const PaymentPage(this.items, this.nextCursor);
  final List<Payment> items;
  final String? nextCursor;
}

/// Backend calls. The server verifies with the gateway; nothing here decides success.
abstract interface class PaymentRepository {
  /// `POST /payments`: starts, or resumes, the open payment of a PENDING_PAYMENT booking.
  Future<Payment> start(String bookingId, {required String idempotencyKey});

  /// `POST /payments/{id}/verify`: what the SDK reported is only a hint.
  Future<Payment> verify(
    String id, {
    required String providerPaymentId,
    required String signature,
    required String idempotencyKey,
  });

  Future<Payment> get(String id, {CancelToken? cancel});

  /// `GET /payments`, newest first; [status] filters on one status.
  Future<PaymentPage> list({String? cursor, PaymentStatus? status});
}

/// What the gateway SDK reported. Never proof of payment.
sealed class PaymentOutcome {
  const PaymentOutcome();
}

final class PaymentPaid extends PaymentOutcome {
  const PaymentPaid(this.providerPaymentId, this.signature);
  final String providerPaymentId;
  final String signature;
}

final class PaymentCancelled extends PaymentOutcome {
  const PaymentCancelled();
}

final class PaymentSdkFailed extends PaymentOutcome {
  const PaymentSdkFailed([this.code]);

  /// Gateway code, for support only; never shown raw.
  final String? code;
}

/// Opens the gateway checkout. One implementation per gateway; [FakePaymentService] in dev/tests.
abstract interface class PaymentService {
  Future<PaymentOutcome> pay(Payment payment);
}
