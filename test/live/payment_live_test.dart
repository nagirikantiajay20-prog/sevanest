// LIVE integration test for module 09: real HTTPS requests to the deployed backend (not mocked).
//
//   Skipped unless SEVANEST_LIVE=1, with the backend test customer from the environment:
//
//     $env:SEVANEST_LIVE = '1'; $env:SEVANEST_TEST_MOBILE = '<number>'; $env:SEVANEST_TEST_OTP = '<otp>'
//     flutter test test/live/payment_live_test.dart
//
//   Reads only, except: if the customer has a PENDING_PAYMENT booking it starts its payment
//   (`POST /payments`, which the backend documents as "start or resume"). It never calls `verify`
//   with real data (no gateway SDK runs in a test) and prints only whether the `checkout` has a key, never its values.
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/core/config/app_config.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/network/dio_provider.dart';
import 'package:sevanest_customer/core/storage/device_id_store.dart';
import 'package:sevanest_customer/core/storage/secure_session_store.dart';
import 'package:sevanest_customer/features/addresses/data/address_repository_remote.dart';
import 'package:sevanest_customer/features/addresses/domain/address.dart';
import 'package:sevanest_customer/features/authentication/data/auth_repository_remote.dart';
import 'package:sevanest_customer/features/booking/data/booking_repository_remote.dart';
import 'package:sevanest_customer/features/booking/domain/booking.dart';
import 'package:sevanest_customer/features/interview_trial/domain/interview.dart';
import 'package:sevanest_customer/features/payment/data/payment_repository_remote.dart';
import 'package:sevanest_customer/features/payment/domain/payment.dart';
import 'package:sevanest_customer/features/service_discovery/data/catalog_repository_remote.dart';
import 'package:sevanest_customer/features/service_discovery/domain/budget.dart';
import 'package:sevanest_customer/features/worker_search/data/worker_search_repository_remote.dart';
import 'package:sevanest_customer/features/worker_search/domain/worker_search.dart';
import 'package:uuid/uuid.dart';

import '../helpers/fakes.dart';

class _RandomDeviceId implements DeviceIdStore {
  final String id = const Uuid().v4();
  @override
  Future<String> get() async => id;
}

/// Books a worker and walks the booking to PENDING_PAYMENT (schedule -> interview-complete ->
/// confirm-worker), as the backend described. Only with SEVANEST_LIVE_BOOK=1: it creates a booking.
Future<Booking> _bookUntilPayable(
  Dio dio,
  BookingRepositoryRemote bookings,
) async {
  final addresses = AddressRepositoryRemote(dio);
  final areas = await addresses.serviceAreas();
  final cats = await CatalogRepositoryRemote(dio).categories();
  final search = WorkerSearchRepositoryRemote(dio);
  final start = DateTime.now().add(const Duration(days: 3));
  for (final area in areas) {
    for (final cat in cats) {
      final eng = cat.engagements.where((e) => e.available).firstOrNull;
      if (eng == null) continue;
      final page = await search.search(
        WorkerQuery(category: cat.id, areaId: area.id, engagement: eng.type),
      );
      final worker = page.items.firstOrNull;
      if (worker == null) continue;
      final saved = await addresses.list();
      final address =
          saved.firstOrNull ??
          await addresses.create(
            AddressInput(
              line: '1',
              area: area.name,
              city: area.city ?? 'Hyderabad',
              pincode: '500001',
            ),
          );
      final Booking created;
      try {
        created = await bookings.create(
          BookingRequest(
            category: cat.id,
            areaId: area.id,
            addressId: address.id,
            startDate: start,
            engagement: eng.type,
            availableFrom: '09:00',
            availableTo: '13:00',
            workerId: worker.id,
            budgetMin: cat.requiresBudget ? 10000 : null,
            budgetMax: cat.requiresBudget ? 20000 : null,
            budgetPeriod: cat.requiresBudget ? BudgetPeriod.monthly : null,
          ),
          idempotencyKey: const Uuid().v4(),
        );
      } on ValidationFailure catch (e) {
        // ignore: avoid_print
        print('LIVE create refused: ${e.code} ${e.fieldErrors} ${e.message}');
        continue;
      } on ConflictFailure catch (e) {
        // ignore: avoid_print
        print('LIVE create conflict: ${e.code} ${e.message}');
        continue;
      }
      final b = created;
      // ignore: avoid_print
      print('LIVE booked ${cat.id} with a worker: ${b.status.name}');
      return _advance(bookings, b, start);
    }
  }
  throw StateError('no category/area/worker to book with');
}

/// matched -> schedule -> interview-complete -> confirm-worker (PENDING_PAYMENT). Resumes from
/// whichever step the booking is at, so a run that stopped half way does not book again.
Future<Booking> _advance(
  BookingRepositoryRemote bookings,
  Booking from,
  DateTime start,
) async {
  var b = from;
  try {
    if (b.status == BookingStatus.matched) {
      b = await bookings.schedule(
        b.id,
        InterviewType.interview,
        DateTime.now().add(const Duration(days: 1)),
      );
    }
    if (b.status == BookingStatus.interviewTrialScheduled) {
      b = await bookings.interviewComplete(b.id);
    }
    if (b.status == BookingStatus.interviewTrialCompleted) {
      b = await bookings.confirmWorker(b.id, start);
    }
  } on ValidationFailure catch (e) {
    // ignore: avoid_print
    print(
      'LIVE step refused at ${b.status.name}: ${e.code} ${e.fieldErrors} ${e.message}',
    );
    rethrow;
  } on ConflictFailure catch (e) {
    // ignore: avoid_print
    print('LIVE step conflict at ${b.status.name}: ${e.code} ${e.message}');
    rethrow;
  }
  // ignore: avoid_print
  print('LIVE booking now: ${b.status.name}');
  return b;
}

