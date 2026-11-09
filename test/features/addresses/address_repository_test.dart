// REPOSITORY/API tests (mocked HTTP adapter, no network). Paths/methods/request fields come from the
// deployed Swagger; response bodies are UNVERIFIED shapes (the Swagger publishes no success schemas).
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/features/addresses/data/address_repository_remote.dart';
import 'package:sevanest_customer/features/addresses/domain/address.dart';

import '../../helpers/fakes.dart';

const _input = AddressInput(
  line: ' Flat 7B, Lake View ',
  area: 'Madhapur',
  city: 'Hyderabad',
  pincode: '500081',
  isDefault: true,
);

void main() {
  late List<RequestOptions> seen;
  late AddressRepositoryRemote repo;

  void respond(String body, int status) {
    seen = [];
    final dio = Dio(BaseOptions(baseUrl: 'https://x/api/v1'))
      ..httpClientAdapter = FakeAdapter((o) async {
        seen.add(o);
        return jsonBody(body, status);
      });
    repo = AddressRepositoryRemote(dio);
  }

  const one =
      '{"id":"a1","line":"Flat 7B","area":"Madhapur","city":"Hyderabad","pincode":"500081","latitude":null,"longitude":null,"isDefault":true}';

  test('ADDR-10 parse tolerates null lat/lng and missing fields', () async {
    respond('[$one,{"id":7,"line":"x"}]', 200);
    final list = await repo.list();
    expect(seen.single.method, 'GET');
    expect(seen.single.path, '/customers/me/addresses');
    expect(list.first.latitude, isNull);
    expect(list.first.isDefault, isTrue);
    expect(list.last.id, '7');
    expect(list.last.area, '');
    expect(list.last.isDefault, isFalse);
  });

  test(
    'list accepts a wrapped {items: []} body and skips id-less rows',
    () async {
      respond('{"items":[$one,{"line":"no id"}]}', 200);
      expect((await repo.list()).map((a) => a.id), ['a1']);
    },
  );

  test(
    'list: valid empty body -> empty list; unexpected body -> ServerFailure',
    () async {
      respond('[]', 200);
      expect(await repo.list(), isEmpty);
      respond('{"items":[]}', 200);
      expect(await repo.list(), isEmpty);
      // A broken contract must not read as "no addresses saved".
      respond('{"unexpected":true}', 200);
      await expectLater(repo.list(), throwsA(isA<ServerFailure>()));
    },
  );

  test(
    'create = POST with the address fields; unset label/line2/state go as null',
    () async {
      respond(one, 201);
      final a = await repo.create(_input);
      expect(seen.single.method, 'POST');
      expect(seen.single.path, '/customers/me/addresses');
      expect(seen.single.data, {
        'line': 'Flat 7B, Lake View',
        'area': 'Madhapur',
        'city': 'Hyderabad',
        'pincode': '500081',
        'label': null,
        'line2': null,
        'state': null,
        'isDefault': true,
      });
      expect(a.id, 'a1');
    },
  );

  test('update = PATCH {id} without isDefault', () async {
    respond(one, 200);
    await repo.update('a1', _input);
    expect(seen.single.method, 'PATCH');
    expect(seen.single.path, '/customers/me/addresses/a1');
    expect((seen.single.data as Map).containsKey('isDefault'), isFalse);
  });

  test('delete = DELETE {id} (204)', () async {
    respond('', 204);
    await repo.delete('a1');
    expect(seen.single.method, 'DELETE');
    expect(seen.single.path, '/customers/me/addresses/a1');
  });

  test('setDefault = PUT {id}/default', () async {
    respond(one, 200);
    await repo.setDefault('a1');
    expect(seen.single.method, 'PUT');
    expect(seen.single.path, '/customers/me/addresses/a1/default');
  });

  test('ids are URL-encoded', () async {
    respond('', 204);
    await repo.delete('a/../b');
    expect(seen.single.path, '/customers/me/addresses/a%2F..%2Fb');
  });

  test('create with an id-less success body fails closed', () async {
    respond('{"ok":true}', 201);
    await expectLater(repo.create(_input), throwsA(isA<UnknownFailure>()));
  });

  test(
    'serviceAreas = GET /service-areas?limit&city; skips unnamed rows',
    () async {
      respond(
        '{"items":[{"id":"s1","name":"Madhapur","city":"Hyderabad"},{"id":"s2"}]}',
        200,
      );
      final areas = await repo.serviceAreas(city: 'Hyderabad');
      expect(seen.single.path, '/service-areas');
      expect(seen.single.queryParameters, {'limit': 100, 'city': 'Hyderabad'});
      expect(areas.map((a) => a.name), ['Madhapur']);
    },
  );

  test(
    '401 -> Unauthorized, 403 -> Forbidden, 404 -> NotFound, 409 -> Conflict',
    () async {
      for (final (status, matcher) in <(int, Matcher)>[
        (401, isA<UnauthorizedFailure>()),
        (403, isA<ForbiddenFailure>()),
        (404, isA<NotFoundFailure>()),
        (409, isA<ConflictFailure>()),
      ]) {
        respond('{"code":"X","message":"m"}', status);
        await expectLater(repo.delete('a1'), throwsA(matcher));
      }
    },
  );

  test('400 field errors map to backend field names', () async {
    respond(
      '{"code":"VALIDATION_FAILED","message":"bad","details":[{"field":"pincode","messages":["pincode must be 6 digits"]}]}',
      400,
    );
    await expectLater(
      repo.create(_input),
      throwsA(
        isA<ValidationFailure>().having(
          (f) => f.fieldErrors['pincode'],
          'pincode',
          'pincode must be 6 digits',
        ),
      ),
    );
  });
}
