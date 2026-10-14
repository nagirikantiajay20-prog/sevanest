import 'package:sevanest_customer/features/booking/domain/booking.dart';
import 'package:sevanest_customer/features/worker_search/domain/worker_search.dart';

/// `ReplacementView.status` (Swagger). Unknown codes map to [unknown] and read "Updated".
enum ReplacementStatus {
  requested,
  approved,
  rejected,
  cancelled,
  completed,
  unknown,
}

ReplacementStatus replacementStatusFrom(Object? code) =>
    switch (code is String ? code.toUpperCase() : null) {
      'REQUESTED' => ReplacementStatus.requested,
      'APPROVED' => ReplacementStatus.approved,
      'REJECTED' => ReplacementStatus.rejected,
      'CANCELLED' || 'CANCELED' => ReplacementStatus.cancelled,
      'COMPLETED' => ReplacementStatus.completed,
      _ => ReplacementStatus.unknown,
    };

/// A request the customer can still withdraw (the booking is REPLACEMENT_REQUESTED).
bool replacementIsOpen(ReplacementStatus s) =>
    s == ReplacementStatus.requested || s == ReplacementStatus.approved;

/// The reasons of design screen 25. The backend takes free text (`reason`, max 1000) and defines no
/// list (Q-54, BACKEND_REQUESTS 37), so the English [text] is what staff read.
enum ReplacementReason {
  notOnTime('Not arriving on time'),
  frequentAbsences('Frequent absences'),
  workQuality('Work quality is not good'),
  behaviour('Behaviour concern'),
  scheduleChanged('Schedule no longer suits'),
  workerLeft("Worker left or can't continue"),
  safety('Safety or trust concern'),
  other('Other');

  const ReplacementReason(this.text);
  final String text;

  /// Null when the stored text is the customer's own words (an older or free-text request).
  static ReplacementReason? fromText(String text) {
    final t = text.trim().toLowerCase();
    for (final r in values) {
      if (r.text.toLowerCase() == t) return r;
    }
    return null;
  }
}

/// `ReplacementView` (Swagger). The alternatives are NOT in the Swagger (the customer has no
/// candidates route, BACKEND_REQUESTS 39): they are read from `alternatives` / `candidates` when the
/// backend sends them and are empty otherwise.
class Replacement {
  const Replacement({
    required this.id,
    required this.bookingId,
    required this.status,
    required this.reason,
    this.notes,
    this.decisionRemarks,
    this.replacementBookingId,
    this.createdAt,
    this.decidedAt,
    this.completedAt,
    this.alternatives = const [],
  });

  final String id;
  final String bookingId;
  final ReplacementStatus status;
  final String reason;
  final String? notes;
  final String? decisionRemarks;
  final String? replacementBookingId;
  final DateTime? createdAt;
  final DateTime? decidedAt;
  final DateTime? completedAt;
  final List<WorkerSummary> alternatives;

  /// "RP-3104" style reference taken from the id.
  String get reference {
    final tail = id.length > 6 ? id.substring(id.length - 6) : id;
    return tail.toUpperCase();
  }

  static Replacement? fromJson(Object? json) {
    if (json is! Map) return null;
    final j = json['data'] is Map ? json['data'] as Map : json;
    final id = j['id'];
    if (id is! String || id.isEmpty) return null;
    String? s(Object? v) => v is String && v.isNotEmpty ? v : null;
    DateTime? d(Object? v) {
      final t = v is String ? DateTime.tryParse(v) : null;
      return t != null && t.isUtc ? t.toLocal() : t;
    }

    final raw = j['alternatives'] ?? j['candidates'];
    return Replacement(
      id: id,
      bookingId: '${j['bookingId']}',
      status: replacementStatusFrom(j['status']),
      reason: s(j['reason']) ?? '',
      notes: s(j['notes']),
      decisionRemarks: s(j['decisionRemarks']),
      replacementBookingId: s(j['replacementBookingId']),
      createdAt: d(j['createdAt']),
      decidedAt: d(j['decidedAt']),
      completedAt: d(j['completedAt']),
      alternatives: [
        if (raw is List)
          for (final e in raw)
            ?(WorkerSummary.fromJson(e) ??
                (e is Map ? WorkerSummary.fromJson(e['worker']) : null)),
      ],
    );
  }
}

class ReplacementPage {
  const ReplacementPage(this.items, this.nextCursor);
  final List<Replacement> items;
  final String? nextCursor;
}

/// `ChainEntryView`: one booking of a replacement chain, oldest first.
class ChainEntry {
  const ChainEntry({
    required this.bookingId,
    required this.position,
    required this.status,
    required this.current,
    this.replacesBookingId,
    this.startDate,
  });

  final String bookingId;
  final int position;
  final BookingStatus status;
  final bool current;
  final String? replacesBookingId;
  final DateTime? startDate;

  static ChainEntry? fromJson(Object? j) {
    if (j is! Map || j['bookingId'] is! String) return null;
    final start = j['startDate'] is String
        ? DateTime.tryParse(j['startDate'] as String)
        : null;
    return ChainEntry(
      bookingId: j['bookingId'] as String,
      position: j['position'] is num ? (j['position'] as num).toInt() : 0,
      status: bookingStatusFrom(j['status']),
      current: j['current'] == true,
      replacesBookingId: j['replacesBookingId'] is String
          ? j['replacesBookingId'] as String
          : null,
      startDate: start == null
          ? null
          : DateTime(start.year, start.month, start.day),
    );
  }
}

/// `/replacement-requests` of the deployed backend (docs/backend_openapi_2026-10-13.json).
abstract interface class ReplacementRepository {
  /// `POST /replacement-requests`. One key per form: repeating it returns the first request.
  /// 404 not mine, 422 `REPLACEMENT_NOT_ELIGIBLE`, 409 while one is open.
  Future<Replacement> create({
    required String bookingId,
    required String reason,
    String? notes,
    required String idempotencyKey,
  });

  /// `GET /replacement-requests`: mine, newest first.
  Future<ReplacementPage> list({String? cursor});

  Future<Replacement> get(String id);

  /// `POST /replacement-requests/{id}/cancel`: withdraw an open request.
  Future<Replacement> cancel(String id, {required String idempotencyKey});

  /// `POST /replacement-requests/{id}/select {workerId}`.
  Future<Replacement> select(
    String id,
    String workerId, {
    required String idempotencyKey,
  });

  /// `GET /bookings/{id}/replacement-chain`, oldest first.
  Future<List<ChainEntry>> chain(String bookingId);
}
