// REPOSITORY/API tests (mocked HTTP adapter, no network): the profile request shapes follow the
// deployed Swagger (`/customers/me`, PATCH for updates); response bodies are UNVERIFIED shapes.
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/features/customer_profile/data/customer_profile_repository_remote.dart';

import '../../helpers/fakes.dart';

void main() {
  late List<RequestOptions> seen;
  late CustomerProfileRepositoryRemote repo;

  void respond(String body, int status) {
    seen = [];
    final dio = Dio(BaseOptions(baseUrl: 'https://x/api/v1'))
      ..httpClientAdapter = FakeAdapter((o) async {
        seen.add(o);
        return jsonBody(body, status);
      });
    repo = CustomerProfileRepositoryRemote(dio);
  }

  test('GET /customers/me parses the profile', () async {
    respond(
      '{"name":"Asha Rao","email":"asha@example.com","preferredLanguage":"en","mobile":"9876543210","verificationStatus":"PENDING"}',
      200,
    );
    final p = await repo.get();
    expect(seen.single.method, 'GET');
    expect(seen.single.path, '/customers/me');
    expect(p.name, 'Asha Rao');
    expect(p.mobile, '9876543210');
    expect(p.verificationStatus, 'PENDING');
  });

  test('missing / null optional fields never throw', () async {
    respond('{"name":"Asha Rao","email":null}', 200);
    final p = await repo.get();
    expect(p.email, '');
    expect(p.preferredLanguage, 'en');
    expect(p.mobile, isNull);
    expect(p.verificationStatus, isNull);
  });

  test(
    'create = POST /customers/me with the three DTO fields, trimmed',
    () async {
      respond('{"id":"c1"}', 201);
      final p = await repo.create(
        name: '  Asha Rao ',
        email: ' asha@example.com ',
        preferredLanguage: 'en',
      );
      expect(seen.single.method, 'POST');
      expect(seen.single.path, '/customers/me');
      expect(seen.single.data, {
        'name': 'Asha Rao',
        'email': 'asha@example.com',
        'preferredLanguage': 'en',
      });
      // Body without profile fields -> what we sent is kept.
      expect(p.name, 'Asha Rao');
    },
  );

  test('update = PATCH /customers/me', () async {
    respond(
      '{"name":"New Name","email":"a@b.co","preferredLanguage":"en"}',
      200,
    );
    final p = await repo.update(
      name: 'New Name',
      email: 'a@b.co',
      preferredLanguage: 'en',
    );
    expect(seen.single.method, 'PATCH');
    expect(seen.single.path, '/customers/me');
    expect(p.name, 'New Name');
  });

  test('404 CUSTOMER_PROFILE_NOT_FOUND -> NotFoundFailure', () async {
    respond('{"code":"CUSTOMER_PROFILE_NOT_FOUND","message":"nope"}', 404);
    await expectLater(repo.get(), throwsA(isA<NotFoundFailure>()));
  });

  test('401 -> UnauthorizedFailure', () async {
    respond('{"code":"UNAUTHORIZED","message":"no"}', 401);
    await expectLater(repo.get(), throwsA(isA<UnauthorizedFailure>()));
  });

  test('409 on create (profile exists) -> ConflictFailure', () async {
    respond('{"code":"CUSTOMER_PROFILE_EXISTS","message":"exists"}', 409);
    await expectLater(
      repo.create(name: 'Asha', email: 'a@b.co', preferredLanguage: 'en'),
      throwsA(isA<ConflictFailure>()),
    );
  });

  test('400 details[] -> field errors keyed by backend field names', () async {
    respond(
      jsonEncode({
        'code': 'VALIDATION_FAILED',
        'message': 'bad',
        'details': [
          {
            'field': 'email',
            'messages': ['email must be an email'],
          },
        ],
      }),
      400,
    );
    await expectLater(
      repo.create(name: 'Asha', email: 'x', preferredLanguage: 'en'),
      throwsA(
        isA<ValidationFailure>().having(
          (f) => f.fieldErrors['email'],
          'email',
          'email must be an email',
        ),
      ),
    );
  });

  test('429 -> RateLimitedFailure; 500 -> ServerFailure', () async {
    respond('{"code":"RATE_LIMITED","message":"slow"}', 429);
    await expectLater(repo.get(), throwsA(isA<RateLimitedFailure>()));
    respond('{"code":"INTERNAL","message":"boom"}', 500);
    await expectLater(repo.get(), throwsA(isA<ServerFailure>()));
  });

  test('connection error -> NetworkFailure', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://x/api/v1'))
      ..httpClientAdapter = FakeAdapter(
        (o) async => throw DioException.connectionError(
          requestOptions: o,
          reason: 'offline',
        ),
      );
    await expectLater(
      CustomerProfileRepositoryRemote(dio).get(),
      throwsA(isA<NetworkFailure>()),
    );
  });
}
