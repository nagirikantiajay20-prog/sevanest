import 'package:dio/dio.dart';
import 'package:sevanest_customer/features/service_discovery/domain/catalog.dart';

/// Time-of-day windows offered as an availability filter. The backend matches a worker whose one
/// availability window covers the whole range (`availableFrom`..`availableTo`).
enum AvailabilityFilter {
  morning('06:00', '12:00'),
  afternoon('12:00', '17:00'),
  evening('17:00', '21:00');

  const AvailabilityFilter(this.from, this.to);
  final String from;
  final String to;
}

/// Languages offered in the filter (backend `language` takes a code such as `hi`).
const workerLanguages = {
  'en': 'English',
  'hi': 'Hindi',
  'te': 'Telugu',
  'ta': 'Tamil',
};

/// Display name for a worker language, falling back to whatever the backend sent.
String languageName(String code) => workerLanguages[code] ?? code;

/// Optional narrowing on top of the requirement. Only what `GET /search/workers` supports: a star
/// rating filter is left out because the rating scale is configurable (OPEN_QUESTIONS #40).
class WorkerFilters {
  const WorkerFilters({
    this.availability,
    this.language,
    this.minExperienceMonths,
  });

  final AvailabilityFilter? availability;
  final String? language;
  final int? minExperienceMonths;

  /// How many filters are active (the badge on the Filter button).
  int get count => [
    availability,
    language,
    minExperienceMonths,
  ].where((e) => e != null).length;

  @override
  bool operator ==(Object other) =>
      other is WorkerFilters &&
      other.availability == availability &&
      other.language == language &&
      other.minExperienceMonths == minExperienceMonths;

  @override
  int get hashCode => Object.hash(availability, language, minExperienceMonths);
}

/// What the customer is searching for. Equality makes it a provider key: a changed query is a new
/// search. [category] is the backend category code, [areaId] the service-area id.
class WorkerQuery {
  const WorkerQuery({
    required this.category,
    required this.areaId,
    this.engagement,
    this.filters = const WorkerFilters(),
  });

  final String category;
  final String areaId;
  final EngagementType? engagement;
  final WorkerFilters filters;

  @override
  bool operator ==(Object other) =>
      other is WorkerQuery &&
      other.category == category &&
      other.areaId == areaId &&
      other.engagement == engagement &&
      other.filters == filters;

  @override
  int get hashCode => Object.hash(category, areaId, engagement, filters);
}

class AvailabilityWindow {
  const AvailabilityWindow(this.start, this.end);
  final String start;
  final String end;
}

/// A search result card (Swagger `WorkerCard`). The backend sends no name, contact or address, and
/// only verified workers, so there is nothing KYC-like to leak. Every optional field is nullable.
class WorkerSummary {
  const WorkerSummary({
    required this.id,
    this.experienceMonths,
    this.categories = const [],
    this.languages = const [],
    this.areas = const [],
    this.availability = const [],
    this.ratingAverage,
    this.ratingCount = 0,
    this.photoUrl,
    this.verified = false,
    this.engagement,
  });

  final String id;
  final int? experienceMonths;
  final List<String> categories;
  final List<String> languages;
  final List<String> areas;
  final List<AvailabilityWindow> availability;
  final double? ratingAverage;
  final int ratingCount;

  /// Short-lived link: never persisted.
  final String? photoUrl;
  final bool verified;

  /// The engagement type the worker prefers (null when not stated or not recognised).
  final EngagementType? engagement;

  bool get hasRating => ratingAverage != null && ratingCount > 0;

  /// Null when the card is unusable (no id).
  static WorkerSummary? fromJson(Object? j) {
    if (j is! Map) return null;
    final id = j['workerId'];
    if (id is! String || id.isEmpty) return null;
    List<String> names(Object? v, String key) => v is List
        ? [
            for (final e in v)
              if (e is Map && e[key] is String) e[key] as String,
          ]
        : const [];
    final rating = j['rating'];
    final photo = j['photo'];
    final exp = j['experienceMonths'];
    return WorkerSummary(
      id: id,
      experienceMonths: exp is num ? exp.toInt() : null,
      categories: names(j['categories'], 'name'),
      languages: j['languages'] is List
          ? [
              for (final e in j['languages'] as List)
                if (e is String) e,
            ]
          : const [],
      areas: names(j['serviceAreas'], 'name'),
      availability: j['availability'] is List
          ? [
              for (final e in j['availability'] as List)
                if (e is Map && e['start'] is String && e['end'] is String)
                  AvailabilityWindow(e['start'] as String, e['end'] as String),
            ]
          : const [],
      ratingAverage: rating is Map && rating['average'] is num
          ? (rating['average'] as num).toDouble()
          : null,
      ratingCount: rating is Map && rating['count'] is num
          ? (rating['count'] as num).toInt()
          : 0,
      photoUrl: photo is Map && photo['url'] is String
          ? photo['url'] as String
          : null,
      // Badge only from the backend status (AGENTS §27).
      verified: j['verification'] == 'VERIFIED',
      engagement: _engagementFromCode(j['engagementPreference']),
    );
  }
}

EngagementType? _engagementFromCode(Object? c) => switch (c) {
  'FULL_TIME' => EngagementType.fullTime,
  'PART_TIME' => EngagementType.partTime,
  'DAILY' => EngagementType.daily,
  'HOURLY' => EngagementType.hourly,
  'LIVE_IN' => EngagementType.liveIn,
  _ => null,
};

/// One page plus the cursor of the next (null = end).
class WorkerPage {
  const WorkerPage(this.items, this.nextCursor);
  final List<WorkerSummary> items;
  final String? nextCursor;
}

abstract interface class WorkerSearchRepository {
  /// [cursor] is opaque to callers (the remote one carries the page number).
  Future<WorkerPage> search(
    WorkerQuery query, {
    String? cursor,
    CancelToken? cancel,
  });

  /// One worker's public card. Throws `NotFoundFailure` when the worker is gone or not visible.
  Future<WorkerSummary> detail(String id, {CancelToken? cancel});
}
