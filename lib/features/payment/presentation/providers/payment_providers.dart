import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/core/network/dio_provider.dart';
import 'package:sevanest_customer/core/services/clock.dart';
import 'package:sevanest_customer/features/booking/data/booking_repository_mock.dart';
import 'package:sevanest_customer/features/booking/presentation/providers/booking_providers.dart';
import 'package:sevanest_customer/features/home/presentation/providers/home_providers.dart';
import 'package:sevanest_customer/features/payment/data/payment_repository_mock.dart';
import 'package:sevanest_customer/features/payment/data/payment_repository_remote.dart';
import 'package:sevanest_customer/features/payment/data/payment_services.dart';
import 'package:sevanest_customer/features/payment/data/receipt_pdf_service.dart';
import 'package:sevanest_customer/features/payment/domain/payment.dart';
import 'package:sevanest_customer/shared/models/paged_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Live backend in stg / prod (and in dev when switched on); the seeded mock otherwise. The mock
/// is wired to the booking mock so a "paid" booking really becomes CONFIRMED.
final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final live = ref.watch(mockApiProvider.select((s) => s.live));
  if (live) return PaymentRepositoryRemote(ref.watch(dioProvider));
  final bookings = ref.read(bookingRepositoryProvider);
  return PaymentRepositoryMock(
    () => ref.read(mockApiProvider),
    now: ref.read(nowProvider),
    isPayable: (id) =>
        bookings is BookingRepositoryMock && bookings.isPayable(id),
    onPaid: (id) {
      if (bookings is BookingRepositoryMock) bookings.markPaid(id);
    },
  );
});

final paymentServiceProvider = Provider<PaymentService>(
  (ref) => ref.watch(mockApiProvider.select((s) => s.live))
      ? RazorpayPaymentService()
      : FakePaymentService(),
);

/// Waits between status reads after a payment is reported, ~60 s in all (docs/modules/09).
final paymentPollDelaysProvider = Provider<List<Duration>>(
  (ref) => const [
    Duration(seconds: 2),
    Duration(seconds: 4),
    Duration(seconds: 8),
    Duration(seconds: 16),
    Duration(seconds: 30),
  ],
);

/// The id of a payment whose result the app has not seen yet (the app may be killed while the
/// gateway is open). An id is not sensitive; no card or token data is ever stored.
class PendingPaymentStore {
  static const _key = 'pending_payment_id';

  Future<String?> read() async =>
      (await SharedPreferences.getInstance()).getString(_key);

  Future<void> write(String id) async =>
      (await SharedPreferences.getInstance()).setString(_key, id);

  Future<void> clear() async =>
      (await SharedPreferences.getInstance()).remove(_key);
}

final pendingPaymentStoreProvider = Provider<PendingPaymentStore>(
  (ref) => PendingPaymentStore(),
);

/// The payment the app stored when its checkout opened and has not seen the result of: for the
/// "confirming" banner on Home and the booking. Null when none is stored, it is settled (the
/// recovery check clears those), it was never started, or it cannot be read now.
final unconfirmedPaymentProvider = FutureProvider.autoDispose<Payment?>((
  ref,
) async {
  ref.watch(mockApiProvider);
  final id = await ref.read(pendingPaymentStoreProvider).read();
  if (id == null) return null;
  try {
    final p = await ref.read(paymentRepositoryProvider).get(id);
    return p.isSettled || p.status == PaymentStatus.created ? null : p;
  } on Object {
    return null;
  }
});

/// Everything a settled payment changes on screen: the booking, the lists, Home, transactions.
void refreshAfterPayment(WidgetRef ref, String bookingId) {
  ref
    ..invalidate(unconfirmedPaymentProvider)
    ..invalidate(bookingProvider(bookingId))
    ..invalidate(bookingListProvider)
    ..invalidate(homeProvider)
    ..invalidate(transactionListProvider);
}

/// Builds, saves and shares receipt PDFs; overridden in tests.
final receiptPdfServiceProvider = Provider<ReceiptPdfService>(
  (ref) => const ReceiptPdfService(),
);

/// One payment (receipt screen).
final paymentProvider = FutureProvider.autoDispose.family<Payment, String>((
  ref,
  id,
) {
  ref.watch(mockApiProvider);
  final cancel = CancelToken();
  ref.onDispose(cancel.cancel);
  return ref.read(paymentRepositoryProvider).get(id, cancel: cancel);
});

/// The receipt of a paid payment (`GET /payments/{id}/receipt`). A 409 `RECEIPT_NOT_AVAILABLE`
/// (not paid yet) is an error here; the receipt screen falls back to the payment itself.
final receiptProvider = FutureProvider.autoDispose.family<Receipt, String>((
  ref,
  id,
) {
  ref.watch(mockApiProvider);
  final cancel = CancelToken();
  ref.onDispose(cancel.cancel);
  return ref.read(paymentRepositoryProvider).receipt(id, cancel: cancel);
});

/// The paid payment of a booking, for its Receipt button (`GET /payments?bookingId=`, which only
/// returns the customer's own payments). Null when none was paid or the lookup failed.
Future<String?> paidPaymentIdOf(WidgetRef ref, String bookingId) async {
  try {
    final page = await ref
        .read(paymentRepositoryProvider)
        .list(bookingId: bookingId);
    return page.items.where((p) => p.wasPaid).firstOrNull?.id;
  } on Object {
    return null;
  }
}

/// Transactions filter: all, paid (SUCCEEDED) or refunded (`refunded=true`: REFUND_PENDING,
/// REFUNDED and REFUND_FAILED).
enum TransactionFilter { all, paid, refunded }

class TransactionFilterNotifier extends Notifier<TransactionFilter> {
  @override
  TransactionFilter build() => TransactionFilter.all;

  // ignore: use_setters_to_change_properties
  void set(TransactionFilter f) => state = f;
}

final transactionFilterProvider =
    NotifierProvider.autoDispose<TransactionFilterNotifier, TransactionFilter>(
      TransactionFilterNotifier.new,
    );

class TransactionListNotifier extends AsyncNotifier<PagedState<Payment>> {
  PaymentStatus? get _status =>
      ref.read(transactionFilterProvider) == TransactionFilter.paid
      ? PaymentStatus.succeeded
      : null;

  bool get _refunded =>
      ref.read(transactionFilterProvider) == TransactionFilter.refunded;

  @override
  Future<PagedState<Payment>> build() async {
    ref
      ..watch(mockApiProvider)
      ..watch(transactionFilterProvider);
    final page = await ref
        .read(paymentRepositoryProvider)
        .list(status: _status, refunded: _refunded);
    return const PagedState<Payment>().appended(page.items, page.nextCursor);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await future;
    } on Object {
      // The error is already in `state`.
    }
  }

  Future<void> loadMore() async {
    final cur = state.value;
    if (cur == null || !cur.canLoadMore) return;
    state = AsyncData(cur.loadingMore());
    try {
      final page = await ref
          .read(paymentRepositoryProvider)
          .list(cursor: cur.nextCursor, status: _status, refunded: _refunded);
      state = AsyncData(cur.appended(page.items, page.nextCursor));
    } on Object catch (e) {
      state = AsyncData(cur.failedMore(e));
    }
  }
}

final transactionListProvider =
    AsyncNotifierProvider.autoDispose<
      TransactionListNotifier,
      PagedState<Payment>
    >(TransactionListNotifier.new);
