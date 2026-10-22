import 'package:dio/dio.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/network/guarded.dart';
import 'package:sevanest_customer/features/ratings/domain/rating.dart';

class RatingRepositoryRemote implements RatingRepository {
  RatingRepositoryRemote(this._dio);
  final Dio _dio;

  static const pageSize = 50;

  @override
  Future<Rating?> forBooking(String bookingId) async {
    try {
      final res = await guarded(
        () => _dio.get<dynamic>(
          '/ratings/bookings/${Uri.encodeComponent(bookingId)}',
        ),
      );
      return Rating.fromJson(res.data);
    } on NotFoundFailure {
      return null;
    }
  }

  @override
  Future<RatingPage> mine({String? cursor}) async {
    final page = int.tryParse(cursor ?? '') ?? 1;
    final res = await guarded(
      () => _dio.get<dynamic>(
        '/ratings',
        queryParameters: {'page': page, 'limit': pageSize},
      ),
    );
    final body = res.data;
    final meta = body is Map ? body['meta'] : null;
    final total = meta is Map && meta['total'] is num
        ? (meta['total'] as num).toInt()
        : 0;
    return RatingPage([
      for (final m in listOf(body)) ?Rating.fromJson(m),
    ], page * pageSize < total ? '${page + 1}' : null);
  }

  @override
  Future<Rating> submit(
    String bookingId, {
    required int score,
    String? review,
    List<String> tags = const [],
    required String idempotencyKey,
  }) async {
    final res = await guarded(
      () => _dio.post<dynamic>(
        '/ratings',
        options: Options(headers: {'Idempotency-Key': idempotencyKey}),
        data: {
          'bookingId': bookingId,
          'score': score,
          if (review != null && review.trim().isNotEmpty)
            'review': review.trim(),
          if (tags.isNotEmpty) 'tags': tags,
        },
      ),
    );
    return Rating.fromJson(res.data) ?? (throw const UnknownFailure());
  }
}
