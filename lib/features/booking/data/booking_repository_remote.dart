import 'package:dio/dio.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/network/guarded.dart';
import 'package:sevanest_customer/features/booking/domain/booking.dart';
import 'package:sevanest_customer/features/interview_trial/domain/interview.dart';
import 'package:sevanest_customer/features/service_discovery/domain/budget.dart';
import 'package:sevanest_customer/features/worker_search/data/worker_search_repository_remote.dart';

/// `/bookings` (Swagger, 2026-10-12). Interviews and trials are states of the same booking, so
/// `POST /bookings/{id}/schedule` etc. are the only interview calls the backend has.
class BookingRepositoryRemote implements BookingRepository {
  BookingRepositoryRemote(this._dio);
  final Dio _dio;

  static const pageSize = 20;

  String _item(String id, [String suffix = '']) =>
      '/bookings/${Uri.encodeComponent(id)}$suffix';

  static String day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Booking _parse(Object? body) =>
      Booking.fromJson(body) ?? (throw const UnknownFailure());

  @override
  Future<Booking> create(
    BookingRequest r, {
    required String idempotencyKey,
  }) async {
    final res = await guarded(
      () => _dio.post<dynamic>(
        '/bookings',
        options: Options(headers: {'Idempotency-Key': idempotencyKey}),
        data: {
          'category': r.category,
          'areaId': r.areaId,
          'addressId': r.addressId,
          'startDate': day(r.startDate),
          if (r.engagement != null) 'engagement': engagementCode(r.engagement!),
          'availableFrom': ?r.availableFrom,
          'availableTo': ?r.availableTo,
          'workerId': ?r.workerId,
          if (r.budgetMin != null) 'budgetMinMinor': r.budgetMin! * 100,
          if (r.budgetMax != null) 'budgetMaxMinor': r.budgetMax! * 100,
          if (r.budgetMin != null && r.budgetPeriod != null)
            'budgetPeriod': r.budgetPeriod == BudgetPeriod.hourly
                ? 'HOUR'
                : 'MONTH',
          if (r.note != null && r.note!.isNotEmpty) 'requirementNote': r.note,
        },
      ),
    );
    return _parse(res.data);
  }

  @override
  Future<BookingPage> list({String? cursor}) async {
    final page = int.tryParse(cursor ?? '') ?? 1;
    final res = await guarded(
      () => _dio.get<dynamic>(
        '/bookings',
        queryParameters: {'page': page, 'limit': pageSize},
      ),
    );
    final body = res.data;
    final meta = body is Map ? body['meta'] : null;
    final total = meta is Map && meta['total'] is num
        ? (meta['total'] as num).toInt()
        : 0;
    return BookingPage([
      for (final m in listOf(body)) ?Booking.fromJson(m),
    ], page * pageSize < total ? '${page + 1}' : null);
  }

  @override
  Future<Booking> get(String id, {CancelToken? cancel}) async {
    final res = await guarded(
      () => _dio.get<dynamic>(_item(id), cancelToken: cancel),
    );
    return _parse(res.data);
  }

  /// The action answers with the booking (or nothing); either way we re-read it so the screen
  /// shows what the server now holds.
  Future<Booking> _act(
    String id,
    String action,
    Map<String, Object?> body,
  ) async {
    await guarded(() => _dio.post<dynamic>(_item(id, '/$action'), data: body));
    return get(id);
  }

  @override
  Future<Booking> schedule(String id, InterviewType type, DateTime at) =>
      _act(id, 'schedule', {
        'scheduleType': type == InterviewType.trial ? 'TRIAL' : 'INTERVIEW',
        'scheduledAt': at.toUtc().toIso8601String(),
      });

  @override
  Future<Booking> interviewComplete(String id, {String? note}) =>
      // The backend requires `outcomeNote` (400 without it, seen live 2026-10-14).
      _act(id, 'interview-complete', {
        'outcomeNote': note ?? 'The interview took place',
      });

  @override
  Future<Booking> confirmWorker(String id, DateTime startDate) =>
      _act(id, 'confirm-worker', {'startDate': day(startDate)});

  @override
  Future<Booking> reopenMatching(String id) => _act(id, 'reopen-matching', {});

  @override
  Future<Booking> cancel(String id, String reason) =>
      _act(id, 'cancel', {'reason': reason});
}
