import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/core/network/dio_provider.dart';
import 'package:sevanest_customer/core/services/clock.dart';
import 'package:sevanest_customer/features/support/data/support_repository_mock.dart';
import 'package:sevanest_customer/features/support/data/support_repository_remote.dart';
import 'package:sevanest_customer/features/support/domain/support.dart';
import 'package:sevanest_customer/shared/models/paged_state.dart';

/// Limits from the Swagger: `CreateTicketDto.description` 4000, `PostMessageDto.body` 2000,
/// `CreateReportDto.note` 1000. The Swagger has no minimum; the module doc asks for 10 characters,
/// so that is the form's floor (BACKEND_REQUESTS 46). Tests and a future config override these.
final ticketDescriptionMaxProvider = Provider<int>((ref) => 4000);
final ticketDescriptionMinProvider = Provider<int>((ref) => 10);
final ticketMessageMaxProvider = Provider<int>((ref) => 2000);
final reportNoteMaxProvider = Provider<int>((ref) => 1000);

/// Live backend in stg / prod (and in dev when switched on); the seeded mock otherwise.
final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  final live = ref.watch(mockApiProvider.select((s) => s.live));
  return live
      ? SupportRepositoryRemote(ref.watch(dioProvider))
      : SupportRepositoryMock(
          () => ref.read(mockApiProvider),
          now: ref.read(nowProvider),
        );
});

final safetyRepositoryProvider = Provider<SafetyRepository>((ref) {
  final live = ref.watch(mockApiProvider.select((s) => s.live));
  return live
      ? SafetyRepositoryRemote(ref.watch(dioProvider))
      : SafetyRepositoryMock(
          () => ref.read(mockApiProvider),
          now: ref.read(nowProvider),
        );
});

/// `GET /support/categories`. Server-driven: nothing is hard-coded.
final supportCategoriesProvider =
    FutureProvider.autoDispose<List<SupportCategory>>((ref) {
      ref.watch(mockApiProvider);
      return ref.read(supportRepositoryProvider).categories();
    });

/// `GET /app-config` -> `support`. Null phone and email (today) keep Contact disabled.
final supportContactProvider = FutureProvider.autoDispose<SupportContact>((
  ref,
) async {
  if (!ref.watch(mockApiProvider.select((s) => s.live))) {
    return const SupportContact();
  }
  final res = await ref.read(dioProvider).get<dynamic>('/app-config');
  final data = res.data;
  final s = data is Map ? data['support'] : null;
  String? v(Object? x) => x is String && x.trim().isNotEmpty ? x.trim() : null;
  return s is Map
      ? SupportContact(phone: v(s['phone']), email: v(s['email']))
      : const SupportContact();
});

/// The customer's tickets, newest first.
class TicketListNotifier extends AsyncNotifier<PagedState<Ticket>> {
  @override
  Future<PagedState<Ticket>> build() async {
    ref.watch(mockApiProvider);
    final page = await ref.read(supportRepositoryProvider).list();
    return const PagedState<Ticket>().appended(page.items, page.nextCursor);
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
          .read(supportRepositoryProvider)
          .list(cursor: cur.nextCursor);
      state = AsyncData(cur.appended(page.items, page.nextCursor));
    } on Object catch (e) {
      state = AsyncData(cur.failedMore(e));
    }
  }
}

final ticketListProvider =
    AsyncNotifierProvider.autoDispose<TicketListNotifier, PagedState<Ticket>>(
      TicketListNotifier.new,
    );

/// One ticket with its history. Re-read after a send, on pull-to-refresh, on resume and when a
/// "support replied" notification arrives.
final ticketProvider = FutureProvider.autoDispose.family<Ticket, String>((
  ref,
  id,
) {
  ref.watch(mockApiProvider);
  return ref.read(supportRepositoryProvider).get(id);
});

/// The whole conversation, oldest first (every page is read; a ticket holds few messages).
final ticketMessagesProvider = FutureProvider.autoDispose
    .family<List<TicketMessage>, String>((ref, id) async {
      ref.watch(mockApiProvider);
      final repo = ref.read(supportRepositoryProvider);
      final all = <TicketMessage>[];
      String? cursor;
      var pages = 0;
      do {
        final page = await repo.messages(id, cursor: cursor);
        all.addAll(page.items);
        cursor = page.nextCursor;
      } while (cursor != null && ++pages < 20);
      all.sort(
        (a, b) => (a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
      );
      return all;
    });

/// An open ticket that already names [bookingId] (design "Duplicate notice"), read from the first
/// page of the customer's own tickets. Null when there is none or the list cannot be read.
final openTicketForBookingProvider = FutureProvider.autoDispose
    .family<Ticket?, String>((ref, bookingId) async {
      ref.watch(mockApiProvider);
      try {
        final page = await ref.read(supportRepositoryProvider).list();
        for (final t in page.items) {
          if (t.bookingId == bookingId && ticketAcceptsReplies(t.status)) {
            return t;
          }
        }
      } on Object {
        // a hint only
      }
      return null;
    });
