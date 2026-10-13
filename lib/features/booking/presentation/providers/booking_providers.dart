import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/core/network/dio_provider.dart';
import 'package:sevanest_customer/core/services/clock.dart';
import 'package:sevanest_customer/features/booking/data/booking_repository_mock.dart';
import 'package:sevanest_customer/features/booking/data/booking_repository_remote.dart';
import 'package:sevanest_customer/features/booking/domain/booking.dart';
import 'package:sevanest_customer/shared/models/paged_state.dart';

/// Live backend in stg / prod (and in dev when switched on); the seeded state machine otherwise.
final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  final live = ref.watch(mockApiProvider.select((s) => s.live));
  return live
      ? BookingRepositoryRemote(ref.watch(dioProvider))
      : BookingRepositoryMock(
          () => ref.read(mockApiProvider),
          now: ref.read(nowProvider),
        );
});

/// One booking. Re-read after every action and on app resume.
final bookingProvider = FutureProvider.autoDispose.family<Booking, String>((
  ref,
  id,
) {
  ref.watch(mockApiProvider);
  final cancel = CancelToken();
  ref.onDispose(cancel.cancel);
  return ref.read(bookingRepositoryProvider).get(id, cancel: cancel);
});

/// The customer's bookings, newest first. Current / Past is a filter over this one list because
/// the backend filters by a single status only.
class BookingListNotifier extends AsyncNotifier<PagedState<Booking>> {
  @override
  Future<PagedState<Booking>> build() async {
    ref.watch(mockApiProvider);
    final page = await ref.read(bookingRepositoryProvider).list();
    return const PagedState<Booking>().appended(page.items, page.nextCursor);
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
          .read(bookingRepositoryProvider)
          .list(cursor: cur.nextCursor);
      state = AsyncData(cur.appended(page.items, page.nextCursor));
    } on Object catch (e) {
      state = AsyncData(cur.failedMore(e));
    }
  }
}

final bookingListProvider =
    AsyncNotifierProvider.autoDispose<BookingListNotifier, PagedState<Booking>>(
      BookingListNotifier.new,
    );
