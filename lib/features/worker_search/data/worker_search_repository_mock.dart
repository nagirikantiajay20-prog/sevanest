import 'package:dio/dio.dart';
import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/features/worker_search/domain/worker_search.dart';

/// Seeded workers behind the mock-API toggle (same shape as the real `WorkerCard`).
class WorkerSearchRepositoryMock implements WorkerSearchRepository {
  WorkerSearchRepositoryMock(this._state);
  final MockApiState Function() _state;

  static const pageSize = 20;
  static const _categoryNames = {
    'maid': 'Maid',
    'cook': 'Cook',
    'driver': 'Driver',
    'nanny': 'Nanny',
  };
  static const _langs = [
    ['Telugu', 'Hindi'],
    ['Hindi', 'English'],
    ['Telugu'],
    ['Tamil', 'Telugu', 'English'],
  ];

  /// 45 per category so a second and third page exist.
  static List<WorkerSummary> _seed(String category) => [
    for (var i = 0; i < 45; i++)
      WorkerSummary(
        id: '$category-${i + 1}',
        experienceMonths: i % 7 == 0 ? null : 6 + i * 3,
        categories: [_categoryNames[category] ?? category],
        languages: _langs[i % _langs.length],
        areas: const ['Madhapur', 'Gachibowli'],
        availability: const [AvailabilityWindow('08:00', '18:00')],
        ratingAverage: i % 4 == 0 ? null : 3.5 + (i % 6) / 4,
        ratingCount: i % 4 == 0 ? 0 : 3 + i,
        verified: true,
      ),
  ];

  @override
  Future<WorkerPage> search(
    WorkerQuery query, {
    String? cursor,
    CancelToken? cancel,
  }) => mockCall(_state(), () {
    if (_state().mode == MockMode.empty) return const WorkerPage([], null);
    final all = _seed(query.category);
    final start = int.tryParse(cursor ?? '') ?? 0;
    final end = (start + pageSize).clamp(0, all.length);
    return WorkerPage(
      all.sublist(start, end),
      end < all.length ? '$end' : null,
    );
  });
}
