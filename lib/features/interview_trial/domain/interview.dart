import 'package:dio/dio.dart';
import 'package:sevanest_customer/features/service_discovery/domain/requirement_draft.dart';
import 'package:sevanest_customer/features/worker_search/domain/worker_search.dart';

enum InterviewType { interview, trial }

/// Backend-owned status. Anything we don't know maps to [unknown] and renders neutrally
/// ("Updated"); it must never crash or be guessed (module 07).
enum InterviewStatus {
  requested,
  scheduled,
  completed,
  cancelled,
  declined,
  confirmed,
  notAFit,
  unknown,
}

InterviewStatus interviewStatusFrom(Object? code) =>
    switch (code is String ? code.toUpperCase() : null) {
      'REQUESTED' || 'PENDING' => InterviewStatus.requested,
      'SCHEDULED' || 'ACCEPTED' => InterviewStatus.scheduled,
      'COMPLETED' => InterviewStatus.completed,
      'CANCELLED' || 'CANCELED' => InterviewStatus.cancelled,
      'DECLINED' || 'REJECTED' => InterviewStatus.declined,
      'CONFIRMED' => InterviewStatus.confirmed,
      'NOT_A_FIT' || 'CUSTOMER_DECLINED' => InterviewStatus.notAFit,
      _ => InterviewStatus.unknown,
    };

/// What the customer may do right now. The UI shows exactly these, nothing inferred.
enum InterviewAction { cancel, reschedule, confirm, decline }

Set<InterviewAction> interviewActionsFrom(Object? raw) => {
  if (raw is List)
    for (final a in raw)
      if (a is String)
        ...switch (a.toLowerCase()) {
          'cancel' => [InterviewAction.cancel],
          'reschedule' => [InterviewAction.reschedule],
          'confirm' => [InterviewAction.confirm],
          'decline' => [InterviewAction.decline],
          _ => const <InterviewAction>[],
        },
};

enum TimelineState { done, current, upcoming, failed }

class InterviewTimelineEntry {
  const InterviewTimelineEntry(this.title, this.state, [this.at]);
  final String title;
  final TimelineState state;
  final DateTime? at;
}

class Interview {
  const Interview({
    required this.id,
    required this.status,
    required this.type,
    required this.workerId,
    this.worker,
    this.date,
    this.slot,
    this.note,
    this.requirement,
    this.timeline = const [],
    this.actions = const {},
  });

  final String id;
  final InterviewStatus status;
  final InterviewType type;
  final String workerId;

  /// The worker's public card, when the backend embeds it.
  final WorkerSummary? worker;

  /// Date only; [slot] is the start time as `HH:mm`.
  final DateTime? date;
  final String? slot;
  final String? note;
  final RequirementDraft? requirement;
  final List<InterviewTimelineEntry> timeline;
  final Set<InterviewAction> actions;

  /// Start as minutes since midnight, from [slot].
  int? get slotMinutes => parseSlot(slot);

  /// Tolerant parse of the assumed contract (docs/05). Null when there is no id.
  static Interview? fromJson(Object? j) {
    if (j is! Map) return null;
    final id = j['id'];
    if (id is! String || id.isEmpty) return null;
    RequirementDraft? req;
    try {
      final r = j['requirement'];
      if (r is Map<String, dynamic>) req = RequirementDraft.fromJson(r);
    } on Object {
      req = null;
    }
    final date = j['date'] is String
        ? DateTime.tryParse(j['date'] as String)
        : null;
    final w = j['worker'];
    return Interview(
      id: id,
      status: interviewStatusFrom(j['status']),
      type: '${j['type']}'.toLowerCase() == 'trial'
          ? InterviewType.trial
          : InterviewType.interview,
      workerId: '${j['workerId'] ?? (w is Map ? w['workerId'] : '')}',
      worker: WorkerSummary.fromJson(w),
      date: date == null ? null : DateTime(date.year, date.month, date.day),
      slot: j['slot'] is String ? j['slot'] as String : null,
      note: j['note'] is String ? j['note'] as String : null,
      requirement: req,
      timeline: [
        if (j['timeline'] is List)
          for (final e in j['timeline'] as List)
            if (e is Map && e['title'] is String)
              InterviewTimelineEntry(
                e['title'] as String,
                switch ('${e['state']}'.toLowerCase()) {
                  'done' => TimelineState.done,
                  'current' => TimelineState.current,
                  'failed' => TimelineState.failed,
                  _ => TimelineState.upcoming,
                },
                e['at'] is String ? DateTime.tryParse(e['at'] as String) : null,
              ),
      ],
      actions: interviewActionsFrom(j['allowedActions']),
    );
  }
}

/// "17:30" -> 1050, or null when malformed.
int? parseSlot(String? s) {
  final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(s ?? '');
  if (m == null) return null;
  final h = int.parse(m[1]!);
  final min = int.parse(m[2]!);
  return h > 23 || min > 59 ? null : h * 60 + min;
}

String slotId(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';

/// One bookable start time. One hour long (assumed: the backend has no slot endpoint yet).
class InterviewSlot {
  const InterviewSlot(this.id);
  final String id;
  int get startMinutes => parseSlot(id) ?? 0;
  int get endMinutes => startMinutes + 60;
}

class InterviewRequest {
  const InterviewRequest({
    required this.workerId,
    required this.type,
    required this.date,
    required this.slot,
    required this.requirement,
    this.note,
  });

  final String workerId;
  final InterviewType type;
  final DateTime date;
  final String slot;
  final RequirementDraft requirement;
  final String? note;
}

class InterviewPage {
  const InterviewPage(this.items, this.nextCursor);
  final List<Interview> items;
  final String? nextCursor;
}

/// Assumed contract (docs/05; the deployed Swagger has no interview endpoints yet).
abstract interface class InterviewRepository {
  /// [idempotencyKey] is generated once per form so a retry cannot create a second request.
  Future<Interview> create(
    InterviewRequest request, {
    required String idempotencyKey,
  });

  Future<Interview> reschedule(
    String id,
    DateTime date,
    String slot, {
    required String idempotencyKey,
  });

  Future<InterviewPage> list({String? cursor});
  Future<Interview> get(String id, {CancelToken? cancel});
  Future<Interview> cancel(String id, {String? reason});

  /// "Not a fit". Confirming goes through the booking flow instead.
  Future<Interview> decline(String id);

  /// Free start times for [workerId] on [date].
  Future<List<InterviewSlot>> slots(String workerId, DateTime date);
}
