import 'package:dio/dio.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/network/guarded.dart';
import 'package:sevanest_customer/features/support/domain/support.dart';

/// `/support/*` and `/safety/*` of the deployed backend. Paging is `page` / `limit` with
/// `meta.total` (always present per the Swagger); the cursor is the next page number.
class SupportRepositoryRemote implements SupportRepository {
  SupportRepositoryRemote(this._dio);
  final Dio _dio;

  static const pageSize = 20;

  static Options _key(String k) => Options(headers: {'Idempotency-Key': k});

  String _path(String id, [String tail = '']) =>
      '/support/tickets/${Uri.encodeComponent(id)}$tail';

  /// Page number of [cursor] and the cursor after it (null on the last page).
  static (int, String?) _next(Object? body, String? cursor, int got) {
    final page = int.tryParse(cursor ?? '') ?? 1;
    final meta = body is Map ? body['meta'] : null;
    final total = meta is Map && meta['total'] is num
        ? (meta['total'] as num).toInt()
        : 0;
    return (page, page * pageSize < total ? '${page + 1}' : null);
  }

  @override
  Future<List<SupportCategory>> categories() async {
    final res = await guarded(() => _dio.get<dynamic>('/support/categories'));
    return [for (final m in listOf(res.data)) ?SupportCategory.fromJson(m)];
  }

  @override
  Future<Ticket> create({
    required String categoryId,
    required String description,
    String? bookingId,
    required String idempotencyKey,
  }) async {
    final res = await guarded(
      () => _dio.post<dynamic>(
        '/support/tickets',
        options: _key(idempotencyKey),
        data: {
          'categoryId': categoryId,
          'description': description.trim(),
          if (bookingId != null && bookingId.isNotEmpty) 'bookingId': bookingId,
        },
      ),
    );
    return Ticket.fromJson(res.data) ?? (throw const UnknownFailure());
  }

  @override
  Future<TicketPage> list({String? cursor}) async {
    final page = int.tryParse(cursor ?? '') ?? 1;
    final res = await guarded(
      () => _dio.get<dynamic>(
        '/support/tickets',
        queryParameters: {'page': page, 'limit': pageSize},
      ),
    );
    final (_, next) = _next(res.data, cursor, 0);
    return TicketPage([
      for (final m in listOf(res.data)) ?Ticket.fromJson(m),
    ], next);
  }

  @override
  Future<Ticket> get(String id) async {
    final res = await guarded(() => _dio.get<dynamic>(_path(id)));
    return Ticket.fromJson(res.data) ?? (throw const UnknownFailure());
  }

  @override
  Future<MessagePage> messages(String id, {String? cursor}) async {
    final page = int.tryParse(cursor ?? '') ?? 1;
    final res = await guarded(
      () => _dio.get<dynamic>(
        _path(id, '/messages'),
        queryParameters: {'page': page, 'limit': pageSize},
      ),
    );
    final (_, next) = _next(res.data, cursor, 0);
    return MessagePage([
      for (final m in listOf(res.data)) ?TicketMessage.fromJson(m),
    ], next);
  }

  @override
  Future<TicketMessage> post(
    String id,
    String body, {
    required String idempotencyKey,
  }) async {
    final res = await guarded(
      () => _dio.post<dynamic>(
        _path(id, '/messages'),
        options: _key(idempotencyKey),
        data: {'body': body.trim()},
      ),
    );
    return TicketMessage.fromJson(res.data) ?? (throw const UnknownFailure());
  }
}

class SafetyRepositoryRemote implements SafetyRepository {
  SafetyRepositoryRemote(this._dio);
  final Dio _dio;

  static Options _key(String k) => Options(headers: {'Idempotency-Key': k});

  /// The reference is the worker id, or (customers) a booking they are a party to.
  static Map<String, Object?> _who(String? workerId, String? bookingId) => {
    if (workerId != null && workerId.isNotEmpty) 'workerId': workerId,
    if ((workerId == null || workerId.isEmpty) &&
        bookingId != null &&
        bookingId.isNotEmpty)
      'bookingId': bookingId,
  };

  @override
  Future<void> report({
    String? workerId,
    String? bookingId,
    required ReportReason reason,
    String? note,
    bool alsoBlock = false,
    required String idempotencyKey,
  }) async {
    await guarded(
      () => _dio.post<dynamic>(
        '/safety/reports',
        options: _key(idempotencyKey),
        data: {
          ..._who(workerId, bookingId),
          'reasonCode': reason.code,
          if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
          if (alsoBlock) 'alsoBlock': true,
        },
      ),
    );
  }

  @override
  Future<WorkerBlock> block({
    String? workerId,
    String? bookingId,
    required String idempotencyKey,
  }) async {
    final res = await guarded(
      () => _dio.post<dynamic>(
        '/safety/blocks',
        data: _who(workerId, bookingId),
        options: _key(idempotencyKey),
      ),
    );
    return WorkerBlock.fromJson(res.data) ?? WorkerBlock(id: workerId ?? '');
  }

  @override
  Future<List<WorkerBlock>> blocks() async {
    final res = await guarded(() => _dio.get<dynamic>('/safety/blocks'));
    return [for (final m in listOf(res.data)) ?WorkerBlock.fromJson(m)];
  }

  @override
  Future<void> unblock(String id) async {
    await guarded(
      () => _dio.delete<dynamic>('/safety/blocks/${Uri.encodeComponent(id)}'),
    );
  }
}
