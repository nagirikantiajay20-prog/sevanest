/// `RatingView` (Swagger). A rating cannot be edited or deleted by the customer.
class Rating {
  const Rating({
    required this.id,
    required this.bookingId,
    required this.score,
    this.review,
    this.tags = const [],
    this.createdAt,
  });

  final String id;
  final String bookingId;
  final int score;
  final String? review;

  /// Tag codes (`PUNCTUAL`...), always a list; show the label from [RatingTag].
  final List<String> tags;
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
      tags: [
        if (j['tags'] is List)
          for (final t in j['tags'] as List)
            if (t is String) t,
      ],
      createdAt: DateTime.tryParse('${j['createdAt']}'),
    );
  }
}

/// One `ratingTags` entry of `GET /reference-data`. Send [code], show [label].
class RatingTag {
  const RatingTag(this.code, this.label, {required this.positive});
  final String code;
  final String label;
  final bool positive;

  /// Used until `/reference-data` answers (and offline); same codes as the backend catalogue.
  static const fallback = [
    RatingTag('PUNCTUAL', 'Punctual', positive: true),
    RatingTag('POLITE', 'Polite', positive: true),
    RatingTag('SKILLED', 'Skilled', positive: true),
    RatingTag('CLEAN_WORK', 'Clean work', positive: true),
    RatingTag('TRUSTWORTHY', 'Trustworthy', positive: true),
    RatingTag('LATE', 'Late', positive: false),
    RatingTag('RUDE', 'Rude', positive: false),
    RatingTag('POOR_QUALITY_WORK', 'Poor quality work', positive: false),
    RatingTag('UNRELIABLE', 'Unreliable', positive: false),
  ];

  static List<RatingTag> listFrom(Object? json) {
    final out = <RatingTag>[
      if (json is List)
        for (final m in json)
          if (m is Map && m['code'] is String && m['label'] is String)
            RatingTag(
              m['code'] as String,
              m['label'] as String,
              positive: '${m['sentiment']}'.toUpperCase() != 'NEGATIVE',
            ),
    ];
    return out.isEmpty ? fallback : out;
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
    List<String> tags = const [],
    required String idempotencyKey,
  });
}
