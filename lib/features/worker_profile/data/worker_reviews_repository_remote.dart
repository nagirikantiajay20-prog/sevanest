import 'package:sevanest_customer/features/worker_profile/domain/worker_review.dart';

/// No customer-facing endpoint lists a worker's reviews yet (OPEN_QUESTIONS #41), so live there
/// are none to show. The card's own rating summary still comes from the search API.
class WorkerReviewsRepositoryRemote implements WorkerReviewsRepository {
  const WorkerReviewsRepositoryRemote();

  @override
  Future<ReviewsPage> reviews(String workerId, {String? cursor}) async =>
      const ReviewsPage([], null);
}
