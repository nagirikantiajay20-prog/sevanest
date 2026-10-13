import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/core/network/dio_provider.dart';
import 'package:sevanest_customer/features/favourites/data/favourites_repository_mock.dart';
import 'package:sevanest_customer/features/favourites/data/favourites_repository_remote.dart';
import 'package:sevanest_customer/features/favourites/domain/favourites.dart';
import 'package:sevanest_customer/shared/models/paged_state.dart';

/// Live backend in stg / prod (and in dev when switched on); in-memory mock otherwise.
final favouritesRepositoryProvider = Provider<FavouritesRepository>((ref) {
  final live = ref.watch(mockApiProvider.select((s) => s.live));
  return live
      ? FavouritesRepositoryRemote(ref.watch(dioProvider))
      : FavouritesRepositoryMock(() => ref.read(mockApiProvider));
});

/// Which workers are shortlisted, plus the ones with a request in flight.
class FavouriteState {
  const FavouriteState(this.ids, [this.pending = const {}]);
  final Set<String> ids;
  final Set<String> pending;
}

/// Single source of truth for every heart (results, detail, shortlist), so they never disagree.
/// Toggling is optimistic and rolls back when the server rejects it (AGENTS §28).
class FavouriteNotifier extends AsyncNotifier<FavouriteState> {
  @override
  Future<FavouriteState> build() async {
    ref.watch(mockApiProvider);
    return FavouriteState(await ref.read(favouritesRepositoryProvider).ids());
  }

  /// Returns false when the change was rolled back. A tap while this worker's request is still
  /// running is ignored (one request per tap burst).
  Future<bool> toggle(String id) async {
    final cur = state.value;
    if (cur == null) return false;
    if (cur.pending.contains(id)) return true;
    final adding = !cur.ids.contains(id);
    FavouriteState next(bool add, {required bool pending}) {
      final s = state.value ?? cur;
      return FavouriteState(
        add ? {...s.ids, id} : ({...s.ids}..remove(id)),
        pending ? {...s.pending, id} : ({...s.pending}..remove(id)),
      );
    }

    state = AsyncData(next(adding, pending: true));
    final repo = ref.read(favouritesRepositoryProvider);
    try {
      await (adding ? repo.add(id) : repo.remove(id));
      state = AsyncData(next(adding, pending: false));
      ref.invalidate(favouritesListProvider);
      return true;
    } on Object {
      state = AsyncData(next(!adding, pending: false));
      return false;
    }
  }
}

final favouriteProvider =
    AsyncNotifierProvider.autoDispose<FavouriteNotifier, FavouriteState>(
      FavouriteNotifier.new,
    );

/// The shortlist tab's rows.
class FavouritesListNotifier extends AsyncNotifier<PagedState<FavouriteEntry>> {
  @override
  Future<PagedState<FavouriteEntry>> build() async {
    ref.watch(mockApiProvider);
    final page = await ref.read(favouritesRepositoryProvider).list();
    return const PagedState<FavouriteEntry>().appended(
      page.items,
      page.nextCursor,
    );
  }

  /// Riverpod keeps the old rows while this reloads, and with the error attached if it fails.
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
          .read(favouritesRepositoryProvider)
          .list(cursor: cur.nextCursor);
      state = AsyncData(cur.appended(page.items, page.nextCursor));
    } on Object catch (e) {
      state = AsyncData(cur.failedMore(e));
    }
  }
}

final favouritesListProvider =
    AsyncNotifierProvider.autoDispose<
      FavouritesListNotifier,
      PagedState<FavouriteEntry>
    >(FavouritesListNotifier.new);
