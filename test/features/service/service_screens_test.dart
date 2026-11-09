// Module 10: active service, service history and rating (SVC-01 .. SVC-14), on the real routes of
// docs/backend_openapi_2026-10-13.json (attendance, ratings, bookings).
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/widgets/sn_button.dart';
import 'package:sevanest_customer/features/active_service/domain/attendance.dart';
import 'package:sevanest_customer/features/active_service/presentation/providers/service_providers.dart';
import 'package:sevanest_customer/features/addresses/presentation/providers/address_providers.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart'
    show AuthCta;
import 'package:sevanest_customer/features/booking/domain/booking.dart';
import 'package:sevanest_customer/features/booking/presentation/providers/booking_providers.dart';
import 'package:sevanest_customer/features/customer_profile/domain/customer_profile.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/providers/customer_profile_providers.dart';
import 'package:sevanest_customer/features/home/domain/home_data.dart';
import 'package:sevanest_customer/features/ratings/domain/rating.dart';
import 'package:sevanest_customer/features/ratings/presentation/providers/rating_providers.dart';
import 'package:sevanest_customer/features/service_discovery/domain/catalog.dart';
import 'package:sevanest_customer/features/worker_search/data/worker_search_repository_mock.dart';
import 'package:sevanest_customer/features/worker_search/presentation/providers/worker_search_providers.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_parts.dart'
    show GlassNoteField;

import '../../helpers/discover_harness.dart';
import '../../helpers/fakes.dart';

Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 3; i++) {
    await t.pumpAndSettle();
    await t.pump(const Duration(seconds: 1));
  }
  await t.pumpAndSettle();
}

class _Att implements AttendanceRepository {
  _Att([this.entries = const []]);
  List<AttendanceEntry> entries;
  int pageSize = 20;
  Object? pageFails;
  var pageCalls = 0;

  @override
  Future<AttendancePage> page(String bookingId, {String? cursor}) async {
    pageCalls++;
    final f = pageFails;
    if (f != null) throw f;
    final from = int.tryParse(cursor ?? '0') ?? 0;
    final to = (from + pageSize).clamp(0, entries.length);
    return AttendancePage(
      entries.sublist(from, to),
      to < entries.length ? '$to' : null,
    );
  }

  AttendanceSummary? summaryOverride;

  @override
  Future<AttendanceSummary> summary(String bookingId, String month) async {
    int c(AttendanceStatus s) => entries.where((e) => e.status == s).length;
    return summaryOverride ??
        AttendanceSummary(
          month: month,
          present: c(AttendanceStatus.present),
          absent: c(AttendanceStatus.absent),
          exception: c(AttendanceStatus.exception),
          late: c(AttendanceStatus.late),
          leave: c(AttendanceStatus.leave),
        );
  }

  final raised = <(String, String, String)>[];
  Object? raiseFails;

  @override
  Future<AttendanceEntry> raiseException(
    String bookingId, {
    required String date,
    required String note,
    required String idempotencyKey,
  }) async {
    final f = raiseFails;
    if (f != null) throw f;
    raised.add((bookingId, date, note));
    final e = AttendanceEntry(
      id: date,
      date: date,
      status: AttendanceStatus.exception,
      note: note,
    );
    entries = [e, ...entries];
    return e;
  }
}

class _Rate implements RatingRepository {
  final given = <String, Rating>{};
  Object? submitFails;
  Completer<void>? gate;
  var submitCalls = 0;
  final keys = <String>[];
  int? lastScore;
  String? lastReview;
  List<String> lastTags = const [];

  @override
  Future<Rating?> forBooking(String bookingId) async => given[bookingId];

  @override
  Future<RatingPage> mine({String? cursor}) async =>
      RatingPage(given.values.toList(), null);

  @override
  Future<Rating> submit(
    String bookingId, {
    required int score,
    String? review,
    List<String> tags = const [],
    required String idempotencyKey,
  }) async {
    submitCalls++;
    keys.add(idempotencyKey);
    await gate?.future;
    final f = submitFails;
    if (f != null) throw f;
    lastScore = score;
    lastReview = review;
    lastTags = tags;
    return given[bookingId] = Rating(
      id: 'r$submitCalls',
      bookingId: bookingId,
      score: score,
      review: review,
    );
  }
}

class _Bookings implements BookingRepository {
  _Bookings(this.items);
  List<Booking> items;
  int pageSize = 20;
  Object? listFails;
  HistoryFilter? lastFilter;
  final rebooked = <String>[];

  @override
  Future<BookingPage> history(HistoryFilter filter, {String? cursor}) {
    lastFilter = filter;
    return list(cursor: cursor);
  }

  @override
  Future<HistorySummary> historySummary(HistoryFilter filter) async =>
      HistorySummary(
        totalServices: items.length,
        distinctWorkers: 2,
        totalSpent: 12500,
      );

