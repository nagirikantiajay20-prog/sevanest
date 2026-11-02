import 'package:dio/dio.dart';
import 'package:sevanest_customer/features/interview_trial/domain/interview.dart';
import 'package:sevanest_customer/features/service_discovery/domain/budget.dart';
import 'package:sevanest_customer/features/service_discovery/domain/catalog.dart';
import 'package:sevanest_customer/features/worker_search/domain/worker_search.dart';

/// The backend's booking state model (Swagger `GET /bookings?status=`). Everything the app calls
/// an "interview" or "trial" is a state of one booking. Unknown codes map to [unknown] and render
/// as "Updated".
enum BookingStatus {
  newRequest,
  matched,
  interviewTrialScheduled,
  interviewTrialCompleted,
  pendingPayment,
  confirmed,
  active,
  replacementRequested,
  replaced,
  completed,
  cancelled,
  unknown,
}

BookingStatus bookingStatusFrom(Object? code) =>
    switch (code is String ? code.toUpperCase() : null) {
      'NEW_REQUEST' => BookingStatus.newRequest,
      'MATCHED' => BookingStatus.matched,
      'INTERVIEW_TRIAL_SCHEDULED' => BookingStatus.interviewTrialScheduled,
      'INTERVIEW_TRIAL_COMPLETED' => BookingStatus.interviewTrialCompleted,
      'PENDING_PAYMENT' => BookingStatus.pendingPayment,
      'CONFIRMED' => BookingStatus.confirmed,
      'ACTIVE' => BookingStatus.active,
      'REPLACEMENT_REQUESTED' => BookingStatus.replacementRequested,
      'REPLACED' => BookingStatus.replaced,
      'COMPLETED' => BookingStatus.completed,
      'CANCELLED' || 'CANCELED' => BookingStatus.cancelled,
      _ => BookingStatus.unknown,
    };

/// Past = finished for good. An unknown status stays under "Current" so it is never hidden.
bool bookingIsPast(BookingStatus s) =>
    s == BookingStatus.completed ||
    s == BookingStatus.cancelled ||
    s == BookingStatus.replaced;

/// What the customer can do. The first five are backend transitions
/// (`POST /bookings/{id}/{action}`); the rest are screens in later modules.
enum BookingAction {
  schedule,
  interviewComplete,
  confirmWorker,
  reopenMatching,
  cancel,
  pay,
  viewService,
  rate,
  replace,
  receipt,
  rebook,
}

Set<BookingAction> bookingActionsFrom(Object? raw) => {
  if (raw is List)
    for (final a in raw)
      if (a is String) ?_actionByName(a),
};

BookingAction? _actionByName(String a) =>
    switch (a.toLowerCase().replaceAll('_', '-')) {
      'schedule' || 'reschedule' => BookingAction.schedule,
      'interview-complete' => BookingAction.interviewComplete,
      'confirm-worker' || 'confirm' => BookingAction.confirmWorker,
      'reopen-matching' || 'decline' => BookingAction.reopenMatching,
      'cancel' => BookingAction.cancel,
      'pay' => BookingAction.pay,
      'view-service' => BookingAction.viewService,
      'rate' => BookingAction.rate,
      'replace' => BookingAction.replace,
      'receipt' => BookingAction.receipt,
      'rebook' => BookingAction.rebook,
      _ => null,
    };

/// Used only when a response carries no `allowedActions` list at all (mock data, old fixtures). A
/// backend-supplied list always wins, even an empty one (a rated or REPLACED booking has no `rate`).
Set<BookingAction> derivedBookingActions(BookingStatus s) => switch (s) {
  BookingStatus.newRequest => {BookingAction.cancel},
  BookingStatus.matched => {BookingAction.schedule, BookingAction.cancel},
  BookingStatus.interviewTrialScheduled => {
    BookingAction.interviewComplete,
    BookingAction.schedule,
    BookingAction.cancel,
  },
  BookingStatus.interviewTrialCompleted => {
    BookingAction.confirmWorker,
    BookingAction.reopenMatching,
    BookingAction.cancel,
  },
  BookingStatus.pendingPayment => {BookingAction.pay, BookingAction.cancel},
  BookingStatus.confirmed => {BookingAction.cancel, BookingAction.receipt},
  BookingStatus.active => {
    BookingAction.viewService,
    BookingAction.replace,
    BookingAction.receipt,
  },
  BookingStatus.replacementRequested => {BookingAction.viewService},
  BookingStatus.completed => {BookingAction.rate, BookingAction.receipt},
  BookingStatus.replaced ||
  BookingStatus.cancelled ||
  BookingStatus.unknown => const {},
};

