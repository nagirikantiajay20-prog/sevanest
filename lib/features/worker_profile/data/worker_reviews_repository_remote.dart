import 'package:dio/dio.dart';
import 'package:sevanest_customer/core/network/guarded.dart';
import 'package:sevanest_customer/features/worker_profile/domain/worker_review.dart';

/// `GET /search/workers/{workerId}/ratings` (OpenAPI): `{score, comment, createdAt,
/// reviewerFirstName}` per review, newest first, paged by number. A worker who is unknown or no
/// longer visible answers 404 `WORKER_NOT_FOUND`, which the screen shows as unavailable.
class WorkerReviewsRepositoryRemote implements WorkerReviewsRepository {
  const WorkerReviewsRepositoryRemote(this._dio);
  final Dio _dio;

  static const pageSize = 20;

  @override
  Future<ReviewsPage> reviews(String workerId, {String? cursor}) async {
    final page = int.tryParse(cursor ?? '') ?? 1;
    final res = await guarded(
      () => _dio.get<dynamic>(
        '/search/workers/${Uri.encodeComponent(workerId)}/ratings',
        queryParameters: {'page': page, 'limit': pageSize},
      ),
    );
    final body = res.data;
    final meta = body is Map ? body['meta'] : null;
    final total = meta is Map && meta['total'] is num
        ? (meta['total'] as num).toInt()
        : 0;
    return ReviewsPage([
      for (final m in listOf(body))
        if (m['score'] is num && DateTime.tryParse('${m['createdAt']}') != null)
          WorkerReview(
            reviewerFirstName: m['reviewerFirstName'] is String
                ? m['reviewerFirstName'] as String
                : '',
            rating: (m['score'] as num).toDouble(),
            date: DateTime.parse('${m['createdAt']}').toLocal(),
            text: m['comment'] is String && (m['comment'] as String).isNotEmpty
                ? m['comment'] as String
                : null,
          ),
    ], page * pageSize < total ? '${page + 1}' : null);
  }
}
