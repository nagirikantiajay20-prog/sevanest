import 'package:dio/dio.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/network/guarded.dart';
import 'package:sevanest_customer/features/service_discovery/domain/budget.dart';
import 'package:sevanest_customer/features/worker_search/data/worker_search_repository_remote.dart';

/// `GET /pricing/guidance?category&engagement&areaId` -> `{minMinor, maxMinor, period, basis}` in
/// paise. It answers 404 `PRICING_GUIDANCE_NOT_FOUND` until an admin enters price bands, and the
/// Budget step then hides the card (the customer types a range): never a made-up market price.
/// Only HOUR and MONTH bands can be shown, so a DAY / ONE_TIME band counts as none.
class GuidanceRepositoryRemote implements GuidanceRepository {
  const GuidanceRepositoryRemote(this._dio);
  final Dio _dio;

  @override
  Future<Guidance> guidance(GuidanceQuery q) async {
    final res = await guarded(
      () => _dio.get<dynamic>(
        '/pricing/guidance',
        queryParameters: {
          'category': q.serviceId,
          'engagement': engagementCode(q.engagement),
          if (q.areaId != null) 'areaId': q.areaId,
        },
      ),
    );
    final m = res.data;
    if (m is! Map || m['minMinor'] is! num || m['maxMinor'] is! num) {
      throw const NotFoundFailure();
    }
    final period = switch (m['period']) {
      'HOUR' => BudgetPeriod.hourly,
      'MONTH' => BudgetPeriod.monthly,
      _ => throw const NotFoundFailure(),
    };
    return Guidance(
      min: ((m['minMinor'] as num) / 100).round(),
      max: ((m['maxMinor'] as num) / 100).round(),
      period: period,
      city: q.city,
      basis: m['basis'] is String ? m['basis'] as String : '',
    );
  }
}
