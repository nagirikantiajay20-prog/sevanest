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

/// `checkout` of `POST /payments`: `{ gateway, keyId, orderId, amount, currency }`. `gateway` is
/// `razorpay` once configured on the server, `fake` before that (then `keyId` is null).
class PaymentCheckout {
  const PaymentCheckout({
    required this.gateway,
    required this.orderId,
    this.keyId,
    this.amount,
    this.currency,
  });

  final String gateway;
  final String? keyId;
  final String orderId;

  /// Paise, as the gateway order holds it; the payment's own amount is used when absent.
  final int? amount;
  final String? currency;

  bool get isRazorpay => gateway == 'razorpay' && keyId != null;

  static PaymentCheckout? fromJson(Object? j) {
    if (j is! Map) return null;
    final order = j['orderId'];
    if (order is! String || order.isEmpty) return null;
    final key = j['keyId'];
    final gateway = j['gateway'];
    return PaymentCheckout(
      gateway: gateway is String ? gateway : '',
      orderId: order,
      keyId: key is String && key.isNotEmpty ? key : null,
      amount: j['amount'] is num ? (j['amount'] as num).toInt() : null,
      currency: j['currency'] is String ? j['currency'] as String : null,
    );
  }
}

/// `paymentMethod` of a payment or receipt. Unknown codes are kept out of the UI.
enum PaymentMethod { upi, card, netbanking, wallet, emi }

PaymentMethod? paymentMethodFrom(Object? code) =>
    switch (code is String ? code.toLowerCase() : null) {
      'upi' => PaymentMethod.upi,
      'card' => PaymentMethod.card,
      'netbanking' => PaymentMethod.netbanking,
      'wallet' => PaymentMethod.wallet,
      'emi' => PaymentMethod.emi,
      _ => null,
    };

String? _str(Object? v) => v is String && v.isNotEmpty ? v : null;

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
    this.paymentMethod,
    this.paymentMethodDetail,
    this.gatewayReference,
    this.failureCode,
    this.failureReason,
    this.refundStatus,
    this.refundedAt,
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

  /// Public gateway data from `POST /payments`; null once the payment is past checkout.
  final PaymentCheckout? checkout;

  /// Null until the gateway answers.
  final PaymentMethod? paymentMethod;

  /// Always masked by the server (`ab***@okhdfc`, `Visa **** 4242`, a bank or wallet code).
  final String? paymentMethodDetail;

  /// The gateway's payment id (`pay_...`).
  final String? gatewayReference;

  /// `FAILED` payments only. [failureReason] is the gateway's own display message; [failureCode] is
  /// for support and never shown.
  final String? failureCode;
  final String? failureReason;

  /// The gateway's refund state and when the refund went through; null until a refund exists.
  final String? refundStatus;
  final DateTime? refundedAt;

  /// The customer can open the checkout: `PENDING` with a checkout (`CREATED` has none yet and is
  /// started again with `POST /payments`).
  bool get canPay =>
      (status == PaymentStatus.pending || status == PaymentStatus.created) &&
      checkout != null;

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
    return Payment(
      id: id,
      bookingId: booking,
      status: paymentStatusFrom(j['status']),
      amountMinor: j['amountMinor'] is num
          ? (j['amountMinor'] as num).toInt()
          : 0,
      currency: j['currency'] is String ? j['currency'] as String : 'INR',
      receiptNumber: _str(j['receiptNumber']),
      paidAt: DateTime.tryParse('${j['paidAt']}'),
      createdAt: DateTime.tryParse('${j['createdAt']}'),
      checkout: PaymentCheckout.fromJson(j['checkout']),
      paymentMethod: paymentMethodFrom(j['paymentMethod']),
      paymentMethodDetail: _str(j['paymentMethodDetail']),
      gatewayReference: _str(j['gatewayReference']),
      failureCode: _str(j['failureCode']),
      failureReason: _str(j['failureReason']),
      refundStatus: _str(j['refundStatus']),
      refundedAt: DateTime.tryParse('${j['refundedAt']}'),
    );
  }
}

/// `GET /payments/{id}/receipt`: only once the payment has succeeded (409 `RECEIPT_NOT_AVAILABLE`
/// before that). There is no PDF; the app renders it.
class Receipt {
  const Receipt({
    required this.receiptNumber,
    required this.paymentId,
    required this.bookingId,
    required this.amountMinor,
    this.currency = 'INR',
    this.paidAt,
    this.paymentMethod,
    this.paymentMethodDetail,
    this.gatewayReference,
    this.status = PaymentStatus.unknown,
    this.refundedAt,
  });

  final String receiptNumber;
  final String paymentId;
  final String bookingId;
  final int amountMinor;
  final String currency;
  final DateTime? paidAt;
  final PaymentMethod? paymentMethod;
  final String? paymentMethodDetail;
  final String? gatewayReference;
  final PaymentStatus status;
  final DateTime? refundedAt;

  static Receipt? fromJson(Object? j) {
    if (j is! Map) return null;
    final number = j['receiptNumber'];
    final payment = j['paymentId'];
    final booking = j['bookingId'];
    if (number is! String || payment is! String || booking is! String) {
      return null;
    }
    return Receipt(
      receiptNumber: number,
      paymentId: payment,
      bookingId: booking,
      amountMinor: j['amountMinor'] is num
          ? (j['amountMinor'] as num).toInt()
          : 0,
      currency: j['currency'] is String ? j['currency'] as String : 'INR',
      paidAt: DateTime.tryParse('${j['paidAt']}'),
      paymentMethod: paymentMethodFrom(j['paymentMethod']),
      paymentMethodDetail: _str(j['paymentMethodDetail']),
      gatewayReference: _str(j['gatewayReference']),
      status: paymentStatusFrom(j['status']),
      refundedAt: DateTime.tryParse('${j['refundedAt']}'),
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

  /// `GET /payments`, newest first; [status] filters on one status, [refunded] on every refund
  /// state (`REFUND_PENDING`, `REFUNDED`, `REFUND_FAILED`), [bookingId] on one of the customer's
  /// bookings.
  Future<PaymentPage> list({
    String? cursor,
    PaymentStatus? status,
    String? bookingId,
    bool refunded = false,
  });

  /// `GET /payments/{id}/receipt`; throws a 409 `RECEIPT_NOT_AVAILABLE` before the payment succeeds.
  Future<Receipt> receipt(String id, {CancelToken? cancel});
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
