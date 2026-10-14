// Module 11: replacement request and status screens (REP-01 .. REP-12), on the real routes of
// docs/backend_openapi_2026-10-13.json. Widget tests use the design state names of screens 25 / 26.
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/features/booking/domain/booking.dart';
import 'package:sevanest_customer/features/booking/presentation/providers/booking_providers.dart';
import 'package:sevanest_customer/features/replacement/data/replacement_repository_mock.dart';
import 'package:sevanest_customer/features/replacement/domain/replacement.dart';
import 'package:sevanest_customer/features/replacement/presentation/providers/replacement_providers.dart';
import 'package:sevanest_customer/features/service_discovery/domain/catalog.dart';
import 'package:sevanest_customer/features/worker_search/data/worker_search_repository_mock.dart';
import 'package:sevanest_customer/features/worker_search/domain/worker_search.dart';

import '../../helpers/discover_harness.dart';

Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 3; i++) {
    await t.pumpAndSettle();
    await t.pump(const Duration(seconds: 1));
  }
  await t.pumpAndSettle();
}

class _Rep implements ReplacementRepository {
  final items = <String, Replacement>{};
  Object? createFails;
  Object? getFails;
  Object? listFails;
  Object? cancelFails;
  Object? selectFails;

  /// The request exists on the server although the answer was lost.
  var storeThenFail = false;
  Completer<void>? gate;
  Completer<void>? getGate;
  var createCalls = 0;
  var selectCalls = 0;
  var cancelCalls = 0;
  var getCalls = 0;
  final createKeys = <String>[];
  final selectKeys = <String>[];
  String? lastReason;
  String? lastNotes;
  String? lastWorker;

  /// Runs inside select before it answers (a worker taken meanwhile, a lost answer).
  void Function(_Rep rep)? onSelect;

  @override
  Future<Replacement> create({
    required String bookingId,
    required String reason,
    String? notes,
    required String idempotencyKey,
  }) async {
    createCalls++;
    createKeys.add(idempotencyKey);
    lastReason = reason;
    lastNotes = notes;
    await gate?.future;
    final r = Replacement(
      id: 'rp_3104',
      bookingId: bookingId,
      status: ReplacementStatus.requested,
      reason: reason,
      notes: notes,
      createdAt: DateTime(2026, 10, 9, 20, 15),
    );
    final f = createFails;
    if (f != null) {
      if (storeThenFail) items[r.id] = r;
      throw f;
    }
    return items[r.id] = r;
  }

  Object? alternativesFails;
  var alternativesCalls = 0;
  String? lastListBooking;

  @override
  Future<ReplacementPage> list({String? cursor, String? bookingId}) async {
    lastListBooking = bookingId;
    final f = listFails;
    if (f != null) throw f;
    return ReplacementPage([
      for (final r in items.values.toList().reversed)
        if (bookingId == null || r.bookingId == bookingId) r,
    ], null);
  }

  @override
  Future<WorkerPage> alternatives(String id, {String? cursor}) async {
    alternativesCalls++;
    final f = alternativesFails;
    if (f != null) throw f;
    final r = items[id] ?? (throw const NotFoundFailure());
    if (r.status != ReplacementStatus.approved) {
      throw const ConflictFailure('x', 'INVALID_TRANSITION');
    }
    return WorkerPage(_altStore[id] ?? const [], null);
  }

  @override
  Future<Replacement> get(String id) async {
    getCalls++;
    await getGate?.future;
    final f = getFails;
    if (f != null) throw f;
    return items[id] ?? (throw const NotFoundFailure());
  }

  @override
  Future<Replacement> cancel(
    String id, {
    required String idempotencyKey,
  }) async {
    cancelCalls++;
    final f = cancelFails;
    if (f != null) throw f;
    return items[id] = _r(id: id, status: ReplacementStatus.cancelled);
  }

  @override
  Future<Replacement> select(
    String id,
    String workerId, {
    required String idempotencyKey,
  }) async {
    selectCalls++;
    selectKeys.add(idempotencyKey);
    lastWorker = workerId;
    await gate?.future;
    onSelect?.call(this);
    final f = selectFails;
    if (f != null) throw f;
    return items[id] = _r(
      id: id,
      status: ReplacementStatus.completed,
      replacementBookingId: 'b2',
    );
  }

  @override
  Future<List<ChainEntry>> chain(String bookingId) async => [
    const ChainEntry(
      bookingId: 'b1',
      position: 1,
      status: BookingStatus.replaced,
      current: true,
    ),
    ChainEntry(
      bookingId: 'b2',
      position: 2,
      status: BookingStatus.matched,
      current: false,
      replacesBookingId: 'b1',
      startDate: DateTime(2026, 10, 12),
    ),
  ];
}

/// The cards `GET .../alternatives` answers per request id; `_r` records them.
final _altStore = <String, List<WorkerSummary>>{};

Replacement _r({
  String id = 'rp_3104',
  ReplacementStatus status = ReplacementStatus.requested,
  String bookingId = 'b1',
  List<String> alternatives = const [],
  String? replacementBookingId,
  String? remarks,
  String reason = 'Work quality is not good',
  String? notes,
}) {
  _altStore[id] = [
    for (final w in alternatives) ?WorkerSearchRepositoryMock.byId(w),
  ];
  return _r2(
    id: id,
    bookingId: bookingId,
    status: status,
    replacementBookingId: replacementBookingId,
    remarks: remarks,
    reason: reason,
    notes: notes,
  );
}

Replacement _r2({
  required String id,
  required String bookingId,
  required ReplacementStatus status,
  String? replacementBookingId,
  String? remarks,
  required String reason,
  String? notes,
}) => Replacement(
  id: id,
  bookingId: bookingId,
  status: status,
  reason: reason,
  notes: notes,
  decisionRemarks: remarks,
  replacementBookingId: replacementBookingId,
  createdAt: DateTime(2026, 10, 9, 20, 15),
  decidedAt: DateTime(2026, 10, 9, 21, 40),
  completedAt: DateTime(2026, 10, 10, 11, 30),
  timeline: [
    ReplacementEvent(
      status: ReplacementStatus.requested,
      at: DateTime(2026, 10, 9, 20, 15),
      actor: ReplacementActor.customer,
    ),
  ],
);

