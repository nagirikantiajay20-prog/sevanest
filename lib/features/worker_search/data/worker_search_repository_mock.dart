import 'package:dio/dio.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/features/service_discovery/domain/catalog.dart';
import 'package:sevanest_customer/features/worker_search/domain/worker_search.dart';

/// Seeded workers behind the mock-API toggle (same shape as the real `WorkerCard`).
class WorkerSearchRepositoryMock implements WorkerSearchRepository {
  WorkerSearchRepositoryMock(this._state);
  final MockApiState Function() _state;

  static const pageSize = 20;
  static const _categoryNames = {
    'maid': 'House Maid',
    'cook': 'Cook',
    'driver': 'Driver',
    'babysitter': 'Babysitter',
    'elderly': 'Elderly Care Helper',
    'cleaner': 'Cleaning Helper',
  };
  static const _langs = [
    ['te', 'hi'],
    ['hi', 'en'],
    ['te'],
    ['ta', 'te', 'en'],
  ];

  // Display names as the backend sends them: first name and last initial (D-91).
  static const _names = [
    ['Lakshmi', 'D'],
    ['Ramesh', 'K'],
    ['Meena', 'P'],
    ['Sunita', 'R'],
    ['Anita', 'S'],
    ['Kavitha', 'M'],
  ];

  /// 45 per category so a second and third page exist.
  static List<WorkerSummary> _seed(String category) => [
    for (var i = 0; i < 45; i++)
      WorkerSummary(
        id: '$category-${i + 1}',
        name:
            '${_names[i % _names.length][0]} ${_names[(i ~/ 2) % _names.length][1]}.',
        initials:
            '${_names[i % _names.length][0][0]}${_names[(i ~/ 2) % _names.length][1]}',
        experienceMonths: i % 7 == 0 ? null : 6 + i * 3,
        categories: [_categoryNames[category] ?? category],
        languages: _langs[i % _langs.length],
        areas: const ['Madhapur', 'Gachibowli'],
        availability: [
          i % 3 == 0
              ? const AvailabilityWindow('06:00', '21:00')
              : const AvailabilityWindow('08:00', '18:00'),
        ],
        ratingAverage: i % 4 == 0 ? null : 3.5 + (i % 6) / 4,
        ratingCount: i % 4 == 0 ? 0 : 3 + i,
        verified: true,
        engagement: EngagementType.values[i % EngagementType.values.length],
      ),
  ];

  /// A seeded worker by id (`cook-3`), or null for an unknown / withdrawn one (any id containing
  /// `gone` stands for a worker who is no longer visible).
  static WorkerSummary? byId(String id) {
    final i = id.lastIndexOf('-');
    if (i < 0 || id.contains('gone')) return null;
    final n = int.tryParse(id.substring(i + 1));
    final seed = _seed(id.substring(0, i));
    return n == null || n < 1 || n > seed.length ? null : seed[n - 1];
  }

  @override
  Future<WorkerSummary> detail(String id, {CancelToken? cancel}) =>
      mockCall(_state(), () => byId(id) ?? (throw const NotFoundFailure()));

  @override
  Future<WorkerPage> search(
    WorkerQuery query, {
    String? cursor,
    CancelToken? cancel,
  }) => mockCall(_state(), () {
    if (_state().mode == MockMode.empty) return const WorkerPage([], null);
    final f = query.filters;
    bool covers(WorkerSummary w) =>
        f.availability == null ||
        w.availability.any(
          (a) =>
              a.start.compareTo(f.availability!.from) <= 0 &&
              a.end.compareTo(f.availability!.to) >= 0,
        );
    final all = [
      for (final w in _seed(query.category))
        if (covers(w) &&
            (f.language == null || w.languages.contains(f.language)) &&
            (f.minExperienceMonths == null ||
                (w.experienceMonths ?? 0) >= f.minExperienceMonths!) &&
            (f.minRating == null || (w.ratingAverage ?? 0) >= f.minRating!))
          w,
    ];
    if (f.sort == WorkerSort.highestRated) {
      all.sort(
        (a, b) => (b.ratingAverage ?? 0).compareTo(a.ratingAverage ?? 0),
      );
    }
    final start = int.tryParse(cursor ?? '') ?? 0;
    final end = (start + pageSize).clamp(0, all.length);
    return WorkerPage(
      all.sublist(start, end),
      end < all.length ? '$end' : null,
    );
  });
}
