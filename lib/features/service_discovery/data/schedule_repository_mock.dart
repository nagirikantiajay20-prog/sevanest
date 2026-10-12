import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/features/service_discovery/domain/schedule_repository.dart';
import 'package:sevanest_customer/features/service_discovery/domain/timing.dart';

class ScheduleRepositoryMock implements ScheduleRepository {
  ScheduleRepositoryMock(this._state);
  final MockApiState Function() _state;

  @override
  Future<ScheduleConfig> config() =>
      mockCall(_state(), () => ScheduleConfig.fallback);
}
