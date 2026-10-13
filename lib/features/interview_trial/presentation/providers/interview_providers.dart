import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/core/network/dio_provider.dart';
import 'package:sevanest_customer/core/services/clock.dart';
import 'package:sevanest_customer/features/interview_trial/data/interview_repository_mock.dart';
import 'package:sevanest_customer/features/interview_trial/data/interview_repository_remote.dart';
import 'package:sevanest_customer/features/interview_trial/domain/interview.dart';
import 'package:sevanest_customer/shared/models/paged_state.dart';

/// Live backend in stg / prod (assumed contract, not yet published); seeded mock in dev.
final interviewRepositoryProvider = Provider<InterviewRepository>((ref) {
  final live = ref.watch(mockApiProvider.select((s) => s.live));
  return live
      ? InterviewRepositoryRemote(ref.watch(dioProvider))
      : InterviewRepositoryMock(
          () => ref.read(mockApiProvider),
          now: ref.read(nowProvider),
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