/// `worker` on a customer booking (from the interview stage on): name, initials and a short-lived
/// photo link. No phone or address. The image is cached by [cacheKey], not by its expiring URL.
class WorkerIdentity {
  const WorkerIdentity({
    required this.displayName,
    this.initials,
    this.photoUrl,
    this.cacheKey,
    this.verified = false,
  });

  final String displayName;
  final String? initials;
  final String? photoUrl;
  final String? cacheKey;

  /// The backend's real flag (false for a blacklisted worker); the badge shows only when true.
  final bool verified;

  static WorkerIdentity? fromJson(Object? j) {
    if (j is! Map) return null;
    final name = _s(j['displayName']) ?? _s(j['name']);
    if (name == null) return null;
    final photo = j['photo'];
    return WorkerIdentity(
      displayName: name,
      verified: j['verified'] == true,
      initials: _s(j['initials']),
      photoUrl: _s(j['photoUrl']) ?? (photo is Map ? _s(photo['url']) : null),
      cacheKey: photo is Map ? _s(photo['cacheKey']) : null,
    );
  }
}

class BookingTimelineEntry {
  const BookingTimelineEntry(this.status, this.at, [this.note]);
  final BookingStatus status;
  final DateTime? at;
  final String? note;
}

class Booking {
  const Booking({
    required this.id,
    required this.status,
    this.categoryCode,
    this.categoryName,
    this.engagement,
    this.workerId,
    this.worker,
    this.identity,
    this.ratingScore,
    this.ratingReview,
    this.areaName,
    this.addressId,
    this.startDate,
    this.scheduledAt,
    this.scheduleType,
    this.budgetMin,
    this.budgetMax,
    this.budgetPeriod,
    this.note,
    this.timeline = const [],
    this.actions = const {},
    this.paymentId,
    this.previousBookingId,
    this.createdAt,
  });

  final String id;
  final BookingStatus status;
  final String? categoryCode;
  final String? categoryName;
  final EngagementType? engagement;
  final String? workerId;
  final WorkerSummary? worker;
  final WorkerIdentity? identity;

  /// My rating of this booking (`rating` on every customer booking), null when not rated.
  final int? ratingScore;
  final String? ratingReview;
  final String? areaName;
  final String? addressId;
  final DateTime? startDate;

  /// Local date and time of the interview / trial.
  final DateTime? scheduledAt;
  final InterviewType? scheduleType;

  /// Whole rupees (the API speaks paise).
  final int? budgetMin;
  final int? budgetMax;
  final BudgetPeriod? budgetPeriod;
  final String? note;
  final List<BookingTimelineEntry> timeline;
  final Set<BookingAction> actions;
  final String? paymentId;
  final String? previousBookingId;
  final DateTime? createdAt;

  /// Short reference shown to the customer ("SN-2048" style, from the id).
  String get reference {
    final tail = id.length > 6 ? id.substring(id.length - 6) : id;
    return tail.toUpperCase();
  }

