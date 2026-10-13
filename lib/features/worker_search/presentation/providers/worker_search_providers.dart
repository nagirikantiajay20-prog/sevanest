import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/features/addresses/presentation/providers/address_providers.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/requirement_draft_provider.dart';
import 'package:sevanest_customer/features/worker_search/data/worker_search_repository_mock.dart';
import 'package:sevanest_customer/features/worker_search/domain/worker_search.dart';
import 'package:sevanest_customer/shared/models/paged_state.dart';

// ponytail: mock until the catalogue is real. Swap for WorkerSearchRepositoryRemote(dio) once
// category codes come from /service-categories (the mock catalogue ids are not backend codes).
final workerSearchRepositoryProvider = Provider<WorkerSearchRepository>(
  (ref) => WorkerSearchRepositoryMock(() => ref.read(mockApiProvider)),
);

/// The search the draft describes, or null while it has no service or address yet.
final workerQueryProvider = Provider.autoDispose<WorkerQuery?>((ref) {
  final d = ref.watch(requirementDraftProvider);
  final address = d.address;
  if (d.serviceId == null || address == null) return null;
  // The address stores the area name; the search wants the service-area id.
  final areas = ref.watch(serviceAreasProvider).asData?.value ?? const [];
  final areaId = areas.where((a) => a.name == address.area).firstOrNull?.id;
  return WorkerQuery(
    category: d.serviceId!,
    areaId: areaId ?? address.area,
    engagement: d.engagement,
  );
});

/// Results of the current query. A changed query rebuilds (cancelling the old request);
/// [refresh] keeps the old list on screen if it fails (stale banner).
class WorkerSearchNotifier extends AsyncNotifier<PagedState<WorkerSummary>> {
  CancelToken? _token;

  CancelToken _newToken() {
    _token?.cancel('superseded');
    return _token = CancelToken();
  }

  @override
  Future<PagedState<WorkerSummary>> build() async {
    ref.onDispose(() => _token?.cancel('disposed'));
    final q = ref.watch(workerQueryProvider);
    if (q == null) return const PagedState();
    final page = await ref
        .read(workerSearchRepositoryProvider)
        .search(q, cancel: _newToken());
    return const PagedState<WorkerSummary>().appended(
      page.items,
      page.nextCursor,
    );
  }

  /// Re-runs the search from page 1. Riverpod keeps the old list while it loads, and on failure
  /// keeps it with the error attached, which the screen shows as the stale banner.
  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await future;
    } on Object {
      // The error is already in `state`.
    }
  }

  /// Next page from the backend cursor, one request at a time. A failure keeps the list and shows
  /// a footer retry.
  Future<void> loadMore() async {
    final cur = state.value;
    final q = ref.read(workerQueryProvider);
    if (cur == null || q == null || !cur.canLoadMore) return;
    final token = _token ?? _newToken();
    state = AsyncData(cur.loadingMore());
    try {
      final page = await ref
          .read(workerSearchRepositoryProvider)
          .search(q, cursor: cur.nextCursor, cancel: token);
      if (token.isCancelled) return;
      state = AsyncData(cur.appended(page.items, page.nextCursor));
    } on Object catch (e) {
      if (token.isCancelled) return;
      state = AsyncData(cur.failedMore(e));
    }
  }
}

final workerSearchProvider =
    AsyncNotifierProvider.autoDispose<
      WorkerSearchNotifier,
      PagedState<WorkerSummary>
    >(WorkerSearchNotifier.new);
