import 'package:dio/dio.dart';
import 'package:sevanest_customer/features/service_discovery/domain/catalog.dart';

/// What the customer is searching for. Equality makes it a provider key: a changed query is a new
/// search. [category] is the backend category code, [areaId] the service-area id.
class WorkerQuery {
  const WorkerQuery({
    required this.category,
    required this.areaId,
    this.engagement,
  });

  final String category;
  final String areaId;
  final EngagementType? engagement;

  @override
  bool operator ==(Object other) =>
      other is WorkerQuery &&
      other.category == category &&
      other.areaId == areaId &&
      other.engagement == engagement;

  @override
  int get hashCode => Object.hash(category, areaId, engagement);
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
    );
  }
}

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
}
