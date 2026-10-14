import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/core/network/dio_provider.dart';
import 'package:sevanest_customer/core/services/clock.dart';
import 'package:sevanest_customer/features/notifications/data/notification_repository_mock.dart';
import 'package:sevanest_customer/features/notifications/data/notification_repository_remote.dart';
import 'package:sevanest_customer/features/notifications/domain/notification.dart';
import 'package:sevanest_customer/shared/models/paged_state.dart';

/// Live backend in stg / prod (and in dev when switched on); the seeded mock otherwise.
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final live = ref.watch(mockApiProvider.select((s) => s.live));
  return live
      ? NotificationRepositoryRemote(ref.watch(dioProvider))
      : NotificationRepositoryMock(
          () => ref.read(mockApiProvider),
          now: ref.read(nowProvider),
        );
});

/// Bumped when a notification arrives (a push in the foreground, or a refresh of the centre).
/// A screen that shows one entity (ticket, booking, replacement) listens and reads it again.
class NotificationTick extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final notificationTickProvider = NotifierProvider<NotificationTick, int>(
  NotificationTick.new,
);

/// `GET /notifications/unread-count`: the bell badge and the Unread tab count.
final notificationUnreadProvider = FutureProvider<int>((ref) {
  ref.watch(mockApiProvider);
  return ref.read(notificationRepositoryProvider).unreadCount();
});

/// The inbox, newest first, paged. `family` key: true = the Unread tab. Tapping a row marks it
/// read optimistically and puts it back (silently) if the server says no.
class NotificationListNotifier
    extends AsyncNotifier<PagedState<AppNotification>> {
  NotificationListNotifier(this.unreadOnly);
  final bool unreadOnly;

  @override
  Future<PagedState<AppNotification>> build() async {
    ref.watch(mockApiProvider);
    final page = await ref
        .read(notificationRepositoryProvider)
        .list(unreadOnly: unreadOnly);
    return const PagedState<AppNotification>().appended(
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

  /// Marks [id] read in the loaded list and returns the list as it was, for a rollback.
  PagedState<AppNotification>? readLocally(String id, DateTime at) {
    final before = state.value;
    if (before != null) {
      state = AsyncData(
        PagedState<AppNotification>(
          items: [
            for (final x in before.items) x.id == id ? x.markedRead(at) : x,
          ],
          nextCursor: before.nextCursor,
        ),
      );
    }
    return before;
  }

  void restore(PagedState<AppNotification> list) => state = AsyncData(list);

  Future<void> loadMore() async {
    final cur = state.value;
    if (cur == null || !cur.canLoadMore) return;
    state = AsyncData(cur.loadingMore());
    try {
      final page = await ref
          .read(notificationRepositoryProvider)
          .list(unreadOnly: unreadOnly, cursor: cur.nextCursor);
      state = AsyncData(cur.appended(page.items, page.nextCursor));
    } on Object catch (e) {
      state = AsyncData(cur.failedMore(e));
    }
  }
}

final notificationListProvider = AsyncNotifierProvider.autoDispose
    .family<NotificationListNotifier, PagedState<AppNotification>, bool>(
      NotificationListNotifier.new,
    );

/// Marks one notification read (optimistic on the All list, silent rollback on failure) and
/// refreshes the badge. Returns once the server answered.
Future<void> markNotificationRead(WidgetRef ref, AppNotification n) async {
  if (n.isRead) return;
  final now = ref.read(nowProvider)();
  final list = ref.read(notificationListProvider(false).notifier);
  final before = list.readLocally(n.id, now);
  try {
    await ref.read(notificationRepositoryProvider).markRead(n.id);
    ref
      ..invalidate(notificationUnreadProvider)
      ..invalidate(notificationListProvider(true));
  } on Object {
    // The row goes back to unread; no message for a background write.
    if (before != null) list.restore(before);
  }
}

/// Marks everything read, then reads the badge and both tabs again.
Future<void> markAllNotificationsRead(WidgetRef ref) async {
  await ref.read(notificationRepositoryProvider).markAllRead();
  ref
    ..invalidate(notificationUnreadProvider)
    ..invalidate(notificationListProvider(false))
    ..invalidate(notificationListProvider(true));
}
