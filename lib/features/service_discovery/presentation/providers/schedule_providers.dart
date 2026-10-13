import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/features/service_discovery/data/guidance_repository_mock.dart';
import 'package:sevanest_customer/features/service_discovery/data/guidance_repository_remote.dart';
import 'package:sevanest_customer/features/service_discovery/data/schedule_repository_mock.dart';
import 'package:sevanest_customer/features/service_discovery/domain/budget.dart';
import 'package:sevanest_customer/features/service_discovery/domain/schedule_repository.dart';
import 'package:sevanest_customer/features/service_discovery/domain/timing.dart';

final scheduleRepositoryProvider = Provider<ScheduleRepository>(
  (ref) => ScheduleRepositoryMock(() => ref.read(mockApiProvider)),
);

/// Live: no guidance is published, so none is shown (never a made-up market price).
final guidanceRepositoryProvider = Provider<GuidanceRepository>((ref) {
  final live = ref.watch(mockApiProvider.select((s) => s.live));
  return live
      ? const GuidanceRepositoryRemote()
      : GuidanceRepositoryMock(() => ref.read(mockApiProvider));
});

/// Remote schedule rules for Timing and Start date. Re-fetches when the dev menu flips the mock.
final scheduleConfigProvider = FutureProvider.autoDispose<ScheduleConfig>((
  ref,
) {
  ref.watch(mockApiProvider);
  return ref.read(scheduleRepositoryProvider).config();
});

/// Price guidance for service + location + engagement. Keyed by the query, so changing any of
/// them fetches fresh guidance and an old range is never shown for the new choice.
final guidanceProvider = FutureProvider.autoDispose
    .family<Guidance, GuidanceQuery>((ref, query) {
      ref.watch(mockApiProvider);
      return ref.read(guidanceRepositoryProvider).guidance(query);
    });
