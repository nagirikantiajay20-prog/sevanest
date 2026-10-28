import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/features/service_discovery/domain/budget.dart';
import 'package:sevanest_customer/features/service_discovery/domain/catalog.dart';

/// Market ranges (monthly part-time min/max, hourly min/max) per service, scaled per engagement.
const _base = {
  'cook': (6000, 10000, 100, 200),
  'maid': (4000, 7000, 80, 150),
  'driver': (7000, 11000, 150, 300),
  'babysitter': (8000, 13000, 150, 250),
  'elderly': (9000, 14000, 150, 300),
  'cleaner': (3000, 6000, 80, 150),
};

class GuidanceRepositoryMock implements GuidanceRepository {
  GuidanceRepositoryMock(this._state);
  final MockApiState Function() _state;

  static int _round(double v, int step) => (v / step).round() * step;

  @override
  Future<Guidance> guidance(GuidanceQuery q) => mockCall(_state(), () {
    final b = _base[q.serviceId] ?? _base['cook']!;
    final hourly = budgetPeriodFor(q.engagement) == BudgetPeriod.hourly;
    final scale = switch (q.engagement) {
      EngagementType.fullTime => 1.7,
      EngagementType.daily => 1.1,
      EngagementType.liveIn => 1.9,
      EngagementType.shift => 1.5,
      _ => 1.0,
    };
    return hourly
        ? Guidance(
            min: b.$3,
            max: b.$4,
            period: BudgetPeriod.hourly,
            city: q.city,
            basis: 'Based on recent bookings',
          )
        : Guidance(
            min: _round(b.$1 * scale, 500),
            max: _round(b.$2 * scale, 500),
            period: BudgetPeriod.monthly,
            city: q.city,
            basis: 'Based on recent bookings',
          );
  });
}
