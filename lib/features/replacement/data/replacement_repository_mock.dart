import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/features/booking/domain/booking.dart';
import 'package:sevanest_customer/features/replacement/domain/replacement.dart';
import 'package:sevanest_customer/features/worker_search/data/worker_search_repository_mock.dart';

/// In-memory replacement requests behind the dev mock toggle. Staff decide in the real system, so
/// with [autoApprove] a request becomes APPROVED (with three alternatives) on its second read;
/// tests switch that off and call [approve] / [reject] themselves. The booking mock is not touched:
/// a mock booking stays ACTIVE after a request.
class ReplacementRepositoryMock implements ReplacementRepository {
  ReplacementRepositoryMock(
    this._state, {
    DateTime Function()? now,
    this.autoApprove = true,
  }) : _now = now ?? DateTime.now;

  final MockApiState Function() _state;
  final DateTime Function() _now;
  final bool autoApprove;

  final _items = <Replacement>[];
  final _reads = <String, int>{};
  final _keys = <String, String>{};
  var _seq = 3103;

  /// Worker ids that answer 409 on select, as if they were booked meanwhile.
  final unavailable = <String>{};

  /// Requests created so far (tests count real writes with this).
  int get created => _items.length;

  static const alternativeIds = ['cook-2', 'cook-5', 'cook-8'];

  int _index(String id) {
    final i = _items.indexWhere((r) => r.id == id);
    if (i < 0) throw const NotFoundFailure();
    return i;
  }

  Replacement _put(
    Replacement o,
    ReplacementStatus s, {
    String? remarks,
    String? newBooking,
  }) {
    final n = _now();
    return _items[_index(o.id)] = Replacement(
      id: o.id,
      bookingId: o.bookingId,
      status: s,
      reason: o.reason,
      notes: o.notes,
      decisionRemarks: remarks ?? o.decisionRemarks,
      replacementBookingId: newBooking ?? o.replacementBookingId,
      createdAt: o.createdAt,
      decidedAt:
          s == ReplacementStatus.approved || s == ReplacementStatus.rejected
          ? n
          : o.decidedAt,
      completedAt:
          s == ReplacementStatus.completed || s == ReplacementStatus.cancelled
          ? n
          : o.completedAt,
      alternatives: s == ReplacementStatus.approved
          ? [
              for (final w in alternativeIds)
                ?WorkerSearchRepositoryMock.byId(w),
            ]
          : s == ReplacementStatus.completed
          ? const []
          : o.alternatives,
    );
  }

  /// Staff approval: the request now carries the alternatives.
  void approve(String id) =>
      _put(_items[_index(id)], ReplacementStatus.approved);

  /// Staff rejection with remarks.
  void reject(String id, String remarks) =>
      _put(_items[_index(id)], ReplacementStatus.rejected, remarks: remarks);

  @override
  Future<Replacement> create({
    required String bookingId,
    required String reason,
    String? notes,
    required String idempotencyKey,
  }) => mockCall(_state(), () {
    final prior = _keys[idempotencyKey];
    if (prior != null) return _items[_index(prior)];
    if (_items.any(
      (r) => r.bookingId == bookingId && replacementIsOpen(r.status),
    )) {
      throw const ConflictFailure('Already requested', 'REPLACEMENT_REQUESTED');
    }
    final r = Replacement(
      id: 'rp_${++_seq}',
      bookingId: bookingId,
      status: ReplacementStatus.requested,
      reason: reason.trim(),
      notes: notes == null || notes.trim().isEmpty ? null : notes.trim(),
      createdAt: _now(),
    );
    _items.add(r);
    _keys[idempotencyKey] = r.id;
    return r;
  });

  @override
  Future<ReplacementPage> list({String? cursor}) =>
      mockCall(_state(), () => ReplacementPage(List.of(_items.reversed), null));

  @override
  Future<Replacement> get(String id) => mockCall(_state(), () {
    final reads = _reads[id] = (_reads[id] ?? 0) + 1;
    final r = _items[_index(id)];
    if (autoApprove && r.status == ReplacementStatus.requested && reads >= 2) {
      return _put(r, ReplacementStatus.approved);
    }
    return r;
  });

  @override
  Future<Replacement> cancel(String id, {required String idempotencyKey}) =>
      mockCall(_state(), () {
        final r = _items[_index(id)];
        if (r.status == ReplacementStatus.cancelled) return r;
        if (!replacementIsOpen(r.status)) {
          throw const ConflictFailure('Not open', 'REPLACEMENT_NOT_OPEN');
        }
        return _put(r, ReplacementStatus.cancelled);
      });

  @override
  Future<Replacement> select(
    String id,
    String workerId, {
    required String idempotencyKey,
  }) => mockCall(_state(), () {
    final r = _items[_index(id)];
    if (r.status == ReplacementStatus.completed) return r;
    if (r.status != ReplacementStatus.approved) {
      throw const ConflictFailure('Not approved', 'REPLACEMENT_NOT_APPROVED');
    }
    if (unavailable.contains(workerId)) {
      throw const ConflictFailure('Worker unavailable', 'WORKER_UNAVAILABLE');
    }
    if (!r.alternatives.any((w) => w.id == workerId)) {
      throw const ValidationFailure(
        'Worker not eligible',
        {},
        'WORKER_NOT_ELIGIBLE',
      );
    }
    return _put(r, ReplacementStatus.completed, newBooking: 'bk_rep_${r.id}');
  });

  @override
  Future<List<ChainEntry>> chain(String bookingId) => mockCall(_state(), () {
    final r = _items.where((x) => x.bookingId == bookingId).firstOrNull;
    return [
      ChainEntry(
        bookingId: bookingId,
        position: 1,
        status: r?.status == ReplacementStatus.completed
            ? BookingStatus.replaced
            : BookingStatus.active,
        current: true,
      ),
      if (r?.replacementBookingId != null)
        ChainEntry(
          bookingId: r!.replacementBookingId!,
          position: 2,
          status: BookingStatus.matched,
          current: false,
          replacesBookingId: bookingId,
        ),
    ];
  });
}
