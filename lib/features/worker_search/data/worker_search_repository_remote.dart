import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/network/guarded.dart';
import 'package:sevanest_customer/features/service_discovery/domain/catalog.dart';
import 'package:sevanest_customer/features/worker_search/domain/worker_search.dart';

/// `GET /search/workers` (Swagger). The deployed backend pages by number with `meta.total`, so the
/// cursor handed to `PagedState` is the next page number.
class WorkerSearchRepositoryRemote implements WorkerSearchRepository {
  WorkerSearchRepositoryRemote(this._dio);
  final Dio _dio;

  static const pageSize = 20;

  @override
  Future<WorkerPage> search(
    WorkerQuery query, {
    String? cursor,
    CancelToken? cancel,
  }) async {
    final page = int.tryParse(cursor ?? '') ?? 1;
    final res = await guarded(
      () => _dio.get<dynamic>(
        '/search/workers',
        cancelToken: cancel,
        queryParameters: {
          'page': page,
          'limit': pageSize,
          ..._params(query),
          if (query.filters.sort?.code != null)
            'sort': query.filters.sort!.code,
        },
      ),
    );
    final body = res.data;
    final raw = listOf(body);
    final items = [for (final m in raw) ?WorkerSummary.fromJson(m)];
    if (kDebugMode) {
      // Debug builds only; no tokens or personal data (worker cards are anonymous).
      debugPrint(
        '[search] ${res.requestOptions.uri} -> ${res.statusCode} '
        'raw=${raw.length} parsed=${items.length} meta=${body is Map ? body['meta'] : null}',
      );
    }
    final meta = body is Map ? body['meta'] : null;
    final total = meta is Map && meta['total'] is num
        ? (meta['total'] as num).toInt()
        : 0;
    return WorkerPage(items, page * pageSize < total ? '${page + 1}' : null);
  }

  /// `GET /search/workers/count`: the search's filters, answers `{total}` (equals the search's
  /// `meta.total`; page, limit and sort are ignored).
  @override
  Future<int> count(WorkerQuery query, {CancelToken? cancel}) async {
    final res = await guarded(
      () => _dio.get<dynamic>(
        '/search/workers/count',
        cancelToken: cancel,
        queryParameters: _params(query),
      ),
    );
    final body = res.data;
    final total = body is Map ? body['total'] : null;
    return total is num ? total.toInt() : throw const NotFoundFailure();
  }

  /// `GET /search/workers/{id}`: same allow-listed card; 404 `WORKER_NOT_FOUND` also covers a
  /// worker who is no longer visible.
  @override
  Future<WorkerSummary> detail(String id, {CancelToken? cancel}) async {
    final res = await guarded(
      () => _dio.get<dynamic>(
        '/search/workers/${Uri.encodeComponent(id)}',
        cancelToken: cancel,
      ),
    );
    return WorkerSummary.fromJson(res.data) ?? (throw const NotFoundFailure());
  }
}

/// The requirement and filters shared by the search and its count.
Map<String, Object?> _params(WorkerQuery query) => {
  'category': query.category,
  'areaId': query.areaId,
  if (query.engagement != null) 'engagement': engagementCode(query.engagement!),
  if (query.filters.availability != null) ...{
    'availableFrom': query.filters.availability!.from,
    'availableTo': query.filters.availability!.to,
  },
  if (query.filters.language != null) 'language': query.filters.language,
  if (query.filters.minExperienceMonths != null)
    'minExperienceMonths': query.filters.minExperienceMonths,
  if (query.filters.minRating != null) 'minRating': query.filters.minRating,
  if (query.startDate != null) 'startDate': _day(query.startDate!),
};

String _day(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String engagementCode(EngagementType t) => t.code;
