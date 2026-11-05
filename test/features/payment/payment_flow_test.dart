// Module 09: payment screen, results, recovery, transactions and receipt.
import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/features/booking/data/booking_repository_mock.dart';
import 'package:sevanest_customer/features/booking/domain/booking.dart';
import 'package:sevanest_customer/features/booking/presentation/providers/booking_providers.dart';
import 'package:sevanest_customer/features/payment/data/payment_repository_mock.dart';
import 'package:sevanest_customer/features/payment/data/receipt_pdf_service.dart';
import 'package:sevanest_customer/features/payment/domain/payment.dart';
import 'package:sevanest_customer/features/payment/domain/receipt_document.dart';
import 'package:sevanest_customer/features/payment/presentation/providers/payment_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/discover_harness.dart';
import '../../helpers/fakes.dart';

Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 3; i++) {
    await t.pumpAndSettle();
    await t.pump(const Duration(seconds: 1));
  }
  await t.pumpAndSettle();
}

/// The seeded payment mock with counters and failure hooks.
class _Repo implements PaymentRepository {
  _Repo(this.inner);
  final PaymentRepositoryMock inner;
  final startKeys = <String>[];
  final verifyKeys = <String>[];
  var startCalls = 0;
  var verifyCalls = 0;
  var getCalls = 0;

  Object? startFails;
  Object? verifyFails;

  /// Holds `start` open so the loading state can be observed.
  Completer<void>? startGate;

  /// Verify succeeds server-side but the answer is lost.
  bool loseVerifyAnswer = false;

  /// Reads fail (offline after paying).
  bool getFails = false;

  /// What `get` answers instead of the stored payment, e.g. a payment still PENDING.
  Payment? forcedGet;
  Payment? forcedVerify;

  /// What the first `start` answers instead of the mock (e.g. a CREATED payment).
  Payment? firstStart;
  Completer<void>? verifyGate;
  Object? listFails;
  bool emptyList = false;

  @override
  Future<Payment> start(
    String bookingId, {
    required String idempotencyKey,
  }) async {
    startCalls++;
    startKeys.add(idempotencyKey);
    await startGate?.future;
    final f = startFails;
    if (f != null) throw f;
    final first = firstStart;
    if (first != null) {
      firstStart = null;
      return first;
    }
    return inner.start(bookingId, idempotencyKey: idempotencyKey);
  }

  @override
  Future<Payment> verify(
    String id, {
    required String providerPaymentId,
    required String signature,
    required String idempotencyKey,
  }) async {
    verifyCalls++;
    verifyKeys.add(idempotencyKey);
    await verifyGate?.future;
    final f = verifyFails;
    if (f != null) throw f;
    final p = await inner.verify(
      id,
      providerPaymentId: providerPaymentId,
      signature: signature,
      idempotencyKey: idempotencyKey,
    );
    if (loseVerifyAnswer) throw const NetworkFailure();
    return forcedVerify ?? p;
  }

  @override
  Future<Payment> get(String id, {CancelToken? cancel}) async {
    getCalls++;
    if (getFails) throw const NetworkFailure();
    return forcedGet ?? await inner.get(id, cancel: cancel);
  }

  Object? receiptFails;
  var receiptCalls = 0;

  @override
  Future<Receipt> receipt(String id, {CancelToken? cancel}) async {
    receiptCalls++;
    final f = receiptFails;
    if (f != null) throw f;
    return inner.receipt(id, cancel: cancel);
  }

  @override
  Future<PaymentPage> list({
    String? cursor,
    PaymentStatus? status,
    String? bookingId,
    bool refunded = false,
  }) async {
    final f = listFails;
    if (f != null) throw f;
    if (emptyList) return const PaymentPage([], null);
    return inner.list(
      cursor: cursor,
      status: status,
      bookingId: bookingId,
      refunded: refunded,
    );
  }
}

class _Svc implements PaymentService {
  _Svc();
  PaymentOutcome? outcome;
  Completer<void>? gate;
  var calls = 0;

  @override
  Future<PaymentOutcome> pay(Payment payment) async {
    calls++;
    await gate?.future;
    return outcome ??
        PaymentPaid(
          '${PaymentRepositoryMock.fakeProviderPrefix}${payment.id}',
          'sig',
        );
  }
}

