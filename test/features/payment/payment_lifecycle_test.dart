// Payment lifecycle (PaymentFlow): offline, restart, UPI return, duplicates, polling, and the
// split between payment status and booking status. Fakes only: no gateway, no real writes.
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/widgets/offline_banner.dart';
import 'package:sevanest_customer/features/booking/domain/booking.dart';
import 'package:sevanest_customer/features/booking/presentation/providers/booking_providers.dart';
import 'package:sevanest_customer/features/payment/domain/payment.dart';
import 'package:sevanest_customer/features/payment/presentation/providers/payment_flow.dart';
import 'package:sevanest_customer/features/payment/presentation/providers/payment_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _checkout = PaymentCheckout(
  gateway: 'razorpay',
  keyId: 'rzp_test_x',
  orderId: 'order_1',
);

Payment _pay(PaymentStatus s, {bool checkout = true}) => Payment(
  id: 'pay_1',
  bookingId: 'bk_1',
  status: s,
  amountMinor: 49900,
  checkout: checkout ? _checkout : null,
);

class _Repo implements PaymentRepository {
  /// A [Payment] is returned, anything else is thrown.
  Object startResult = _pay(PaymentStatus.pending);
  Object getResult = _pay(PaymentStatus.pending);
  Object verifyResult = _pay(PaymentStatus.succeeded);
  final startKeys = <String>[];
  final verifyKeys = <String>[];
  var gets = 0;

  Future<Payment> _out(Object o) async => o is Payment ? o : throw o;

  @override
  Future<Payment> start(String bookingId, {required String idempotencyKey}) {
    startKeys.add(idempotencyKey);
    return _out(startResult);
  }

  @override
  Future<Payment> verify(
    String id, {
    required String providerPaymentId,
    required String signature,
    required String idempotencyKey,
  }) {
    verifyKeys.add(idempotencyKey);
    return _out(verifyResult);
  }

  @override
  Future<Payment> get(String id, {CancelToken? cancel}) {
    gets++;
    return _out(getResult);
  }

  @override
  Future<PaymentPage> list({
    String? cursor,
    PaymentStatus? status,
    String? bookingId,
    bool refunded = false,
  }) async => const PaymentPage([], null);

  @override
  Future<Receipt> receipt(String id, {CancelToken? cancel}) =>
      throw UnimplementedError();
}

class _Svc implements PaymentService {
  PaymentOutcome outcome = const PaymentPaid('pay_gw', 'sig');
  Completer<void>? gate;
  var calls = 0;

  @override
  Future<PaymentOutcome> pay(Payment payment) async {
    calls++;
    await gate?.future;
    return outcome;
  }
}

