import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/features/worker_profile/data/worker_reviews_repository_mock.dart';
import 'package:sevanest_customer/features/worker_profile/domain/worker_review.dart';
import 'package:sevanest_customer/features/worker_search/domain/worker_search.dart';
import 'package:sevanest_customer/features/worker_search/presentation/providers/worker_search_providers.dart';
import 'package:sevanest_customer/shared/models/paged_state.dart';

/// One worker's card. Cancelled when the screen closes; a 404 means "no longer available".
final workerDetailProvider = FutureProvider.autoDispose
    .family<WorkerSummary, String>((ref, id) {
      ref.watch(mockApiProvider);
      final cancel = CancelToken();
      ref.onDispose(cancel.cancel);
      return ref
          .read(workerSearchRepositoryProvider)
          .detail(id, cancel: cancel);
    });

// ponytail: mock only; the backend has no worker-reviews endpoint for customers (OPEN_QUESTIONS #41).
final workerReviewsRepositoryProvider = Provider<WorkerReviewsRepository>(
  (ref) => WorkerReviewsRepositoryMock(() => ref.read(mockApiProvider)),
);

/// A worker's reviews, newest first, cursor-paged.
class WorkerReviewsNotifier extends AsyncNotifier<PagedState<WorkerReview>> {
  WorkerReviewsNotifier(this.workerId);
  final String workerId;

  @override
  Future<PagedState<WorkerReview>> build() async {
    ref.watch(mockApiProvider);
    final page = await ref
        .read(workerReviewsRepositoryProvider)
        .reviews(workerId);
    return const PagedState<WorkerReview>().appended(
      page.items,
      page.nextCursor,
    );
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
          .read(workerReviewsRepositoryProvider)
          .reviews(workerId, cursor: cur.nextCursor);
      state = AsyncData(cur.appended(page.items, page.nextCursor));
    } on Object catch (e) {
      state = AsyncData(cur.failedMore(e));
    }
  }
}

final workerReviewsProvider = AsyncNotifierProvider.autoDispose
    .family<WorkerReviewsNotifier, PagedState<WorkerReview>, String>(
      WorkerReviewsNotifier.new,
    );
