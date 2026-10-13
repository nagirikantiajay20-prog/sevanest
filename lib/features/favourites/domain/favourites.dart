import 'package:sevanest_customer/features/worker_search/domain/worker_search.dart';

/// One shortlist row. [worker] is null when the worker is no longer visible to customers (the
/// backend then returns only the id): shown as "Unavailable" with remove as the only action.
class FavouriteEntry {
  const FavouriteEntry(this.workerId, this.worker);
  final String workerId;
  final WorkerSummary? worker;
  bool get available => worker != null;

  /// Tolerates the shapes the card can arrive in (inline, `card`, or `worker`).
  static FavouriteEntry? fromJson(Object? j) {
    if (j is! Map) return null;
    final card =
        j['card'] ?? j['worker'] ?? (j['categories'] != null ? j : null);
    final worker = j['available'] == false
        ? null
        : WorkerSummary.fromJson(card);
    final id = j['workerId'] ?? worker?.id;
    return id is String && id.isNotEmpty ? FavouriteEntry(id, worker) : null;
  }
}

class FavouritesPage {
  const FavouritesPage(this.items, this.nextCursor);
  final List<FavouriteEntry> items;
  final String? nextCursor;
}

abstract interface class FavouritesRepository {
  Future<FavouritesPage> list({String? cursor});

  /// Every shortlisted id (the backend caps the shortlist at 100), for the hearts.
  Future<Set<String>> ids();

  /// Idempotent: adding twice or removing twice is safe.
  Future<void> add(String workerId);
  Future<void> remove(String workerId);
}
