import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/providers/account_providers.dart';
import 'package:sevanest_customer/features/notifications/domain/notification.dart';
import 'package:sevanest_customer/features/ratings/domain/rating.dart';
import 'package:sevanest_customer/features/replacement/domain/replacement.dart';

void main() {
  test('rating tags: parsed as a list, catalogue falls back', () {
    expect(
      Rating.fromJson({
        'id': 'r',
        'score': 5,
        'tags': ['POLITE'],
      })!.tags,
      ['POLITE'],
    );
    expect(Rating.fromJson({'id': 'r', 'score': 5})!.tags, isEmpty);
    final cat = RatingTag.listFrom([
      {'code': 'LATE', 'label': 'Late', 'sentiment': 'NEGATIVE'},
    ]);
    expect(cat.single.positive, isFalse);
    expect(RatingTag.listFrom(null), RatingTag.fallback);
  });

  test('replacement neededFrom is read', () {
    final r = Replacement.fromJson({'id': 'x', 'neededFrom': '2026-10-20'});
    expect(r!.neededFrom, '2026-10-20');
    expect(
      Replacement.fromJson({'id': 'x', 'neededFrom': null})!.neededFrom,
      isNull,
    );
  });

  test('policy is empty while all null', () {
    expect(PolicyConfig.from({'cancellationText': null}).isEmpty, isTrue);
    expect(
      PolicyConfig.from({'refundText': 'Refunds in 5 days'}).isEmpty,
      isFalse,
    );
  });

  test(
    'push route types payment, replacement, interview open their screens',
    () {
      for (final t in ['payment', 'replacement', 'interview']) {
        expect(
          routeForPushData({'routeType': t, 'routeId': 'abc'}),
          isNot(contains('/notifications')),
        );
      }
    },
  );
}