void main() {
  final env = Platform.environment;
  final live = env['SEVANEST_LIVE'] == '1';
  final mobile = env['SEVANEST_TEST_MOBILE'];
  final otp = env['SEVANEST_TEST_OTP'];
  final baseUrl = env['SEVANEST_API_BASE'] ?? AppConfig.dev.apiBaseUrl;

  test(
    'LIVE payments: auth, history, not-found, not-payable, start',
    () async {
      final store = InMemorySessionStore();
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(
            AppConfig(env: AppEnv.dev, apiBaseUrl: baseUrl, useMocks: false),
          ),
          sessionStoreProvider.overrideWithValue(store),
        ],
      );
      addTearDown(container.dispose);
      final dio = container.read(dioProvider);
      final payments = PaymentRepositoryRemote(dio);

      // Anonymous calls are refused.
      await expectLater(payments.list(), throwsA(isA<UnauthorizedFailure>()));

      final auth = AuthRepositoryRemote(dio, _RandomDeviceId());
      await auth.requestOtp(mobile!);
      final tokens = await auth.verifyOtp(mobile, otp!);
      await store.write(access: tokens.access, refresh: tokens.refresh);

      // History parses against the typed shape.
      final page = await payments.list();
      // ignore: avoid_print
      print(
        'LIVE payments in history: ${page.items.length}, next: ${page.nextCursor}',
      );
      for (final p in page.items) {
        expect(p.id, isNotEmpty);
        expect(p.bookingId, isNotEmpty);
        expect(p.status, isNot(PaymentStatus.unknown));
      }
      final refunded = await payments.list(refunded: true);
      expect(refunded.items.every((p) => p.wasRefunded), isTrue);
      if (page.items.isNotEmpty) {
        final first = page.items.first;
        final ofBooking = await payments.list(bookingId: first.bookingId);
        expect(ofBooking.items.map((p) => p.id), contains(first.id));
      }
      final paid = page.items.where((p) => p.wasPaid).firstOrNull;
      if (paid != null) {
        final r = await payments.receipt(paid.id);
        expect(r.paymentId, paid.id);
        expect(r.receiptNumber, isNotEmpty);
      }

      // Somebody else's / unknown payment: 404.
      await expectLater(
        payments.get('00000000-0000-4000-8000-000000000000'),
        throwsA(isA<NotFoundFailure>()),
      );
      await expectLater(
        payments.verify(
          '00000000-0000-4000-8000-000000000000',
          providerPaymentId: 'pay_none',
          signature: 'none',
          idempotencyKey: const Uuid().v4(),
        ),
        throwsA(isA<NotFoundFailure>()),
      );

      // A booking that is not waiting for payment cannot be paid; one that is gets a payment.
      final bookings = BookingRepositoryRemote(dio);
      final all = await bookings.list();
      // ignore: avoid_print
      print('LIVE bookings: ${all.items.map((b) => b.status.name).toList()}');
      final notPayable = all.items
          .where((b) => b.status != BookingStatus.pendingPayment)
          .firstOrNull;
      if (notPayable != null) {
        await expectLater(
          payments.start(notPayable.id, idempotencyKey: const Uuid().v4()),
          throwsA(
            isA<ConflictFailure>().having(
              (e) => e.code,
              'code',
              'BOOKING_NOT_PAYABLE',
            ),
          ),
        );
      }
      var payable = all.items
          .where((b) => b.status == BookingStatus.pendingPayment)
          .firstOrNull;
      if (payable == null && env['SEVANEST_LIVE_BOOK'] == '1') {
        final open = all.items
            .where(
              (b) => const {
                BookingStatus.matched,
                BookingStatus.interviewTrialScheduled,
                BookingStatus.interviewTrialCompleted,
              }.contains(b.status),
            )
            .firstOrNull;
        payable = open == null
            ? await _bookUntilPayable(dio, bookings)
            : await _advance(
                bookings,
                open,
                DateTime.now().add(const Duration(days: 3)),
              );
      }
      if (payable != null) {
        final key = const Uuid().v4();
        final a = await payments.start(payable.id, idempotencyKey: key);
        final again = await payments.start(payable.id, idempotencyKey: key);
        expect(again.id, a.id); // same key, same answer
        final resumed = await payments.start(
          payable.id,
          idempotencyKey: const Uuid().v4(),
        );
        expect(
          resumed.id,
          a.id,
        ); // "calling again while a payment is open returns the same"
        // ignore: avoid_print
        print(
          'LIVE started payment: status=${a.status.name} amountMinor=${a.amountMinor} '
          'gateway=${a.checkout?.gateway} hasKeyId=${a.checkout?.keyId != null}',
        );
        // Staging runs Razorpay test mode: the app opens the SDK only for this shape.
        expect(a.checkout?.isRazorpay, isTrue);
        expect(a.checkout!.orderId, startsWith('order_'));
        expect(a.status, PaymentStatus.pending);
        expect((await payments.get(a.id)).bookingId, payable.id);
        await expectLater(
          payments.receipt(a.id),
          throwsA(
            isA<ConflictFailure>().having(
              (e) => e.code,
              'code',
              'RECEIPT_NOT_AVAILABLE',
            ),
          ),
        );
      } else {
        // ignore: avoid_print
        print(
          'LIVE: no PENDING_PAYMENT booking for this customer; start was NOT exercised',
        );
      }
    },
    skip: live && mobile != null && otp != null
        ? false
        : 'set SEVANEST_LIVE=1 and the test customer env vars',
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
