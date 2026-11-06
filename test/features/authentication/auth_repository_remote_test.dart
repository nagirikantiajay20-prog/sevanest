// UNIT tests: HTTP is mocked. Response bodies mirror what the deployed backend returned during
// the controlled live checks documented in docs/05_API_CONTRACT_ASSUMPTIONS.md.
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/core/config/app_config.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/network/dio_provider.dart';
import 'package:sevanest_customer/core/network/safe_log_interceptor.dart';
import 'package:sevanest_customer/core/storage/device_id_store.dart';
import 'package:sevanest_customer/core/storage/secure_session_store.dart';
import 'package:sevanest_customer/features/authentication/data/auth_repository_remote.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fakes.dart';

class _FixedDeviceId implements DeviceIdStore {
  @override
  Future<String> get() async => '11111111-1111-4111-8111-111111111111';
}

String _err(String code, [String message = 'm']) =>
    jsonEncode({'code': code, 'message': message, 'requestId': 'r'});

const _session =
    '{"accessToken":"acc-token","refreshToken":"ref-token","tokenType":"Bearer",'
    '"expiresIn":900,"user":{"id":"u1","type":"CUSTOMER","isNewUser":true}}';

void main() {
  late List<RequestOptions> seen;
  late AuthRepositoryRemote repo;

  AuthRepositoryRemote build(AdapterHandler handler) {
    seen = [];
    final dio = Dio(BaseOptions(baseUrl: 'https://x.test/api/v1'))
      ..httpClientAdapter = FakeAdapter((o) {
        seen.add(o);
        return handler(o);
      });
    return repo = AuthRepositoryRemote(dio, _FixedDeviceId());
  }

  group('requestOtp', () {
    test('POSTs mobile + appType CUSTOMER and maps the challenge', () async {
      build(
        (o) async =>
            jsonBody('{"expiresInSeconds":300,"resendAfterSeconds":30}', 200),
      );
      final c = await repo.requestOtp('9876543210');
      expect(seen.single.method, 'POST');
      expect(seen.single.path, '/auth/otp/request');
      expect(seen.single.data, {'mobile': '9876543210', 'appType': 'CUSTOMER'});
      expect(c.expiresInSeconds, 300);
      expect(c.resendAfterSeconds, 30);
    });

    test('missing/odd fields fall back to defaults, never crash', () async {
      build((o) async => jsonBody('{"resendAfterSeconds":"x"}', 200));
      final c = await repo.requestOtp('9876543210');
      expect(c.expiresInSeconds, 300);
      expect(c.resendAfterSeconds, 30);
    });

    test('429 carries Retry-After from details[0].retryAfterSeconds', () async {
      build(
        (o) async => jsonBody(
          '{"code":"RATE_LIMITED","message":"slow down","details":[{"retryAfterSeconds":45}]}',
          429,
        ),
      );
      await expectLater(
        repo.requestOtp('9876543210'),
        throwsA(
          isA<RateLimitedFailure>().having(
            (f) => f.retryAfterSeconds,
            'retryAfterSeconds',
            45,
          ),
        ),
      );
    });

    test('429 prefers the Retry-After header', () async {
      build(
        (o) async => ResponseBody.fromString(
          '{"code":"RATE_LIMITED"}',
          429,
          headers: {
            'retry-after': ['90'],
            Headers.contentTypeHeader: ['application/json'],
          },
        ),
      );
      await expectLater(
        repo.requestOtp('9876543210'),
        throwsA(
          isA<RateLimitedFailure>().having(
            (f) => f.retryAfterSeconds,
            'retryAfterSeconds',
            90,
          ),
        ),
      );
    });

    test('503 SMS_NOT_CONFIGURED -> ServerFailure', () async {
      build(
        (o) async => jsonBody(_err('SMS_NOT_CONFIGURED', 'unavailable'), 503),
      );
      await expectLater(
        repo.requestOtp('9876543210'),
        throwsA(isA<ServerFailure>()),
      );
    });

    test('409 ACCOUNT_TYPE_MISMATCH keeps the backend message', () async {
      build(
        (o) async => jsonBody(
          _err('ACCOUNT_TYPE_MISMATCH', 'registered for a different type'),
          409,
        ),
      );
      await expectLater(
        repo.requestOtp('9876500001'),
        throwsA(
          isA<ConflictFailure>().having(
            (f) => f.message,
            'message',
            'registered for a different type',
          ),
        ),
      );
    });

    test('400 details[] become field errors', () async {
      build(
        (o) async => jsonBody(
          '{"code":"VALIDATION_FAILED","message":"Request validation failed",'
          '"details":[{"field":"mobile","messages":["must be a valid Indian mobile number"]}]}',
          400,
        ),
      );
      await expectLater(
        repo.requestOtp('123'),
        throwsA(
          isA<ValidationFailure>().having(
            (f) => f.fieldErrors['mobile'],
            'mobile',
            'must be a valid Indian mobile number',
          ),
        ),
      );
    });

    test('connection problems map to NetworkFailure', () async {
      build(
        (o) async => throw DioException(
          requestOptions: o,
          type: DioExceptionType.connectionError,
        ),
      );
      await expectLater(
        repo.requestOtp('9876543210'),
        throwsA(isA<NetworkFailure>()),
      );
    });
  });

  group('verifyOtp', () {
    test('sends deviceId + appType and returns the tokens', () async {
      build((o) async => jsonBody(_session, 200));
      final t = await repo.verifyOtp('9876543210', '123456');
      expect(seen.single.path, '/auth/otp/verify');
      expect(seen.single.data, {
        'mobile': '9876543210',
        'appType': 'CUSTOMER',
        'otp': '123456',
        'deviceId': '11111111-1111-4111-8111-111111111111',
      });
      expect(t, (access: 'acc-token', refresh: 'ref-token'));
    });

    test('OTP_INVALID -> OtpFailure.invalid', () async {
      build((o) async => jsonBody(_err('OTP_INVALID'), 400));
      await expectLater(
        repo.verifyOtp('9876543210', '000000'),
        throwsA(
          isA<OtpFailure>().having((f) => f.error, 'error', OtpError.invalid),
        ),
      );
    });

    test('OTP_EXPIRED -> OtpFailure.expired', () async {
      build((o) async => jsonBody(_err('OTP_EXPIRED'), 400));
      await expectLater(
        repo.verifyOtp('9876543210', '000000'),
        throwsA(
          isA<OtpFailure>().having((f) => f.error, 'error', OtpError.expired),
        ),
      );
    });

    test(
      'an OTP error whose message is a list is still an OtpFailure',
      () async {
        build(
          (o) async => jsonBody(
            jsonEncode({
              'code': 'OTP_INVALID',
              'message': ['otp must be 6 digits'],
              'requestId': 'r',
            }),
            400,
          ),
        );
        await expectLater(
          repo.verifyOtp('9876543210', '000000'),
          throwsA(
            isA<OtpFailure>().having((f) => f.error, 'error', OtpError.invalid),
          ),
        );
      },
    );

    test('lock-out style code -> OtpFailure.locked', () async {
      build((o) async => jsonBody(_err('OTP_ATTEMPTS_EXCEEDED'), 400));
      await expectLater(
        repo.verifyOtp('9876543210', '000000'),
        throwsA(
          isA<OtpFailure>().having((f) => f.error, 'error', OtpError.locked),
        ),
      );
    });

    test('429 is not turned into an OtpFailure (keeps Retry-After)', () async {
      build(
        (o) async => jsonBody(
          '{"code":"RATE_LIMITED","details":[{"retryAfterSeconds":300}]}',
          429,
        ),
      );
      await expectLater(
        repo.verifyOtp('9876543210', '123456'),
        throwsA(isA<RateLimitedFailure>()),
      );
    });

    test('a success body without tokens fails closed', () async {
      build((o) async => jsonBody('{"user":{"id":"u"}}', 200));
      await expectLater(
        repo.verifyOtp('9876543210', '123456'),
        throwsA(isA<UnknownFailure>()),
      );
    });

    test('parseTokens rejects empty / missing / non-string tokens', () {
      expect(parseTokens(null), isNull);
      expect(parseTokens({'accessToken': '', 'refreshToken': 'r'}), isNull);
      expect(parseTokens({'accessToken': 'a'}), isNull);
      expect(parseTokens({'accessToken': 1, 'refreshToken': 2}), isNull);
      expect(parseTokens({'accessToken': 'a', 'refreshToken': 'r'}), (
        access: 'a',
        refresh: 'r',
      ));
    });
  });

  group('profileComplete', () {
    test('200 -> true', () async {
      build((o) async => jsonBody('{"id":"c1"}', 200));
      expect(await repo.profileComplete(), isTrue);
      expect(seen.single.path, '/customers/me');
    });

    test('404 CUSTOMER_PROFILE_NOT_FOUND -> false', () async {
      build((o) async => jsonBody(_err('CUSTOMER_PROFILE_NOT_FOUND'), 404));
      expect(await repo.profileComplete(), isFalse);
    });

    test('any other 404 is a failure, not "incomplete"', () async {
      build((o) async => jsonBody(_err('NOT_FOUND'), 404));
      await expectLater(
        repo.profileComplete(),
        throwsA(isA<NotFoundFailure>()),
      );
    });

    test('401 -> UnauthorizedFailure', () async {
      build((o) async => jsonBody(_err('UNAUTHENTICATED'), 401));
      await expectLater(
        repo.profileComplete(),
        throwsA(isA<UnauthorizedFailure>()),
      );
    });
  });

  test('logout POSTs /auth/logout (204)', () async {
    build((o) async => ResponseBody.fromString('', 204));
    await repo.logout();
    expect(seen.single.method, 'POST');
    expect(seen.single.path, '/auth/logout');
  });

  group('safety', () {
    test('device id is a v4 UUID and stable across reads', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      final store = PrefsDeviceIdStore();
      final a = await store.get();
      final b = await store.get();
      expect(a, b);
      expect(
        a,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
    });

    test('dev/stg/prod all use https and TLS checks are not bypassed', () {
      for (final c in [AppConfig.dev, AppConfig.stg, AppConfig.prod]) {
        expect(c.apiBaseUrl, startsWith('https://'));
      }
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(AppConfig.dev),
          sessionStoreProvider.overrideWithValue(InMemorySessionStore()),
        ],
      );
      addTearDown(container.dispose);
      final dio = container.read(dioProvider);
      // A custom createHttpClient / badCertificateCallback would be set here to relax TLS.
      expect(dio.httpClientAdapter.runtimeType.toString(), contains('IOHttp'));
      expect(dio.options.baseUrl, AppConfig.dev.apiBaseUrl);
    });

    test('request logging never prints bodies, OTPs or tokens', () async {
      final lines = <String>[];
      final original = debugPrint;
      debugPrint = (message, {wrapWidth}) => lines.add(message ?? '');
      addTearDown(() => debugPrint = original);

      final dio = Dio(BaseOptions(baseUrl: 'https://x.test'))
        ..httpClientAdapter = FakeAdapter((o) async => jsonBody(_session, 200))
        ..interceptors.add(SafeLogInterceptor());
      await dio.post<dynamic>(
        '/auth/otp/verify',
        data: {'mobile': '9876543210', 'otp': '123456'},
        options: Options(headers: {'Authorization': 'Bearer secret-token'}),
      );
      final log = lines.join('\n');
      expect(log, contains('/auth/otp/verify'));
      for (final secret in [
        '123456',
        '9876543210',
        'secret-token',
        'acc-token',
      ]) {
        expect(log, isNot(contains(secret)));
      }
    });
  });
}
