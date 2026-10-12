// LIVE integration tests: real HTTPS requests to the deployed backend (not mocked).
//
//   Always skipped unless SEVANEST_LIVE=1, so `flutter test` stays hermetic and offline-safe.
//   The full-login test additionally needs a backend-provisioned TEST customer number and its
//   static OTP, supplied ONLY through the environment (never commit them):
//
//     $env:SEVANEST_LIVE = '1'
//     $env:SEVANEST_TEST_MOBILE = '<10-digit test customer number>'
//     $env:SEVANEST_TEST_OTP = '<its static OTP>'
//     flutter test test/live
//
//   Optional: SEVANEST_API_BASE (defaults to the dev config URL).
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/core/config/app_config.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/network/dio_provider.dart';
import 'package:sevanest_customer/core/network/error_mapper.dart';
import 'package:sevanest_customer/core/storage/device_id_store.dart';
import 'package:sevanest_customer/core/storage/secure_session_store.dart';
import 'package:sevanest_customer/features/authentication/data/auth_repository_remote.dart';
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
  const why = 'set SEVANEST_LIVE=1 to run live backend tests';

  late InMemorySessionStore store;
  late ProviderContainer container;
  late AuthRepositoryRemote repo;
  late Dio dio;

  setUp(() {
    store = InMemorySessionStore();
    container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(
          AppConfig(env: AppEnv.dev, apiBaseUrl: baseUrl, useMocks: false),
        ),
        sessionStoreProvider.overrideWithValue(store),
      ],
    );
    dio = container.read(dioProvider);
    repo = AuthRepositoryRemote(dio, _RandomDeviceId());
  });
  tearDown(() => container.dispose());

  group('LIVE public checks (no SMS sent, no account touched)', () {
    test(
      'invalid mobile -> VALIDATION_FAILED mapped to a field error',
      () async {
        await expectLater(
          repo.requestOtp('123'),
          throwsA(
            isA<ValidationFailure>().having(
              (f) => f.fieldErrors.containsKey('mobile'),
              'has mobile field error',
              isTrue,
            ),
          ),
        );
      },
      skip: live ? false : why,
    );

    test(
      'verifying a code that was never requested -> OTP expired',
      () async {
        await expectLater(
          repo.verifyOtp('9000000001', '000000'),
          throwsA(
            isA<OtpFailure>().having((f) => f.error, 'error', OtpError.expired),
          ),
        );
      },
      skip: live ? false : why,
    );

    test(
      'GET /customers/me without a session -> 401 UnauthorizedFailure',
      () async {
        await expectLater(
          repo.profileComplete(),
          throwsA(isA<UnauthorizedFailure>()),
        );
      },
      skip: live ? false : why,
    );

    test('rate-limit headers are exposed on every response', () async {
      final res = await Dio(
        BaseOptions(baseUrl: baseUrl),
      ).get<dynamic>('/app-config');
      expect(res.statusCode, 200);
      expect(res.headers.value('x-ratelimit-limit'), isNotNull);
    }, skip: live ? false : why);

    test('TLS is enforced: the API is reached over https', () {
      expect(baseUrl, startsWith('https://'));
    }, skip: live ? false : why);
  });

  group('LIVE full login with the backend test account', () {
    test(
      'request -> wrong OTP -> verify -> /customers/me -> refresh rotation -> logout',
      () async {
        // 1. Request an OTP (the backend test number does not need the SMS provider).
        final challenge = await repo.requestOtp(mobile!);
        expect(challenge.resendAfterSeconds, greaterThan(0));
        expect(challenge.expiresInSeconds, greaterThan(0));

        // 2. A wrong code is rejected as "invalid" (not expired, not a crash).
        await expectLater(
          repo.verifyOtp(mobile, otp == '000001' ? '000002' : '000001'),
          throwsA(
            isA<OtpFailure>().having((f) => f.error, 'error', OtpError.invalid),
          ),
        );

        // 3. The right code starts a session.
        final tokens = await repo.verifyOtp(mobile, otp!);
        expect(tokens.access, isNotEmpty);
        expect(tokens.refresh, isNotEmpty);
        await store.write(access: tokens.access, refresh: tokens.refresh);

        try {
          // 4. Authenticated call works and reports profile state as a bool.
          expect(await repo.profileComplete(), isA<bool>());

          // 5. Expired access token -> interceptor refreshes once, rotates, retries.
          await store.write(
            access: 'expired.invalid.token',
            refresh: tokens.refresh,
          );
          final me = await dio.get<dynamic>('/users/me');
          expect(me.statusCode, 200);
          final rotated = (await store.read())!;
          expect(rotated.refresh, isNot(tokens.refresh));
          expect(rotated.access, isNot('expired.invalid.token'));
        } finally {
          // 6. Logout revokes the session server-side.
          final current = await store.read();
          if (current != null) await repo.logout();
        }

        final after = await store.read();
        await expectLater(
          Dio(BaseOptions(baseUrl: baseUrl)).get<dynamic>(
            '/users/me',
            options: Options(
              headers: {'Authorization': 'Bearer ${after!.access}'},
            ),
          ),
          throwsA(
            isA<DioException>().having(
              (e) => mapDioError(e),
              'mapped',
              isA<UnauthorizedFailure>(),
            ),
          ),
        );
      },
      skip: live && mobile != null && otp != null
          ? false
          : 'needs SEVANEST_LIVE=1, SEVANEST_TEST_MOBILE and SEVANEST_TEST_OTP',
    );
  });
}