  /// Tolerant parse: the Swagger publishes no response schema yet.
  static Booking? fromJson(Object? json) {
    if (json is! Map) return null;
    final j = json['data'] is Map ? json['data'] as Map : json;
    final id = j['id'];
    if (id is! String || id.isEmpty) return null;
    final status = bookingStatusFrom(j['status']);
    final cat = j['category'];
    final area = j['area'] ?? j['serviceArea'];
    final w = j['worker'];
    final at = _date(j['scheduledAt']);
    final allowed = j['allowedActions'];
    final rating = j['rating'];
    return Booking(
      id: id,
      status: status,
      categoryCode: cat is Map
          ? _s(cat['code'])
          : _s(cat) ?? _s(j['categoryCode']),
      categoryName: cat is Map ? _s(cat['name']) : _s(j['categoryName']),
      engagement: _engagement(j['engagement']),
      workerId: _s(j['workerId']) ?? (w is Map ? _s(w['workerId']) : null),
      worker: WorkerSummary.fromJson(w),
      identity: WorkerIdentity.fromJson(w),
      ratingScore: rating is Map && rating['score'] is num
          ? (rating['score'] as num).toInt()
          : null,
      ratingReview: rating is Map ? _s(rating['review']) : null,
      areaName: area is Map ? _s(area['name']) : _s(j['areaName']),
      addressId: _s(j['addressId']),
      startDate: _date(j['startDate'], dateOnly: true),
      scheduledAt: at,
      scheduleType: switch ('${j['scheduleType']}'.toUpperCase()) {
        'TRIAL' => InterviewType.trial,
        'INTERVIEW' => InterviewType.interview,
        _ => null,
      },
      budgetMin: _minor(j['budgetMinMinor']),
      budgetMax: _minor(j['budgetMaxMinor']),
      budgetPeriod: switch ('${j['budgetPeriod']}'.toUpperCase()) {
        'HOUR' => BudgetPeriod.hourly,
        'MONTH' => BudgetPeriod.monthly,
        _ => null,
      },
      note: _s(j['requirementNote']),
      timeline: _timeline(j['timeline'] ?? j['events'] ?? j['history']),
      actions: allowed is List
          ? bookingActionsFrom(allowed)
          : derivedBookingActions(status),
      paymentId: _s(j['paymentId']),
      previousBookingId: _s(
        j['replacesBookingId'] ?? j['previousBookingId'] ?? j['replacedFromId'],
      ),
      createdAt: _date(j['createdAt']),
    );
  }
}

List<BookingTimelineEntry> _timeline(Object? raw) => [
  if (raw is List)
    for (final e in raw)
      if (e is Map)
        BookingTimelineEntry(
          // The deployed `TimelineEntry` is `{from, to, by, note, at}`: the stage reached is `to`.
          bookingStatusFrom(
            e['to'] ?? e['status'] ?? e['toStatus'] ?? e['type'],
          ),
          _date(e['at'] ?? e['createdAt'] ?? e['occurredAt']),
          _s(e['note'] ?? e['reason']),
        ),
];

String? _s(Object? v) => v is String && v.isNotEmpty ? v : null;

int? _minor(Object? v) => v is num ? (v / 100).round() : null;

DateTime? _date(Object? v, {bool dateOnly = false}) {
  if (v is! String) return null;
  final d = DateTime.tryParse(v);
  if (d == null) return null;
  final local = d.isUtc ? d.toLocal() : d;
  return dateOnly ? DateTime(local.year, local.month, local.day) : local;
}

EngagementType? _engagement(Object? c) => EngagementType.fromCode(c);

/// `POST /bookings` body (Swagger `CreateBookingDto`). Money is sent in paise.
class BookingRequest {
  const BookingRequest({
    required this.category,
    required this.areaId,
    required this.addressId,
    required this.startDate,
    this.engagement,
    this.availableFrom,
    this.availableTo,
    this.workerId,
    this.budgetMin,
    this.budgetMax,
    this.budgetPeriod,
    this.note,
  });

  final String category;
  final String areaId;
  final String addressId;
  final DateTime startDate;
  final EngagementType? engagement;
  final String? availableFrom;
  final String? availableTo;
  final String? workerId;
  final int? budgetMin;
  final int? budgetMax;
  final BudgetPeriod? budgetPeriod;
  final String? note;
}

class BookingPage {
  const BookingPage(this.items, this.nextCursor);
  final List<Booking> items;
  final String? nextCursor;
}

/// `/bookings` of the deployed backend. Actions return the fresh booking.
abstract interface class BookingRepository {
  /// The key is generated once per form; repeating it returns the first booking.
  Future<Booking> create(
    BookingRequest request, {
    required String idempotencyKey,
  });
  Future<BookingPage> list({String? cursor});
  Future<Booking> get(String id, {CancelToken? cancel});

