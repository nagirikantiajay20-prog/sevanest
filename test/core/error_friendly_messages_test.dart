import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/localization/failure_message.dart';
import 'package:sevanest_customer/core/network/error_mapper.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations_en.dart';

final _l10n = AppLocalizationsEn();
final _req = RequestOptions(path: '/x');

DioException _type(DioExceptionType t, [Object? error]) =>
    DioException(requestOptions: _req, type: t, error: error);

DioException _http(int status, Object? body) => DioException(
  requestOptions: _req,
  type: DioExceptionType.badResponse,
  response: Response(requestOptions: _req, statusCode: status, data: body),
);

String _msg(DioException e) => failureMessage(_l10n, mapDioError(e));

void main() {
  test('all three timeouts -> friendly timeout text, not "offline"', () {
    for (final t in [
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
    ]) {
      expect(_msg(_type(t)), _l10n.errorTimeout);
    }
    expect(_msg(_http(408, null)), _l10n.errorTimeout);
  });

  test('offline (connection error / SocketException) -> network text', () {
    expect(_msg(_type(DioExceptionType.connectionError)), _l10n.errorNetwork);
    expect(
      _msg(_type(DioExceptionType.unknown, const SocketException('x'))),
      _l10n.errorNetwork,
    );
  });

  test('invalid JSON -> server text, parser text never shown', () {
    final m = _msg(
      _type(DioExceptionType.unknown, const FormatException('Unexpected char')),
    );
    expect(m, _l10n.errorServer);
    expect(m, isNot(contains('Unexpected')));
  });

  test('5xx and empty / non-map bodies map to safe text', () {
    for (final s in [500, 502, 503]) {
      expect(_msg(_http(s, '<html>Bad Gateway</html>')), _l10n.errorServer);
      expect(_msg(_http(s, null)), _l10n.errorServer);
    }
    expect(_msg(_http(418, [1, 2])), _l10n.errorGeneric);
  });

  test('401/403/404 map to their friendly text', () {
    expect(_msg(_http(401, {})), _l10n.errorSessionExpired);
    expect(_msg(_http(403, {})), _l10n.errorForbidden);
    expect(_msg(_http(404, {})), _l10n.errorNotFound);
  });

  test('raw technical backend messages are never shown', () {
    for (final s in [400, 422]) {
      expect(
        _msg(_http(s, {'message': 'PrismaClientKnownRequestError at x.dart'})),
        _l10n.errorGeneric,
      );
    }
    // Non-string message (array) is tolerated.
    expect(
      _msg(
        _http(422, {
          'message': ['a', 'b'],
        }),
      ),
      _l10n.errorGeneric,
    );
  });

  test('readable validation message is kept; 409 codes map to guidance', () {
    expect(
      _msg(_http(422, {'message': 'Pick a time after 9 AM.'})),
      'Pick a time after 9 AM.',
    );
    expect(
      _msg(_http(409, {'code': 'DUPLICATE_BOOKING', 'message': 'db_dup'})),
      _l10n.errorDuplicateBooking,
    );
    expect(
      _msg(_http(409, {'code': 'WORKER_UNAVAILABLE'})),
      _l10n.errorWorkerUnavailable,
    );
    expect(
      _msg(_http(409, {'code': 'INVALID_TRANSITION', 'message': 'ERR_STATE'})),
      _l10n.errorConflictGeneric,
    );
  });

  test('field errors survive mapping', () {
    final f = mapDioError(
      _http(422, {
        'code': 'VALIDATION',
        'details': [
          {
            'field': 'email',
            'messages': ['must be an email'],
          },
        ],
      }),
    );
    expect((f as ValidationFailure).fieldErrors['email'], isNotNull);
  });

  test('unknown objects fall back to generic text', () {
    expect(failureMessage(_l10n, StateError('boom')), _l10n.errorGeneric);
    expect(
      failureMessage(_l10n, const UnknownFailure('x')),
      _l10n.errorGeneric,
    );
  });
}
