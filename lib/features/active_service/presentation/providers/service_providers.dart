import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/core/network/dio_provider.dart';
import 'package:sevanest_customer/core/services/clock.dart';
import 'package:sevanest_customer/features/active_service/data/attendance_repository_mock.dart';
import 'package:sevanest_customer/features/active_service/data/attendance_repository_remote.dart';
import 'package:sevanest_customer/features/active_service/domain/attendance.dart';
import 'package:sevanest_customer/shared/models/paged_state.dart';

/// Live backend in stg / prod (and in dev when switched on); seeded attendance otherwise.
final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  final live = ref.watch(mockApiProvider.select((s) => s.live));
  return live
      ? AttendanceRepositoryRemote(ref.watch(dioProvider))
      : AttendanceRepositoryMock(
          () => ref.read(mockApiProvider),
          now: ref.read(nowProvider),
        );
});

/// One booking's attendance, newest day first, paged.
class AttendanceNotifier extends AsyncNotifier<PagedState<AttendanceEntry>> {
  AttendanceNotifier(this.bookingId);
  final String bookingId;

  @override
  Future<PagedState<AttendanceEntry>> build() async {
    ref.watch(mockApiProvider);
    final page = await ref.read(attendanceRepositoryProvider).page(bookingId);
    return const PagedState<AttendanceEntry>().appended(
      page.items,
      page.nextCursor,
    );
  }

  Future<void> loadMore() async {
    final cur = state.value;
    if (cur == null || !cur.canLoadMore) return;
    state = AsyncData(cur.loadingMore());
    try {
      final page = await ref
          .read(attendanceRepositoryProvider)
          .page(bookingId, cursor: cur.nextCursor);
      state = AsyncData(cur.appended(page.items, page.nextCursor));
    } on Object catch (e) {
      state = AsyncData(cur.failedMore(e));
    }
  }
}

final attendanceProvider = AsyncNotifierProvider.autoDispose
    .family<AttendanceNotifier, PagedState<AttendanceEntry>, String>(
      AttendanceNotifier.new,
    );

/// This month's counts (`YYYY-MM` of today). A failure only hides the card.
final attendanceSummaryProvider = FutureProvider.autoDispose
    .family<AttendanceSummary, String>((ref, bookingId) {
      ref.watch(mockApiProvider);
      final n = ref.read(nowProvider)();
      final month =
          '${n.year.toString().padLeft(4, '0')}-'
          '${n.month.toString().padLeft(2, '0')}';
      return ref.read(attendanceRepositoryProvider).summary(bookingId, month);
    });
