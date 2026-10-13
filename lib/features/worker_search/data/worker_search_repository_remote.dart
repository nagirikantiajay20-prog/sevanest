import 'package:dio/dio.dart';
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
          'category': query.category,
          'areaId': query.areaId,
          if (query.engagement != null)
            'engagement': engagementCode(query.engagement!),
          if (query.filters.availability != null) ...{
            'availableFrom': query.filters.availability!.from,
            'availableTo': query.filters.availability!.to,
          },
          if (query.filters.language != null)
            'language': query.filters.language,
          if (query.filters.minExperienceMonths != null)
            'minExperienceMonths': query.filters.minExperienceMonths,
        },
      ),
    );
    final body = res.data;
    final items = [for (final m in listOf(body)) ?WorkerSummary.fromJson(m)];
    final meta = body is Map ? body['meta'] : null;
    final total = meta is Map && meta['total'] is num
        ? (meta['total'] as num).toInt()
        : 0;
    return WorkerPage(items, page * pageSize < total ? '${page + 1}' : null);
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

String engagementCode(EngagementType t) => switch (t) {
  EngagementType.fullTime => 'FULL_TIME',
  EngagementType.partTime => 'PART_TIME',
  EngagementType.daily => 'DAILY',
  EngagementType.hourly => 'HOURLY',
  EngagementType.liveIn => 'LIVE_IN',
};
