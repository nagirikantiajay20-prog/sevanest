// LIVE integration test for module 10: read-only requests to the deployed backend (not mocked).
//
//   Skipped unless SEVANEST_LIVE=1, with the backend test customer from the environment:
//
//     $env:SEVANEST_LIVE = '1'; $env:SEVANEST_TEST_MOBILE = '<number>'; $env:SEVANEST_TEST_OTP = '<otp>'
//     flutter test test/live/service_live_test.dart
//
//   It never calls `POST /ratings`: a rating cannot be edited or deleted by the customer, so a
//   test must not leave one behind.
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/core/config/app_config.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/network/dio_provider.dart';
import 'package:sevanest_customer/core/storage/device_id_store.dart';
import 'package:sevanest_customer/core/storage/secure_session_store.dart';
import 'package:sevanest_customer/features/active_service/data/attendance_repository_remote.dart';
import 'package:sevanest_customer/features/active_service/domain/attendance.dart';
import 'package:sevanest_customer/features/authentication/data/auth_repository_remote.dart';
import 'package:sevanest_customer/features/booking/data/booking_repository_remote.dart';
import 'package:sevanest_customer/features/booking/domain/booking.dart';
import 'package:sevanest_customer/features/ratings/data/rating_repository_remote.dart';
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
    'LIVE active service / history / rating: reads only',
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
      final attendance = AttendanceRepositoryRemote(dio);
      final ratings = RatingRepositoryRemote(dio);
      const unknown = '00000000-0000-4000-8000-000000000000';

      // Anonymous calls are refused.
      await expectLater(
        attendance.page(unknown),
        throwsA(isA<UnauthorizedFailure>()),
      );
      await expectLater(ratings.mine(), throwsA(isA<UnauthorizedFailure>()));

      final auth = AuthRepositoryRemote(dio, _RandomDeviceId());
      await auth.requestOtp(mobile!);
      final tokens = await auth.verifyOtp(mobile, otp!);
      await store.write(access: tokens.access, refresh: tokens.refresh);

      // A customer token may read attendance (request 28: confirmed by the Swagger, not by data).
      await expectLater(
        attendance.page(unknown),
        throwsA(isA<NotFoundFailure>()),
      );
      await expectLater(
        attendance.summary(unknown, '2026-10'),
        throwsA(isA<NotFoundFailure>()),
      );
      // Not rated = null, never an error.
      expect(await ratings.forBooking(unknown), isNull);

      final mine = await ratings.mine();
      // ignore: avoid_print
      print('LIVE my ratings: ${mine.items.length}, next: ${mine.nextCursor}');
      for (final r in mine.items) {
        expect(r.bookingId, isNotEmpty);
        expect(r.score, greaterThanOrEqualTo(1));
      }

      final bookings = await BookingRepositoryRemote(dio).list();
      // ignore: avoid_print
      print(
        'LIVE bookings: ${bookings.items.map((b) => b.status.name).toList()}',
      );
      final withService = bookings.items
          .where(
            (b) =>
                b.status == BookingStatus.active ||
                b.status == BookingStatus.completed ||
                b.status == BookingStatus.replacementRequested,
          )
          .firstOrNull;
      if (withService == null) {
        // ignore: avoid_print
        print(
          'LIVE: no ACTIVE / COMPLETED booking for this customer; '
          'attendance and the rating read of a real booking were NOT exercised',
        );
        return;
      }
      final page = await attendance.page(withService.id);
      // ignore: avoid_print
      print(
        'LIVE attendance of ${withService.status.name}: ${page.items.length} rows, '
        'statuses ${page.items.map((e) => e.status.name).toSet()}',
      );
      for (final e in page.items) {
        expect(e.date, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
        expect(e.status, isNot(AttendanceStatus.unknown));
      }
      final now = DateTime.now();
      final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final summary = await attendance.summary(withService.id, month);
      expect(summary.present, greaterThanOrEqualTo(0));
      // 404 (none) or a rating that belongs to this booking.
      final r = await ratings.forBooking(withService.id);
      if (r != null) expect(r.bookingId, withService.id);
    },
    skip: live && mobile != null && otp != null
        ? false
        : 'set SEVANEST_LIVE=1 and the test customer env vars',
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
