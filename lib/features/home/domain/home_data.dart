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
  });

  final String id;
  final String reference;
  final String workerName;
  final String service;
  final String engagement;
  final String startLabel;
  final BookingStage stage;
  final bool verified;

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
  });

  final String workerId;
  final String name;
  final String service;

  Map<String, Object?> toJson() => {
    'workerId': workerId,
    'name': name,
    'service': service,
  };

  factory ShortlistPreview.fromJson(Map<String, dynamic> j) => ShortlistPreview(
    workerId: j['workerId'] as String,
    name: j['name'] as String,
    service: j['service'] as String,
  );
}

/// What Home shows. Any section can be absent; Home hides it (modules/03).
class HomeData {
  const HomeData({
    this.activeBooking,
    this.upcomingInterview,
    this.shortlist = const [],
    this.unreadCount = 0,
    this.fromCache = false,
  });

  final ActiveBookingSummary? activeBooking;
  final UpcomingInterview? upcomingInterview;
  final List<ShortlistPreview> shortlist;
  final int unreadCount;

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
    fromCache: true,
  );

  Map<String, Object?> toJson() => {
    'activeBooking': activeBooking?.toJson(),
    'upcomingInterview': upcomingInterview?.toJson(),
    'shortlist': [for (final s in shortlist) s.toJson()],
    'unreadCount': unreadCount,
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
  );
}

/// `GET /home` (aggregate, assumed in docs/05) or composed from bookings / interviews / favourites.
abstract interface class HomeRepository {
  Future<HomeData> fetch();
}
