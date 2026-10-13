/// A review shown on a worker's profile: reviewer first name only (never contact details).
class WorkerReview {
  const WorkerReview({
    required this.reviewerFirstName,
    required this.rating,
    required this.date,
    this.text,
  });
  final String reviewerFirstName;
  final double rating;
  final DateTime date;
  final String? text;
}

class ReviewsPage {
  const ReviewsPage(this.items, this.nextCursor);
  final List<WorkerReview> items;
  final String? nextCursor;
}

abstract interface class WorkerReviewsRepository {
  Future<ReviewsPage> reviews(String workerId, {String? cursor});
}
