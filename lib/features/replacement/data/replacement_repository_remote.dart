import 'package:dio/dio.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/network/guarded.dart';
import 'package:sevanest_customer/features/replacement/domain/replacement.dart';

class ReplacementRepositoryRemote implements ReplacementRepository {
  ReplacementRepositoryRemote(this._dio);
  final Dio _dio;

  static const pageSize = 20;

  static Options _key(String k) => Options(headers: {'Idempotency-Key': k});

  String _path(String id, [String tail = '']) =>
      '/replacement-requests/${Uri.encodeComponent(id)}$tail';

  Replacement _one(Response<dynamic> res) =>
      Replacement.fromJson(res.data) ?? (throw const UnknownFailure());

  @override
  Future<Replacement> create({
    required String bookingId,
    required String reason,
    String? notes,
    required String idempotencyKey,
  }) async => _one(
    await guarded(
      () => _dio.post<dynamic>(
        '/replacement-requests',
        options: _key(idempotencyKey),
        data: {
          'bookingId': bookingId,
          'reason': reason.trim(),
          if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        },
      ),
    ),
  );

  @override
  Future<ReplacementPage> list({String? cursor}) async {
    final page = int.tryParse(cursor ?? '') ?? 1;
    final res = await guarded(
      () => _dio.get<dynamic>(
        '/replacement-requests',
        queryParameters: {'page': page, 'limit': pageSize},
      ),
    );
    final body = res.data;
    final meta = body is Map ? body['meta'] : null;
    final total = meta is Map && meta['total'] is num
        ? (meta['total'] as num).toInt()
        : 0;
    return ReplacementPage([
      for (final m in listOf(body)) ?Replacement.fromJson(m),
    ], page * pageSize < total ? '${page + 1}' : null);
  }

  @override
  Future<Replacement> get(String id) async =>
      _one(await guarded(() => _dio.get<dynamic>(_path(id))));

  @override
  Future<Replacement> cancel(
    String id, {
    required String idempotencyKey,
  }) async => _one(
    await guarded(
      () => _dio.post<dynamic>(
        _path(id, '/cancel'),
        options: _key(idempotencyKey),
      ),
    ),
  );

  @override
  Future<Replacement> select(
    String id,
    String workerId, {
    required String idempotencyKey,
  }) async => _one(
    await guarded(
      () => _dio.post<dynamic>(
        _path(id, '/select'),
        options: _key(idempotencyKey),
        data: {'workerId': workerId},
      ),
    ),
  );

  @override
  Future<List<ChainEntry>> chain(String bookingId) async {
    final res = await guarded(
      () => _dio.get<dynamic>(
        '/bookings/${Uri.encodeComponent(bookingId)}/replacement-chain',
      ),
    );
    return [for (final m in listOf(res.data)) ?ChainEntry.fromJson(m)];
  }
}
