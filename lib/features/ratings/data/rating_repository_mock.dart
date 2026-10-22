import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/features/ratings/domain/rating.dart';

/// In-memory ratings behind the dev mock toggle. Enforces the backend's once-per-booking rule.
class RatingRepositoryMock implements RatingRepository {
  RatingRepositoryMock(this._state, {this.scaleMax = 5});
  final MockApiState Function() _state;
  final int scaleMax;
  final _items = <Rating>[];
  final _keys = <String, Rating>{};

  @override
  Future<Rating?> forBooking(String bookingId) => mockCall(
    _state(),
    () => _items.where((r) => r.bookingId == bookingId).firstOrNull,
  );

  @override
  Future<RatingPage> mine({String? cursor}) =>
      mockCall(_state(), () => RatingPage(List.of(_items.reversed), null));

  @override
  Future<Rating> submit(
    String bookingId, {
    required int score,
    String? review,
    List<String> tags = const [],
    required String idempotencyKey,
  }) => mockCall(_state(), () {
    final prior = _keys[idempotencyKey];
    if (prior != null) return prior;
    if (score < 1 || score > scaleMax) {
      throw const ValidationFailure(
        'Score out of scale',
        {},
        'RATING_SCORE_OUT_OF_SCALE',
      );
    }
    if (_items.any((r) => r.bookingId == bookingId)) {
      throw const ConflictFailure('Already rated', 'RATING_ALREADY_EXISTS');
    }
    final r = Rating(
      id: 'rt_${_items.length + 1}',
      bookingId: bookingId,
      score: score,
      review: review?.trim().isEmpty ?? true ? null : review!.trim(),
      tags: tags,
      createdAt: DateTime.now(),
    );
    _items.add(r);
    return _keys[idempotencyKey] = r;
  });
}
