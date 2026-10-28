import 'package:dio/dio.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/features/addresses/domain/address.dart';
import 'package:sevanest_customer/features/booking/domain/booking.dart';
import 'package:sevanest_customer/features/interview_trial/domain/interview.dart';
import 'package:sevanest_customer/features/service_discovery/domain/requirement_draft.dart';
import 'package:sevanest_customer/features/service_discovery/domain/timing.dart';
import 'package:sevanest_customer/features/worker_search/domain/worker_search.dart';

/// The deployed backend has no interview resource: an interview or trial is a state of a
/// booking (`MATCHED` -> `INTERVIEW_TRIAL_SCHEDULED` -> `INTERVIEW_TRIAL_COMPLETED`), driven by
/// `POST /bookings` and `POST /bookings/{id}/{action}`. This adapter gives the interview screens
/// their own view of that.
class InterviewRepositoryOverBookings implements InterviewRepository {
  InterviewRepositoryOverBookings(
    this.bookings,
    this.workers, {
    required this.areaIdFor,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final BookingRepository bookings;
  final WorkerSearchRepository workers;

  /// `areaId` for the requirement's address area (from `/service-areas`).
  final Future<String> Function(RequirementDraft draft) areaIdFor;
  final DateTime Function() _now;

  static DateTime at(DateTime date, String slot) {
    final m = parseSlot(slot) ?? 0;
    return DateTime(date.year, date.month, date.day, m ~/ 60, m % 60);
  }

  /// "09:00"-style window of the draft's timing, when it has explicit hours.
  static (String?, String?) _window(Timing? t) {
    final s = t?.startMinutes;
    final e = t?.endMinutes;
    if (s == null || e == null || t?.window == TimeWindow.flexible) {
      return (null, null);
    }
    return (slotId(s), slotId(e % (24 * 60)));
  }

  /// The booking an interview request hangs on (it names the worker). The backend requires an
  /// hours window, so a flexible requirement falls back to the worker's own window. The same key on
  /// a retry returns the first booking, so a lost answer cannot create two.
  Future<Booking> createBooking(
    InterviewRequest r,
    String idempotencyKey,
  ) async {
    final d = r.requirement;
    final address = d.address;
    final category = d.serviceId;
    if (address == null || category == null) {
      throw const ValidationFailure('Requirement is incomplete');
    }
    var (from, to) = _window(d.timing);
    if (from == null || to == null) {
      final win = (await workers.detail(r.workerId)).availability.firstOrNull;
      from = win?.start ?? '09:00';
      to = win?.end ?? '18:00';
    }
    final budget = d.budget;
    final money = budget != null && !budget.flexible && budget.min != null;
    return bookings.create(
      BookingRequest(
        category: category,
        areaId: await areaIdFor(d),
        addressId: address.id,
        startDate:
            d.startDate ?? DateTime(r.date.year, r.date.month, r.date.day),
        engagement: d.engagement,
        availableFrom: from,
        availableTo: to,
        workerId: r.workerId,
        budgetMin: money ? budget.min : null,
        budgetMax: money ? budget.max : null,
        budgetPeriod: money ? budget.period : null,
        note: r.note,
      ),
      idempotencyKey: idempotencyKey,
    );
  }

  @override
  Future<Interview> create(
    InterviewRequest r, {
    required String idempotencyKey,
  }) async {
    final booking = await createBooking(r, idempotencyKey);
    return _toInterview(
      await bookings.schedule(booking.id, r.type, at(r.date, r.slot)),
    );
  }

  @override
  Future<Interview> reschedule(
    String id,
    DateTime date,
    String slot, {
    required String idempotencyKey,
  }) async {
    final current = await bookings.get(id);
    return _toInterview(
      await bookings.schedule(
        id,
        current.scheduleType ?? InterviewType.interview,
        at(date, slot),
      ),
    );
  }

  @override
  Future<InterviewPage> list({String? cursor}) async {
    final page = await bookings.list(cursor: cursor);
    return InterviewPage([
      for (final b in page.items)
        if (_isInterviewStage(b)) _toInterview(b),
    ], page.nextCursor);
  }

  /// Bookings that are still (or were) at the interview stage and have a worker. From payment on
  /// they belong to the Bookings tab.
  static bool _isInterviewStage(Booking b) =>
      b.workerId != null &&
      switch (b.status) {
        BookingStatus.matched ||
        BookingStatus.interviewTrialScheduled ||
        BookingStatus.interviewTrialCompleted => true,
        BookingStatus.cancelled => b.scheduleType != null,
        _ => false,
      };

  /// Here an interview is a state of its booking, so the ids are the same.
  @override
  Future<String?> interviewIdFor(
    String bookingId, {
    bool openOnly = false,
  }) async => bookingId;

  @override
  Future<Interview> get(String id, {CancelToken? cancel}) async =>
      _toInterview(await bookings.get(id, cancel: cancel));

  @override
  Future<Interview> cancel(String id, {String? reason}) async => _toInterview(
    await bookings.cancel(id, reason ?? 'Cancelled by customer'),
  );

  @override
  Future<Interview> decline(String id) async =>
      _toInterview(await bookings.reopenMatching(id));

  @override
  Future<Interview> complete(String id) async =>
      _toInterview(await bookings.interviewComplete(id));

  /// Only the live backend proposes other times; nothing to answer here.
  @override
  Future<Interview> answerProposal(String id, {required bool accept}) =>
      get(id);

  @override
  Future<List<InterviewSlot>> slots(String workerId, DateTime date) async {
    final w = await workers.detail(workerId);
    final win = w.availability.firstOrNull;
    return generateInterviewSlots(
      date: date,
      now: _now(),
      windowStart: win?.start,
      windowEnd: win?.end,
    );
  }

  static InterviewStatus _status(Booking b) => switch (b.status) {
    BookingStatus.newRequest =>
      b.workerId == null ? InterviewStatus.notAFit : InterviewStatus.requested,
    BookingStatus.matched => InterviewStatus.requested,
    BookingStatus.interviewTrialScheduled => InterviewStatus.scheduled,
    BookingStatus.interviewTrialCompleted => InterviewStatus.completed,
    BookingStatus.pendingPayment ||
    BookingStatus.confirmed ||
    BookingStatus.active ||
    BookingStatus.replacementRequested ||
    BookingStatus.completed => InterviewStatus.confirmed,
    BookingStatus.cancelled => InterviewStatus.cancelled,
    BookingStatus.replaced || BookingStatus.unknown => InterviewStatus.unknown,
  };

  static Set<InterviewAction> _actions(Set<BookingAction> a) => {
    for (final x in a)
      ?switch (x) {
        BookingAction.cancel => InterviewAction.cancel,
        BookingAction.schedule => InterviewAction.reschedule,
        BookingAction.interviewComplete => InterviewAction.complete,
        BookingAction.confirmWorker => InterviewAction.confirm,
        BookingAction.reopenMatching => InterviewAction.decline,
        _ => null,
      },
  };

  static Interview _toInterview(Booking b) {
    final when = b.scheduledAt;
    return Interview(
      id: b.id,
      status: _status(b),
      type: b.scheduleType ?? InterviewType.interview,
      workerId: b.workerId ?? '',
      bookingId: b.id,
      worker: b.worker,
      date: when == null ? null : DateTime(when.year, when.month, when.day),
      slot: when == null ? null : slotId(when.hour * 60 + when.minute),
      note: b.note,
      requirement: requirementOf(b),
      actions: _actions(b.actions),
    );
  }

  /// What the screens show of the requirement, from the booking.
  static RequirementDraft requirementOf(Booking b) => RequirementDraft(
    serviceId: b.categoryCode,
    engagement: b.engagement,
    address: b.areaName == null
        ? null
        : Address(
            id: b.addressId ?? '',
            line: '',
            area: b.areaName!,
            city: '',
            pincode: '',
          ),
    startDate: b.startDate,
  );
}