/// Stands in for the PDF service: records what it was asked to print, optionally waits or fails.
class _FakePdf implements ReceiptPdfService {
  final saved = <ReceiptDocument>[];
  final shared = <String>[];
  Completer<void>? gate;
  bool fails = false;

  @override
  Future<File> save(ReceiptDocument doc) async {
    saved.add(doc);
    await gate?.future;
    if (fails) throw const FileSystemException('disk full');
    return File(doc.fileName);
  }

  @override
  Future<void> share(File file, String subject) async => shared.add(file.path);
}

const _bookingId = 'bk_2100'; // seeded in PENDING_PAYMENT

void main() {
  late BookingRepositoryMock bookings;
  late _Repo repo;
  late _Svc svc;
  late _FakePdf pdf;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    bookings = BookingRepositoryMock(
      () => const MockApiState(returningUser: true),
      now: () => testNow,
    );
    repo = _Repo(
      PaymentRepositoryMock(
        () => const MockApiState(returningUser: true),
        isPayable: bookings.isPayable,
        onPaid: bookings.markPaid,
        now: () => testNow,
      ),
    );
    svc = _Svc();
    pdf = _FakePdf();
  });

  Future<DiscoverEnv> open(WidgetTester t, {String? route}) async {
    final env = await launchDiscover(
      t,
      overrides: [
        bookingRepositoryProvider.overrideWithValue(bookings),
        paymentRepositoryProvider.overrideWithValue(repo),
        paymentServiceProvider.overrideWithValue(svc),
        receiptPdfServiceProvider.overrideWithValue(pdf),
        paymentPollDelaysProvider.overrideWithValue(
          List.filled(3, const Duration(milliseconds: 10)),
        ),
      ],
    );
    await env.go(route ?? '/payments/new?bookingId=$_bookingId');
    await settle(t);
    return env;
  }

  Future<void> tapKey(WidgetTester t, String key) async {
    await t.ensureVisible(find.byKey(Key(key)));
    await t.pump();
    await t.tap(find.byKey(Key(key)));
    await settle(t);
  }

  Finder k(String key) => find.byKey(Key(key));

  Future<String?> pendingId(WidgetTester t) => t.runAsync<String?>(
    () => SharedPreferences.getInstance().then(
      (p) => p.getString('pending_payment_id'),
    ),
  );

  group('entry', () {
    testWidgets('booking detail Pay opens the payment with the amount', (
      t,
    ) async {
      final env = await open(t, route: '/bookings/$_bookingId');
      await tapKey(t, 'booking_pay_btn');
      expect(env.where, '/payments/new');
      expect(find.text('₹499'), findsWidgets);
      expect(k('payment_pay_btn'), findsOneWidget);
      expect(repo.startCalls, 1);
    });

    testWidgets('the Bookings list card Pay button opens it too', (t) async {
      final env = await open(t, route: '/bookings');
      await tapKey(t, 'booking_card_pay_btn_$_bookingId');
      expect(env.where, '/payments/new');
      expect(k('payment_pay_btn'), findsOneWidget);
    });
  });

  group('paying', () {
    testWidgets('success: backend SUCCEEDED, booking refreshed to Confirmed', (
      t,
    ) async {
      final env = await open(t);
      await tapKey(t, 'payment_pay_btn');
      expect(find.text('Payment successful'), findsOneWidget);
      expect(find.text('₹499'), findsOneWidget);
      expect(repo.verifyCalls, 1);
      expect(svc.calls, 1);
      expect(
        (await t.runAsync(() => bookings.get(_bookingId)))!.status,
        BookingStatus.confirmed,
      );
      // The stored id is gone once the result is known.
      expect(await pendingId(t), isNull);
      await tapKey(t, 'payment_view_booking_btn');
      expect(env.where, '/bookings/$_bookingId');
    });

    testWidgets('double tap opens the checkout once', (t) async {
      svc.gate = Completer();
      await open(t);
      await t.tap(k('payment_pay_btn'));
      await t.pump();
      await t.tap(k('payment_pay_btn'), warnIfMissed: false);
      await t.pump();
      expect(svc.calls, 1);
      svc.gate!.complete();
      await settle(t);
      expect(repo.verifyCalls, 1);
      expect(find.text('Payment successful'), findsOneWidget);
    });

    testWidgets(
      'cancel: back to ready with a note, no new payment, retry works',
      (t) async {
        svc.outcome = const PaymentCancelled();
        await open(t);
        await tapKey(t, 'payment_pay_btn');
        expect(
          find.text('Payment cancelled. You can try again.'),
          findsOneWidget,
        );
        expect(k('payment_pay_btn'), findsOneWidget);
        expect(repo.verifyCalls, 0);
        svc.outcome = null;
        await tapKey(t, 'payment_pay_btn');
        expect(find.text('Payment successful'), findsOneWidget);
        expect(repo.startCalls, 1); // never a second payment or booking
      },
    );

    testWidgets(
      'gateway failure: failed view; Try again starts with a fresh key',
      (t) async {
        svc.outcome = const PaymentSdkFailed('BAD_REQUEST');
        await open(t);
        await tapKey(t, 'payment_pay_btn');
        expect(find.text("Payment didn't go through"), findsOneWidget);
        expect(find.text('Payment successful'), findsNothing);
        expect(repo.verifyCalls, 0);
        svc.outcome = null;
        await tapKey(t, 'payment_retry_btn');
        expect(k('payment_pay_btn'), findsOneWidget);
        expect(repo.startKeys.length, 2);
        expect(repo.startKeys[0], isNot(repo.startKeys[1]));
        await tapKey(t, 'payment_pay_btn');
        expect(find.text('Payment successful'), findsOneWidget);
      },
    );

    testWidgets(
      'SDK says paid but the server refuses the signature: failed, never success',
      (t) async {
        repo.verifyFails = const ValidationFailure(
          'bad',
          {},
          'PAYMENT_VERIFICATION_FAILED',
        );
        await open(t);
        await tapKey(t, 'payment_pay_btn');
        expect(find.text("Payment didn't go through"), findsOneWidget);
        expect(find.text('Payment successful'), findsNothing);
        expect(
          (await t.runAsync(() => bookings.get(_bookingId)))!.status,
          BookingStatus.pendingPayment,
        );
      },
    );

    testWidgets(
      'lost answer after paying: the payment is read again, then success',
      (t) async {
        repo.loseVerifyAnswer = true;
        await open(t);
        await tapKey(t, 'payment_pay_btn');
        expect(find.text('Payment successful'), findsOneWidget);
        expect(repo.verifyCalls, 1);
        expect(repo.getCalls, greaterThanOrEqualTo(1));
      },
    );

    testWidgets('lost answer and offline: pending, not failed', (t) async {
      repo
        ..loseVerifyAnswer = true
        ..getFails = true;
      await open(t);
      // The start call needed the repo; go offline only for the reads after paying.
      repo.getFails = true;
      await tapKey(t, 'payment_pay_btn');
      expect(find.text("We're confirming your payment"), findsOneWidget);
      expect(find.text("Payment didn't go through"), findsNothing);
      expect(k('payment_pay_btn'), findsNothing);
    });

    testWidgets(
      'still PENDING after the polls: pending view, Pay hidden; Check again settles it',
      (t) async {
        final base = (await t.runAsync(
          () => repo.inner.start(_bookingId, idempotencyKey: 'seed-key-0001'),
        ))!;
        final pending = Payment(
          id: base.id,
          bookingId: base.bookingId,
          status: PaymentStatus.pending,
          amountMinor: base.amountMinor,
        );
        repo
          ..forcedVerify = pending
          ..forcedGet = pending;
        await open(t);
        final getsBefore = repo.getCalls;
        await tapKey(t, 'payment_pay_btn');
        expect(find.text("We're confirming your payment"), findsOneWidget);
        expect(k('payment_pay_btn'), findsNothing);
        expect(
          repo.getCalls - getsBefore,
          greaterThanOrEqualTo(3),
        ); // polled with a cap
        repo.forcedGet = null; // the server now says SUCCEEDED
        await tapKey(t, 'payment_refresh_btn');
        expect(find.text('Payment successful'), findsOneWidget);
      },
    );

    testWidgets(
      'PENDING with a checkout is payable; once the SDK reported it stays confirming',
      (t) async {
        final base = (await t.runAsync(
          () => repo.inner.start(_bookingId, idempotencyKey: 'seed-key-0001'),
        ))!;
        expect(base.status, PaymentStatus.pending);
        expect(base.checkout, isNotNull);
        await open(t);
        expect(k('payment_pay_btn'), findsOneWidget); // can pay
        // The server still shows the checkout, but the customer already paid in the SDK.
        repo
          ..forcedVerify = base
          ..forcedGet = base;
        await tapKey(t, 'payment_pay_btn');
        expect(find.text("We're confirming your payment"), findsOneWidget);
        expect(k('payment_pay_btn'), findsNothing);
        await tapKey(t, 'payment_refresh_btn');
        expect(find.text("We're confirming your payment"), findsOneWidget);
        expect(k('payment_pay_btn'), findsNothing);
      },
    );

    testWidgets(
      'CREATED (no gateway order yet): POST /payments is made again',
      (t) async {
        repo.firstStart = const Payment(
          id: 'pay_c',
          bookingId: _bookingId,
          status: PaymentStatus.created,
          amountMinor: 49900,
        );
        await open(t);
        expect(repo.startCalls, 2);
        expect(repo.startKeys[0], isNot(repo.startKeys[1]));
        expect(k('payment_pay_btn'), findsOneWidget);
      },
    );

    testWidgets('failed: the gateway reason and the refund note are shown', (
      t,
    ) async {
      final base = (await t.runAsync(
        () => repo.inner.start(_bookingId, idempotencyKey: 'seed-key-0001'),
      ))!;
      repo.verifyFails = const ValidationFailure(
        'x',
        {},
        'PAYMENT_VERIFICATION_FAILED',
      );
      await open(t);
      repo.forcedGet = Payment(
        id: base.id,
        bookingId: base.bookingId,
        status: PaymentStatus.failed,
        amountMinor: base.amountMinor,
        failureCode: 'BAD_REQUEST_ERROR',
        failureReason: 'Your bank declined the payment',
      );
      await tapKey(t, 'payment_pay_btn');
      expect(find.text('Your bank declined the payment'), findsOneWidget);
      expect(
        find.text(
          'If any amount was debited, it will be refunded automatically.',
        ),
        findsOneWidget,
      );
      expect(find.text('BAD_REQUEST_ERROR'), findsNothing); // for support only
      expect(find.textContaining('No money'), findsNothing);
    });

    testWidgets('the key of each verify is fresh', (t) async {
      repo.verifyFails = const NetworkFailure();
      repo.getFails = false;
      await open(t);
      await tapKey(t, 'payment_pay_btn');
      expect(repo.verifyKeys.length, 1);
      expect(repo.verifyKeys.single.length, inInclusiveRange(8, 100));
    });
  });

  group('loading, duplicate submission, outcomes (requirement coverage)', () {
    testWidgets('loading: spinner while the payment is created, no Pay yet', (
      t,
    ) async {
      repo.startGate = Completer();
      final env = await launchDiscover(
        t,
        overrides: [
          bookingRepositoryProvider.overrideWithValue(bookings),
          paymentRepositoryProvider.overrideWithValue(repo),
          paymentServiceProvider.overrideWithValue(svc),
        ],
      );
      env.unawaitedPush('/payments/new?bookingId=$_bookingId');
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
      expect(k('payment_loading'), findsOneWidget);
      expect(k('payment_pay_btn'), findsNothing);
      repo.startGate!.complete();
      await settle(t);
      expect(k('payment_loading'), findsNothing);
      expect(k('payment_pay_btn'), findsOneWidget);
      expect(repo.startCalls, 1);
    });

    testWidgets('taps while verifying cannot submit a second verification', (
      t,
    ) async {
      repo.verifyGate = Completer();
      await open(t);
      await t.tap(k('payment_pay_btn'));
      await t.pump(const Duration(seconds: 1));
      expect(k('payment_verifying'), findsOneWidget);
      expect(k('payment_pay_btn'), findsNothing); // nothing left to tap twice
      expect(svc.calls, 1);
      expect(repo.verifyCalls, 1);
      repo.verifyGate!.complete();
      await settle(t);
      expect(repo.verifyCalls, 1);
      expect(svc.calls, 1);
      expect(find.text('Payment successful'), findsOneWidget);
    });

    testWidgets('success then failure on retry: each outcome has its own view', (
      t,
    ) async {
      svc.outcome = const PaymentSdkFailed('BAD_REQUEST');
      await open(t);
      await tapKey(t, 'payment_pay_btn');
      expect(find.text("Payment didn't go through"), findsOneWidget);
      svc.outcome = null;
      await tapKey(t, 'payment_retry_btn');
      await tapKey(t, 'payment_pay_btn');
      expect(find.text('Payment successful'), findsOneWidget);
      expect(find.text("Payment didn't go through"), findsNothing);
    });
  });

  group('errors and back', () {
    testWidgets(
      'booking not payable (409): "Nothing to pay" and a way to the booking',
      (t) async {
        repo.startFails = const ConflictFailure('x', 'BOOKING_NOT_PAYABLE');
        final env = await open(t);
        expect(find.text('Nothing to pay'), findsOneWidget);
        expect(k('payment_pay_btn'), findsNothing);
        await tapKey(t, 'payment_view_booking_btn');
        expect(env.where, '/bookings/$_bookingId');
      },
    );

    testWidgets(
      'start failed: message and Retry; fee not configured is explained',
      (t) async {
        repo.startFails = const ValidationFailure(
          'x',
          {},
          'FEE_NOT_CONFIGURED',
        );
        await open(t);
        expect(
          find.text(
            "The booking fee isn't set up yet. Please try again later or contact support.",
          ),
          findsOneWidget,
        );
        repo.startFails = null;
        await tapKey(t, 'payment_load_retry_btn');
        expect(k('payment_pay_btn'), findsOneWidget);
      },
    );

    testWidgets('server down on start: localized message, Retry', (t) async {
      repo.startFails = const ServerFailure('raw server text');
      await open(t);
      expect(find.text('raw server text'), findsNothing);
      expect(k('payment_load_retry_btn'), findsOneWidget);
    });

    testWidgets('Back while confirming is blocked', (t) async {
      repo.verifyGate = Completer();
      final env = await open(t);
      await t.tap(k('payment_pay_btn'));
      await t.pump(const Duration(seconds: 1));
      await t.pump(const Duration(seconds: 1));
      expect(k('payment_verifying'), findsOneWidget);
      await t.tap(k('app_back_btn'));
      await t.pump();
      expect(find.text('Please wait, confirming your payment'), findsWidgets);
      expect(env.where, '/payments/new');
      repo.verifyGate!.complete();
      await settle(t);
      expect(find.text('Payment successful'), findsOneWidget);
    });

    testWidgets('Back from ready asks first, then lands on the booking', (
      t,
    ) async {
      final env = await open(t);
      await tapKey(t, 'app_back_btn');
      expect(find.text('Leave payment?'), findsOneWidget);
      await tapKey(t, 'payment_leave_confirm_btn');
      expect(env.where, '/bookings/$_bookingId');
    });
  });

  group('recovery', () {
    testWidgets('a stored payment that succeeded is cleared and told', (
      t,
    ) async {
      final p = (await t.runAsync(
        () => repo.inner.start(_bookingId, idempotencyKey: 'seed-key-0001'),
      ))!;
      await t.runAsync(
        () => repo.inner.verify(
          p.id,
          providerPaymentId: '${PaymentRepositoryMock.fakeProviderPrefix}x',
          signature: 's',
          idempotencyKey: 'seed-key-0002',
        ),
      );
      SharedPreferences.setMockInitialValues({'pending_payment_id': p.id});
      await open(t, route: '/home');
      expect(find.text('Your payment was received.'), findsOneWidget);
      expect(await pendingId(t), isNull);
    });

    testWidgets(
      'a payment still being confirmed keeps its id and offers View',
      (t) async {
        final p = (await t.runAsync(
          () => repo.inner.start(_bookingId, idempotencyKey: 'seed-key-0001'),
        ))!;
        repo.forcedGet = Payment(
          id: p.id,
          bookingId: p.bookingId,
          status: PaymentStatus.pending,
          amountMinor: p.amountMinor,
        );
        SharedPreferences.setMockInitialValues({'pending_payment_id': p.id});
        await open(t, route: '/home');
        // The snackbar and the Home banner both say it.
        expect(
          find.text("We're still confirming your last payment."),
          findsNWidgets(2),
        );
        expect(k('pending_payment_banner'), findsOneWidget);
        expect(await pendingId(t), p.id);
      },
    );

    testWidgets(
      'opened from a stored id while the checkout may have been paid: confirming, with Pay again',
      (t) async {
        final p = (await t.runAsync(
          () => repo.inner.start(_bookingId, idempotencyKey: 'seed-key-0001'),
        ))!;
        SharedPreferences.setMockInitialValues({'pending_payment_id': p.id});
        await open(t, route: '/payments/${p.id}');
        expect(find.text("We're confirming your payment"), findsOneWidget);
        expect(k('payment_pay_btn'), findsNothing);
        expect(k('payment_refresh_btn'), findsOneWidget);
        await tapKey(t, 'payment_pay_again_btn');
        expect(k('payment_pay_btn'), findsOneWidget);
        expect(k('payment_pay_again_btn'), findsNothing);
      },
    );

    testWidgets('an open payment that was never in a checkout is payable', (
      t,
    ) async {
      final p = (await t.runAsync(
        () => repo.inner.start(_bookingId, idempotencyKey: 'seed-key-0001'),
      ))!;
      await open(t, route: '/payments/${p.id}');
      expect(k('payment_pay_btn'), findsOneWidget);
      expect(k('payment_pay_again_btn'), findsNothing);
    });

    testWidgets(
      'Pay again is not offered while confirming after the SDK paid',
      (t) async {
        final base = (await t.runAsync(
          () => repo.inner.start(_bookingId, idempotencyKey: 'seed-key-0001'),
        ))!;
        repo
          ..forcedVerify = base
          ..forcedGet = base;
        await open(t);
        await tapKey(t, 'payment_pay_btn');
        expect(find.text("We're confirming your payment"), findsOneWidget);
        expect(k('payment_pay_again_btn'), findsNothing);
      },
    );

    testWidgets('a failed stored payment is cleared and told', (t) async {
      final p = (await t.runAsync(
        () => repo.inner.start(_bookingId, idempotencyKey: 'seed-key-0001'),
      ))!;
      repo.forcedGet = Payment(
        id: p.id,
        bookingId: p.bookingId,
        status: PaymentStatus.failed,
        amountMinor: p.amountMinor,
      );
      SharedPreferences.setMockInitialValues({'pending_payment_id': p.id});
      await open(t, route: '/home');
      expect(find.text("Your last payment didn't go through."), findsOneWidget);
      expect(await pendingId(t), isNull);
    });

    testWidgets('a payment id that cannot be read yet stays stored', (t) async {
      repo.getFails = true;
      SharedPreferences.setMockInitialValues({'pending_payment_id': 'pay_x'});
      await open(t, route: '/home');
      expect(await pendingId(t), 'pay_x');
    });
  });

  group('confirming banner', () {
    Future<Payment> storedPending(WidgetTester t) async {
      final p = (await t.runAsync(
        () => repo.inner.start(_bookingId, idempotencyKey: 'seed-key-0001'),
      ))!;
      SharedPreferences.setMockInitialValues({'pending_payment_id': p.id});
      return p;
    }

    testWidgets('Home shows it, and View opens the payment', (t) async {
      final p = await storedPending(t);
      final env = await open(t, route: '/home');
      expect(k('pending_payment_banner'), findsOneWidget);
      await tapKey(t, 'pending_payment_view_btn');
      expect(env.where, '/payments/${p.id}');
    });

    testWidgets('nothing stored: no banner', (t) async {
      await open(t, route: '/home');
      expect(k('pending_payment_banner'), findsNothing);
    });

    testWidgets('a settled stored payment shows no banner', (t) async {
      final p = (await t.runAsync(
        () => repo.inner.start(_bookingId, idempotencyKey: 'seed-key-0001'),
      ))!;
      await t.runAsync(
        () => repo.inner.verify(
          p.id,
          providerPaymentId: '${PaymentRepositoryMock.fakeProviderPrefix}x',
          signature: 's',
          idempotencyKey: 'seed-key-0002',
        ),
      );
      SharedPreferences.setMockInitialValues({'pending_payment_id': p.id});
      await open(t, route: '/home');
      expect(k('pending_payment_banner'), findsNothing);
    });

    testWidgets('the booking of that payment shows it', (t) async {
      await storedPending(t);
      await open(t, route: '/bookings/$_bookingId');
      expect(k('pending_payment_banner'), findsOneWidget);
    });

    testWidgets('another booking does not', (t) async {
      await storedPending(t);
      await open(t, route: '/bookings/bk_1900');
      expect(k('pending_payment_banner'), findsNothing);
    });

    testWidgets('an unreadable payment shows no banner', (t) async {
      await storedPending(t);
      repo.getFails = true;
      await open(t, route: '/home');
      expect(k('pending_payment_banner'), findsNothing);
    });
  });

  group('transactions (9.3) and receipt (9.4)', () {
    testWidgets('list shows rows with status chips; a row opens the receipt', (
      t,
    ) async {
      final env = await open(t, route: '/transactions');
      expect(k('txn_row_pay_1900'), findsOneWidget);
      expect(find.text('Paid'), findsWidgets);
      expect(find.text('Refunded'), findsWidgets);
      await tapKey(t, 'txn_row_pay_1900');
      expect(env.where, '/transactions/pay_1900');
      expect(find.text('SN-R-1900'), findsOneWidget);
      expect(k('txn_booking_link'), findsOneWidget);
    });

    testWidgets('filters ask the backend for one status', (t) async {
      await open(t, route: '/transactions');
      await tapKey(t, 'txn_filter_paid');
      expect(k('txn_row_pay_1900'), findsOneWidget);
      expect(k('txn_row_pay_1800'), findsNothing);
      await tapKey(t, 'txn_filter_refunded');
      expect(k('txn_row_pay_1800'), findsOneWidget);
    });

    testWidgets('a refunded receipt says where the money goes', (t) async {
      await open(t, route: '/transactions/pay_1800');
      expect(k('txn_refund_note'), findsOneWidget);
    });

    testWidgets('receipt shows the masked method and the gateway reference', (
      t,
    ) async {
      await open(t, route: '/transactions/pay_1900');
      expect(repo.receiptCalls, 1);
      expect(find.text('Card · Visa **** 4242'), findsOneWidget);
      expect(find.text('pay_mock1900'), findsOneWidget);
    });

    testWidgets('a refunded receipt shows its method too', (t) async {
      await open(t, route: '/transactions/pay_1800');
      expect(find.text('UPI · ab***@okhdfc'), findsOneWidget);
      expect(
        find.text('Refunded on'),
        findsOneWidget,
      ); // from the payment's refundedAt
    });

    testWidgets('Download PDF prints the receipt data and offers to share', (
      t,
    ) async {
      await open(t, route: '/transactions/pay_1900');
      await tapKey(t, 'txn_download_pdf_btn');
      expect(pdf.saved, hasLength(1));
      final doc = pdf.saved.single;
      expect(doc.receiptNumber, 'SN-R-1900');
      expect(doc.fileName, 'SevaNest_Receipt_SN-R-1900.pdf');
      final values = doc.rows.map((r) => r.value);
      expect(values, contains('pay_mock1900'));
      expect(values, contains('Card · Visa **** 4242'));
      expect(find.textContaining('Receipt PDF saved'), findsOneWidget);
      await t.tap(find.text('Share'));
      await settle(t);
      expect(pdf.shared, ['SevaNest_Receipt_SN-R-1900.pdf']);
    });

    testWidgets('repeated taps while the PDF is being made save it once', (
      t,
    ) async {
      pdf.gate = Completer();
      await open(t, route: '/transactions/pay_1900');
      await t.tap(k('txn_download_pdf_btn'));
      await t.pump();
      expect(find.text('Preparing PDF…'), findsOneWidget);
      await t.tap(k('txn_download_pdf_btn'), warnIfMissed: false);
      await t.pump();
      expect(pdf.saved, hasLength(1));
      pdf.gate!.complete();
      await settle(t);
      expect(pdf.saved, hasLength(1));
      expect(find.text('Download PDF'), findsOneWidget);
    });

    testWidgets('a failed save shows an error and allows another try', (
      t,
    ) async {
      pdf.fails = true;
      await open(t, route: '/transactions/pay_1900');
      await tapKey(t, 'txn_download_pdf_btn');
      expect(
        find.textContaining("Couldn't create the receipt PDF"),
        findsOneWidget,
      );
      await t.pump(const Duration(seconds: 9)); // snackbar clears the button
      await settle(t);
      pdf.fails = false;
      await tapKey(t, 'txn_download_pdf_btn');
      expect(pdf.saved, hasLength(2));
    });

    testWidgets('receipt lays out without overflow on a small phone', (
      t,
    ) async {
      t.view.physicalSize = const Size(320 * 3, 568 * 3);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      await open(t, route: '/transactions/pay_1900');
      expect(t.takeException(), isNull);
      expect(k('txn_amount'), findsOneWidget);
      expect(k('txn_download_pdf_btn'), findsOneWidget);
    });

    testWidgets('an unpaid payment has no PDF to make', (t) async {
      final p = (await t.runAsync(
        () => repo.inner.start(_bookingId, idempotencyKey: 'seed-key-0002'),
      ))!;
      await open(t, route: '/transactions/${p.id}');
      await tapKey(t, 'txn_download_pdf_btn');
      expect(pdf.saved, isEmpty);
      expect(
        find.textContaining('available once the payment is complete'),
        findsOneWidget,
      );
    });

    testWidgets('receipt not readable: the payment itself is shown', (t) async {
      repo.receiptFails = const ConflictFailure('x', 'RECEIPT_NOT_AVAILABLE');
      await open(t, route: '/transactions/pay_1900');
      expect(find.text('SN-R-1900'), findsOneWidget);
      expect(find.text('Card · Visa **** 4242'), findsOneWidget);
    });

    testWidgets('a payment that is not paid does not ask for a receipt', (
      t,
    ) async {
      final p = (await t.runAsync(
        () => repo.inner.start(_bookingId, idempotencyKey: 'seed-key-0001'),
      ))!;
      await open(t, route: '/transactions/${p.id}');
      expect(repo.receiptCalls, 0);
      expect(find.text('Issued once the payment succeeds'), findsOneWidget);
    });

    testWidgets('booking Receipt button finds its payment by booking id', (
      t,
    ) async {
      final env = await open(t, route: '/bookings/bk_1900');
      await tapKey(t, 'booking_receipt_btn');
      expect(env.where, '/transactions/pay_1900');
    });

    testWidgets('booking Receipt button falls back to the list on an error', (
      t,
    ) async {
      repo.listFails = const NetworkFailure();
      final env = await open(t, route: '/bookings/bk_1900');
      await tapKey(t, 'booking_receipt_btn');
      expect(env.where, '/transactions');
    });

    testWidgets('empty list: "No transactions yet"', (t) async {
      repo.emptyList = true;
      await open(t, route: '/transactions');
      expect(find.text('No transactions yet'), findsOneWidget);
    });

    testWidgets('account tab links to Transactions', (t) async {
      final env = await open(t, route: '/home');
      await tapKey(t, 'nav_account');
      await tapKey(t, 'account_transactions_btn');
      expect(env.where, '/transactions');
    });

    testWidgets('a list error shows Retry, which recovers', (t) async {
      repo.listFails = const NetworkFailure();
      await open(t, route: '/transactions');
      expect(find.text('Retry'), findsOneWidget);
      repo.listFails = null;
      await t.tap(find.text('Retry'));
      await settle(t);
      expect(k('txn_row_pay_1900'), findsOneWidget);
    });
  });

  test('no gateway secret in the app source (PAY-15)', () {
    final hits = <String>[];
    for (final f in Directory(
      'lib',
    ).listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      final s = f.readAsStringSync();
      if (RegExp(r'key_secret|rzp_(live|test)_[A-Za-z0-9]{6,}').hasMatch(s)) {
        hits.add(f.path);
      }
    }
    expect(hits, isEmpty);
  });
}
