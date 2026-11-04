import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/features/worker_search/domain/worker_search.dart';

void main() {
  test('reads displayName and skills', () {
    final w = WorkerSummary.fromJson({
      'workerId': 'w1',
      'displayName': 'vaishhhh',
      'skills': [
        {'code': 'COOK', 'name': 'Cook'},
        {'code': 'DRIVER', 'name': 'Driver'},
      ],
    })!;
    expect(w.name, 'vaishhhh');
    expect(w.categories, ['Cook', 'Driver']);
  });

  test('still reads name and categories', () {
    final w = WorkerSummary.fromJson({
      'workerId': 'w2',
      'name': 'Lakshmi D.',
      'categories': [
        {'name': 'Cook'},
      ],
    })!;
    expect(w.name, 'Lakshmi D.');
    expect(w.categories, ['Cook']);
  });
}
