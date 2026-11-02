enum BookingStage { matched, trial, active }

class ActiveBookingSummary {
  const ActiveBookingSummary({
    required this.id,
    required this.reference,
    required this.workerName,
    required this.service,
    required this.engagement,
    required this.startLabel,
    required this.stage,
    this.verified = true,
    this.photoUrl,
  });

  final String id;
  final String reference;
  final String workerName;
  final String service;
  final String engagement;
  final String startLabel;
  final BookingStage stage;
  final bool verified;

  /// Short-lived link: shown, never persisted.
  final String? photoUrl;

  String get initials => workerName
      .split(' ')
      .where((p) => p.isNotEmpty)
      .take(2)
      .map((p) => p[0].toUpperCase())
      .join();

  Map<String, Object?> toJson() => {
    'id': id,
    'reference': reference,
    'workerName': workerName,
    'service': service,
    'engagement': engagement,
    'startLabel': startLabel,
    'stage': stage.name,
    'verified': verified,
  };

  factory ActiveBookingSummary.fromJson(Map<String, dynamic> j) =>
      ActiveBookingSummary(
        id: j['id'] as String,
        reference: j['reference'] as String,
        workerName: j['workerName'] as String,
        service: j['service'] as String,
        engagement: j['engagement'] as String,
        startLabel: j['startLabel'] as String,
        stage: BookingStage.values.byName(j['stage'] as String),
        verified: j['verified'] as bool? ?? true,
      );
}

class UpcomingInterview {
  const UpcomingInterview({
    required this.id,
    required this.workerName,
    required this.startsAt,
    this.isTrialVisit = false,
  });

  final String id;
  final String workerName;
  final DateTime startsAt;
  final bool isTrialVisit;

  Map<String, Object?> toJson() => {
    'id': id,
    'workerName': workerName,
    'startsAt': startsAt.toIso8601String(),
    'isTrialVisit': isTrialVisit,
  };

  factory UpcomingInterview.fromJson(Map<String, dynamic> j) =>
      UpcomingInterview(
        id: j['id'] as String,
        workerName: j['workerName'] as String,
        startsAt: DateTime.parse(j['startsAt'] as String),
        isTrialVisit: j['isTrialVisit'] as bool? ?? false,
      );
}

class ShortlistPreview {
  const ShortlistPreview({
    required this.workerId,
    required this.name,
    required this.service,
    this.category,
    this.photoUrl,
    this.ratingAverage,
    this.experienceMonths,
    this.verified = false,
  });

  final String workerId;

  /// Display name ("Lakshmi D."), or the category when the backend sent none.
  final String name;
  final String service;

  /// The worker's first category; picks the fallback picture when there is no photo.
  final String? category;

  /// Short-lived link: shown, never persisted in the offline cache.
  final String? photoUrl;
  final double? ratingAverage;
  final int? experienceMonths;
  final bool verified;

  Map<String, Object?> toJson() => {
    'workerId': workerId,
    'name': name,
    'service': service,
    'category': category,
    'ratingAverage': ratingAverage,
    'experienceMonths': experienceMonths,
    'verified': verified,
  };

  factory ShortlistPreview.fromJson(Map<String, dynamic> j) => ShortlistPreview(
    workerId: j['workerId'] as String,
    name: j['name'] as String,
    service: j['service'] as String,
    category: j['category'] as String?,
    ratingAverage: (j['ratingAverage'] as num?)?.toDouble(),
    experienceMonths: (j['experienceMonths'] as num?)?.toInt(),
    verified: j['verified'] as bool? ?? false,
  );
}

/// Backend `todayAttendance.status`. Unknown values fall back to [notArrived].
enum HomeAttendanceStatus {
  arrived,
  notArrived,
  absent,
  leave,
  exception;

  static HomeAttendanceStatus parse(Object? v) => switch (v) {
    'ARRIVED' => arrived,
    'ABSENT' => absent,
    'LEAVE' => leave,
    'EXCEPTION' => exception,
    _ => notArrived,
  };
}

/// `todayAttendance`: the customer's newest ACTIVE booking today. Never cached offline (stale
/// attendance would mislead), so it has no JSON form.
class TodayAttendance {
  const TodayAttendance({
    required this.bookingId,
    required this.status,
    required this.workerName,
    this.arrivedAt,
    this.photoUrl,
  });

  final String bookingId;
  final HomeAttendanceStatus status;
  final String workerName;

  /// Server-stamped check-in time; null when nobody checked in.
  final DateTime? arrivedAt;
  final String? photoUrl;

