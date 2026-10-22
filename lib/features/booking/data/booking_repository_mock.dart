import 'package:dio/dio.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/features/booking/domain/booking.dart';
import 'package:sevanest_customer/features/interview_trial/domain/interview.dart';
import 'package:sevanest_customer/features/service_discovery/domain/catalog.dart';
import 'package:sevanest_customer/features/worker_search/data/worker_search_repository_mock.dart';

/// In-memory bookings behind the mock-API toggle, following the backend state model
/// (NEW_REQUEST -> MATCHED -> INTERVIEW_TRIAL_SCHEDULED -> INTERVIEW_TRIAL_COMPLETED ->
/// PENDING_PAYMENT ...). A returning customer starts with one booking in each state worth seeing;
/// a new one starts empty. The interview ids (`iv_301`...) match the Home mock.
class BookingRepositoryMock implements BookingRepository {
  BookingRepositoryMock(this._state, {DateTime Function()? now})
    : _now = now ?? DateTime.now {
    if (_state().returningUser) _seed();
  }

  final MockApiState Function() _state;
  final DateTime Function() _now;
  final _items = <Booking>[];
  final _keys = <String, String>{};
  var _seq = 400;

  DateTime get _today {
    final n = _now();
    return DateTime(n.year, n.month, n.day);
  }

  Booking _seeded(
    String id,
    BookingStatus status,
    String worker, {
    DateTime? at,
    InterviewType? type,
    List<BookingStatus> path = const [],
    DateTime? startDate,
  }) {
    final base = _now().subtract(const Duration(days: 5));
    return Booking(
      id: id,
      status: status,
      categoryCode: 'cook',
      categoryName: 'Cook',
      engagement: EngagementType.fullTime,
      workerId: worker,
      worker: WorkerSearchRepositoryMock.byId(worker),
      areaName: 'Madhapur',
      addressId: 'h1',
      startDate: startDate ?? _today.add(const Duration(days: 4)),
      scheduledAt: at,
      scheduleType: type,
      timeline: [
        for (var i = 0; i < path.length; i++)
          BookingTimelineEntry(path[i], base.add(Duration(days: i))),
      ],
      actions: {
        ...derivedBookingActions(status),
        if (status == BookingStatus.completed) BookingAction.rebook,
      },
      createdAt: base,
    );
  }