  @override
  Future<Booking> rebook(String bookingId, {DateTime? startDate}) async {
    rebooked.add(bookingId);
    return _booking('new1', BookingStatus.newRequest);
  }

  @override
  Future<BookingPage> list({String? cursor}) async {
    final f = listFails;
    if (f != null) throw f;
    final from = int.tryParse(cursor ?? '0') ?? 0;
    final to = (from + pageSize).clamp(0, items.length);
    return BookingPage(
      items.sublist(from, to),
      to < items.length ? '$to' : null,
    );
  }

  @override
  Future<Booking> get(String id, {CancelToken? cancel}) async {
    final b = items.where((x) => x.id == id).firstOrNull;
    if (b == null) throw const NotFoundFailure();
    return b;
  }

  @override
  dynamic noSuchMethod(Invocation i) =>
      throw UnimplementedError('${i.memberName}');
}

Booking _booking(
  String id,
  BookingStatus status, {
  Set<BookingAction>? actions,
  int? ratingScore,
  WorkerIdentity? identity,
}) => Booking(
  id: id,
  status: status,
  ratingScore: ratingScore,
  identity: identity,
  categoryName: 'Cook',
  engagement: EngagementType.fullTime,
  workerId: 'cook-7',
  worker: WorkerSearchRepositoryMock.byId('cook-7'),
  areaName: 'Madhapur',
  startDate: DateTime(2026, 10, 6),
  actions: actions ?? derivedBookingActions(status),
);

AttendanceEntry _e(String date, AttendanceStatus s, [String? note]) =>
    AttendanceEntry(id: date, date: date, status: s, note: note);

