import 'package:dio/dio.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/network/guarded.dart';
import 'package:sevanest_customer/features/booking/data/booking_repository_remote.dart';
import 'package:sevanest_customer/features/booking/domain/booking.dart';
import 'package:sevanest_customer/features/interview_trial/data/interview_repository_over_bookings.dart';
import 'package:sevanest_customer/features/interview_trial/domain/interview.dart';

/// `/interviews` (OpenAPI 2026-10-13). An interview belongs to a booking that already names the
/// worker, so [create] makes the booking first and then the interview. The interview carries no
/// worker or requirement, so those come from its booking; "confirm" and "not a fit" are booking
/// actions that open once the interview is completed.
class InterviewRepositoryRemote extends InterviewRepositoryOverBookings {
  InterviewRepositoryRemote(
    this._dio,
    super.bookings,
    super.workers, {
    required super.areaIdFor,
    super.now,
  });

  final Dio _dio;

  static const pageSize = 20;

  String _item(String id, [String suffix = '']) =>
      '/interviews/${Uri.encodeComponent(id)}$suffix';

  Interview _parse(Object? body) =>
      Interview.fromJson(body) ?? (throw const UnknownFailure());

  /// A fresh key per user action: the backend needs one on every write.
  static String _key(String what) =>
      'iv-$what-${DateTime.now().microsecondsSinceEpoch}';

  Future<Interview> _post(
    String path,
    Map<String, Object?> body, {
    required String key,
  }) async {
    final res = await guarded(
      () => _dio.post<dynamic>(
        path,
        options: Options(headers: {'Idempotency-Key': key}),
        data: body,
      ),
    );
    return _enrich(_parse(res.data));
  }

  /// Adds worker, requirement and the booking-level actions. The interview itself is already
  /// valid, so a failed booking read only leaves those out.
  Future<Interview> _enrich(Interview iv) async {
    if (iv.bookingId.isEmpty) return iv;
    try {
      final b = await bookings.get(iv.bookingId);
      final decide =
          iv.status == InterviewStatus.completed &&
          b.status == BookingStatus.interviewTrialCompleted;
      return iv.copyWith(
        workerId: b.workerId,
        requirement: InterviewRepositoryOverBookings.requirementOf(b),
        actions: {
          ...iv.actions,
          if (decide) ...[InterviewAction.confirm, InterviewAction.decline],
        },
      );
    } on Object {
      return iv;
    }
  }

  static String _iso(DateTime date, String slot) =>
      istInstant(date, slot).toIso8601String();

  /// The booking made for a form, by its key: a retry after the interview step failed reuses it
  /// instead of making (and being refused) a second booking for the same worker and service.
  final _bookingByKey = <String, Booking>{};

  @override
  Future<Interview> create(
    InterviewRequest r, {
    required String idempotencyKey,
  }) async {
    final booking = _bookingByKey[idempotencyKey] ??= await createBooking(
      r,
      '$idempotencyKey-booking',
    );
    final body = {
      'bookingId': booking.id,
      'type': r.type == InterviewType.trial ? 'TRIAL' : 'INTERVIEW',
      'preferredAt': _iso(r.date, r.slot),
      if (r.note != null && r.note!.isNotEmpty) 'note': r.note,
    };
    // The key follows the content: the same request retried is deduplicated, while a changed
    // time or type is a new request and must not collide with the failed one.
    return _post(
      '/interviews',
      body,
      key: '$idempotencyKey-interview-${body.toString().hashCode}',
    );
  }

  @override
  Future<Interview> reschedule(
    String id,
    DateTime date,
    String slot, {
    required String idempotencyKey,
  }) => _post(_item(id, '/reschedule'), {
    'preferredAt': _iso(date, slot),
  }, key: idempotencyKey);

  @override
  Future<InterviewPage> list({String? cursor}) async {
    final page = int.tryParse(cursor ?? '') ?? 1;
    final res = await guarded(
      () => _dio.get<dynamic>(
        '/interviews',
        queryParameters: {'page': page, 'limit': pageSize},
      ),
    );
    final body = res.data;
    final meta = body is Map ? body['meta'] : null;
    final total = meta is Map && meta['total'] is num
        ? (meta['total'] as num).toInt()
        : 0;
    return InterviewPage([
      for (final m in listOf(body)) ?Interview.fromJson(m),
    ], page * pageSize < total ? '${page + 1}' : null);
  }

  /// `GET /bookings/{id}/interviews` (oldest first, a bare list).
  @override
  Future<String?> interviewIdFor(
    String bookingId, {
    bool openOnly = false,
  }) async {
    final res = await guarded(
      () => _dio.get<dynamic>(
        '/bookings/${Uri.encodeComponent(bookingId)}/interviews',
      ),
    );
    final all = [for (final m in listOf(res.data)) ?Interview.fromJson(m)];
    bool open(Interview i) =>
        i.status == InterviewStatus.requested ||
        i.status == InterviewStatus.scheduled ||
        i.status == InterviewStatus.rescheduleProposed;
    final pick =
        all.where(open).lastOrNull ?? (openOnly ? null : all.lastOrNull);
    return pick?.id;
  }

  @override
  Future<Interview> get(String id, {CancelToken? cancel}) async {
    final res = await guarded(
      () => _dio.get<dynamic>(_item(id), cancelToken: cancel),
    );
    return _enrich(_parse(res.data));
  }

  @override
  Future<Interview> cancel(String id, {String? reason}) => _post(
    _item(id, '/cancel'),
    {'reason': reason ?? 'Cancelled by customer'},
    key: _key('cancel'),
  );

  @override
  Future<Interview> complete(String id) => _post(_item(id, '/complete'), {
    'outcomeNote': 'The interview took place',
  }, key: _key('complete'));

  @override
  Future<Interview> answerProposal(String id, {required bool accept}) => _post(
    _item(id, accept ? '/accept-proposal' : '/reject-proposal'),
    {},
    key: _key('proposal'),
  );

  /// "Not a fit": the booking goes back to matching. There is no interview route for it.
  @override
  Future<Interview> decline(String id) async {
    final iv = await get(id);
    await bookings.reopenMatching(iv.bookingId);
    return get(id);
  }

  @override
  Future<List<InterviewSlot>> slots(String workerId, DateTime date) async {
    final d = BookingRepositoryRemote.day(date);
    final res = await guarded(
      () => _dio.get<dynamic>(
        '/search/workers/${Uri.encodeComponent(workerId)}/slots',
        queryParameters: {'date': d},
      ),
    );
    final body = res.data;
    final raw = body is Map ? body['slots'] : null;
    final len = body is Map ? body['slotMinutes'] : null;
    final minutes = len is num && len > 0 ? len.toInt() : 60;
    return [
      if (raw is List)
        for (final s in raw)
          if (s is String && parseSlot(s) != null)
            InterviewSlot(s, minutes: minutes),
    ];
  }
}
