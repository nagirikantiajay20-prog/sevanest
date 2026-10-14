import 'package:dio/dio.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/network/guarded.dart';
import 'package:sevanest_customer/features/active_service/domain/attendance.dart';

/// `GET /attendance/bookings/{id}` and `/summary` (Swagger 2026-10-13, customer token).
class AttendanceRepositoryRemote implements AttendanceRepository {
  AttendanceRepositoryRemote(this._dio);
  final Dio _dio;

  static const pageSize = 20;

  String _path(String id, [String suffix = '']) =>
      '/attendance/bookings/${Uri.encodeComponent(id)}$suffix';

  @override
  Future<AttendancePage> page(String bookingId, {String? cursor}) async {
    final page = int.tryParse(cursor ?? '') ?? 1;
    final res = await guarded(
      () => _dio.get<dynamic>(
        _path(bookingId),
        queryParameters: {'page': page, 'limit': pageSize},
      ),
    );
    final body = res.data;
    final meta = body is Map ? body['meta'] : null;
    final total = meta is Map && meta['total'] is num
        ? (meta['total'] as num).toInt()
        : 0;
    return AttendancePage([
      for (final m in listOf(body)) ?AttendanceEntry.fromJson(m),
    ], page * pageSize < total ? '${page + 1}' : null);
  }

  @override
  Future<AttendanceSummary> summary(String bookingId, String month) async {
    final res = await guarded(
      () => _dio.get<dynamic>(
        _path(bookingId, '/summary'),
        queryParameters: {'month': month},
      ),
    );
    return AttendanceSummary.fromJson(res.data) ??
        (throw const UnknownFailure());
  }
}
