// UNIT tests: mock API modes (loading / slow / error / offline / empty) and the schedule + guidance mocks.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/features/service_discovery/data/guidance_repository_mock.dart';
import 'package:sevanest_customer/features/service_discovery/data/schedule_repository_mock.dart';
import 'package:sevanest_customer/features/service_discovery/domain/budget.dart';
import 'package:sevanest_customer/features/service_discovery/domain/catalog.dart';

MockApiState _s(MockMode m) => MockApiState(mode: m);

void main() {
  group('mockCall', () {
    test('normal returns the value after a short latency', () async {
      expect(await mockCall(_s(MockMode.normal), () => 7), 7);
      expect(_s(MockMode.normal).latency, lessThan(const Duration(seconds: 1)));
    });

    test('slow keeps the same answer but with a long latency', () {
      expect(_s(MockMode.slow).latency, const Duration(seconds: 4));
    });

    test('error -> server failure, offline -> network failure', () async {
      await expectLater(
        mockCall(_s(MockMode.error), () => 1),
        throwsA(isA<ServerFailure>()),
      );
      await expectLater(
        mockCall(_s(MockMode.offline), () => 1),
        throwsA(isA<NetworkFailure>()),
      );
    });

    test('loading never answers', () async {
      var done = false;
      unawaited(
        mockCall(_s(MockMode.loading), () => 1).then((_) => done = true),
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(done, isFalse);
    });
  });

  group('ScheduleRepositoryMock', () {
    test('serves the rules, honours the toggle', () async {
      var s = _s(MockMode.normal);
      final r = ScheduleRepositoryMock(() => s);
      final c = await r.config();
      expect(c.maxLeadDays, 60);
      expect(c.minLeadDays, 1);
      s = _s(MockMode.error);
      await expectLater(r.config(), throwsA(isA<ServerFailure>()));
    });
  });

  group('GuidanceRepositoryMock', () {
    GuidanceQuery q(String service, EngagementType e) => GuidanceQuery(
      serviceId: service,
      engagement: e,
      area: 'Madhapur',
      city: 'Hyderabad',
    );
    final r = GuidanceRepositoryMock(() => _s(MockMode.normal));

    test('part-time cook matches the design range', () async {
      final g = await r.guidance(q('cook', EngagementType.partTime));
      expect((g.min, g.max, g.period), (6000, 10000, BudgetPeriod.monthly));
      expect(g.city, 'Hyderabad');
    });

    test('hourly cook is per hour', () async {
      final g = await r.guidance(q('cook', EngagementType.hourly));
      expect((g.min, g.max, g.period), (100, 200, BudgetPeriod.hourly));
    });

    test('full-time costs more than part-time; live-in more again', () async {
      final pt = await r.guidance(q('maid', EngagementType.partTime));
      final ft = await r.guidance(q('maid', EngagementType.fullTime));
      final li = await r.guidance(q('maid', EngagementType.liveIn));
      expect(ft.min, greaterThan(pt.min));
      expect(li.min, greaterThan(ft.min));
      expect(ft.min % 500, 0);
    });

    test('query equality is by value (provider family key)', () {
      expect(
        q('cook', EngagementType.daily) == q('cook', EngagementType.daily),
        isTrue,
      );
      expect(
        q('cook', EngagementType.daily) == q('maid', EngagementType.daily),
        isFalse,
      );
    });

    test('error mode fails the guidance only', () async {
      final bad = GuidanceRepositoryMock(() => _s(MockMode.error));
      await expectLater(
        bad.guidance(q('cook', EngagementType.daily)),
        throwsA(isA<ServerFailure>()),
      );
    });
  });
}
