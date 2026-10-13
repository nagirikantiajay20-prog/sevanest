import 'package:dio/dio.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/features/addresses/domain/address.dart';
import 'package:sevanest_customer/features/interview_trial/domain/interview.dart';
import 'package:sevanest_customer/features/service_discovery/domain/catalog.dart';
import 'package:sevanest_customer/features/service_discovery/domain/requirement_draft.dart';
import 'package:sevanest_customer/features/worker_search/data/worker_search_repository_mock.dart';

/// In-memory interviews behind the mock-API toggle. A returning customer starts with one of each
/// kind of state worth seeing (scheduled, completed, requested); a new one starts empty.
class InterviewRepositoryMock implements InterviewRepository {
  InterviewRepositoryMock(this._state, {DateTime Function()? now})
    : _now = now ?? DateTime.now {
    if (_state().returningUser) _seed();
  }

  final MockApiState Function() _state;
  final DateTime Function() _now;
  final _items = <Interview>[];
  var _seq = 400;

  /// The 5 pm slot is "grabbed by someone else" the first time it is requested, so the 409 path
  /// (module 07, INT-05) can be seen on a device.
  var _raceUsed = false;

  static const _dayStart = 9 * 60;
  static const _dayEnd = 18 * 60;

  static const _requirement = RequirementDraft(
    serviceId: 'cook',
    engagement: EngagementType.fullTime,
    address: Address(
      id: 'h1',
      line: 'Flat 402, Sai Residency',
      area: 'Madhapur',
      city: 'Hyderabad',
      pincode: '500081',
      isDefault: true,
    ),
  );

  DateTime get _today {
    final n = _now();
    return DateTime(n.year, n.month, n.day);
  }

  void _seed() {
    final tomorrow = _today.add(const Duration(days: 1));
    _items.addAll([
      Interview(
        id: 'iv_301',
        status: InterviewStatus.scheduled,
        type: InterviewType.interview,
        workerId: 'cook-2',
        worker: WorkerSearchRepositoryMock.byId('cook-2'),
        date: tomorrow,
        slot: '17:30',
        requirement: _requirement,
        actions: const {InterviewAction.cancel, InterviewAction.reschedule},
      ),
      Interview(
        id: 'iv_302',
        status: InterviewStatus.completed,
        type: InterviewType.trial,
        workerId: 'cook-5',
        worker: WorkerSearchRepositoryMock.byId('cook-5'),
        date: _today.subtract(const Duration(days: 2)),
        slot: '10:00',
        requirement: _requirement,
        actions: const {InterviewAction.confirm, InterviewAction.decline},
      ),
      Interview(
        id: 'iv_303',
        status: InterviewStatus.requested,
        type: InterviewType.interview,
        workerId: 'cook-3',
        worker: WorkerSearchRepositoryMock.byId('cook-3'),
        date: _today.add(const Duration(days: 3)),
        slot: '11:00',
        requirement: _requirement,
        actions: const {InterviewAction.cancel},
      ),
    ]);
  }

  int _index(String id) {
    final i = _items.indexWhere((e) => e.id == id);
    if (i < 0) throw const NotFoundFailure();
    return i;
  }

  Interview _replace(
    String id,
    InterviewStatus status,
    Set<InterviewAction> actions, {
    DateTime? date,
    String? slot,
  }) {
    final i = _index(id);
    final o = _items[i];
    return _items[i] = Interview(
      id: o.id,
      status: status,
      type: o.type,
      workerId: o.workerId,
      worker: o.worker,
      date: date ?? o.date,
      slot: slot ?? o.slot,
      note: o.note,
      requirement: o.requirement,
      timeline: o.timeline,
      actions: actions,
    );
  }

  @override
  Future<Interview> create(
    InterviewRequest r, {
    required String idempotencyKey,
  }) => mockCall(_state(), () {
    final worker = WorkerSearchRepositoryMock.byId(r.workerId);
    if (worker == null) throw const NotFoundFailure();
    if (r.slot == '17:00' && !_raceUsed) {
      _raceUsed = true;
      throw const ConflictFailure('slot_taken');
    }
    final created = Interview(
      id: 'iv_${++_seq}',
      status: InterviewStatus.requested,
      type: r.type,
      workerId: r.workerId,
      worker: worker,
      date: r.date,
      slot: r.slot,
      note: r.note,
      requirement: r.requirement,
      actions: const {InterviewAction.cancel},
    );
    _items.insert(0, created);
    return created;
  });

  @override
  Future<Interview> reschedule(
    String id,
    DateTime date,
    String slot, {
    required String idempotencyKey,
  }) => mockCall(
    _state(),
    () => _replace(
      id,
      InterviewStatus.requested,
      const {InterviewAction.cancel, InterviewAction.reschedule},
      date: date,
      slot: slot,
    ),
  );

  @override
  Future<InterviewPage> list({String? cursor}) => mockCall(_state(), () {
    if (_state().mode == MockMode.empty) return const InterviewPage([], null);
    return InterviewPage(List.of(_items), null);
  });

  @override
  Future<Interview> get(String id, {CancelToken? cancel}) =>
      mockCall(_state(), () => _items[_index(id)]);

  @override
  Future<Interview> cancel(String id, {String? reason}) => mockCall(
    _state(),
    () => _replace(id, InterviewStatus.cancelled, const {}),
  );

  @override
  Future<Interview> decline(String id) =>
      mockCall(_state(), () => _replace(id, InterviewStatus.notAFit, const {}));

  /// Hourly starts inside the worker's availability window (9-6 when it states none). Today's
  /// slots must still be at least an hour away.
  @override
  Future<List<InterviewSlot>> slots(String workerId, DateTime date) =>
      mockCall(_state(), () {
        final w = WorkerSearchRepositoryMock.byId(workerId);
        if (w == null) throw const NotFoundFailure();
        final win = w.availability.firstOrNull;
        final from = parseSlot(win?.start) ?? _dayStart;
        final to = parseSlot(win?.end) ?? _dayEnd;
        final now = _now();
        final isToday = DateTime(date.year, date.month, date.day) == _today;
        final earliest = isToday ? now.hour * 60 + now.minute + 60 : 0;
        return [
          for (var m = from; m + 60 <= to; m += 60)
            if (m >= earliest) InterviewSlot(slotId(m)),
        ];
      });
}
