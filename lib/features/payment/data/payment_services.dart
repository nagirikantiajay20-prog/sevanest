import 'dart:async';

import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:sevanest_customer/features/payment/data/payment_repository_mock.dart';
import 'package:sevanest_customer/features/payment/domain/payment.dart';

/// Dev / mock mode: pays instantly with a reference the mock repository accepts.
class FakePaymentService implements PaymentService {
  FakePaymentService({this.outcome});

  /// Overrides the default "paid" answer (tests, dev menu).
  PaymentOutcome? outcome;
  var calls = 0;

  @override
  Future<PaymentOutcome> pay(Payment payment) async {
    calls++;
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return outcome ??
        PaymentPaid(
          '${PaymentRepositoryMock.fakeProviderPrefix}${payment.id}',
          'sig',
        );
  }
}

/// Razorpay Checkout. Opens only for a `razorpay` checkout with a `keyId`; any other checkout fails
/// safely. The SDK's answer is only a hint; the server verifies it.
class RazorpayPaymentService implements PaymentService {
  @override
  Future<PaymentOutcome> pay(Payment payment) {
    final c = payment.checkout;
    if (c == null || !c.isRazorpay) {
      return Future.value(const PaymentSdkFailed('CHECKOUT_UNSUPPORTED'));
    }
    final done = Completer<PaymentOutcome>();
    final rz = Razorpay();
    void finish(PaymentOutcome o) {
      if (done.isCompleted) return;
      rz.clear();
      done.complete(o);
    }

    rz
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse r) {
        final id = r.paymentId;
        final sig = r.signature;
        finish(
          id == null || sig == null
              ? const PaymentSdkFailed('INCOMPLETE_RESPONSE')
              : PaymentPaid(id, sig),
        );
      })
      ..on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse r) {
        // 0 = NETWORK_ERROR, 2 = user pressed back (Razorpay codes).
        finish(
          r.code == 2
              ? const PaymentCancelled()
              : PaymentSdkFailed('${r.code}'),
        );
      })
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, (_) {});
    try {
      rz.open({
        'key': c.keyId,
        'order_id': c.orderId,
        'amount': c.amount ?? payment.amountMinor,
        'currency': c.currency ?? payment.currency,
        'name': 'SevaNest',
      });
    } on Object {
      finish(const PaymentSdkFailed('OPEN_FAILED'));
    }
    return done.future;
  }
}
