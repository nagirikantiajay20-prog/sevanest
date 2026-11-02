import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/features/worker_profile/domain/worker_review.dart';

void main() {
  test('ReviewSummary parses the backend breakdown, top score first', () {
    final s = ReviewSummary.fromJson({
      'average': 4.8,
      'count': 36,
      'distribution': {'1': 0, '5': 29, '4': 6, '3': 1, '2': 0},
    })!;
    expect(s.count, 36);
    expect(s.distribution.keys.toList(), [5, 4, 3, 2, 1]);
    expect(s.distribution[5], 29);
  });

  test('ReviewSummary is null when the backend sends none', () {
    expect(ReviewSummary.fromJson(null), isNull);
    expect(ReviewSummary.fromJson({'average': 'x'}), isNull);
  });
}