  static TodayAttendance? fromJson(Object? j) {
    if (j is! Map || j['bookingId'] is! String) return null;
    final at = j['arrivedAt'];
    return TodayAttendance(
      bookingId: j['bookingId'] as String,
      status: HomeAttendanceStatus.parse(j['status']),
      workerName: j['workerName'] as String? ?? '',
      arrivedAt: at is String ? DateTime.tryParse(at)?.toLocal() : null,
      photoUrl: j['photoUrl'] as String?,
    );
  }
}

/// One of `topRated[]` (max 6). [ratingCount] is shown next to the score because the backend
/// applies no minimum count.
class TopRatedWorker {
  const TopRatedWorker({
    required this.workerId,
    required this.name,
    required this.ratingAverage,
    required this.ratingCount,
    this.roleName,
    this.photoUrl,
    this.completedJobs = 0,
    this.reviewSnippet,
    this.verified = false,
  });

  final String workerId;
  final String name;
  final String? roleName;
  final double ratingAverage;
  final int ratingCount;
  final int completedJobs;
  final String? reviewSnippet;
  final bool verified;

  /// Short-lived link: shown, never persisted.
  final String? photoUrl;

  static TopRatedWorker? fromJson(Object? j) {
    if (j is! Map || j['workerId'] is! String || j['ratingAverage'] is! num) {
      return null;
    }
    return TopRatedWorker(
      workerId: j['workerId'] as String,
      name: j['name'] as String? ?? '',
      roleName: j['roleName'] as String?,
      photoUrl: j['photoUrl'] as String?,
      ratingAverage: (j['ratingAverage'] as num).toDouble(),
      ratingCount: (j['ratingCount'] as num?)?.toInt() ?? 0,
      completedJobs: (j['completedJobs'] as num?)?.toInt() ?? 0,
      reviewSnippet: j['latestReviewSnippet'] as String?,
      verified: j['verified'] == true,
    );
  }

  Map<String, Object?> toJson() => {
    'workerId': workerId,
    'name': name,
    'roleName': roleName,
    'ratingAverage': ratingAverage,
    'ratingCount': ratingCount,
    'completedJobs': completedJobs,
    'latestReviewSnippet': reviewSnippet,
    'verified': verified,
  };
}

/// What Home shows. Any section can be absent; Home hides it (modules/03).
class HomeData {
  const HomeData({
    this.activeBooking,
    this.upcomingInterview,
    this.shortlist = const [],
    this.unreadCount = 0,
    this.topRated = const [],
    this.todayAttendance,
    this.fromCache = false,
  });

  final ActiveBookingSummary? activeBooking;
  final UpcomingInterview? upcomingInterview;
  final List<ShortlistPreview> shortlist;
  final int unreadCount;
  final List<TopRatedWorker> topRated;
  final TodayAttendance? todayAttendance;

  /// True when served from the offline cache (Home shows the "You're offline" banner).
  final bool fromCache;

  /// New user: nothing to show but the onboarding card.
  bool get isNewUser =>
      activeBooking == null && upcomingInterview == null && shortlist.isEmpty;

  HomeData asCached() => HomeData(
    activeBooking: activeBooking,
    upcomingInterview: upcomingInterview,
    shortlist: shortlist,
    unreadCount: unreadCount,
    topRated: topRated,
    fromCache: true,
  );

  Map<String, Object?> toJson() => {
    'activeBooking': activeBooking?.toJson(),
    'upcomingInterview': upcomingInterview?.toJson(),
    'shortlist': [for (final s in shortlist) s.toJson()],
    'unreadCount': unreadCount,
    'topRated': [for (final t in topRated) t.toJson()],
  };

  factory HomeData.fromJson(Map<String, dynamic> j) => HomeData(
    activeBooking: j['activeBooking'] == null
        ? null
        : ActiveBookingSummary.fromJson(
            j['activeBooking'] as Map<String, dynamic>,
          ),
    upcomingInterview: j['upcomingInterview'] == null
        ? null
        : UpcomingInterview.fromJson(
            j['upcomingInterview'] as Map<String, dynamic>,
          ),
    shortlist: [
      for (final s in j['shortlist'] as List<dynamic>)
        ShortlistPreview.fromJson(s as Map<String, dynamic>),
    ],
    unreadCount: j['unreadCount'] as int? ?? 0,
    topRated: [
      if (j['topRated'] is List)
        for (final t in j['topRated'] as List) ?TopRatedWorker.fromJson(t),
    ],
  );
}

/// `GET /home` (aggregate, assumed in docs/05) or composed from bookings / interviews / favourites.
abstract interface class HomeRepository {
  Future<HomeData> fetch();
}
