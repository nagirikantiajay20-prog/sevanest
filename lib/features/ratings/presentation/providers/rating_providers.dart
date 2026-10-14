import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/core/network/dio_provider.dart';
import 'package:sevanest_customer/features/ratings/data/rating_repository_mock.dart';
import 'package:sevanest_customer/features/ratings/data/rating_repository_remote.dart';
import 'package:sevanest_customer/features/ratings/domain/rating.dart';

final ratingRepositoryProvider = Provider<RatingRepository>((ref) {
  final live = ref.watch(mockApiProvider.select((s) => s.live));
  return live
      ? RatingRepositoryRemote(ref.watch(dioProvider))
      : RatingRepositoryMock(() => ref.read(mockApiProvider));
});

/// Longest review the form accepts. The Swagger caps `review` at 2000 and `/reference-data` has no
/// field for it (BACKEND_REQUESTS 28); tests and a future config override this provider.
final ratingReviewMaxProvider = Provider<int>((ref) => 2000);

/// My rating of one booking, or null when it is not rated yet.
final bookingRatingProvider = FutureProvider.autoDispose
    .family<Rating?, String>((ref, bookingId) {
      ref.watch(mockApiProvider);
      return ref.read(ratingRepositoryProvider).forBooking(bookingId);
    });

/// bookingId -> my rating, for the stars on history cards. Reads every page (50 per page).
final myRatingsProvider = FutureProvider.autoDispose<Map<String, Rating>>((
  ref,
) async {
  ref.watch(mockApiProvider);
  final repo = ref.read(ratingRepositoryProvider);
  final out = <String, Rating>{};
  String? cursor;
  do {
    final page = await repo.mine(cursor: cursor);
    for (final r in page.items) {
      out[r.bookingId] = r;
    }
    cursor = page.nextCursor;
  } while (cursor != null);
  return out;
});
