import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/features/favourites/domain/favourites.dart';
import 'package:sevanest_customer/features/worker_search/data/worker_search_repository_mock.dart';

/// In-memory shortlist behind the mock-API toggle. Newest first, like the backend. A returning
/// customer starts with two workers and one who has since become unavailable.
class FavouritesRepositoryMock implements FavouritesRepository {
  FavouritesRepositoryMock(this._state) {
    if (_state().returningUser) {
      _ids.addAll(['cook-gone-1', 'cook-5', 'cook-2']);
    }
  }
  final MockApiState Function() _state;
  final _ids = <String>[];

  static const pageSize = 20;

  @override
  Future<FavouritesPage> list({String? cursor}) => mockCall(_state(), () {
    if (_state().mode == MockMode.empty) return const FavouritesPage([], null);
    final start = int.tryParse(cursor ?? '') ?? 0;
    final end = (start + pageSize).clamp(0, _ids.length);
    return FavouritesPage([
      for (final id in _ids.sublist(start, end))
        FavouriteEntry(id, WorkerSearchRepositoryMock.byId(id)),
    ], end < _ids.length ? '$end' : null);
  });

  @override
  Future<Set<String>> ids() => mockCall(
    _state(),
    () => _state().mode == MockMode.empty ? <String>{} : _ids.toSet(),
  );

  @override
  Future<void> add(String workerId) => mockCall(_state(), () {
    if (WorkerSearchRepositoryMock.byId(workerId) == null) {
      throw const NotFoundFailure();
    }
    if (!_ids.contains(workerId)) _ids.insert(0, workerId);
  });

  @override
  Future<void> remove(String workerId) =>
      mockCall(_state(), () => _ids.remove(workerId));
}
