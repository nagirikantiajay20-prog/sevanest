import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/network/get_retry_interceptor.dart';
import 'package:sevanest_customer/core/network/guarded.dart';

/// Replies from a script: an int = HTTP status, a DioExceptionType = transport failure.
class _Script implements HttpClientAdapter {
  _Script(this.steps, {this.headers = const {}});
  final List<Object> steps;
  final Map<String, List<String>> headers;
  final calls = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<List<int>>? body,
    Future<void>? cancel,
  ) async {
    calls.add(o.method);
    final step = steps[(calls.length - 1).clamp(0, steps.length - 1)];
    if (step is DioExceptionType) {
      throw DioException(requestOptions: o, type: step);
    }
    return ResponseBody.fromString(
      '{}',
      step as int,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        ...headers,
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

({Dio dio, _Script script, List<Duration> waits}) _make(
  List<Object> steps, {
  Map<String, List<String>> headers = const {},
}) {
  final script = _Script(steps, headers: headers);
  final waits = <Duration>[];
  final dio = Dio(BaseOptions(baseUrl: 'https://x.test'))
    ..httpClientAdapter = script;
  dio.interceptors.add(
    GetRetryInterceptor(
      dio: dio,
      delay: (d) async => waits.add(d),
      random: () => 0, // no jitter -> exact backoff
    ),
  );
  return (dio: dio, script: script, waits: waits);
}

void main() {
  group('GetRetryInterceptor', () {
    test(
      'GET retries timeouts with exponential backoff, then succeeds',
      () async {
        final t = _make([
          DioExceptionType.receiveTimeout,
          DioExceptionType.connectionError,
          200,
        ]);
        final res = await t.dio.get<dynamic>('/a');
        expect(res.statusCode, 200);
        expect(t.script.calls.length, 3);
        expect(t.waits, [
          const Duration(milliseconds: 400),
          const Duration(milliseconds: 800),
        ]);
      },
    );

    test('gives up after maxRetries (2 retries = 3 calls)', () async {
      final t = _make([503]);
      await expectLater(t.dio.get<dynamic>('/a'), throwsA(isA<DioException>()));
      expect(t.script.calls.length, 3);
    });

    for (final method in ['POST', 'PUT', 'PATCH', 'DELETE']) {
      test('$method is NEVER retried', () async {
        final t = _make([DioExceptionType.receiveTimeout]);
        await expectLater(
          t.dio.request<dynamic>('/a', options: Options(method: method)),
          throwsA(isA<DioException>()),
        );
        expect(t.script.calls.length, 1);
        expect(t.waits, isEmpty);
      });
    }

    for (final status in [400, 401, 403, 404, 409, 422, 500]) {
      test('GET $status is not retried', () async {
        final t = _make([status]);
        await expectLater(
          t.dio.get<dynamic>('/a'),
          throwsA(isA<DioException>()),
        );
        expect(t.script.calls.length, 1);
      });
    }

    test('429 with a short Retry-After waits that long and retries', () async {
      final t = _make(
        [429, 200],
        headers: {
          'retry-after': ['2'],
        },
      );
      final res = await t.dio.get<dynamic>('/a');
      expect(res.statusCode, 200);
      expect(t.waits, [const Duration(seconds: 2)]);
    });

    test('429 with a long or missing Retry-After is not retried', () async {
      final long = _make(
        [429],
        headers: {
          'retry-after': ['120'],
        },
      );
      await expectLater(
        long.dio.get<dynamic>('/a'),
        throwsA(isA<DioException>()),
      );
      expect(long.script.calls.length, 1);
      final none = _make([429]);
      await expectLater(
        none.dio.get<dynamic>('/a'),
        throwsA(isA<DioException>()),
      );
      expect(none.script.calls.length, 1);
    });

    test('a cancelled GET is not sent or retried', () async {
      final t = _make([200]);
      final token = CancelToken()..cancel();
      await expectLater(
        t.dio.get<dynamic>('/a', cancelToken: token),
        throwsA(
          isA<DioException>().having(
            (e) => e.type,
            'type',
            DioExceptionType.cancel,
          ),
        ),
      );
      expect(t.script.calls, isEmpty);
    });
  });

  group('listOf', () {
    test('valid empty shapes stay empty lists', () {
      expect(listOf(<Object>[]), isEmpty);
      expect(listOf({'items': <Object>[]}), isEmpty);
      expect(listOf({'data': <Object>[]}), isEmpty);
    });

    test('valid shapes keep working; non-object rows are skipped', () {
      expect(
        listOf([
          {'id': 1},
          'junk',
          3,
        ]),
        [
          {'id': 1},
        ],
      );
      expect(
        listOf({
          'items': [
            {'id': 2},
          ],
          'meta': {'total': 1},
        }),
        [
          {'id': 2},
        ],
      );
      expect(
        listOf({
          'data': [
            {'id': 3},
          ],
        }),
        [
          {'id': 3},
        ],
      );
    });

    for (final bad in <Object?>[
      null,
      'oops',
      42,
      <String, Object?>{},
      {'items': 'x'},
      {
        'items': {'a': 1},
      },
      {'other': <Object>[]},
    ]) {
      test('malformed body $bad throws ServerFailure, not an empty list', () {
        expect(() => listOf(bad), throwsA(isA<ServerFailure>()));
      });
    }
  });
}
