import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/core/network/dio_provider.dart';
import 'package:sevanest_customer/core/services/clock.dart';
import 'package:sevanest_customer/features/addresses/domain/address.dart';
import 'package:sevanest_customer/features/addresses/presentation/providers/address_providers.dart';
import 'package:sevanest_customer/features/booking/presentation/providers/booking_providers.dart';
import 'package:sevanest_customer/features/interview_trial/data/interview_repository_over_bookings.dart';
import 'package:sevanest_customer/features/interview_trial/data/interview_repository_remote.dart';
import 'package:sevanest_customer/features/interview_trial/domain/interview.dart';
import 'package:sevanest_customer/features/service_discovery/domain/requirement_draft.dart';
import 'package:sevanest_customer/features/worker_search/presentation/providers/worker_search_providers.dart';
import 'package:sevanest_customer/shared/models/paged_state.dart';

/// Live `/interviews` in stg / prod (and in dev when switched on); in dev's mock mode a view over
/// the seeded booking state machine.
final interviewRepositoryProvider = Provider<InterviewRepository>((ref) {
  Future<String> areaIdFor(RequirementDraft draft) async {
    final name = draft.address?.area;
    if (name == null) throw const ValidationFailure('Address is missing');
    try {
      final areas = await ref.read(serviceAreasProvider.future);
      return serviceAreaIdFor(areas, name) ?? name;
    } on Object {
      return name;
    }
  }

  final bookings = ref.watch(bookingRepositoryProvider);
  final workers = ref.watch(workerSearchRepositoryProvider);
  final now = ref.read(nowProvider);
  return ref.watch(mockApiProvider.select((s) => s.live))
      ? InterviewRepositoryRemote(
          ref.watch(dioProvider),
          bookings,
          workers,
          now: now,
          areaIdFor: areaIdFor,
        )
      : InterviewRepositoryOverBookings(
          bookings,
          workers,
          now: now,
          areaIdFor: areaIdFor,
        );
});

/// One interview. Re-read after every action so the buttons always match the backend's
/// `allowedActions`.
final interviewProvider = FutureProvider.autoDispose.family<Interview, String>((
  ref,
  id,
) {
  ref.watch(mockApiProvider);
  final cancel = CancelToken();
  ref.onDispose(cancel.cancel);
  return ref.read(interviewRepositoryProvider).get(id, cancel: cancel);
});

/// Free start times for a worker on a date (key = worker id + date).
final interviewSlotsProvider = FutureProvider.autoDispose
    .family<List<InterviewSlot>, ({String workerId, DateTime date})>((ref, k) {
      ref.watch(mockApiProvider);
      return ref.read(interviewRepositoryProvider).slots(k.workerId, k.date);
    });

/// The customer's interviews, newest first.
class InterviewListNotifier extends AsyncNotifier<PagedState<Interview>> {
  @override
  Future<PagedState<Interview>> build() async {
    ref.watch(mockApiProvider);
    final page = await ref.read(interviewRepositoryProvider).list();
    return const PagedState<Interview>().appended(page.items, page.nextCursor);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await future;
    } on Object {
      // The error is already in `state`.
    }
  }

  Future<void> loadMore() async {
    final cur = state.value;
    if (cur == null || !cur.canLoadMore) return;
    state = AsyncData(cur.loadingMore());
    try {
      final page = await ref
          .read(interviewRepositoryProvider)
          .list(cursor: cur.nextCursor);
      state = AsyncData(cur.appended(page.items, page.nextCursor));
    } on Object catch (e) {
      state = AsyncData(cur.failedMore(e));
    }
  }
}

final interviewListProvider =
    AsyncNotifierProvider.autoDispose<
      InterviewListNotifier,
      PagedState<Interview>
    >(InterviewListNotifier.new);
