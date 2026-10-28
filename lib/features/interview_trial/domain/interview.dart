import 'package:dio/dio.dart';
import 'package:sevanest_customer/features/service_discovery/domain/requirement_draft.dart';
import 'package:sevanest_customer/features/worker_search/domain/worker_search.dart';

enum InterviewType { interview, trial }

/// Backend-owned status (`GET /interviews`: REQUESTED, CONFIRMED, RESCHEDULE_PROPOSED, DECLINED,
/// CANCELLED, COMPLETED). Backend CONFIRMED = the time is agreed, so it is [scheduled] here;
/// [confirmed] and [notAFit] describe the customer's decision on the worker afterwards (set from
/// the booking state). Anything unknown maps to [unknown] and renders neutrally ("Updated"); it
/// must never crash or be guessed (module 07).
enum InterviewStatus {
  requested,
  scheduled,
  rescheduleProposed,
  completed,
  cancelled,
  declined,
  confirmed,
  notAFit,
  unknown,
}

InterviewStatus interviewStatusFrom(Object? code) =>
    switch (code is String ? code.toUpperCase() : null) {
      'REQUESTED' => InterviewStatus.requested,
      'CONFIRMED' => InterviewStatus.scheduled,
      'RESCHEDULE_PROPOSED' => InterviewStatus.rescheduleProposed,
      'COMPLETED' => InterviewStatus.completed,
      'CANCELLED' || 'CANCELED' => InterviewStatus.cancelled,
      'DECLINED' => InterviewStatus.declined,
      _ => InterviewStatus.unknown,
    };

/// What the customer may do right now. The UI shows exactly these, nothing inferred. The backend's
/// `allowedActions` are reschedule, cancel, complete, accept-proposal and reject-proposal;
/// [confirm] and [decline] ("not a fit") come from the booking once the interview is completed.
enum InterviewAction {
  cancel,
  reschedule,
  complete,
  confirm,
  decline,
  acceptProposal,
  rejectProposal,
}

Set<InterviewAction> interviewActionsFrom(Object? raw) => {
  if (raw is List)
    for (final a in raw)
      if (a is String)
        ...switch (a.toLowerCase().replaceAll('_', '-')) {
          'cancel' => [InterviewAction.cancel],
          'reschedule' => [InterviewAction.reschedule],
          'complete' => [InterviewAction.complete],
          'accept-proposal' => [InterviewAction.acceptProposal],
          'reject-proposal' => [InterviewAction.rejectProposal],
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
    this.bookingId = '',
    this.worker,
    this.date,
    this.slot,
    this.proposedAt,
    this.note,
    this.requirement,
    this.timeline = const [],
    this.actions = const {},
  });

  final String id;
  final InterviewStatus status;
  final InterviewType type;
  final String workerId;

  /// The booking this interview belongs to (it names the worker).
  final String bookingId;

  /// The worker's public card, when the backend embeds it.
  final WorkerSummary? worker;

  /// Date only; [slot] is the start time as `HH:mm`.
  final DateTime? date;
  final String? slot;

  /// The other time the worker proposed (status [InterviewStatus.rescheduleProposed]), local.
  final DateTime? proposedAt;
  final String? note;
  final RequirementDraft? requirement;
  final List<InterviewTimelineEntry> timeline;
  final Set<InterviewAction> actions;

  /// Start as minutes since midnight, from [slot].
  int? get slotMinutes => parseSlot(slot);

  Interview copyWith({
    String? workerId,
    RequirementDraft? requirement,
    Set<InterviewAction>? actions,
  }) => Interview(
    id: id,
    status: status,
    type: type,
    workerId: workerId ?? this.workerId,
    bookingId: bookingId,
    worker: worker,
    date: date,
    slot: slot,
    proposedAt: proposedAt,
    note: note,
    requirement: requirement ?? this.requirement,
    timeline: timeline,
    actions: actions ?? this.actions,
  );

  /// `GET /interviews/{id}` (OpenAPI `InterviewView`). The time shown is the agreed one, else the
  /// requested one. Worker and requirement come from the booking. Null when there is no id.
  static Interview? fromJson(Object? j) {
    if (j is! Map) return null;
    final id = j['id'];
    if (id is! String || id.isEmpty) return null;
    final at = _time(j['scheduledAt']) ?? _time(j['preferredAt']);
    return Interview(
      id: id,
      status: interviewStatusFrom(j['status']),
      type: '${j['type']}'.toLowerCase() == 'trial'
          ? InterviewType.trial
          : InterviewType.interview,
      workerId: j['workerId'] is String ? j['workerId'] as String : '',
      bookingId: j['bookingId'] is String ? j['bookingId'] as String : '',
      date: at == null ? null : DateTime(at.year, at.month, at.day),
      slot: at == null ? null : slotId(at.hour * 60 + at.minute),
      proposedAt: _time(j['proposedAt']),
      note: j['note'] is String ? j['note'] as String : null,
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
                _time(e['at']),
              ),
      ],
      actions: interviewActionsFrom(j['allowedActions']),
    );
  }
}

/// ISO time to local time, or null.
DateTime? _time(Object? v) {
  final d = v is String ? DateTime.tryParse(v) : null;
  return d == null ? null : (d.isUtc ? d.toLocal() : d);
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
  const InterviewSlot(this.id, {this.minutes = 60});
  final String id;

  /// Slot length from `GET /search/workers/{id}/slots` -> `slotMinutes` (60 when absent).
  final int minutes;
  int get startMinutes => parseSlot(id) ?? 0;
  int get endMinutes => startMinutes + minutes;
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

/// Hourly start times inside a worker's availability window (09:00-18:00 when it states none). On
/// the current day a slot must start at least an hour from [now]. The backend only checks that the
/// time is in the future, so the windows are the app's own guard against pointless requests.
List<InterviewSlot> generateInterviewSlots({
  required DateTime date,
  required DateTime now,
  String? windowStart,
  String? windowEnd,
}) {
  final from = parseSlot(windowStart) ?? 9 * 60;
  final to = parseSlot(windowEnd) ?? 18 * 60;
  final isToday =
      DateTime(date.year, date.month, date.day) ==
      DateTime(now.year, now.month, now.day);
  final earliest = isToday ? now.hour * 60 + now.minute + 60 : 0;
  return [
    for (var m = from; m + 60 <= to; m += 60)
      if (m >= earliest) InterviewSlot(slotId(m)),
  ];
}

/// The interview screens' view of a booking (see `InterviewRepositoryOverBookings`).
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

  /// The interview id to open or reschedule for a booking. The booking and interview ids differ
  /// on the live backend, so a booking screen must resolve it. [openOnly]: only one still open
  /// (requested, scheduled or reschedule proposed). Null when there is none.
  Future<String?> interviewIdFor(String bookingId, {bool openOnly = false});

  Future<Interview> get(String id, {CancelToken? cancel});
  Future<Interview> cancel(String id, {String? reason});

  /// "Not a fit". Confirming goes through the booking flow instead.
  Future<Interview> decline(String id);

  /// "The interview took place" (backend `interview-complete`).
  Future<Interview> complete(String id);

  /// Answer the time the worker proposed: accept it, or keep the original.
  Future<Interview> answerProposal(String id, {required bool accept});

  /// Free start times for [workerId] on [date].
  Future<List<InterviewSlot>> slots(String workerId, DateTime date);
}
