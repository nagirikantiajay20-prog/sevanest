import 'package:dio/dio.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/features/payment/domain/payment.dart';

/// In-memory payments behind the mock-API toggle. [isPayable] / [onPaid] tie it to the booking
/// mock: only a PENDING_PAYMENT booking can be paid, and a verified payment confirms it.
class PaymentRepositoryMock implements PaymentRepository {
  PaymentRepositoryMock(
    this._state, {
    required this.isPayable,
    required this.onPaid,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    if (_state().returningUser) _seed();
  }

  final MockApiState Function() _state;
  final bool Function(String bookingId) isPayable;
  final void Function(String bookingId) onPaid;
  final DateTime Function() _now;
  final _items = <Payment>[];
  final _byKey = <String, Payment>{};
  var _seq = 700;

  /// The gateway reference the fake checkout reports; verify accepts only this prefix.
  static const fakeProviderPrefix = 'fake_pay_';

  void _seed() {
    final base = _now().subtract(const Duration(days: 30));
    _items.addAll([
      Payment(
        id: 'pay_1900',
        bookingId: 'bk_1900',
        status: PaymentStatus.succeeded,
        amountMinor: 49900,
        receiptNumber: 'SN-R-1900',
        paidAt: base,
        createdAt: base,
      ),
      Payment(
        id: 'pay_1800',
        bookingId: 'bk_1800',
        status: PaymentStatus.refunded,
        amountMinor: 49900,
        receiptNumber: 'SN-R-1800',
        paidAt: base.subtract(const Duration(days: 20)),
        createdAt: base.subtract(const Duration(days: 20)),
      ),
    ]);
  }

  int _index(String id) {
    final i = _items.indexWhere((p) => p.id == id);
    if (i < 0) throw const NotFoundFailure();
    return i;
  }

  Payment _set(Payment p, PaymentStatus s, {bool receipt = false}) {
    final next = Payment(
      id: p.id,
      bookingId: p.bookingId,
      status: s,
      amountMinor: p.amountMinor,
      receiptNumber: receipt ? 'SN-R-${p.id}' : p.receiptNumber,
      paidAt: receipt ? _now() : p.paidAt,
      createdAt: p.createdAt,
      checkout: s == PaymentStatus.created ? p.checkout : null,
    );
    return _items[_index(p.id)] = next;
  }

  @override
  Future<Payment> start(String bookingId, {required String idempotencyKey}) =>
      mockCall(_state(), () {
        final first = _byKey[idempotencyKey];
        if (first != null) return first;
        if (!isPayable(bookingId)) {
          throw const ConflictFailure(
            'This booking is not waiting for payment',
            'BOOKING_NOT_PAYABLE',
          );
        }
        // "Calling again while a payment is open returns the same payment."
        final open = _items.where(
          (p) =>
              p.bookingId == bookingId &&
              (p.status == PaymentStatus.created ||
                  p.status == PaymentStatus.pending),
        );
        if (open.isNotEmpty) return _byKey[idempotencyKey] = open.first;
        final p = Payment(
          id: 'pay_${_seq++}',
          bookingId: bookingId,
          status: PaymentStatus.created,
          amountMinor: 49900,
          createdAt: _now(),
          checkout: const {'provider': 'fake'},
        );
        _items.insert(0, p);
        return _byKey[idempotencyKey] = p;
      });

  @override
  Future<Payment> verify(
    String id, {
    required String providerPaymentId,
    required String signature,
    required String idempotencyKey,
  }) => mockCall(_state(), () {
    final first = _byKey[idempotencyKey];
    if (first != null) return first;
    final p = _items[_index(id)];
    if (p.wasPaid) return p;
    if (!providerPaymentId.startsWith(fakeProviderPrefix) ||
        signature.isEmpty) {
      throw const ValidationFailure(
        'Payment could not be verified',
        {},
        'PAYMENT_VERIFICATION_FAILED',
      );
    }
    final paid = _set(p, PaymentStatus.succeeded, receipt: true);
    onPaid(p.bookingId);
    return _byKey[idempotencyKey] = paid;
  });

  @override
  Future<Payment> get(String id, {CancelToken? cancel}) =>
      mockCall(_state(), () => _items[_index(id)]);

  @override
  Future<PaymentPage> list({String? cursor, PaymentStatus? status}) => mockCall(
    _state(),
    () => PaymentPage([
      for (final p in _items)
        if (status == null || p.status == status) p,
    ], null),
  );
}
