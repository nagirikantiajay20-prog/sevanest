import 'package:dio/dio.dart';
import 'package:sevanest_customer/core/network/guarded.dart';
import 'package:sevanest_customer/features/favourites/domain/favourites.dart';

/// `GET /shortlist`, `PUT|DELETE /shortlist/{workerId}` (Swagger; docs/05 called it /favourites).
class FavouritesRepositoryRemote implements FavouritesRepository {
  FavouritesRepositoryRemote(this._dio);
  final Dio _dio;

  static const pageSize = 20;
  static const _maxSize = 100;

  String _item(String id) => '/shortlist/${Uri.encodeComponent(id)}';

  Future<(List<FavouriteEntry>, int)> _page(int page, int limit) async {
    final res = await guarded(
      () => _dio.get<dynamic>(
        '/shortlist',
        queryParameters: {'page': page, 'limit': limit},
      ),
    );
    final body = res.data;
    final meta = body is Map ? body['meta'] : null;
    return (
      [for (final m in listOf(body)) ?FavouriteEntry.fromJson(m)],
      meta is Map && meta['total'] is num ? (meta['total'] as num).toInt() : 0,
    );
  }

  @override
  Future<FavouritesPage> list({String? cursor}) async {
    final page = int.tryParse(cursor ?? '') ?? 1;
    final (items, total) = await _page(page, pageSize);
    return FavouritesPage(
      items,
      page * pageSize < total ? '${page + 1}' : null,
    );
  }

  @override
  Future<Set<String>> ids() async {
    final (items, _) = await _page(1, _maxSize);
    return {for (final e in items) e.workerId};
  }

  @override
  Future<void> add(String workerId) async {
    await guarded(() => _dio.put<dynamic>(_item(workerId)));
  }

  @override
  Future<void> remove(String workerId) async {
    await guarded(() => _dio.delete<dynamic>(_item(workerId)));
  }
}
