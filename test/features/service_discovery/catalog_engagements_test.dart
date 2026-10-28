import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/features/service_discovery/data/catalog_repository_mock.dart';
import 'package:sevanest_customer/features/service_discovery/domain/budget.dart';
import 'package:sevanest_customer/features/service_discovery/domain/catalog.dart';

void main() {
  test('mock catalogue follows the client category table', () {
    final byId = {
      for (final c in CatalogRepositoryMock.categories_)
        c.id: [for (final e in c.engagements) e.type],
    };
    expect(byId.keys, [
      'maid',
      'driver',
      'cook',
      'babysitter',
      'elderly',
      'cleaner',
    ]);
    expect(byId['maid'], [
      EngagementType.partTime,
      EngagementType.fullTime,
      EngagementType.liveIn,
    ]);
    expect(byId['driver'], [
      EngagementType.hourly,
      EngagementType.daily,
      EngagementType.monthly,
    ]);
    expect(byId['cook'], [EngagementType.partTime, EngagementType.monthly]);
    expect(byId['elderly'], [EngagementType.shift, EngagementType.fullTime]);
    expect(byId['cleaner'], [EngagementType.oneTime, EngagementType.hourly]);
  });

  test('engagement codes round-trip the backend vocabulary', () {
    for (final t in EngagementType.values) {
      expect(EngagementType.fromCode(t.code), t);
    }
    expect(EngagementType.fromCode('MONTHLY'), EngagementType.monthly);
    expect(EngagementType.fromCode('WEEKLY'), isNull);
  });

  test('one-time is priced per hour', () {
    expect(budgetPeriodFor(EngagementType.oneTime), BudgetPeriod.hourly);
    expect(budgetPeriodFor(EngagementType.shift), BudgetPeriod.monthly);
  });
}