  void _seed() {
    final tomorrow = _today.add(const Duration(days: 1));
    _items.addAll([
      _seeded(
        'iv_301',
        BookingStatus.interviewTrialScheduled,
        'cook-2',
        at: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 17, 30),
        type: InterviewType.interview,
        path: const [
          BookingStatus.newRequest,
          BookingStatus.matched,
          BookingStatus.interviewTrialScheduled,
        ],
      ),
      _seeded(
        'iv_302',
        BookingStatus.interviewTrialCompleted,
        'cook-5',
        at: _today
            .subtract(const Duration(days: 2))
            .add(const Duration(hours: 10)),
        type: InterviewType.trial,
        path: const [
          BookingStatus.newRequest,
          BookingStatus.matched,
          BookingStatus.interviewTrialScheduled,
          BookingStatus.interviewTrialCompleted,
        ],
      ),
      _seeded(
        'iv_303',
        BookingStatus.matched,
        'cook-3',
        path: const [BookingStatus.newRequest, BookingStatus.matched],
      ),
      _seeded(
        'bk_2100',
        BookingStatus.pendingPayment,
        'cook-8',
        path: const [
          BookingStatus.newRequest,
          BookingStatus.matched,
          BookingStatus.interviewTrialScheduled,
          BookingStatus.interviewTrialCompleted,
          BookingStatus.pendingPayment,
        ],
      ),
      _seeded(
        'bk_2048',
        BookingStatus.active,
        'cook-7',
        startDate: _today.subtract(const Duration(days: 3)),
        path: const [
          BookingStatus.newRequest,
          BookingStatus.matched,
          BookingStatus.interviewTrialScheduled,
          BookingStatus.interviewTrialCompleted,
          BookingStatus.pendingPayment,
          BookingStatus.confirmed,
          BookingStatus.active,
        ],
      ),
      _seeded(
        'bk_1900',
        BookingStatus.completed,
        'cook-9',
        startDate: _today.subtract(const Duration(days: 60)),
        path: const [
          BookingStatus.newRequest,
          BookingStatus.confirmed,
          BookingStatus.active,
          BookingStatus.completed,
        ],
      ),
      _seeded(
        'bk_1800',
        BookingStatus.cancelled,
        'cook-10',
        path: const [BookingStatus.newRequest, BookingStatus.cancelled],
      ),
    ]);
  }

  int _index(String id) {
    final i = _items.indexWhere((b) => b.id == id);
    if (i < 0) throw const NotFoundFailure();
    return i;
  }

  /// Applies one permitted transition; anything else is the backend's 409 INVALID_TRANSITION.
  Booking _move(
    String id,
    Set<BookingStatus> from,
    BookingStatus to, {
    DateTime? scheduledAt,
    InterviewType? type,
    DateTime? startDate,
    bool clearSchedule = false,
  }) {
    final i = _index(id);
    final o = _items[i];
    if (!from.contains(o.status)) {
      throw const ConflictFailure('Not allowed now', 'INVALID_TRANSITION');
    }
    return _items[i] = Booking(
      id: o.id,
      status: to,
      categoryCode: o.categoryCode,
      categoryName: o.categoryName,
      engagement: o.engagement,
      workerId: o.workerId,
      worker: o.worker,
      areaName: o.areaName,
      addressId: o.addressId,
      startDate: startDate ?? o.startDate,
      scheduledAt: clearSchedule ? null : scheduledAt ?? o.scheduledAt,
      scheduleType: clearSchedule ? null : type ?? o.scheduleType,
      budgetMin: o.budgetMin,
      budgetMax: o.budgetMax,
      budgetPeriod: o.budgetPeriod,
      note: o.note,
      timeline: [...o.timeline, BookingTimelineEntry(to, _now())],
      actions: derivedBookingActions(to),
      createdAt: o.createdAt,
    );
  }

  @override
  Future<Booking> create(BookingRequest r, {required String idempotencyKey}) =>
      mockCall(_state(), () {
        final prior = _keys[idempotencyKey];
        if (prior != null) return _items[_index(prior)];
        final worker = r.workerId == null
            ? null
            : WorkerSearchRepositoryMock.byId(r.workerId!);
        if (r.workerId != null && worker == null) {
          throw const ValidationFailure(
            'Worker not eligible',
            {},
            'WORKER_NOT_ELIGIBLE',
          );
        }
        final duplicate = _items.any(
          (b) =>
              r.workerId != null &&
              b.workerId == r.workerId &&
              !bookingIsPast(b.status),
        );
        if (duplicate) {
          throw const ConflictFailure(
            'You already have an open request with this worker',
            'DUPLICATE_BOOKING',
          );
        }
        final status = worker == null
            ? BookingStatus.newRequest
            : BookingStatus.matched;
        final made = Booking(
          id: 'iv_${++_seq}',
          status: status,
          categoryCode: r.category,
          categoryName: worker?.categories.firstOrNull,
          engagement: r.engagement,
          workerId: r.workerId,
          worker: worker,
          areaName: 'Madhapur',
          addressId: r.addressId,
          startDate: r.startDate,
          budgetMin: r.budgetMin,
          budgetMax: r.budgetMax,
          budgetPeriod: r.budgetPeriod,
          note: r.note,
          timeline: [
            BookingTimelineEntry(BookingStatus.newRequest, _now()),
            if (worker != null)
              BookingTimelineEntry(BookingStatus.matched, _now()),
          ],
          actions: derivedBookingActions(status),
          createdAt: _now(),
        );
        _items.insert(0, made);
        _keys[idempotencyKey] = made.id;
        return made;
      });

  @override
  Future<BookingPage> list({String? cursor}) => mockCall(_state(), () {
    if (_state().mode == MockMode.empty) return const BookingPage([], null);
    return BookingPage(List.of(_items), null);
  });

  Iterable<Booking> _filtered(HistoryFilter f) {
    if (_state().mode == MockMode.empty) return const [];
    final q = f.search.trim().toLowerCase();
    return _items.where(
      (b) =>
          (f.year == null || (b.startDate ?? b.createdAt)?.year == f.year) &&
          (f.category == null || b.categoryCode == f.category) &&
          (f.status == null || b.status == f.status) &&
          (q.isEmpty ||
              '${b.categoryName} ${b.identity?.displayName}'
                  .toLowerCase()
                  .contains(q)),
    );
  }

  @override
  Future<BookingPage> history(HistoryFilter filter, {String? cursor}) =>
      mockCall(_state(), () => BookingPage(_filtered(filter).toList(), null));

  @override
  Future<HistorySummary> historySummary(HistoryFilter filter) =>
      mockCall(_state(), () {
        final l = _filtered(filter).toList();
        return HistorySummary(
          totalServices: l.length,
          distinctWorkers: {for (final b in l) ?b.workerId}.length,
          totalSpent: 0,
        );
      });

  /// A new NEW_REQUEST booking for the same worker, as `POST /bookings/rebook` does.
  @override
  Future<Booking> rebook(String bookingId, {DateTime? startDate}) =>
      mockCall(_state(), () {
        final old = _items[_index(bookingId)];
        final made = Booking(
          id: 'bk_${++_seq}',
          status: BookingStatus.newRequest,
          categoryCode: old.categoryCode,
          categoryName: old.categoryName,
          engagement: old.engagement,
          workerId: old.workerId,
          worker: old.worker,
          areaName: old.areaName,
          addressId: old.addressId,
          startDate: startDate ?? _today.add(const Duration(days: 1)),
          timeline: [BookingTimelineEntry(BookingStatus.newRequest, _now())],
          actions: derivedBookingActions(BookingStatus.newRequest),
          createdAt: _now(),
        );
        _items.insert(0, made);
        return made;
      });

  /// For the payment mock: only a PENDING_PAYMENT booking can be paid.
  bool isPayable(String id) =>
      _items[_index(id)].status == BookingStatus.pendingPayment;

  /// A verified payment moves the booking on, as the backend does.
  void markPaid(String id) =>
      _move(id, {BookingStatus.pendingPayment}, BookingStatus.confirmed);

  @override
  Future<Booking> get(String id, {CancelToken? cancel}) =>
      mockCall(_state(), () => _items[_index(id)]);

  @override
  Future<Booking> schedule(String id, InterviewType type, DateTime at) =>
      mockCall(_state(), () {
        if (!at.isAfter(_now())) {
          throw const ValidationFailure('Pick a future time');
        }
        return _move(
          id,
          {BookingStatus.matched, BookingStatus.interviewTrialScheduled},
          BookingStatus.interviewTrialScheduled,
          scheduledAt: at,
          type: type,
        );
      });

  @override
  Future<Booking> interviewComplete(String id, {String? note}) => mockCall(
    _state(),
    () => _move(id, {
      BookingStatus.interviewTrialScheduled,
    }, BookingStatus.interviewTrialCompleted),
  );

  @override
  Future<Booking> confirmWorker(String id, DateTime startDate) =>
      mockCall(_state(), () {
        if (startDate.isBefore(_today)) {
          throw const ValidationFailure('Start date must be today or later');
        }
        return _move(
          id,
          {BookingStatus.interviewTrialCompleted},
          BookingStatus.pendingPayment,
          startDate: startDate,
        );
      });

  @override
  Future<Booking> reopenMatching(String id) => mockCall(
    _state(),
    () => _move(
      id,
      {
        BookingStatus.matched,
        BookingStatus.interviewTrialScheduled,
        BookingStatus.interviewTrialCompleted,
      },
      // Server returns to MATCHED with the same worker; only the schedule is cleared.
      BookingStatus.matched,
      clearSchedule: true,
    ),
  );

  @override
  Future<Booking> cancel(String id, String reason) => mockCall(
    _state(),
    () => _move(id, {
      BookingStatus.newRequest,
      BookingStatus.matched,
      BookingStatus.interviewTrialScheduled,
      BookingStatus.interviewTrialCompleted,
      BookingStatus.pendingPayment,
      BookingStatus.confirmed,
    }, BookingStatus.cancelled),
  );
}
