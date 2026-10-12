import 'package:sevanest_customer/features/service_discovery/domain/timing.dart';

/// `GET /catalog/time-slots` (docs/05): window hours, minimum durations, start-date lead times.
abstract interface class ScheduleRepository {
  Future<ScheduleConfig> config();
}
