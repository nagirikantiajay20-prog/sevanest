/// `RatingView` (Swagger). A rating cannot be edited or deleted by the customer.
class Rating {
  const Rating({
    required this.id,
    required this.bookingId,
    required this.score,
    this.review,
    this.createdAt,
  });

  final String id;
  final String bookingId;
  final int score;
  final String? review;
  final DateTime? createdAt;

  static Rating? fromJson(Object? json) {
    if (json is! Map) return null;
    final j = json['data'] is Map ? json['data'] as Map : json;
    final id = j['id'];
    final score = j['score'];
    if (id is! String || score is! num) return null;
    final review = j['review'];
    return Rating(
      id: id,
      bookingId: '${j['bookingId']}',
      score: score.toInt(),
      review: review is String && review.isNotEmpty ? review : null,
      createdAt: DateTime.tryParse('${j['createdAt']}'),
    );
  }
}

class RatingPage {
  const RatingPage(this.items, this.nextCursor);
  final List<Rating> items;
  final String? nextCursor;
}

/// `/ratings` of the deployed backend. There is no eligibility endpoint: a booking can be rated
/// when it is COMPLETED and [forBooking] answers null.
abstract interface class RatingRepository {
  /// `GET /ratings/bookings/{id}`; 404 means "not rated yet" and answers null.
  Future<Rating?> forBooking(String bookingId);

  /// `GET /ratings`: my ratings, newest first.
  Future<RatingPage> mine({String? cursor});

  /// `POST /ratings`. One key per form: repeating it returns the first rating.
  Future<Rating> submit(
    String bookingId, {
    required int score,
    String? review,
    required String idempotencyKey,
  });
}