void main() {
  late _Att att;
  late _Rate rate;
  late _Bookings books;

  setUp(() {
    att = _Att([
      _e('2026-10-09', AttendanceStatus.present),
      _e('2026-10-08', AttendanceStatus.absent, 'Called in sick'),
      _e('2026-10-07', AttendanceStatus.unknown),
    ]);
    rate = _Rate();
    books = _Bookings([_booking('a1', BookingStatus.active)]);
  });

  Future<DiscoverEnv> open(
    WidgetTester t,
    String route, {
    List<Override> extra = const [],
  }) async {
    final env = await launchDiscover(
      t,
      height: 2400,
      overrides: [
        bookingRepositoryProvider.overrideWithValue(books),
        attendanceRepositoryProvider.overrideWithValue(att),
        ratingRepositoryProvider.overrideWithValue(rate),
        ...extra,
      ],
    );
    await env.go(route);
    await settle(t);
    return env;
  }

  Finder k(String key) => find.byKey(Key(key));

  /// Path + query of the top route (a pushed route keeps its own match list).
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

  void pop(WidgetTester t) =>
      GoRouter.of(t.element(find.byType(Scaffold).first)).pop();

  group('active service (10.1)', () {
    testWidgets(
      'LATE and LEAVE rows, check times, window and the worker name',
      (t) async {
        att.entries = [
          AttendanceEntry(
            id: 'l',
            date: '2026-10-09',
            status: AttendanceStatus.late,
            checkInAt: DateTime(2026, 10, 9, 8, 25),
            checkOutAt: DateTime(2026, 10, 9, 12, 5),
          ),
          _e('2026-10-08', AttendanceStatus.leave),
        ];
        att.summaryOverride = const AttendanceSummary(
          month: '2026-10',
          present: 4,
          absent: 0,
          exception: 0,
          late: 2,
          leave: 1,
          scheduledFrom: '08:00',
          scheduledTo: '12:00',
        );
        books.items = [
          _booking(
            'a1',
            BookingStatus.active,
            identity: const WorkerIdentity(
              displayName: 'Ramesh K.',
              initials: 'RK',
            ),
          ),
        ];
        await open(t, '/services/current?bookingId=a1');
        expect(find.text('Ramesh K.'), findsOneWidget);
        expect(find.text('8 AM – 12 PM'), findsOneWidget);
        Finder inRow(String d, String s) =>
            find.descendant(of: k('attendance_row_$d'), matching: find.text(s));
        expect(inRow('2026-10-09', 'Late'), findsOneWidget);
        expect(inRow('2026-10-08', 'On leave'), findsOneWidget);
        expect(
          find.text('In 8:25 AM · Out 12:05 PM'),
          findsNWidgets(2),
        ); // today + row
        expect(k('attendance_times_2026-10-08'), findsNothing);
        final card = find.descendant(
          of: k('service_summary_card'),
          matching: find.text('2'),
        );
        expect(card, findsOneWidget);
      },
    );

    testWidgets('no report-a-missing-day unless the booking is ACTIVE', (
      t,
    ) async {
      books.items = [_booking('a1', BookingStatus.replacementRequested)];
      await open(t, '/services/current?bookingId=a1');
      expect(k('service_report_missing_btn'), findsNothing);
    });

    testWidgets('report a missing day: posts date and note once', (t) async {
      await open(t, '/services/current?bookingId=a1');
      await tapKey(t, 'service_report_missing_btn');
      expect(t.widget<SnButton>(k('exception_submit_btn')).onPressed, isNull);
      await t.tap(k('exception_date_btn'));
      await settle(t);
      await t.tap(find.text('OK'));
      await settle(t);
      await t.enterText(k('exception_note_field'), 'Did not come');
      await t.pump();
      await t.tap(k('exception_submit_btn'));
      await settle(t);
      expect(att.raised.length, 1);
      expect(att.raised.single.$1, 'a1');
      expect(att.raised.single.$3, 'Did not come');
      expect(k('exception_submit_btn'), findsNothing);
      expect(find.text('Exception'), findsWidgets);
    });

    Future<void> fillDay(WidgetTester t, String note) async {
      await open(t, '/services/current?bookingId=a1');
      await tapKey(t, 'service_report_missing_btn');
      await t.tap(k('exception_date_btn'));
      await settle(t);
      await t.tap(find.text('OK'));
      await settle(t);
      await t.enterText(k('exception_note_field'), note);
      await t.pump();
    }

    testWidgets('report a missing day: a note of only spaces cannot be sent', (
      t,
    ) async {
      await fillDay(t, '     ');
      expect(t.widget<SnButton>(k('exception_submit_btn')).onPressed, isNull);
      await t.tap(k('exception_submit_btn'), warnIfMissed: false);
      await settle(t);
      expect(att.raised, isEmpty);
    });

    testWidgets('report a missing day: the note is sent trimmed', (t) async {
      await fillDay(t, '   Did not come  ');
      await t.tap(k('exception_submit_btn'));
      await settle(t);
      expect(att.raised.single.$3, 'Did not come');
    });

    testWidgets('report a missing day: the note field stops at 500', (t) async {
      await fillDay(t, 'a' * 600);
      expect(
        t.widget<TextField>(k('exception_note_field')).controller!.text.length,
        500,
      );
    });

    testWidgets('report a missing day: a timeout says so and keeps the note', (
      t,
    ) async {
      att.raiseFails = const NetworkFailure(null, true);
      await fillDay(t, 'Did not come');
      await t.tap(k('exception_submit_btn'));
      await settle(t);
      expect(
        t.widget<Text>(k('exception_error')).data,
        "We're taking a little longer than expected. Please try again.",
      );
      expect(find.text('Did not come'), findsOneWidget);
      expect(k('exception_submit_btn'), findsOneWidget);
    });

    testWidgets('a 409 on the day shows the reason and keeps the form', (
      t,
    ) async {
      att.raiseFails = const ConflictFailure('exists');
      await open(t, '/services/current?bookingId=a1');
      await tapKey(t, 'service_report_missing_btn');
      await t.tap(k('exception_date_btn'));
      await settle(t);
      await t.tap(find.text('OK'));
      await settle(t);
      await t.enterText(k('exception_note_field'), 'x');
      await t.pump();
      await t.tap(k('exception_submit_btn'));
      await settle(t);
      expect(k('exception_error'), findsOneWidget);
      expect(find.text('That day already has an entry.'), findsOneWidget);
    });

    testWidgets(
      'SVC-01 shows today, the month and every status, unknown as Updated',
      (t) async {
        await open(t, '/services/current?bookingId=a1');
        expect(k('service_worker_card'), findsOneWidget);
        expect(k('service_schedule'), findsOneWidget);
        expect(k('service_location'), findsOneWidget);
        expect(
          find.descendant(
            of: k('service_today_card'),
            matching: find.text('Present'),
          ),
          findsOneWidget,
        );
        expect(k('service_summary_card'), findsOneWidget);
        Finder inRow(String d, String s) =>
            find.descendant(of: k('attendance_row_$d'), matching: find.text(s));
        expect(inRow('2026-10-09', 'Present'), findsOneWidget);
        expect(inRow('2026-10-08', 'Absent'), findsOneWidget);
        expect(inRow('2026-10-07', 'Updated'), findsOneWidget);
        // The remark opens and closes on tap.
        expect(k('attendance_note_2026-10-08'), findsNothing);
        await t.tap(k('attendance_row_2026-10-08'));
        await t.pump();
        expect(find.text('Called in sick'), findsOneWidget);
        await t.tap(k('attendance_row_2026-10-08'));
        await t.pump();
        expect(find.text('Called in sick'), findsNothing);
      },
    );

    testWidgets('today with no entry reads "Not recorded yet"', (t) async {
      att.entries = [_e('2026-10-08', AttendanceStatus.present)];
      await open(t, '/services/current?bookingId=a1');
      expect(find.text('Not recorded yet'), findsOneWidget);
    });

    testWidgets('SVC-02 no attendance yet: friendly message', (t) async {
      att.entries = [];
      await open(t, '/services/current?bookingId=a1');
      expect(
        find.text("No updates yet. You'll see your worker's status here."),
        findsOneWidget,
      );
    });

    testWidgets('SVC-02 attendance error shows retry, and retry recovers', (
      t,
    ) async {
      att.pageFails = const NetworkFailure();
      await open(t, '/services/current?bookingId=a1');
      expect(
        find.text(
          "Couldn't reach SevaNest. Check your connection and try again.",
        ),
        findsWidgets,
      );
      att.pageFails = null;
      await tapKey(t, 'error_retry_btn');
      expect(k('attendance_row_2026-10-09'), findsOneWidget);
    });

    testWidgets('SVC-02 booking error shows retry', (t) async {
      books.items = [];
      await open(t, '/services/current?bookingId=a1');
      expect(k('error_retry_btn'), findsOneWidget);
      expect(k('service_worker_card'), findsNothing);
    });

    testWidgets('paged attendance: Load more appends the next page', (t) async {
      att.pageSize = 2;
      await open(t, '/services/current?bookingId=a1');
      expect(k('attendance_row_2026-10-07'), findsNothing);
      await tapKey(t, 'attendance_load_more_btn');
      expect(k('attendance_row_2026-10-07'), findsOneWidget);
      expect(k('attendance_load_more_btn'), findsNothing);
    });

    testWidgets('SVC-03 Replace and Rate follow the booking allowed actions', (
      t,
    ) async {
      books.items = [
        _booking('a1', BookingStatus.active, actions: {BookingAction.replace}),
      ];
      await open(t, '/services/current?bookingId=a1');
      expect(k('service_replace_btn'), findsOneWidget);
      expect(k('service_rate_btn'), findsNothing);
      expect(k('service_support_btn'), findsOneWidget);
      expect(k('service_booking_link'), findsOneWidget);
    });

    testWidgets(
      'SVC-03 a booking that can only be rated shows Rate, not Replace',
      (t) async {
        books.items = [
          _booking(
            'a1',
            BookingStatus.completed,
            actions: {BookingAction.rate},
          ),
        ];
        await open(t, '/services/current?bookingId=a1');
        expect(k('service_rate_btn'), findsOneWidget);
        expect(k('service_replace_btn'), findsNothing);
      },
    );

    testWidgets('SVC-04 one active booking opens directly, no picker', (
      t,
    ) async {
      books.items = [
        _booking('a1', BookingStatus.active),
        _booking('c1', BookingStatus.completed),
      ];
      await open(t, '/services/current');
      expect(k('service_worker_card'), findsOneWidget);
      expect(k('service_pick_a1'), findsNothing);
    });

    testWidgets('SVC-04 several active bookings show a picker', (t) async {
      books.items = [
        _booking('a1', BookingStatus.active),
        _booking('a2', BookingStatus.replacementRequested),
      ];
      await open(t, '/services/current');
      expect(k('service_worker_card'), findsNothing);
      expect(k('service_pick_a1'), findsOneWidget);
      await tapKey(t, 'service_pick_a2');
      expect(where(t), '/services/current?bookingId=a2');
      expect(k('service_worker_card'), findsOneWidget);
    });

    testWidgets('SVC-04 no active booking: empty state', (t) async {
      books.items = [_booking('c1', BookingStatus.completed)];
      await open(t, '/services/current');
      expect(find.text('No active service'), findsOneWidget);
    });

    testWidgets('SVC-05 every button goes to its route with its parameters', (
      t,
    ) async {
      books.items = [
        _booking(
          'a1',
          BookingStatus.active,
          actions: {BookingAction.replace, BookingAction.rate},
        ),
      ];
      await open(t, '/services/current?bookingId=a1');
      final targets = {
        'service_worker_card': '/workers/cook-7',
        'service_booking_link': '/bookings/a1',
        'service_support_btn': '/support/new?bookingId=a1',
        'service_replace_btn': '/replacements/new?bookingId=a1',
        'service_rate_btn': '/ratings/a1',
      };
      for (final e in targets.entries) {
        await tapKey(t, e.key);
        expect(where(t), e.value, reason: e.key);
        pop(t);
        await settle(t);
        expect(where(t), '/services/current?bookingId=a1');
      }
    });

    testWidgets('refetches when the app resumes', (t) async {
      await open(t, '/services/current?bookingId=a1');
      final before = att.pageCalls;
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settle(t);
      expect(att.pageCalls, greaterThan(before));
    });
  });

  group('service history (10.2)', () {
    testWidgets('summary line, filters reach the server, worker name shown', (
      t,
    ) async {
      books = _Bookings([
        _booking(
          'c1',
          BookingStatus.completed,
          identity: const WorkerIdentity(displayName: 'Ramesh K.'),
        ),
      ]);
      await open(t, '/services/history');
      expect(
        find.text('1 services · 2 workers · ₹12,500 total spent'),
        findsOneWidget,
      );
      expect(find.text('Ramesh K.'), findsOneWidget);
      expect(books.lastFilter, const HistoryFilter());
      await t.enterText(k('history_search_field'), 'ramesh');
      await t.pump(const Duration(milliseconds: 500));
      await settle(t);
      expect(books.lastFilter!.search, 'ramesh');
      await t.ensureVisible(k('history_status_filter'));
      await t.tap(k('history_status_filter'));
      await settle(t);
      await t.tap(find.text('Cancelled').last);
      await settle(t);
      expect(books.lastFilter!.status, BookingStatus.cancelled);
      expect(books.lastFilter!.search, 'ramesh');
    });

    testWidgets(
      'Hire again only with the rebook action, then opens the new booking',
      (t) async {
        books = _Bookings([
          _booking(
            'c1',
            BookingStatus.completed,
            actions: {BookingAction.rebook},
          ),
          _booking(
            'c2',
            BookingStatus.completed,
            actions: {BookingAction.rate},
          ),
        ]);
        await open(t, '/services/history');
        expect(k('hire_again_btn_c2'), findsNothing);
        await tapKey(t, 'hire_again_btn_c1');
        expect(books.rebooked, ['c1']);
        expect(where(t), '/bookings/new1');
      },
    );

    setUp(() {
      books = _Bookings([
        _booking('a1', BookingStatus.active),
        _booking('c1', BookingStatus.completed, ratingScore: 4),
        _booking('c2', BookingStatus.completed),
        _booking('x1', BookingStatus.cancelled),
        _booking('r1', BookingStatus.replaced),
      ]);
      rate.given['c1'] = const Rating(id: 'r', bookingId: 'c1', score: 4);
    });

    testWidgets('SVC-06 groups Current, Completed, Cancelled and Replaced', (
      t,
    ) async {
      await open(t, '/services/history');
      for (final s in ['current', 'completed', 'cancelled']) {
        expect(k('history_section_$s'), findsOneWidget, reason: s);
      }
      for (final id in ['a1', 'c1', 'c2', 'x1', 'r1']) {
        expect(k('history_card_$id'), findsOneWidget, reason: id);
      }
    });

    testWidgets('a section with no bookings is not shown', (t) async {
      books.items = [_booking('c1', BookingStatus.completed)];
      await open(t, '/services/history');
      expect(k('history_section_completed'), findsOneWidget);
      expect(k('history_section_replaced'), findsNothing);
      expect(k('history_section_cancelled'), findsNothing);
    });

    testWidgets(
      'rating given shows stars; Rate only where it is open; no Rebook',
      (t) async {
        await open(t, '/services/history');
        expect(k('history_stars_c1'), findsOneWidget);
        expect(k('history_stars_c2'), findsNothing);
        expect(k('history_rate_btn_c1'), findsNothing);
        expect(k('history_rate_btn_c2'), findsOneWidget);
        expect(k('history_rate_btn_a1'), findsNothing);
        expect(k('history_rate_btn_x1'), findsNothing);
        expect(find.textContaining('Rebook'), findsNothing);
        expect(find.textContaining('Hire again'), findsNothing);
      },
    );

    testWidgets('card and Rate button navigate', (t) async {
      await open(t, '/services/history');
      await tapKey(t, 'history_rate_btn_c2');
      expect(where(t), '/ratings/c2');
      pop(t);
      await settle(t);
      await tapKey(t, 'history_card_x1');
      expect(where(t), '/bookings/x1');
    });

    testWidgets('SVC-06 pagination loads more', (t) async {
      books.pageSize = 2;
      await open(t, '/services/history');
      expect(k('history_card_c2'), findsNothing);
      await tapKey(t, 'history_load_more_btn');
      await tapKey(t, 'history_load_more_btn');
      expect(k('history_card_r1'), findsOneWidget);
      expect(k('history_load_more_btn'), findsNothing);
    });

    testWidgets('SVC-06 empty state', (t) async {
      books.items = [];
      await open(t, '/services/history');
      expect(find.text('No past services yet'), findsOneWidget);
    });

    testWidgets('error shows retry and recovers', (t) async {
      books.listFails = const ServerFailure();
      await open(t, '/services/history');
      expect(k('error_retry_btn'), findsOneWidget);
      books.listFails = null;
      await tapKey(t, 'error_retry_btn');
      expect(k('history_card_a1'), findsOneWidget);
    });

    testWidgets('Account -> Service history', (t) async {
      final env = await launchDiscover(
        t,
        overrides: [
          bookingRepositoryProvider.overrideWithValue(books),
          ratingRepositoryProvider.overrideWithValue(rate),
        ],
      );
      await t.tap(k('nav_account'));
      await settle(t);
      await env.tapKey('account_history_btn');
      await settle(t);
      expect(where(t), '/services/history');
      expect(k('history_card_c2'), findsOneWidget);
    });
  });

  group('rating (10.3)', () {
    setUp(() {
      books = _Bookings([
        _booking('c2', BookingStatus.completed),
        _booking('a1', BookingStatus.active),
      ]);
    });

    bool submitEnabled(WidgetTester t) =>
        t.widget<AuthCta>(k('rating_submit_btn')).onPressed != null;

    testWidgets('SVC-07 Submit is disabled until a star is chosen', (t) async {
      await open(t, '/ratings/c2');
      expect(k('rating_star_5'), findsOneWidget);
      expect(k('rating_star_6'), findsNothing);
      expect(submitEnabled(t), isFalse);
      expect(k('rating_choose_hint'), findsOneWidget);
      await t.tap(k('rating_star_3'));
      await t.pump();
      expect(submitEnabled(t), isTrue);
      expect(find.text('Good'), findsOneWidget);
    });

    testWidgets('SVC-08 success: thank-you, then Done returns to the booking', (
      t,
    ) async {
      await open(t, '/ratings/c2');
      await t.tap(k('rating_star_4'));
      await t.ensureVisible(k('rating_comment_field'));
      await t.tap(k('rating_comment_field'));
      await t.pump();
      await t.enterText(k('rating_comment_field'), 'Very punctual');
      await t.pump();
      await tapKey(t, 'rating_submit_btn');
      expect(rate.submitCalls, 1);
      expect((rate.lastScore, rate.lastReview), (4, 'Very punctual'));
      expect(k('rating_thanks'), findsOneWidget);
      expect(find.text('Thanks for your feedback'), findsOneWidget);
      expect(k('rating_submit_btn'), findsNothing);
      await tapKey(t, 'rating_done_btn');
      expect(where(t), '/bookings/c2');
    });

    testWidgets('tags: praise at 4-5 stars, complaints at 1-2, none at 3', (
      t,
    ) async {
      await open(t, '/ratings/c2');
      expect(k('rating_tag_PUNCTUAL'), findsNothing);
      await t.tap(k('rating_star_4'));
      await t.pump();
      expect(k('rating_tag_PUNCTUAL'), findsOneWidget);
      expect(k('rating_tag_LATE'), findsNothing);
      await t.tap(k('rating_star_3'));
      await t.pump();
      expect(k('rating_tag_PUNCTUAL'), findsNothing);
      expect(k('rating_tag_LATE'), findsNothing);
      await t.tap(k('rating_star_2'));
      await t.pump();
      expect(k('rating_tag_LATE'), findsOneWidget);
    });

    testWidgets('tags are sent as codes, the review stays plain', (t) async {
      await open(t, '/ratings/c2');
      await t.tap(k('rating_star_5'));
      await t.pump();
      await t.tap(k('rating_tag_PUNCTUAL'));
      await t.tap(k('rating_tag_POLITE'));
      await t.ensureVisible(k('rating_comment_field'));
      await t.tap(k('rating_comment_field'));
      await t.pump();
      await t.enterText(k('rating_comment_field'), 'Great');
      await t.pump();
      await tapKey(t, 'rating_submit_btn');
      expect(rate.lastReview, 'Great');
      expect(rate.lastTags, ['PUNCTUAL', 'POLITE']);
    });

    testWidgets('changing the stars drops tags of the other kind', (t) async {
      await open(t, '/ratings/c2');
      await t.tap(k('rating_star_5'));
      await t.pump();
      await t.tap(k('rating_tag_PUNCTUAL'));
      await t.tap(k('rating_star_1'));
      await t.pump();
      await tapKey(t, 'rating_submit_btn');
      expect(rate.lastReview, '');
      expect(rate.lastTags, isEmpty);
    });

    testWidgets('SVC-08 a double tap submits once', (t) async {
      rate.gate = Completer<void>();
      await open(t, '/ratings/c2');
      await t.tap(k('rating_star_5'));
      await t.pump();
      await t.tap(k('rating_submit_btn'));
      await t.tap(k('rating_submit_btn'));
      await t.pump();
      rate.gate!.complete();
      await settle(t);
      expect(rate.submitCalls, 1);
      expect(k('rating_thanks'), findsOneWidget);
    });

    testWidgets('Back leaves the form without submitting', (t) async {
      await open(t, '/ratings/c2');
      await tapKey(t, 'app_back_btn');
      expect(where(t), '/home');
      expect(rate.submitCalls, 0);
    });

    testWidgets('SVC-09 already rated: no form', (t) async {
      rate.given['c2'] = const Rating(
        id: 'r',
        bookingId: 'c2',
        score: 4,
        review: 'Good',
      );
      await open(t, '/ratings/c2');
      expect(k('rating_already_rated'), findsOneWidget);
      expect(find.text("You've already rated this service"), findsOneWidget);
      expect(k('rating_star_1'), findsNothing);
      expect(k('rating_submit_btn'), findsNothing);
      expect(find.text('Good'), findsOneWidget);
      await tapKey(t, 'rating_done_btn');
      expect(where(t), '/bookings/c2');
    });

    testWidgets(
      'SVC-09 the server answering 409 RATING_ALREADY_EXISTS shows the same state',
      (t) async {
        rate.submitFails = const ConflictFailure('x', 'RATING_ALREADY_EXISTS');
        await open(t, '/ratings/c2');
        await t.tap(k('rating_star_2'));
        await t.pump();
        await tapKey(t, 'rating_submit_btn');
        expect(k('rating_already_rated'), findsOneWidget);
        expect(k('rating_submit_btn'), findsNothing);
      },
    );

    testWidgets('SVC-10 no rate action: reason, no form', (t) async {
      await open(t, '/ratings/a1');
      expect(k('rating_not_eligible'), findsOneWidget);
      expect(find.text("You can't rate this service yet"), findsOneWidget);
      expect(k('rating_star_1'), findsNothing);
      expect(k('rating_comment_field'), findsNothing);
      expect(k('rating_submit_btn'), findsNothing);
    });

    testWidgets(
      'SVC-10 the server answering 422 RATING_NOT_ELIGIBLE hides the form',
      (t) async {
        rate.submitFails = const ValidationFailure(
          'x',
          {},
          'RATING_NOT_ELIGIBLE',
        );
        await open(t, '/ratings/c2');
        await t.tap(k('rating_star_2'));
        await t.pump();
        await tapKey(t, 'rating_submit_btn');
        expect(k('rating_not_eligible'), findsOneWidget);
        expect(k('rating_submit_btn'), findsNothing);
      },
    );

    testWidgets(
      'SVC-11 a network failure keeps the stars and the comment, and the retry reuses the key',
      (t) async {
        rate.submitFails = const NetworkFailure();
        await open(t, '/ratings/c2');
        await t.tap(k('rating_star_4'));
        await t.ensureVisible(k('rating_comment_field'));
        await t.tap(k('rating_comment_field'));
        await t.pump();
        await t.enterText(k('rating_comment_field'), 'Kind and neat');
        await t.pump();
        await tapKey(t, 'rating_submit_btn');
        expect(k('rating_error'), findsOneWidget);
        expect(find.text('Kind and neat'), findsOneWidget);
        expect(find.text('Very good'), findsOneWidget);
        expect(submitEnabled(t), isTrue);
        expect(k('rating_thanks'), findsNothing);
        rate.submitFails = null;
        await tapKey(t, 'rating_submit_btn');
        expect(k('rating_thanks'), findsOneWidget);
        expect(rate.keys, hasLength(2));
        expect(rate.keys[0], rate.keys[1]);
        expect(rate.lastReview, 'Kind and neat');
      },
    );

    testWidgets('a score outside the scale asks to choose again', (t) async {
      rate.submitFails = const ValidationFailure(
        'x',
        {},
        'RATING_SCORE_OUT_OF_SCALE',
      );
      await open(t, '/ratings/c2');
      await t.tap(k('rating_star_5'));
      await t.pump();
      await tapKey(t, 'rating_submit_btn');
      expect(
        find.text("That rating isn't on the scale. Please choose again."),
        findsOneWidget,
      );
      expect(submitEnabled(t), isFalse);
    });

    testWidgets(
      'SVC-12 scale and comment limit come from config, not literals',
      (t) async {
        await open(
          t,
          '/ratings/c2',
          extra: [
            ratingScaleMaxProvider.overrideWith((ref) async => 10),
            ratingReviewMaxProvider.overrideWithValue(120),
          ],
        );
        expect(k('rating_star_10'), findsOneWidget);
        expect(k('rating_star_11'), findsNothing);
        expect(
          t.widget<GlassNoteField>(k('rating_comment_field')).maxLength,
          120,
        );
        await t.tap(k('rating_star_9'));
        await t.pump();
        expect(find.text('9 out of 10'), findsOneWidget);
      },
    );
  });

  group('layout', () {
    for (final route in [
      '/services/current?bookingId=a1',
      '/services/history',
      '/ratings/c2',
    ]) {
      testWidgets(
        '$route has no overflow at 320 px wide, 200% text, 10 stars',
        (t) async {
          books.items = [
            _booking(
              'a1',
              BookingStatus.active,
              actions: {BookingAction.replace},
            ),
            _booking('c2', BookingStatus.completed),
          ];
          att.entries = [
            _e('2026-10-09', AttendanceStatus.present, 'A long note ' * 8),
          ];
          t.platformDispatcher.textScaleFactorTestValue = 2;
          addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
          await open(
            t,
            route,
            extra: [ratingScaleMaxProvider.overrideWith((ref) async => 10)],
          );
          t.view.physicalSize = const Size(960, 2400);
          t.view.devicePixelRatio = 3;
          await settle(t);
          final e = t.takeException();
          if (e != null) fail(e is FlutterError ? e.toStringDeep() : '$e');
        },
      );
    }
  });

  group('flows on the seeded mocks', () {
    Future<DiscoverEnv> mocks(WidgetTester t) =>
        launchDiscover(t, height: 2400);

    testWidgets(
      'SVC-13 Flow G: booking -> active service -> attendance -> history',
      (t) async {
        final env = await mocks(t);
        await env.go('/bookings/bk_2048');
        await settle(t);
        await tapKey(t, 'booking_view_service_btn');
        expect(where(t), '/services/current?bookingId=bk_2048');
        expect(k('service_worker_card'), findsOneWidget);
        expect(k('attendance_row_2026-10-09'), findsOneWidget);
        expect(k('service_today_status'), findsOneWidget);
        // History is reached from Account.
        GoRouter.of(t.element(find.byType(Scaffold).first)).go('/home');
        await settle(t);
        await t.tap(k('nav_account'));
        await settle(t);
        await env.tapKey('account_history_btn');
        await settle(t);
        expect(where(t), '/services/history');
        expect(k('history_card_bk_2048'), findsOneWidget);
        expect(k('history_section_current'), findsOneWidget);
        expect(k('history_section_completed'), findsOneWidget);
        expect(k('history_section_cancelled'), findsOneWidget);
      },
    );

    testWidgets(
      'SVC-14 Flow H: completed booking -> rate -> submit -> thanks',
      (t) async {
        final env = await mocks(t);
        await env.go('/bookings/bk_1900');
        await settle(t);
        await tapKey(t, 'booking_rate_btn');
        expect(where(t), '/ratings/bk_1900');
        await t.tap(k('rating_star_5'));
        await t.pump();
        await tapKey(t, 'rating_submit_btn');
        expect(k('rating_thanks'), findsOneWidget);
        await tapKey(t, 'rating_done_btn');
        expect(where(t), '/bookings/bk_1900');
        // Rated now: the form is gone and history shows the stars.
        await env.go('/ratings/bk_1900');
        await settle(t);
        expect(k('rating_already_rated'), findsOneWidget);
        await env.go('/services/history');
        await settle(t);
        expect(k('history_stars_bk_1900'), findsOneWidget);
        expect(k('history_rate_btn_bk_1900'), findsNothing);
      },
    );

    for (final (stage, expected) in [
      (BookingStage.active, '/services/current?bookingId=bk_2048'),
      (BookingStage.trial, '/bookings/bk_2048'),
    ]) {
      testWidgets('Home active card, ${stage.name} stage, opens $expected', (
        t,
      ) async {
        useTestPhone(t);
        await t.pumpWidget(
          testRootApp(
            store: InMemorySessionStore((access: 'a', refresh: 'r')),
            repo: FakeAuthRepository()..onProfile = () async => true,
            home: FakeHomeRepository(
              HomeData(
                activeBooking: ActiveBookingSummary(
                  id: 'bk_2048',
                  reference: 'SN-2048',
                  workerName: 'Lakshmi Devi',
                  service: 'Cook',
                  engagement: 'Full-time',
                  startLabel: 'Since 6 Oct',
                  stage: stage,
                ),
              ),
            ),
            overrides: [
              bookingRepositoryProvider.overrideWithValue(
                _Bookings([_booking('bk_2048', BookingStatus.active)]),
              ),
              attendanceRepositoryProvider.overrideWithValue(att),
              addressRepositoryProvider.overrideWithValue(
                FakeAddressRepository([testHome]),
              ),
              customerProfileRepositoryProvider.overrideWithValue(
                FakeProfileRepository(
                  const CustomerProfile(
                    name: 'Priya Sharma',
                    email: 'p@x.in',
                    preferredLanguage: 'en',
                  ),
                ),
              ),
            ],
          ),
        );
        await settle(t);
        await t.ensureVisible(k('home_active_booking_card'));
        await t.pump();
        await t.tap(k('home_active_booking_card'));
        await settle(t);
        expect(where(t), expected);
      });
    }
  });
}
