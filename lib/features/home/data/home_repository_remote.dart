import 'package:dio/dio.dart';
import 'package:sevanest_customer/core/network/guarded.dart';
import 'package:sevanest_customer/features/booking/domain/booking.dart';
import 'package:sevanest_customer/features/home/domain/home_data.dart';
import 'package:sevanest_customer/features/interview_trial/domain/interview.dart';
import 'package:sevanest_customer/features/service_discovery/domain/catalog.dart';
import 'package:sevanest_customer/features/worker_search/domain/worker_search.dart';

/// `GET /customers/me/home`: `{activeBooking, upcomingInterview, unreadNotifications,
/// shortlistPreview[5], shortlistTotal}` in one call. Workers carry a display name ("Lakshmi D.");
/// the service stands in only when a name is missing. Sections the backend leaves null are hidden
/// by Home.
///
/// Home sends `ETag` + `Cache-Control: private, no-cache`. The last body and validator are kept in
/// memory and re-sent as `If-None-Match`; a 304 reuses that body. The validator also changes when
/// the signed photo links are about to expire, so a 304 never returns dead links.
class HomeRepositoryRemote implements HomeRepository {
  HomeRepositoryRemote(this._dio);
  final Dio _dio;

  String? _etag;
  HomeData? _last;

  @override
  Future<HomeData> fetch() async {
    final last = _last;
    final etag = _etag;
    final res = await guarded(
      () => _dio.get<dynamic>(
        '/customers/me/home',
        options: Options(
          headers: {if (last != null && etag != null) 'If-None-Match': etag},
          validateStatus: (s) => s != null && (s == 304 || s < 300),
        ),
      ),
    );
    if (res.statusCode == 304 && last != null) return last;
    final j = res.data is Map<String, dynamic>
        ? res.data as Map<String, dynamic>
        : const <String, dynamic>{};
    final booking = Booking.fromJson(j['activeBooking']);
    final interview = Interview.fromJson(j['upcomingInterview']);
    final unread = j['unreadNotifications'];
    final data = HomeData(
      activeBooking: booking == null ? null : _summary(booking),
      upcomingInterview: interview == null || interview.date == null
          ? null
          : _upcoming(
              interview,
              booking?.id == interview.bookingId ? booking : null,
              WorkerIdentity.fromJson(
                (j['upcomingInterview'] as Map)['worker'],
              ),
            ),
      shortlist: [
        if (j['shortlistPreview'] is List)
          for (final e in j['shortlistPreview'] as List)
            if (e is Map && e['available'] != false)
              ?_preview(WorkerSummary.fromJson(e['worker'])),
      ],
      unreadCount: unread is num ? unread.toInt() : 0,
    );
    _last = data;
    _etag = res.headers.value('etag');
    return data;
  }

  static ActiveBookingSummary _summary(Booking b) {
    final service = b.categoryName ?? b.categoryCode ?? 'Service';
    return ActiveBookingSummary(
      id: b.id,
      reference: b.reference,
      workerName: b.identity?.displayName ?? service,
      verified: b.identity?.verified ?? false,
      service: service,
      engagement: b.engagement == null ? '' : _engagement(b.engagement!),
      startLabel: b.startDate == null ? '' : _from(b.startDate!),
      stage: switch (b.status) {
        BookingStatus.interviewTrialScheduled ||
        BookingStatus.interviewTrialCompleted => BookingStage.trial,
        BookingStatus.active ||
        BookingStatus.replacementRequested => BookingStage.active,
        _ => BookingStage.matched,
      },
    );
  }

  static UpcomingInterview _upcoming(
    Interview i,
    Booking? b,
    WorkerIdentity? worker,
  ) {
    final d = i.date!;
    final m = i.slotMinutes ?? 0;
    final at = DateTime(d.year, d.month, d.day, m ~/ 60, m % 60);
    return UpcomingInterview(
      id: i.id,
      workerName:
          worker?.displayName ??
          b?.identity?.displayName ??
          b?.categoryName ??
          'the worker',
      startsAt: at,
      isTrialVisit: i.type == InterviewType.trial,
    );
  }

  static ShortlistPreview? _preview(WorkerSummary? w) {
    if (w == null) return null;
    final category = w.categories.firstOrNull ?? 'Worker';
    return ShortlistPreview(
      workerId: w.id,
      name: w.name ?? category,
      category: w.categories.firstOrNull,
      service: w.engagement == null ? '' : _engagement(w.engagement!),
      photoUrl: w.photoUrl,
      ratingAverage: w.hasRating ? w.ratingAverage : null,
      experienceMonths: w.experienceMonths,
      verified: w.verified,
    );
  }

  static String _engagement(EngagementType e) => switch (e) {
    EngagementType.fullTime => 'Full-time',
    EngagementType.partTime => 'Part-time',
    EngagementType.daily => 'Daily',
    EngagementType.hourly => 'Hourly',
    EngagementType.liveIn => 'Live-in',
    EngagementType.shift => 'Shift',
    EngagementType.oneTime => 'One-time',
    EngagementType.monthly => 'Monthly',
  };

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String _from(DateTime d) => 'From ${d.day} ${_months[d.month - 1]}';
}
