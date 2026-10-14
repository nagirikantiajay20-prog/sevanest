import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/core/network/dio_provider.dart';
import 'package:sevanest_customer/core/services/clock.dart';
import 'package:sevanest_customer/features/replacement/data/replacement_repository_mock.dart';
import 'package:sevanest_customer/features/replacement/data/replacement_repository_remote.dart';
import 'package:sevanest_customer/features/replacement/domain/replacement.dart';

/// Live backend in stg / prod (and in dev when switched on); the seeded mock otherwise.
final replacementRepositoryProvider = Provider<ReplacementRepository>((ref) {
  final live = ref.watch(mockApiProvider.select((s) => s.live));
  return live
      ? ReplacementRepositoryRemote(ref.watch(dioProvider))
      : ReplacementRepositoryMock(
          () => ref.read(mockApiProvider),
          now: ref.read(nowProvider),
        );
});

/// One request. Re-read after every action, on pull-to-refresh and on app resume.
final replacementProvider = FutureProvider.autoDispose
    .family<Replacement, String>((ref, id) {
      ref.watch(mockApiProvider);
      return ref.read(replacementRepositoryProvider).get(id);
    });

/// The still-open request of a booking, or null. The backend has no "request of a booking" route
/// and the booking carries no request id, so this reads `GET /replacement-requests` (newest first)
/// until it finds one; at most one request per booking can be open.
final openReplacementProvider = FutureProvider.autoDispose
    .family<Replacement?, String>((ref, bookingId) async {
      ref.watch(mockApiProvider);
      final repo = ref.read(replacementRepositoryProvider);
      String? cursor;
      do {
        final page = await repo.list(cursor: cursor);
        for (final r in page.items) {
          if (r.bookingId == bookingId && replacementIsOpen(r.status)) return r;
        }
        cursor = page.nextCursor;
      } while (cursor != null);
      return null;
    });

/// `GET /bookings/{id}/replacement-chain`, oldest first.
final replacementChainProvider = FutureProvider.autoDispose
    .family<List<ChainEntry>, String>((ref, bookingId) {
      ref.watch(mockApiProvider);
      return ref.read(replacementRepositoryProvider).chain(bookingId);
    });
