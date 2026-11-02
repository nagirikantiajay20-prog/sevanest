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

/// `summary` of `GET /search/workers/{id}/ratings`: visible reviews only, so [count] is the list's
/// total. [distribution] runs from the top score down to 1, zeros included.
class ReviewSummary {
  const ReviewSummary({
    required this.average,
    required this.count,
    required this.distribution,
  });
  final double average;
  final int count;
  final Map<int, int> distribution;

  /// Null when the backend sent no usable summary.
  static ReviewSummary? fromJson(Object? j) {
    if (j is! Map || j['average'] is! num || j['count'] is! num) return null;
    final d = j['distribution'];
    final byScore = <int, int>{
      if (d is Map)
        for (final e in d.entries)
          if (int.tryParse('${e.key}') != null && e.value is num)
            int.parse('${e.key}'): (e.value as num).toInt(),
    };
    return ReviewSummary(
      average: (j['average'] as num).toDouble(),
      count: (j['count'] as num).toInt(),
      distribution: {
        for (final k in byScore.keys.toList()..sort((a, b) => b.compareTo(a)))
          k: byScore[k]!,
      },
    );
  }
}

class ReviewsPage {
  const ReviewsPage(this.items, this.nextCursor, {this.summary});
  final List<WorkerReview> items;
  final String? nextCursor;
  final ReviewSummary? summary;
}

abstract interface class WorkerReviewsRepository {
  Future<ReviewsPage> reviews(String workerId, {String? cursor});
}