class _Bookings implements BookingRepository {
  _Bookings(List<Booking> items) : items = {for (final b in items) b.id: b};
  final Map<String, Booking> items;

  @override
  Future<BookingPage> list({String? cursor}) async =>
      BookingPage(items.values.toList(), null);

  @override
  Future<Booking> get(String id, {CancelToken? cancel}) async =>
      items[id] ?? (throw const NotFoundFailure());

  @override
  dynamic noSuchMethod(Invocation i) =>
      throw UnimplementedError('${i.memberName}');
}

Booking _booking(
  String id,
  BookingStatus status, {
  Set<BookingAction>? actions,
  DateTime? startDate,
  String? previous,
}) => Booking(
  id: id,
  status: status,
  categoryName: 'Cook',
  engagement: EngagementType.fullTime,
  workerId: 'cook-7',
  worker: WorkerSearchRepositoryMock.byId('cook-7'),
  areaName: 'Madhapur',
  startDate: startDate ?? DateTime(2026, 10, 8),
  actions: actions ?? derivedBookingActions(status),
  previousBookingId: previous,
);

void main() {
  late _Rep rep;
  late _Bookings books;

  setUp(() {
    _altStore.clear();
    rep = _Rep();
    books = _Bookings([
      _booking('b1', BookingStatus.active),
      _booking('b2', BookingStatus.matched, startDate: DateTime(2026, 10, 12)),
    ]);
  });

  Future<DiscoverEnv> open(
    WidgetTester t,
    String route, {
    List<Override> extra = const [],
  }) async {
    final env = await launchDiscover(
      t,
      height: 2600,
      overrides: [
        bookingRepositoryProvider.overrideWithValue(books),
        replacementRepositoryProvider.overrideWithValue(rep),
        ...extra,
      ],
    );
    await env.go(route);
    await settle(t);
    return env;
  }

  Finder k(String key) => find.byKey(Key(key));

  String where(WidgetTester t) {
    final conf = GoRouter.of(
      t.element(find.byType(Scaffold).first),
    ).routerDelegate.currentConfiguration;
    final last = conf.last as dynamic;
    try {
      // ignore: avoid_dynamic_calls
      return (last.matches.uri as Uri).toString();
    } on Object {
      return conf.uri.toString();
    }
  }

  Future<void> tapKey(WidgetTester t, String key) async {
    await t.ensureVisible(k(key));
    await t.pump();
    await t.tap(k(key));
    await settle(t);
  }

  Future<void> submitReason(
    WidgetTester t,
    String reasonKey, {
    String? note,
  }) async {
    await tapKey(t, reasonKey);
    if (note != null) {
      await t.enterText(k('replacement_notes_field'), note);
      await t.pump();
    }
  }

  bool submitEnabled(WidgetTester t) =>
      t
          .widget<FilledButton>(
            find.descendant(
              of: k('replacement_submit_btn'),
              matching: find.byType(FilledButton),
            ),
          )
          .onPressed !=
      null;

  group('request form (design screen 25)', () {
    testWidgets('Default: card, eight reasons, submit disabled with a hint', (
      t,
    ) async {
      await open(t, '/replacements/new?bookingId=b1');
      expect(k('replacement_booking_card'), findsOneWidget);
      expect(find.text("Let's find you a better match"), findsOneWidget);
      for (final r in ReplacementReason.values) {
        expect(k('replacement_reason_${r.name}'), findsOneWidget);
      }
      expect(find.text('Choose a reason to continue'), findsOneWidget);
      expect(submitEnabled(t), isFalse);
      expect(k('replacement_cancel_btn'), findsOneWidget);
      // The backend has no needed-from field, so the design's date question is not offered.
      expect(find.text('From a date'), findsNothing);
      expect(find.text('When do you need someone?'), findsNothing);
    });

    testWidgets('REP-02 Reason chosen enables Submit; notes are optional', (
      t,
    ) async {
      await open(t, '/replacements/new?bookingId=b1');
      await submitReason(t, 'replacement_reason_workQuality');
      expect(submitEnabled(t), isTrue);
      expect(find.text('Choose a reason to continue'), findsNothing);
      expect(
        find.textContaining('Optional', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('REP-02 Other, note required: error and disabled until typed', (
      t,
    ) async {
      await open(t, '/replacements/new?bookingId=b1');
      await submitReason(t, 'replacement_reason_other');
      expect(find.text('Please tell us what happened'), findsOneWidget);
      expect(find.text('Tell us what happened to continue'), findsOneWidget);
      expect(submitEnabled(t), isFalse);
      await t.enterText(k('replacement_notes_field'), 'He broke my plates');
      await t.pumpAndSettle();
      expect(find.text('Please tell us what happened'), findsNothing);
      expect(submitEnabled(t), isTrue);
    });

    testWidgets('Safety concern shows the support card and links to support', (
      t,
    ) async {
      await open(t, '/replacements/new?bookingId=b1');
      expect(k('replacement_safety_card'), findsNothing);
      await submitReason(t, 'replacement_reason_safety');
      expect(k('replacement_safety_card'), findsOneWidget);
      expect(submitEnabled(t), isTrue);
      await tapKey(t, 'replacement_safety_support_btn');
      expect(where(t), '/support/new?bookingId=b1');
    });

    testWidgets('REP-01 Not eligible: no replace action locks the form', (
      t,
    ) async {
      books.items['b1'] = _booking(
        'b1',
        BookingStatus.active,
        actions: {BookingAction.viewService},
      );
      await open(t, '/replacements/new?bookingId=b1');
      expect(k('replacement_not_eligible'), findsOneWidget);
      expect(
        find.text("Replacement isn't available for this booking"),
        findsOneWidget,
      );
      expect(k('replacement_booking_card'), findsOneWidget);
      expect(k('replacement_reason_other'), findsNothing);
      expect(k('replacement_submit_btn'), findsNothing);
      await tapKey(t, 'replacement_support_btn');
      expect(where(t), '/support/new?bookingId=b1');
    });

    testWidgets('REP-03 Submit -> dialog -> one request -> Request received', (
      t,
    ) async {
      await open(t, '/replacements/new?bookingId=b1');
      await submitReason(
        t,
        'replacement_reason_workQuality',
        note: '  Food is undercooked ',
      );
      await tapKey(t, 'replacement_submit_btn');
      expect(find.text('Submit replacement request?'), findsOneWidget);
      expect(rep.createCalls, 0);
      await tapKey(t, 'replacement_confirm_btn');
      expect(rep.createCalls, 1);
      expect(rep.lastReason, 'Work quality is not good');
      expect(rep.lastNotes?.trim(), 'Food is undercooked');
      expect(k('replacement_received'), findsOneWidget);
      expect(find.text('Request received'), findsOneWidget);
      expect(k('replacement_received_ref'), findsOneWidget);
      expect(find.text('Work quality is not good'), findsOneWidget);
      expect(find.text('Under review'), findsOneWidget);
      expect(find.text('Request sent'), findsOneWidget);
    });

    testWidgets('REP-03 Track request replaces the form: back skips it', (
      t,
    ) async {
      final env = await open(t, '/bookings/b1');
      await tapKey(t, 'booking_replace_btn');
      expect(where(t), '/replacements/new?bookingId=b1');
      await submitReason(t, 'replacement_reason_notOnTime');
      await tapKey(t, 'replacement_submit_btn');
      await tapKey(t, 'replacement_confirm_btn');
      await tapKey(t, 'replacement_track_btn');
      expect(where(t), '/replacements/rp_3104');
      expect(k('replacement_banner_review'), findsOneWidget);
      await tapKey(t, 'app_back_btn');
      expect(env.where, '/bookings/b1');
      expect(k('replacement_reason_other'), findsNothing);
    });

    testWidgets('Back to booking from Request received', (t) async {
      await open(t, '/replacements/new?bookingId=b1');
      await submitReason(t, 'replacement_reason_notOnTime');
      await tapKey(t, 'replacement_submit_btn');
      await tapKey(t, 'replacement_confirm_btn');
      // The "Request sent" snackbar floats over the buttons for a few seconds.
      await t.pump(const Duration(seconds: 6));
      await t.pumpAndSettle();
      await tapKey(t, 'replacement_back_booking_btn');
      expect(where(t), '/bookings/b1');
    });

    testWidgets('Go back in the dialog sends nothing', (t) async {
      await open(t, '/replacements/new?bookingId=b1');
      await submitReason(t, 'replacement_reason_notOnTime');
      await tapKey(t, 'replacement_submit_btn');
      await tapKey(t, 'dialog_cancel_btn');
      expect(rep.createCalls, 0);
      expect(k('replacement_reason_notOnTime'), findsOneWidget);
    });

    testWidgets('Submitting: spinner label, and a second tap sends nothing', (
      t,
    ) async {
      rep.gate = Completer<void>();
      await open(t, '/replacements/new?bookingId=b1');
      await submitReason(t, 'replacement_reason_notOnTime');
      await tapKey(t, 'replacement_submit_btn');
      await t.tap(k('replacement_confirm_btn'));
      await t.pump();
      expect(find.text('Submitting...'), findsOneWidget);
      expect(submitEnabled(t), isFalse);
      await t.tap(k('replacement_submit_btn'), warnIfMissed: false);
      await t.pump();
      expect(rep.createCalls, 1);
      rep.gate!.complete();
      await settle(t);
      expect(rep.createCalls, 1);
      expect(k('replacement_received'), findsOneWidget);
    });

    testWidgets('REP-04 409 already requested opens the existing request', (
      t,
    ) async {
      rep.items['rp_old'] = _r(id: 'rp_old');
      rep.createFails = const ConflictFailure('x', 'REPLACEMENT_ALREADY_OPEN');
      await open(t, '/replacements/new?bookingId=b1');
      await submitReason(t, 'replacement_reason_notOnTime');
      await tapKey(t, 'replacement_submit_btn');
      await tapKey(t, 'replacement_confirm_btn');
      expect(where(t), '/replacements/rp_old');
      expect(k('replacement_banner_review'), findsOneWidget);
    });

    testWidgets('a booking that already has a request opens it straight away', (
      t,
    ) async {
      books.items['b1'] = _booking('b1', BookingStatus.replacementRequested);
      rep.items['rp_old'] = _r(id: 'rp_old');
      await open(t, '/replacements/new?bookingId=b1');
      expect(where(t), '/replacements/rp_old');
    });

    testWidgets('REP-05 422 REPLACEMENT_NOT_ELIGIBLE locks the form', (
      t,
    ) async {
      rep.createFails = const ValidationFailure(
        'no',
        {},
        'REPLACEMENT_NOT_ELIGIBLE',
      );
      await open(t, '/replacements/new?bookingId=b1');
      await submitReason(t, 'replacement_reason_notOnTime');
      await tapKey(t, 'replacement_submit_btn');
      await tapKey(t, 'replacement_confirm_btn');
      expect(k('replacement_not_eligible'), findsOneWidget);
      expect(k('replacement_submit_btn'), findsNothing);
      expect(rep.createCalls, 1);
    });

    testWidgets('403 locks the form too, without the server text', (t) async {
      rep.createFails = const ForbiddenFailure('RAW SERVER TEXT');
      await open(t, '/replacements/new?bookingId=b1');
      await submitReason(t, 'replacement_reason_notOnTime');
      await tapKey(t, 'replacement_submit_btn');
      await tapKey(t, 'replacement_confirm_btn');
      expect(k('replacement_not_eligible'), findsOneWidget);
      expect(find.text('RAW SERVER TEXT'), findsNothing);
    });

    testWidgets('Submit error: details kept, Try again reuses the same key', (
      t,
    ) async {
      rep.createFails = const ServerFailure('RAW 500 TEXT');
      await open(t, '/replacements/new?bookingId=b1');
      await submitReason(t, 'replacement_reason_workQuality', note: 'Late');
      await tapKey(t, 'replacement_submit_btn');
      await tapKey(t, 'replacement_confirm_btn');
      expect(k('replacement_error_card'), findsOneWidget);
      expect(find.text("We couldn't submit your request"), findsOneWidget);
      expect(find.text('RAW 500 TEXT'), findsNothing);
      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('Late'), findsOneWidget);
      rep.createFails = null;
      await tapKey(t, 'replacement_submit_btn');
      await tapKey(t, 'replacement_confirm_btn');
      expect(rep.createCalls, 2);
      expect(rep.createKeys[0], rep.createKeys[1]);
      expect(k('replacement_received'), findsOneWidget);
    });

    testWidgets('editing after a failure gets a new key', (t) async {
      rep.createFails = const ServerFailure();
      await open(t, '/replacements/new?bookingId=b1');
      await submitReason(t, 'replacement_reason_workQuality');
      await tapKey(t, 'replacement_submit_btn');
      await tapKey(t, 'replacement_confirm_btn');
      rep.createFails = null;
      await tapKey(t, 'replacement_reason_behaviour');
      await tapKey(t, 'replacement_submit_btn');
      await tapKey(t, 'replacement_confirm_btn');
      expect(rep.createKeys[0], isNot(rep.createKeys[1]));
    });

    testWidgets(
      'a lost answer: the request that did go through is found, not asked twice',
      (t) async {
        rep.createFails = const NetworkFailure();
        rep.storeThenFail = true;
        await open(t, '/replacements/new?bookingId=b1');
        await submitReason(t, 'replacement_reason_notOnTime');
        await tapKey(t, 'replacement_submit_btn');
        await tapKey(t, 'replacement_confirm_btn');
        expect(rep.createCalls, 1);
        expect(k('replacement_received'), findsOneWidget);
        expect(k('replacement_offline_banner'), findsNothing);
      },
    );

    testWidgets('Offline: answers kept, Submit locked, Retry sends it', (
      t,
    ) async {
      rep.createFails = const NetworkFailure();
      rep.listFails = const NetworkFailure();
      await open(t, '/replacements/new?bookingId=b1');
      await submitReason(t, 'replacement_reason_workQuality', note: 'Late');
      await tapKey(t, 'replacement_submit_btn');
      await tapKey(t, 'replacement_confirm_btn');
      expect(k('replacement_offline_banner'), findsOneWidget);
      expect(
        find.text("You're offline. Your answers are kept."),
        findsOneWidget,
      );
      expect(find.text('Connect to the internet to submit'), findsOneWidget);
      expect(find.text('Late'), findsOneWidget);
      expect(submitEnabled(t), isFalse);
      rep.createFails = null;
      rep.listFails = null;
      await tapKey(t, 'replacement_offline_retry_btn');
      expect(rep.createKeys[0], rep.createKeys[1]);
      expect(k('replacement_received'), findsOneWidget);
    });

    testWidgets('leaving with input asks to discard; keep editing stays', (
      t,
    ) async {
      await open(t, '/bookings/b1');
      await tapKey(t, 'booking_replace_btn');
      await submitReason(t, 'replacement_reason_notOnTime');
      await tapKey(t, 'app_back_btn');
      expect(find.text('Discard changes?'), findsOneWidget);
      await tapKey(t, 'dialog_cancel_btn');
      expect(where(t), '/replacements/new?bookingId=b1');
      await tapKey(t, 'replacement_cancel_btn');
      await tapKey(t, 'replacement_discard_confirm_btn');
      expect(where(t), '/bookings/b1');
      expect(rep.createCalls, 0);
    });

    testWidgets('leaving an untouched form needs no dialog', (t) async {
      await open(t, '/bookings/b1');
      await tapKey(t, 'booking_replace_btn');
      await tapKey(t, 'replacement_cancel_btn');
      expect(where(t), '/bookings/b1');
    });

    testWidgets('a missing booking id reads as not eligible', (t) async {
      await open(t, '/replacements/new');
      expect(k('replacement_not_eligible'), findsOneWidget);
    });
  });

  group('status screen (design screen 26)', () {
    testWidgets('Loading shows the skeleton, not the content', (t) async {
      rep.items['rp1'] = _r(id: 'rp1');
      rep.getFails = null;
      final gate = rep.getGate = Completer<void>();
      await open(t, '/replacements/rp1');
      expect(find.bySemanticsLabel('Loading'), findsWidgets);
      expect(k('replacement_request_card'), findsNothing);
      gate.complete();
      await settle(t);
      expect(k('replacement_request_card'), findsOneWidget);
    });

    testWidgets('Error: couldn\'t load, Try again recovers', (t) async {
      rep.items['rp1'] = _r(id: 'rp1');
      rep.getFails = const ServerFailure('RAW');
      await open(t, '/replacements/rp1');
      expect(find.text("We couldn't load this request"), findsOneWidget);
      expect(find.text('RAW'), findsNothing);
      rep.getFails = null;
      await tapKey(t, 'error_retry_btn');
      expect(k('replacement_request_card'), findsOneWidget);
    });

    testWidgets('Offline after a load: what was loaded stays, with a banner', (
      t,
    ) async {
      rep.items['rp1'] = _r(id: 'rp1');
      final env = await open(t, '/replacements/rp1');
      rep.getFails = const NetworkFailure();
      env.container.invalidate(replacementProvider('rp1'));
      await settle(t);
      expect(k('replacement_offline_banner'), findsOneWidget);
      expect(k('replacement_request_card'), findsOneWidget);
      rep.getFails = null;
      await tapKey(t, 'replacement_offline_retry_btn');
      expect(k('replacement_offline_banner'), findsNothing);
    });

    // REP-07: each state shows its own banner and only its own buttons.
    final table =
        <(String, Replacement Function(), String, List<String>, List<String>)>[
          (
            'Under review',
            () => _r(id: 'rp1'),
            'review',
            ['replacement_support_btn', 'replacement_withdraw_btn'],
            [
              'replacement_select_btn',
              'replacement_view_booking_btn',
              'replacement_back_booking_btn',
              'replacement_find_worker_btn',
            ],
          ),
          (
            'Approved, no alternatives yet',
            () => _r(id: 'rp1', status: ReplacementStatus.approved),
            'finding',
            ['replacement_support_btn', 'replacement_withdraw_btn'],
            ['replacement_select_btn', 'replacement_view_booking_btn'],
          ),
          (
            'Alternatives ready',
            () => _r(
              id: 'rp1',
              status: ReplacementStatus.approved,
              alternatives: ['cook-2', 'cook-5', 'cook-8'],
            ),
            'ready',
            ['replacement_select_btn', 'replacement_withdraw_btn'],
            ['replacement_view_booking_btn', 'replacement_back_booking_btn'],
          ),
          (
            'Replacement scheduled',
            () => _r(
              id: 'rp1',
              status: ReplacementStatus.completed,
              replacementBookingId: 'b2',
            ),
            'scheduled',
            ['replacement_view_booking_btn', 'replacement_view_old_btn'],
            [
              'replacement_withdraw_btn',
              'replacement_select_btn',
              'replacement_support_btn',
            ],
          ),
          (
            "Couldn't match",
            () => _r(
              id: 'rp1',
              status: ReplacementStatus.rejected,
              remarks: 'No worker is free in your area.',
            ),
            'rejected',
            [
              'replacement_again_btn',
              'replacement_support_btn',
              'replacement_find_worker_btn',
              'replacement_back_booking_btn',
            ],
            ['replacement_withdraw_btn', 'replacement_select_btn'],
          ),
          (
            'Cancelled',
            () => _r(id: 'rp1', status: ReplacementStatus.cancelled),
            'cancelled',
            ['replacement_back_booking_btn', 'replacement_help_support_btn'],
            [
              'replacement_withdraw_btn',
              'replacement_select_btn',
              'replacement_view_booking_btn',
            ],
          ),
        ];
    for (final (name, make, view, shown, hidden) in table) {
      testWidgets('REP-07 $name: banner "$view" and only its buttons', (
        t,
      ) async {
        rep.items['rp1'] = make();
        await open(t, '/replacements/rp1');
        expect(k('replacement_banner_$view'), findsOneWidget);
        expect(k('replacement_request_card'), findsOneWidget);
        expect(k('replacement_timeline'), findsOneWidget);
        for (final key in shown) {
          expect(k(key), findsOneWidget, reason: key);
        }
        for (final key in hidden) {
          expect(k(key), findsNothing, reason: key);
        }
      });
    }

    testWidgets('Completed: started replacement reads "Replacement complete"', (
      t,
    ) async {
      books.items['b2'] = _booking(
        'b2',
        BookingStatus.active,
        startDate: DateTime(2026, 10, 9),
      );
      rep.items['rp1'] = _r(
        id: 'rp1',
        status: ReplacementStatus.completed,
        replacementBookingId: 'b2',
      );
      await open(t, '/replacements/rp1');
      expect(k('replacement_banner_complete'), findsOneWidget);
      expect(find.text('Replacement complete'), findsOneWidget);
      expect(k('replacement_view_booking_btn'), findsOneWidget);
    });

    testWidgets('scheduled banner names the start date from the new booking', (
      t,
    ) async {
      rep.items['rp1'] = _r(
        id: 'rp1',
        status: ReplacementStatus.completed,
        replacementBookingId: 'b2',
      );
      await open(t, '/replacements/rp1');
      expect(find.text('Replacement confirmed'), findsOneWidget);
      expect(
        find.text(
          'Your new booking is set to start on Mon, 12 Oct. Open it to follow the next steps.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('the request card keeps the current engagement visible', (
      t,
    ) async {
      rep.items['rp1'] = _r(id: 'rp1', notes: 'Undercooked food');
      await open(t, '/replacements/rp1');
      expect(k('replacement_request_no'), findsOneWidget);
      expect(k('replacement_previous_tag'), findsOneWidget);
      expect(find.text('Current engagement'), findsOneWidget);
      expect(find.textContaining('Cook'), findsWidgets);
      expect(find.text('Work quality is not good'), findsOneWidget);
      expect(find.text('Undercooked food'), findsOneWidget);
      expect(find.textContaining('Submitted'), findsOneWidget);
      expect(find.text('Needed'), findsNothing);
    });

    testWidgets('after a replacement the old engagement reads "Previous"', (
      t,
    ) async {
      books.items['b1'] = _booking('b1', BookingStatus.replaced);
      rep.items['rp1'] = _r(
        id: 'rp1',
        status: ReplacementStatus.completed,
        replacementBookingId: 'b2',
      );
      await open(t, '/replacements/rp1');
      expect(find.text('Previous engagement'), findsOneWidget);
    });

    testWidgets('Copy request ID confirms with a snackbar', (t) async {
      rep.items['rp1'] = _r(id: 'rp1');
      await open(t, '/replacements/rp1');
      await t.ensureVisible(k('replacement_copy_btn'));
      await t.tap(k('replacement_copy_btn'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('Request ID copied'), findsOneWidget);
    });

    testWidgets('the Progress timeline follows the status', (t) async {
      rep.items['rp1'] = _r(id: 'rp1');
      await open(t, '/replacements/rp1');
      for (final s in [
        'Request received',
        'Under review',
        'Alternatives ready',
        'You choose a worker',
        'Replacement starts',
      ]) {
        expect(find.text(s), findsWidgets);
      }
      expect(find.text('Now'), findsOneWidget);
      expect(find.text('Upcoming'), findsNWidgets(3));
    });

    testWidgets("Couldn't match shows the team's note and support target", (
      t,
    ) async {
      rep.items['rp1'] = _r(
        id: 'rp1',
        status: ReplacementStatus.rejected,
        remarks: 'No worker is free in your area.',
      );
      await open(t, '/replacements/rp1');
      expect(k('replacement_team_note'), findsOneWidget);
      expect(find.text('No worker is free in your area.'), findsOneWidget);
      await tapKey(t, 'replacement_support_btn');
      expect(where(t), '/support/new?replacementId=rp1');
    });

    testWidgets("Couldn't match: Find a worker and Back to booking", (t) async {
      rep.items['rp1'] = _r(id: 'rp1', status: ReplacementStatus.rejected);
      await open(t, '/replacements/rp1');
      await tapKey(t, 'replacement_back_booking_btn');
      expect(where(t), '/bookings/b1');
    });

    testWidgets('an unknown status reads "Updated", never the raw code', (
      t,
    ) async {
      rep.items['rp1'] = Replacement.fromJson({
        'id': 'rp1',
        'bookingId': 'b1',
        'status': 'ON_HOLD',
        'reason': 'x',
      })!;
      await open(t, '/replacements/rp1');
      expect(k('replacement_banner_unknown'), findsOneWidget);
      expect(find.text('Updated'), findsOneWidget);
      expect(find.textContaining('ON_HOLD'), findsNothing);
      expect(k('replacement_back_booking_btn'), findsOneWidget);
    });

    testWidgets('resuming the app reads the request again', (t) async {
      rep.items['rp1'] = _r(id: 'rp1');
      await open(t, '/replacements/rp1');
      final before = rep.getCalls;
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settle(t);
      expect(rep.getCalls, greaterThan(before));
    });

    testWidgets('pull to refresh picks up the staff decision', (t) async {
      rep.items['rp1'] = _r(id: 'rp1');
      await open(t, '/replacements/rp1');
      expect(k('replacement_banner_review'), findsOneWidget);
      rep.items['rp1'] = _r(
        id: 'rp1',
        status: ReplacementStatus.approved,
        alternatives: ['cook-2', 'cook-5'],
      );
      await t.drag(k('replacement_request_card'), const Offset(0, 1400));
      await settle(t);
      expect(k('replacement_banner_ready'), findsOneWidget);
      expect(find.text('2 alternatives are ready'), findsOneWidget);
    });
  });

  group('withdraw (REP-11)', () {
    testWidgets('Cancel request asks first, then cancels once', (t) async {
      rep.items['rp1'] = _r(id: 'rp1');
      await open(t, '/replacements/rp1');
      await tapKey(t, 'replacement_withdraw_btn');
      expect(find.text('Cancel this request?'), findsOneWidget);
      expect(rep.cancelCalls, 0);
      await tapKey(t, 'replacement_withdraw_confirm_btn');
      expect(rep.cancelCalls, 1);
      expect(k('replacement_banner_cancelled'), findsOneWidget);
      expect(k('replacement_withdraw_btn'), findsNothing);
      expect(find.text('Your current worker continues.'), findsOneWidget);
    });

    testWidgets('Keep request does nothing', (t) async {
      rep.items['rp1'] = _r(id: 'rp1');
      await open(t, '/replacements/rp1');
      await tapKey(t, 'replacement_withdraw_btn');
      await tapKey(t, 'dialog_cancel_btn');
      expect(rep.cancelCalls, 0);
      expect(k('replacement_banner_review'), findsOneWidget);
    });

    testWidgets('a failed withdraw says so and keeps the request', (t) async {
      rep.items['rp1'] = _r(id: 'rp1');
      rep.cancelFails = const ServerFailure('RAW');
      await open(t, '/replacements/rp1');
      await tapKey(t, 'replacement_withdraw_btn');
      await tapKey(t, 'replacement_withdraw_confirm_btn');
      expect(
        find.text("We couldn't cancel the request. Please try again."),
        findsOneWidget,
      );
      expect(find.text('RAW'), findsNothing);
      expect(k('replacement_banner_review'), findsOneWidget);
    });

    testWidgets('Approved with alternatives can still be withdrawn', (t) async {
      rep.items['rp1'] = _r(
        id: 'rp1',
        status: ReplacementStatus.approved,
        alternatives: ['cook-2'],
      );
      await open(t, '/replacements/rp1');
      await tapKey(t, 'replacement_withdraw_btn');
      await tapKey(t, 'replacement_withdraw_confirm_btn');
      expect(rep.cancelCalls, 1);
    });
  });

  group('alternatives and selecting (REP-08, REP-09)', () {
    Replacement ready() => _r(
      id: 'rp1',
      status: ReplacementStatus.approved,
      alternatives: ['cook-2', 'cook-5', 'cook-8'],
    );

    testWidgets('REP-08 Alternatives ready: shared worker cards, none chosen', (
      t,
    ) async {
      rep.items['rp1'] = ready();
      await open(t, '/replacements/rp1');
      expect(find.text('3 alternatives are ready'), findsOneWidget);
      for (final w in ['cook-2', 'cook-5', 'cook-8']) {
        expect(k('replacement_alt_$w'), findsOneWidget);
      }
      expect(find.text('Select a worker to continue'), findsOneWidget);
      expect(
        t
            .widget<FilledButton>(
              find.descendant(
                of: k('replacement_select_btn'),
                matching: find.byType(FilledButton),
              ),
            )
            .onPressed,
        isNull,
      );
    });

    testWidgets('REP-08 View profile opens the worker detail', (t) async {
      rep.items['rp1'] = ready();
      await open(t, '/replacements/rp1');
      await tapKey(t, 'replacement_alt_profile_cook-5');
      expect(where(t), '/workers/cook-5');
    });

    testWidgets('Alternative selected enables Confirm replacement', (t) async {
      rep.items['rp1'] = ready();
      await open(t, '/replacements/rp1');
      await tapKey(t, 'replacement_alt_cook-5');
      expect(find.text('Select a worker to continue'), findsNothing);
      expect(
        t
            .widget<FilledButton>(
              find.descendant(
                of: k('replacement_select_btn'),
                matching: find.byType(FilledButton),
              ),
            )
            .onPressed,
        isNotNull,
      );
      expect(
        find.descendant(
          of: k('replacement_alt_cook-5'),
          matching: find.byIcon(Icons.check_circle),
        ),
        findsOneWidget,
      );
    });

    testWidgets('REP-09 Confirmation dialog, then one select, then Completed', (
      t,
    ) async {
      books.items['b2'] = _booking(
        'b2',
        BookingStatus.matched,
        startDate: DateTime(2026, 10, 12),
      );
      rep.items['rp1'] = ready();
      await open(t, '/replacements/rp1');
      await tapKey(t, 'replacement_alt_cook-5');
      await tapKey(t, 'replacement_select_btn');
      expect(find.text('Confirm this replacement?'), findsOneWidget);
      expect(rep.selectCalls, 0);
      await tapKey(t, 'replacement_select_confirm_btn');
      expect(rep.selectCalls, 1);
      expect(rep.lastWorker, 'cook-5');
      expect(k('replacement_banner_scheduled'), findsOneWidget);
      expect(k('replacement_select_btn'), findsNothing);
      expect(k('replacement_alt_cook-5'), findsNothing);
    });

    testWidgets('Go back in the select dialog sends nothing', (t) async {
      rep.items['rp1'] = ready();
      await open(t, '/replacements/rp1');
      await tapKey(t, 'replacement_alt_cook-2');
      await tapKey(t, 'replacement_select_btn');
      await tapKey(t, 'dialog_cancel_btn');
      expect(rep.selectCalls, 0);
    });

    testWidgets('a double tap while selecting sends one request', (t) async {
      rep.items['rp1'] = ready();
      rep.gate = Completer<void>();
      await open(t, '/replacements/rp1');
      await tapKey(t, 'replacement_alt_cook-2');
      await tapKey(t, 'replacement_select_btn');
      await t.tap(k('replacement_select_confirm_btn'));
      await t.pump();
      await t.tap(k('replacement_select_btn'), warnIfMissed: false);
      await t.pump();
      expect(rep.selectCalls, 1);
      rep.gate!.complete();
      await settle(t);
      expect(rep.selectCalls, 1);
    });

    testWidgets(
      '409 worker unavailable: message, list refetched, pick cleared',
      (t) async {
        rep.items['rp1'] = ready();
        rep.selectFails = const ConflictFailure('x', 'WORKER_UNAVAILABLE');
        rep.onSelect = (r) => r.items['rp1'] = _r(
          id: 'rp1',
          status: ReplacementStatus.approved,
          alternatives: ['cook-2', 'cook-8'],
        );
        await open(t, '/replacements/rp1');
        await tapKey(t, 'replacement_alt_cook-5');
        await tapKey(t, 'replacement_select_btn');
        await tapKey(t, 'replacement_select_confirm_btn');
        expect(
          find.text(
            'That worker is no longer available. Please choose another.',
          ),
          findsOneWidget,
        );
        expect(k('replacement_alt_cook-5'), findsNothing);
        expect(k('replacement_alt_cook-2'), findsOneWidget);
        expect(find.text('2 alternatives are ready'), findsOneWidget);
        expect(find.text('Select a worker to continue'), findsOneWidget);
      },
    );

    testWidgets('422 worker not eligible is handled like unavailable', (
      t,
    ) async {
      rep.items['rp1'] = ready();
      rep.selectFails = const ValidationFailure('x', {}, 'WORKER_NOT_ELIGIBLE');
      await open(t, '/replacements/rp1');
      await tapKey(t, 'replacement_alt_cook-5');
      await tapKey(t, 'replacement_select_btn');
      await tapKey(t, 'replacement_select_confirm_btn');
      expect(k('replacement_select_error'), findsOneWidget);
    });

    testWidgets(
      '422 SAME_WORKER and 409 INVALID_TRANSITION say what happened',
      (t) async {
        rep.items['rp1'] = ready();
        rep.selectFails = const ValidationFailure('x', {}, 'SAME_WORKER');
        await open(t, '/replacements/rp1');
        await tapKey(t, 'replacement_alt_cook-5');
        await tapKey(t, 'replacement_select_btn');
        await tapKey(t, 'replacement_select_confirm_btn');
        expect(
          find.text('That is your current worker. Please choose someone else.'),
          findsOneWidget,
        );
        rep.selectFails = const ConflictFailure('x', 'INVALID_TRANSITION');
        await tapKey(t, 'replacement_alt_cook-5');
        await tapKey(t, 'replacement_select_btn');
        await tapKey(t, 'replacement_select_confirm_btn');
        expect(
          find.text('This request has changed. Here is its latest status.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'alternatives come from the alternatives route, not the request',
      (t) async {
        rep.items['rp1'] = ready();
        final env = await open(t, '/replacements/rp1');
        expect(rep.alternativesCalls, greaterThan(0));
        rep.alternativesFails = const NetworkFailure();
        env.container.invalidate(replacementAlternativesProvider('rp1'));
        await settle(t);
        // The choices already loaded stay, with the offline banner.
        expect(k('replacement_offline_banner'), findsOneWidget);
        expect(k('replacement_alt_cook-5'), findsOneWidget);
      },
    );

    testWidgets('a lost answer: the selection that went through is shown', (
      t,
    ) async {
      books.items['b2'] = _booking(
        'b2',
        BookingStatus.matched,
        startDate: DateTime(2026, 10, 12),
      );
      rep.items['rp1'] = ready();
      rep.selectFails = const ServerFailure();
      rep.onSelect = (r) => r.items['rp1'] = _r(
        id: 'rp1',
        status: ReplacementStatus.completed,
        replacementBookingId: 'b2',
      );
      await open(t, '/replacements/rp1');
      await tapKey(t, 'replacement_alt_cook-5');
      await tapKey(t, 'replacement_select_btn');
      await tapKey(t, 'replacement_select_confirm_btn');
      expect(k('replacement_banner_scheduled'), findsOneWidget);
      expect(k('replacement_select_error'), findsNothing);
    });

    testWidgets(
      'a server error that changed nothing says it could not confirm',
      (t) async {
        rep.items['rp1'] = ready();
        rep.selectFails = const ServerFailure('RAW');
        await open(t, '/replacements/rp1');
        await tapKey(t, 'replacement_alt_cook-5');
        await tapKey(t, 'replacement_select_btn');
        await tapKey(t, 'replacement_select_confirm_btn');
        expect(
          find.text("We couldn't confirm the replacement. Please try again."),
          findsOneWidget,
        );
        expect(find.text('RAW'), findsNothing);
        expect(k('replacement_alt_cook-5'), findsOneWidget);
      },
    );

    testWidgets('Offline: Confirm locked with the design hint, Retry selects', (
      t,
    ) async {
      rep.items['rp1'] = ready();
      rep.selectFails = const NetworkFailure();
      await open(t, '/replacements/rp1');
      await tapKey(t, 'replacement_alt_cook-5');
      await tapKey(t, 'replacement_select_btn');
      await tapKey(t, 'replacement_select_confirm_btn');
      expect(find.text('Connect to the internet to continue.'), findsOneWidget);
      expect(k('replacement_offline_banner'), findsOneWidget);
      rep.selectFails = null;
      await tapKey(t, 'replacement_offline_retry_btn');
      expect(rep.selectCalls, 2);
      expect(rep.selectKeys[0], rep.selectKeys[1]);
      expect(find.text('Replacement confirmed'), findsOneWidget);
    });

    testWidgets('choosing another worker uses a new key', (t) async {
      rep.items['rp1'] = ready();
      rep.selectFails = const NetworkFailure();
      await open(t, '/replacements/rp1');
      await tapKey(t, 'replacement_alt_cook-5');
      await tapKey(t, 'replacement_select_btn');
      await tapKey(t, 'replacement_select_confirm_btn');
      rep.selectFails = null;
      await tapKey(t, 'replacement_alt_cook-8');
      await tapKey(t, 'replacement_offline_retry_btn');
      expect(rep.selectKeys[0], isNot(rep.selectKeys[1]));
      expect(rep.lastWorker, 'cook-8');
    });
  });

  group('links between bookings (REP-10)', () {
    testWidgets('Completed: View booking opens the new booking', (t) async {
      rep.items['rp1'] = _r(
        id: 'rp1',
        status: ReplacementStatus.completed,
        replacementBookingId: 'b2',
      );
      await open(t, '/replacements/rp1');
      await tapKey(t, 'replacement_view_booking_btn');
      expect(where(t), '/bookings/b2');
    });

    testWidgets('Completed: the old engagement stays viewable', (t) async {
      rep.items['rp1'] = _r(
        id: 'rp1',
        status: ReplacementStatus.completed,
        replacementBookingId: 'b2',
      );
      await open(t, '/replacements/rp1');
      await tapKey(t, 'replacement_view_old_btn');
      expect(where(t), '/bookings/b1');
      expect(k('booking_status_chip'), findsOneWidget);
      // ... and back returns to the request.
      await tapKey(t, 'app_back_btn');
      expect(where(t), '/replacements/rp1');
    });

    testWidgets('booking detail links to the open request', (t) async {
      books.items['b1'] = _booking('b1', BookingStatus.replacementRequested);
      rep.items['rp1'] = _r(id: 'rp1');
      await open(t, '/bookings/b1');
      expect(k('booking_replace_btn'), findsNothing);
      expect(rep.lastListBooking, 'b1');
      await tapKey(t, 'booking_replacement_btn');
      expect(where(t), '/replacements/rp1');
    });

    testWidgets('booking detail lists the chain and opens each booking', (
      t,
    ) async {
      books.items['b1'] = _booking('b1', BookingStatus.replaced);
      await open(t, '/bookings/b1');
      expect(find.text('Replacement history'), findsOneWidget);
      expect(find.text('This booking'), findsOneWidget);
      await tapKey(t, 'chain_entry_b2');
      expect(where(t), '/bookings/b2');
    });

    testWidgets('the replacement booking points back to the old one', (
      t,
    ) async {
      books.items['b2'] = _booking('b2', BookingStatus.matched, previous: 'b1');
      await open(t, '/bookings/b2');
      await tapKey(t, 'booking_previous_link');
      expect(where(t), '/bookings/b1');
    });

    testWidgets(
      'a booking that was never replaced shows no replacement links',
      (t) async {
        await open(t, '/bookings/b1');
        expect(find.text('Replacement history'), findsNothing);
        expect(k('booking_replacement_btn'), findsNothing);
      },
    );

    testWidgets('entry follows the replace action: hidden when not allowed', (
      t,
    ) async {
      books.items['b1'] = _booking(
        'b1',
        BookingStatus.completed,
        actions: {BookingAction.rate},
      );
      await open(t, '/bookings/b1');
      expect(k('booking_replace_btn'), findsNothing);
    });

    testWidgets(
      'active service hides the request when replace is not allowed',
      (t) async {
        books.items['b1'] = _booking(
          'b1',
          BookingStatus.completed,
          actions: {BookingAction.rate},
        );
        await open(t, '/services/current?bookingId=b1');
        expect(k('service_replace_btn'), findsNothing);
      },
    );

    testWidgets('active service offers the request when replace is allowed', (
      t,
    ) async {
      await open(t, '/services/current?bookingId=b1');
      await tapKey(t, 'service_replace_btn');
      expect(where(t), '/replacements/new?bookingId=b1');
    });
  });

  group('REP-12 Flow I on the seeded mocks', () {
    testWidgets(
      'Active service -> Replacement -> Reason -> Submit -> Status -> Alternatives -> Select',
      (t) async {
        final env = await launchDiscover(t, height: 2600);
        await env.go('/services/current?bookingId=bk_2048');
        await settle(t);
        expect(k('service_replace_btn'), findsOneWidget);
        await tapKey(t, 'service_replace_btn');
        expect(where(t), '/replacements/new?bookingId=bk_2048');
        await submitReason(t, 'replacement_reason_workQuality');
        await tapKey(t, 'replacement_submit_btn');
        await tapKey(t, 'replacement_confirm_btn');
        expect(k('replacement_received'), findsOneWidget);
        await tapKey(t, 'replacement_track_btn');
        expect(where(t), '/replacements/rp_3104');
        expect(k('replacement_banner_review'), findsOneWidget);
        // Staff approve while the customer waits: the next read has the alternatives.
        env.container.invalidate(replacementProvider('rp_3104'));
        await settle(t);
        expect(k('replacement_banner_ready'), findsOneWidget);
        expect(find.text('3 alternatives are ready'), findsOneWidget);
        await tapKey(t, 'replacement_alt_cook-5');
        await tapKey(t, 'replacement_select_btn');
        await tapKey(t, 'replacement_select_confirm_btn');
        expect(
          k('replacement_banner_scheduled').evaluate().isNotEmpty ||
              k('replacement_banner_complete').evaluate().isNotEmpty,
          isTrue,
        );
        expect(k('replacement_view_booking_btn'), findsOneWidget);
        await tapKey(t, 'replacement_view_old_btn');
        expect(where(t), '/bookings/bk_2048');
      },
    );

    testWidgets('the dev mock repository is what runs without overrides', (
      t,
    ) async {
      final env = await launchDiscover(t);
      expect(
        env.container.read(replacementRepositoryProvider),
        isA<ReplacementRepositoryMock>(),
      );
      expect(env.container.read(mockApiProvider).live, isFalse);
    });
  });
}
