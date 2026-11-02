import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/features/worker_profile/domain/worker_review.dart';
import 'package:sevanest_customer/features/worker_search/data/worker_search_repository_mock.dart';

/// Seeded reviews. The backend has no customer-facing endpoint for a worker's reviews yet
/// (OPEN_QUESTIONS #41), so this is the only implementation.
class WorkerReviewsRepositoryMock implements WorkerReviewsRepository {
  WorkerReviewsRepositoryMock(this._state);
  final MockApiState Function() _state;

  static const pageSize = 10;
  static const _names = ['Anita', 'Ravi', 'Sunita', 'Kiran', 'Meena'];

  @override
  Future<ReviewsPage> reviews(String workerId, {String? cursor}) => mockCall(
    _state(),
    () {
      final w = WorkerSearchRepositoryMock.byId(workerId);
      // Only workers with a rating have reviews; the count matches their card.
      final total = w == null || !w.hasRating || _state().mode == MockMode.empty
          ? 0
          : w.ratingCount;
      final start = int.tryParse(cursor ?? '') ?? 0;
      final end = (start + pageSize).clamp(0, total);
      return ReviewsPage(
        [
          for (var i = start; i < end; i++)
            WorkerReview(
              reviewerFirstName: _names[i % _names.length],
              rating: w!.ratingAverage!,
              date: DateTime(2026, 9, 28).subtract(Duration(days: i * 6)),
              text: i % 3 == 2
                  ? null
                  : 'Punctual, careful and easy to work with.',
            ),
        ],
        end < total ? '$end' : null,
        // Every seeded review carries the worker's rounded average.
        summary: total == 0
            ? null
            : ReviewSummary(
                average: w!.ratingAverage!,
                count: total,
                distribution: {
                  for (var s = 5; s >= 1; s--)
                    s: s == w.ratingAverage!.round() ? total : 0,
                },
              ),
      );
    },
  );
}