class _Bookings extends Mock implements BookingRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Repo repo;
  late _Svc svc;
  late _Bookings bookings;
  late StreamController<bool> online;
  late ProviderContainer c;
  var bookingStatus = BookingStatus.confirmed;
  Object? bookingError;
  var disposedEarly = false;

  PaymentFlow flow() => c.read(paymentFlowProvider.notifier);
  PaymentFlowState st() => c.read(paymentFlowProvider);

  /// Builds the container. [delay] is the single poll wait: tiny for polling tests, an hour to
  /// keep timers out of the way when a test drives the checks itself.
  void make({Duration delay = const Duration(hours: 1)}) {
    c = ProviderContainer(
      overrides: [
        paymentRepositoryProvider.overrideWithValue(repo),
        paymentServiceProvider.overrideWithValue(svc),
        bookingRepositoryProvider.overrideWithValue(bookings),
        paymentPollDelaysProvider.overrideWithValue([delay, delay, delay]),
        onlineProvider.overrideWith((ref) => online.stream),
      ],
    );
    disposedEarly = false;
    addTearDown(() {
      if (!disposedEarly) c.dispose();
    });
    c.read(
      paymentFlowProvider,
    ); // build now so the connectivity listener is live
  }

  Future<void> until(bool Function() ok) async {
    for (var i = 0; i < 200 && !ok(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    expect(ok(), isTrue, reason: 'phase was ${st().phase}');
  }

  Future<String?> stored() async =>
      (await SharedPreferences.getInstance()).getString('pending_payment_id');

  Future<void> openAndPay() async {
    await flow().open(bookingId: 'bk_1');
    await flow().pay();
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repo = _Repo();
    svc = _Svc();
    bookings = _Bookings();
    online = StreamController<bool>.broadcast();
    addTearDown(online.close);
    bookingStatus = BookingStatus.confirmed;
    bookingError = null;
    when(() => bookings.get(any(), cancel: any(named: 'cancel'))).thenAnswer((
      _,
    ) async {
      if (bookingError != null) throw bookingError!;
      return Booking(id: 'bk_1', status: bookingStatus);
    });
  });

  group('lifecycle', () {
    test(
      'success: verified by the backend, store cleared, booking confirmed',
      () async {
        make();
        await openAndPay();
        expect(st().phase, PayPhase.success);
        expect(st().payment!.amountMinor, 49900);
        expect(bookingIsConfirmed(st().bookingStatus), isTrue);
        expect(await stored(), isNull);
        expect(svc.calls, 1);
      },
    );

    test(
      'the stored context holds identifiers only, and is gone once settled',
      () async {
        repo.verifyResult = _pay(PaymentStatus.pending);
        repo.getResult = _pay(PaymentStatus.pending);
        make();
        await openAndPay();
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getKeys(), {
          'pending_payment_id',
          'pending_payment_booking_id',
          'pending_payment_saved_at',
          'pending_payment_last_status',
        });
        expect(prefs.getString('pending_payment_id'), 'pay_1');
        expect(prefs.getString('pending_payment_booking_id'), 'bk_1');
        expect(prefs.getString('pending_payment_last_status'), 'PENDING');
        // The SDK signature is never written down.
        expect(prefs.getKeys().join(), isNot(contains('sig')));
        for (final k in prefs.getKeys()) {
          expect(prefs.get(k).toString(), isNot(contains('sig')));
        }
      },
    );

    test(
      'pending after the SDK paid: confirming, not success, not failed',
      () async {
        repo.verifyResult = _pay(PaymentStatus.pending);
        repo.getResult = _pay(PaymentStatus.pending);
        make();
        await openAndPay();
        expect(st().phase, PayPhase.pending);
        expect(await stored(), 'pay_1');
      },
    );

    test('unknown backend status stays pending', () async {
      repo.verifyResult = _pay(PaymentStatus.unknown, checkout: false);
      repo.getResult = _pay(PaymentStatus.unknown, checkout: false);
      make();
      await openAndPay();
      expect(st().phase, PayPhase.pending);
    });

    test('backend FAILED is the only way to the failed view', () async {
      repo.verifyResult = _pay(PaymentStatus.failed, checkout: false);
      make();
      await openAndPay();
      expect(st().phase, PayPhase.failed);
      expect(await stored(), isNull);
    });

    test(
      'cancelled in the gateway: back to ready, nothing stored, no verify',
      () async {
        svc.outcome = const PaymentCancelled();
        make();
        await openAndPay();
        expect(st().phase, PayPhase.ready);
        expect(st().notice, PayNotice.cancelled);
        expect(repo.verifyKeys, isEmpty);
        expect(await stored(), isNull);
      },
    );
  });

  group('payment and booking are separate', () {
    test(
      'payment SUCCEEDED, booking still PENDING_PAYMENT: not confirmed',
      () async {
        bookingStatus = BookingStatus.pendingPayment;
        make();
        await openAndPay();
        expect(st().phase, PayPhase.success);
        expect(bookingIsConfirmed(st().bookingStatus), isFalse);
        expect(st().bookingStatus, BookingStatus.pendingPayment);
      },
    );

    test(
      'the booking is looked at again and then confirmed, without a second payment',
      () async {
        bookingStatus = BookingStatus.pendingPayment;
        make(delay: const Duration(milliseconds: 10));
        await openAndPay();
        expect(bookingIsConfirmed(st().bookingStatus), isFalse);
        bookingStatus = BookingStatus.confirmed;
        await until(() => bookingIsConfirmed(st().bookingStatus));
        expect(svc.calls, 1);
        expect(repo.startKeys.length, 1);
      },
    );

    test(
      'payment SUCCEEDED but the booking cannot be read: never "confirmed"',
      () async {
        bookingError = const NetworkFailure();
        make();
        await openAndPay();
        expect(st().phase, PayPhase.success);
        expect(st().bookingStatus, isNull);
        expect(bookingIsConfirmed(st().bookingStatus), isFalse);
      },
    );

    test('payment failed: the booking is not touched', () async {
      repo.verifyResult = _pay(PaymentStatus.failed, checkout: false);
      make();
      await openAndPay();
      verifyNever(() => bookings.get(any(), cancel: any(named: 'cancel')));
    });
  });

  group('offline and recovery', () {
    test(
      'offline during verification: kept pending, offline flagged, no new payment',
      () async {
        repo.verifyResult = const NetworkFailure();
        repo.getResult = const NetworkFailure();
        make();
        await openAndPay();
        expect(st().phase, PayPhase.pending);
        expect(st().offline, isTrue);
        expect(repo.startKeys.length, 1);
        expect(svc.calls, 1);
        expect(await stored(), 'pay_1');
      },
    );

    test(
      'connection returns: the unsent verify is re-sent (same key) and the result shown',
      () async {
        repo.verifyResult = const NetworkFailure();
        repo.getResult = const NetworkFailure();
        make();
        // Connectivity is watched by the banner too; a second listener keeps it attached here.
        c.listen(onlineProvider, (_, _) {});
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await openAndPay();
        expect(st().offline, isTrue);
        repo.verifyResult = _pay(PaymentStatus.succeeded, checkout: false);
        // A broadcast stream drops events nobody has subscribed to yet: let the provider attach.
        await Future<void>.delayed(const Duration(milliseconds: 20));
        online.add(false);
        await Future<void>.delayed(const Duration(milliseconds: 20));
        online.add(true);
        await until(() => st().phase == PayPhase.success);
        expect(st().offline, isFalse);
        expect(repo.verifyKeys.toSet().length, 1);
        expect(repo.startKeys.length, 1); // never a second payment
        expect(svc.calls, 1);
      },
    );

    test('gateway timeout / server down: unresolved, never failed', () async {
      repo.verifyResult = const ServerFailure();
      repo.getResult = const ServerFailure();
      make();
      await openAndPay();
      expect(st().phase, PayPhase.pending);
      expect(st().offline, isFalse); // the server was reached, just unwell
      expect(await stored(), 'pay_1');
    });

    test('app resumed: an unresolved payment is read again', () async {
      repo.verifyResult = _pay(PaymentStatus.pending);
      repo.getResult = _pay(PaymentStatus.pending);
      make();
      await openAndPay();
      final before = repo.gets;
      repo.getResult = _pay(PaymentStatus.succeeded, checkout: false);
      WidgetsBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      );
      await until(() => st().phase == PayPhase.success);
      expect(repo.gets, greaterThan(before));
    });

    test(
      'app restart: the stored payment is read, not re-created, and offers Check/Pay again',
      () async {
        SharedPreferences.setMockInitialValues({'pending_payment_id': 'pay_1'});
        make();
        await flow().open(paymentId: 'pay_1');
        expect(st().phase, PayPhase.pending);
        expect(st().resumed, isTrue);
        expect(st().payment!.canPay, isTrue);
        expect(repo.startKeys, isEmpty);
        expect(svc.calls, 0);
      },
    );

    test(
      'app restart, backend says paid: success and booking, store cleared',
      () async {
        SharedPreferences.setMockInitialValues({'pending_payment_id': 'pay_1'});
        repo.getResult = _pay(PaymentStatus.succeeded, checkout: false);
        make();
        await flow().open(paymentId: 'pay_1');
        expect(st().phase, PayPhase.success);
        expect(await stored(), isNull);
      },
    );

    test(
      'stale local state: stored id, backend FAILED → store reconciled',
      () async {
        SharedPreferences.setMockInitialValues({'pending_payment_id': 'pay_1'});
        repo.getResult = _pay(PaymentStatus.failed, checkout: false);
        make();
        await flow().open(paymentId: 'pay_1');
        expect(st().phase, PayPhase.failed);
        expect(await stored(), isNull);
      },
    );

    test(
      'restart while offline: load error keeps the id and the booking to go to',
      () async {
        SharedPreferences.setMockInitialValues({
          'pending_payment_id': 'pay_1',
          'pending_payment_booking_id': 'bk_1',
        });
        repo.getResult = const NetworkFailure();
        make();
        await flow().open(paymentId: 'pay_1');
        expect(st().phase, PayPhase.loadFailed);
        expect(st().offline, isTrue);
        expect(st().bookingId, 'bk_1');
        expect(await stored(), 'pay_1');
      },
    );

    test(
      'back and return: the same open payment is resumed as confirming, not payable',
      () async {
        svc.outcome = const PaymentCancelled();
        svc.gate = null;
        make();
        await flow().open(bookingId: 'bk_1');
        // The checkout was opened and the customer left (id stored, no result seen).
        await c
            .read(pendingPaymentStoreProvider)
            .write('pay_1', bookingId: 'bk_1');
        await flow().open(bookingId: 'bk_1');
        expect(st().phase, PayPhase.pending);
        expect(st().resumed, isTrue);
        expect(svc.calls, 0);
      },
    );
  });

  group('UPI / gateway return', () {
    test(
      'SDK error, backend still pending: confirming (not failed), Pay again possible',
      () async {
        svc.outcome = const PaymentSdkFailed('UPI_RETURN');
        make();
        await openAndPay();
        expect(st().phase, PayPhase.pending);
        expect(st().resumed, isTrue);
        expect(repo.verifyKeys, isEmpty);
        expect(await stored(), 'pay_1');
        flow().payAgain();
        expect(st().phase, PayPhase.ready);
      },
    );

    test(
      'UPI app returned and the backend already has the payment: success',
      () async {
        svc.outcome = const PaymentSdkFailed('NO_CALLBACK');
        make();
        await flow().open(bookingId: 'bk_1');
        repo.getResult = _pay(PaymentStatus.succeeded, checkout: false);
        await flow().pay();
        expect(st().phase, PayPhase.success);
      },
    );

    test(
      'SDK error while unreachable: unresolved and offline, not failed',
      () async {
        svc.outcome = const PaymentSdkFailed('0');
        make();
        await flow().open(bookingId: 'bk_1');
        repo.getResult = const NetworkFailure();
        await flow().pay();
        expect(st().phase, PayPhase.pending);
        expect(st().offline, isTrue);
        expect(await stored(), 'pay_1');
      },
    );

    test(
      'duplicate SDK callbacks / repeated verify: one verify per answer',
      () async {
        make();
        await openAndPay();
        await flow().pay(); // late duplicate: ignored
        expect(svc.calls, 1);
        expect(repo.verifyKeys.length, 1);
      },
    );
  });

  group('duplicate prevention and retry', () {
    test('many taps open the gateway once', () async {
      svc.gate = Completer();
      make();
      await flow().open(bookingId: 'bk_1');
      final taps = [flow().pay(), flow().pay(), flow().pay()];
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(svc.calls, 1);
      expect(st().phase, PayPhase.paying);
      svc.gate!.complete();
      await Future.wait(taps);
      expect(repo.verifyKeys.length, 1);
      expect(st().phase, PayPhase.success);
    });

    test(
      'a start whose answer was lost is retried with the same key',
      () async {
        repo.startResult = const NetworkFailure();
        make();
        await flow().open(bookingId: 'bk_1');
        expect(st().phase, PayPhase.loadFailed);
        await flow().reload();
        expect(repo.startKeys.length, 2);
        expect(repo.startKeys[0], repo.startKeys[1]);
        // Once a start is answered, the next attempt gets a new key.
        repo.startResult = _pay(PaymentStatus.pending);
        await flow().reload();
        await flow().reload();
        expect(repo.startKeys[2], isNot(repo.startKeys[3]));
      },
    );

    test(
      'retry after a confirmed failure makes a new attempt with a new key',
      () async {
        repo.verifyResult = _pay(PaymentStatus.failed, checkout: false);
        make();
        await openAndPay();
        expect(st().phase, PayPhase.failed);
        await flow().retry();
        expect(repo.startKeys.length, 2);
        expect(repo.startKeys[0], isNot(repo.startKeys[1]));
        expect(st().phase, PayPhase.ready);
      },
    );

    test('retry while the payment is pending does nothing', () async {
      repo.verifyResult = _pay(PaymentStatus.pending);
      make();
      await openAndPay();
      await flow().retry();
      expect(repo.startKeys.length, 1);
      expect(st().phase, PayPhase.pending);
    });

    test('pay is ignored while the payment is pending', () async {
      repo.verifyResult = _pay(PaymentStatus.pending);
      make();
      await openAndPay();
      await flow().pay();
      expect(svc.calls, 1);
    });
  });

  group('polling', () {
    test(
      'polls while unresolved, stops at a terminal status, never overlaps',
      () async {
        repo.verifyResult = _pay(PaymentStatus.pending);
        make(delay: const Duration(milliseconds: 10));
        await openAndPay();
        await until(() => repo.gets >= 2);
        repo.getResult = _pay(PaymentStatus.succeeded, checkout: false);
        await until(() => st().phase == PayPhase.success);
        final done = repo.gets;
        await Future<void>.delayed(const Duration(milliseconds: 80));
        expect(repo.gets, done); // no polling after a terminal status
      },
    );

    test(
      'a spent schedule does not fail the payment; Check again restarts it',
      () async {
        repo.verifyResult = _pay(PaymentStatus.pending);
        make(delay: const Duration(milliseconds: 5));
        await openAndPay();
        await Future<void>.delayed(const Duration(milliseconds: 100));
        final spent = repo.gets;
        expect(st().phase, PayPhase.pending);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(repo.gets, spent); // polling stopped, nothing aggressive
        repo.getResult = _pay(PaymentStatus.succeeded, checkout: false);
        await flow().refresh();
        expect(st().phase, PayPhase.success);
      },
    );

    test('disposing the container cancels the timer', () async {
      repo.verifyResult = _pay(PaymentStatus.pending);
      make(delay: const Duration(milliseconds: 10));
      await openAndPay();
      c.dispose();
      disposedEarly = true;
      final gets = repo.gets;
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(repo.gets, gets);
    });
  });

  group('status mapping and refunds', () {
    test('backend codes map; unsupported ones read as unknown', () {
      expect(paymentStatusFrom('SUCCEEDED'), PaymentStatus.succeeded);
      expect(paymentStatusFrom('REFUND_PENDING'), PaymentStatus.refundPending);
      expect(paymentStatusFrom('REFUNDED'), PaymentStatus.refunded);
      expect(paymentStatusFrom('REFUND_FAILED'), PaymentStatus.refundFailed);
      // CANCELLED, EXPIRED, PROCESSING and REFUND_PROCESSING are not in the backend contract.
      for (final c in [
        'CANCELLED',
        'EXPIRED',
        'PROCESSING',
        'REFUND_PROCESSING',
      ]) {
        expect(paymentStatusFrom(c), PaymentStatus.unknown);
      }
    });

    test(
      'refund states keep the payment as paid and are never offered a checkout',
      () {
        for (final s in [
          PaymentStatus.refundPending,
          PaymentStatus.refunded,
          PaymentStatus.refundFailed,
        ]) {
          final p = _pay(s);
          expect(p.wasPaid, isTrue);
          expect(p.wasRefunded, isTrue);
          expect(p.canPay, isFalse);
        }
      },
    );

    test('missing refund information stays null', () {
      final p = Payment.fromJson({
        'id': 'pay_1',
        'bookingId': 'bk_1',
        'status': 'REFUND_PENDING',
        'amountMinor': 100,
      })!;
      expect(p.refundStatus, isNull);
      expect(p.refundedAt, isNull);
    });
  });
}
