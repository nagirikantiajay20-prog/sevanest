// LIVE integration test for module 11: read-only requests to the deployed backend (not mocked).
//
//   Skipped unless SEVANEST_LIVE=1, with the backend test customer from the environment:
//
//     $env:SEVANEST_LIVE = '1'; $env:SEVANEST_TEST_MOBILE = '<number>'; $env:SEVANEST_TEST_OTP = '<otp>'
//     flutter test test/live/replacement_live_test.dart
//
//   It never calls `POST /replacement-requests`, `cancel` or `select`: a request moves the booking
//   to REPLACEMENT_REQUESTED and only staff can settle it, so a test must not leave one behind.
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
import 'package:sevanest_customer/features/replacement/data/replacement_repository_remote.dart';
import 'package:sevanest_customer/features/replacement/domain/replacement.dart';
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
    'LIVE replacement: reads only',
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
      final repo = ReplacementRepositoryRemote(dio);
      const unknown = '00000000-0000-4000-8000-000000000000';

      // Anonymous calls are refused.
      await expectLater(repo.list(), throwsA(isA<UnauthorizedFailure>()));
      await expectLater(repo.get(unknown), throwsA(isA<UnauthorizedFailure>()));

      final auth = AuthRepositoryRemote(dio, _RandomDeviceId());
      await auth.requestOtp(mobile!);
      final tokens = await auth.verifyOtp(mobile, otp!);
      await store.write(access: tokens.access, refresh: tokens.refresh);

      // Somebody else's (or no) request and booking are 404.
      await expectLater(repo.get(unknown), throwsA(isA<NotFoundFailure>()));
      await expectLater(repo.chain(unknown), throwsA(isA<NotFoundFailure>()));

      final mine = await repo.list();
      // ignore: avoid_print
      print(
        'LIVE my replacement requests: ${mine.items.map((r) => r.status.name).toList()}, '
        'next: ${mine.nextCursor}',
      );
      for (final r in mine.items) {
        expect(r.id, isNotEmpty);
        expect(r.bookingId, isNotEmpty);
        expect(r.status, isNot(ReplacementStatus.unknown));
      }
      if (mine.items.isNotEmpty) {
        final one = await repo.get(mine.items.first.id);
        expect(one.id, mine.items.first.id);
        final chain = await repo.chain(one.bookingId);
        expect(chain, isNotEmpty);
        expect(chain.where((e) => e.current), hasLength(1));
        expect(
          [for (var i = 0; i < chain.length; i++) chain[i].position],
          [for (var i = 1; i <= chain.length; i++) i],
          reason: 'the chain is oldest first',
        );
      } else {
        // ignore: avoid_print
        print(
          'LIVE: this customer has no replacement request; get / chain of a real '
          'request, create, cancel and select were NOT exercised',
        );
      }

      final bookings = await BookingRepositoryRemote(dio).list();
      final chained = bookings.items
          .where((b) => b.previousBookingId != null)
          .firstOrNull;
      if (chained != null) {
        final chain = await repo.chain(chained.id);
        expect(chain.length, greaterThan(1));
      }
    },
    skip: live && mobile != null && otp != null
        ? false
        : 'set SEVANEST_LIVE=1 and the test customer env vars',
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