  /// `schedule`: an interview or trial at a future date and time.
  Future<Booking> schedule(String id, InterviewType type, DateTime at);

  /// `interview-complete`.
  Future<Booking> interviewComplete(String id, {String? note});

  /// `confirm-worker`: moves the booking to PENDING_PAYMENT.
  Future<Booking> confirmWorker(String id, DateTime startDate);

  /// `reopen-matching`: "not a fit", back to finding a worker.
  Future<Booking> reopenMatching(String id);

  /// `cancel`: the reason is required.
  Future<Booking> cancel(String id, String reason);

  /// `POST /bookings/rebook`: a new booking for the same worker. Offered only with `rebook`.
  Future<Booking> rebook(String bookingId, {DateTime? startDate});

  /// `GET /customers/me/booking-history`, newest first.
  Future<BookingPage> history(HistoryFilter filter, {String? cursor});

  /// `GET /customers/me/booking-history/summary` for the same filters.
  Future<HistorySummary> historySummary(HistoryFilter filter);
}

/// Filters of the history screen; null / empty means "any".
class HistoryFilter {
  const HistoryFilter({
    this.year,
    this.category,
    this.search = '',
    this.status,
  });

  final int? year;
  final String? category;
  final String search;
  final BookingStatus? status;

  HistoryFilter copyWith({
    int? Function()? year,
    String? Function()? category,
    String? search,
    BookingStatus? Function()? status,
  }) => HistoryFilter(
    year: year != null ? year() : this.year,
    category: category != null ? category() : this.category,
    search: search ?? this.search,
    status: status != null ? status() : this.status,
  );

  Map<String, Object> get query => {
    'year': ?year,
    'category': ?category,
    if (search.trim().isNotEmpty) 'search': search.trim(),
    if (status != null) 'status': bookingStatusCode(status!),
  };

  @override
  bool operator ==(Object other) =>
      other is HistoryFilter &&
      other.year == year &&
      other.category == category &&
      other.search == search &&
      other.status == status;

  @override
  int get hashCode => Object.hash(year, category, search, status);
}

/// Wire code of a status, for the `status` filter.
String bookingStatusCode(BookingStatus s) => switch (s) {
  BookingStatus.newRequest => 'NEW_REQUEST',
  BookingStatus.matched => 'MATCHED',
  BookingStatus.interviewTrialScheduled => 'INTERVIEW_TRIAL_SCHEDULED',
  BookingStatus.interviewTrialCompleted => 'INTERVIEW_TRIAL_COMPLETED',
  BookingStatus.pendingPayment => 'PENDING_PAYMENT',
  BookingStatus.confirmed => 'CONFIRMED',
  BookingStatus.active => 'ACTIVE',
  BookingStatus.replacementRequested => 'REPLACEMENT_REQUESTED',
  BookingStatus.replaced => 'REPLACED',
  BookingStatus.completed => 'COMPLETED',
  BookingStatus.cancelled => 'CANCELLED',
  BookingStatus.unknown => 'UNKNOWN',
};

/// `{totalServices, distinctWorkers, totalSpentMinor, currency}`. "Spent" includes money still held
/// (Q-104, open), so the screen only shows the number the server sends.
class HistorySummary {
  const HistorySummary({
    required this.totalServices,
    required this.distinctWorkers,
    required this.totalSpent,
    this.currency = 'INR',
  });

  final int totalServices;
  final int distinctWorkers;

  /// Whole rupees (the API speaks paise).
  final int totalSpent;
  final String currency;

  static HistorySummary? fromJson(Object? json) {
    if (json is! Map) return null;
    final j = json['data'] is Map ? json['data'] as Map : json;
    int n(Object? v) => v is num ? v.toInt() : 0;
    return HistorySummary(
      totalServices: n(j['totalServices']),
      distinctWorkers: n(j['distinctWorkers']),
      totalSpent: (n(j['totalSpentMinor']) / 100).round(),
      currency: _s(j['currency']) ?? 'INR',
    );
  }
}
