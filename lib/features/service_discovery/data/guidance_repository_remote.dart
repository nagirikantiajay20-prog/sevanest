import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/features/service_discovery/domain/budget.dart';

/// The backend publishes no price guidance yet (OPEN_QUESTIONS), so there is none to show. A
/// not-found answer hides the guidance card; the customer types their own range. Never invent a
/// market price here.
class GuidanceRepositoryRemote implements GuidanceRepository {
  const GuidanceRepositoryRemote();

  @override
  Future<Guidance> guidance(GuidanceQuery query) async =>
      throw const NotFoundFailure();
}
