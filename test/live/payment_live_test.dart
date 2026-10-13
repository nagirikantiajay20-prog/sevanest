// LIVE integration test for module 09: real HTTPS requests to the deployed backend (not mocked).
//
//   Skipped unless SEVANEST_LIVE=1, with the backend test customer from the environment:
//
//     $env:SEVANEST_LIVE = '1'; $env:SEVANEST_TEST_MOBILE = '<number>'; $env:SEVANEST_TEST_OTP = '<otp>'
//     flutter test test/live/payment_live_test.dart
//
//   Reads only, except: if the customer has a PENDING_PAYMENT booking it starts its payment
//   (`POST /payments`, which the backend documents as "start or resume"). It never calls `verify`
//   with real data (no gateway SDK runs in a test) and prints only the NAMES of `checkout` fields.
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/core/config/app_config.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/network/dio_provider.dart';
import 'package:sevanest_customer/core/storage/device_id_store.dart';
import 'package:sevanest_customer/core/storage/secure_session_store.dart';
import 'package:sevanest_customer/features/authentication/data/auth_repository_remote.dart';
import 'package:sevanest_customer/features/booking/data/booking_repository_remote.dart';
import 'package:sevanest_customer/features/booking/domain/booking.dart';
import 'package:sevanest_customer/features/payment/data/payment_repository_remote.dart';
import 'package:sevanest_customer/features/payment/domain/payment.dart';
import 'package:uuid/uuid.dart';

import '../helpers/fakes.dart';

class _RandomDeviceId implements DeviceIdStore {
  final String id = const Uuid().v4();
  @override
  Future<String> get() async => id;
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
      final refunded = await payments.list(status: PaymentStatus.refunded);
      expect(
        refunded.items.every((p) => p.status == PaymentStatus.refunded),
        isTrue,
      );

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
      final payable = all.items
          .where((b) => b.status == BookingStatus.pendingPayment)
          .firstOrNull;
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
          'checkout fields=${a.checkout?.keys.toList()}',
        );
        expect((await payments.get(a.id)).bookingId, payable.id);
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
