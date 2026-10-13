import 'package:dio/dio.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/network/guarded.dart';
import 'package:sevanest_customer/features/interview_trial/domain/interview.dart';

/// ASSUMED contract (docs/05): the deployed Swagger of 2026-10-12 has no interview endpoints, so
/// until the backend publishes them every call here answers 404 and the screens show their error
/// state. Request it: docs/BACKEND_REQUESTS.md item 7.
class InterviewRepositoryRemote implements InterviewRepository {
  InterviewRepositoryRemote(this._dio);
  final Dio _dio;

  static const pageSize = 20;

  String _item(String id, [String suffix = '']) =>
      '/interviews/${Uri.encodeComponent(id)}$suffix';

  static String _day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Interview _parse(Object? body) =>
      Interview.fromJson(body is Map ? (body['data'] ?? body) : body) ??
      (throw const UnknownFailure());

  @override
  Future<Interview> create(
    InterviewRequest r, {
    required String idempotencyKey,
  }) async {
    final res = await guarded(
      () => _dio.post<dynamic>(
        '/interviews',
        options: Options(headers: {'Idempotency-Key': idempotencyKey}),
        data: {
          'workerId': r.workerId,
          'type': r.type.name,
          'date': _day(r.date),
          'slot': r.slot,
          if (r.note != null && r.note!.isNotEmpty) 'note': r.note,
          'requirement': r.requirement.toJson(),
        },
      ),
    );
    return _parse(res.data);
  }

  @override
  Future<Interview> reschedule(
    String id,
    DateTime date,
    String slot, {
    required String idempotencyKey,
  }) async {
    await guarded(
      () => _dio.post<dynamic>(
        _item(id, '/reschedule'),
        options: Options(headers: {'Idempotency-Key': idempotencyKey}),
        data: {'date': _day(date), 'slot': slot},
      ),
    );
    return get(id);
  }

  @override
  Future<InterviewPage> list({String? cursor}) async {
    final page = int.tryParse(cursor ?? '') ?? 1;
    final res = await guarded(
      () => _dio.get<dynamic>(
        '/interviews',
        queryParameters: {'page': page, 'limit': pageSize},
      ),
    );
    final body = res.data;
    final meta = body is Map ? body['meta'] : null;
    final total = meta is Map && meta['total'] is num
        ? (meta['total'] as num).toInt()
        : 0;
    return InterviewPage([
      for (final m in listOf(body)) ?Interview.fromJson(m),
    ], page * pageSize < total ? '${page + 1}' : null);
  }

  @override
  Future<Interview> get(String id, {CancelToken? cancel}) async {
    final res = await guarded(
      () => _dio.get<dynamic>(_item(id), cancelToken: cancel),
    );
    return _parse(res.data);
  }

  @override
  Future<Interview> cancel(String id, {String? reason}) async {
    await guarded(
      () => _dio.post<dynamic>(_item(id, '/cancel'), data: {'reason': ?reason}),
    );
    return get(id);
  }

  @override
  Future<Interview> decline(String id) async {
    await guarded(
      () => _dio.post<dynamic>(
        _item(id, '/decision'),
        data: {'decision': 'decline'},
      ),
    );
    return get(id);
  }

  @override
  Future<List<InterviewSlot>> slots(String workerId, DateTime date) async {
    final res = await guarded(
      () => _dio.get<dynamic>(
        '/workers/${Uri.encodeComponent(workerId)}/slots',
        queryParameters: {'date': _day(date)},
      ),
    );
    final body = res.data;
    final raw = body is Map ? (body['data'] ?? body['slots']) : body;
    return [
      if (raw is List)
        for (final s in raw)
          if (s is String && parseSlot(s) != null)
            InterviewSlot(s)
          else if (s is Map && parseSlot('${s['id'] ?? s['start']}') != null)
            InterviewSlot('${s['id'] ?? s['start']}'),
    ];
  }
}
