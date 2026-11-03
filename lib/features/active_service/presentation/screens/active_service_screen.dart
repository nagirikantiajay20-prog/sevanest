import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/core/services/clock.dart';
import 'package:sevanest_customer/core/widgets/async_value_view.dart';
import 'package:sevanest_customer/features/active_service/domain/attendance.dart';
import 'package:sevanest_customer/features/active_service/presentation/providers/service_providers.dart';
import 'package:sevanest_customer/features/active_service/presentation/widgets/attendance_list.dart';
import 'package:sevanest_customer/features/active_service/presentation/widgets/raise_exception_sheet.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart'
    show AuthCta, authSerif;
import 'package:sevanest_customer/features/booking/domain/booking.dart';
import 'package:sevanest_customer/features/booking/presentation/booking_labels.dart';
import 'package:sevanest_customer/features/booking/presentation/providers/booking_providers.dart';
import 'package:sevanest_customer/features/interview_trial/presentation/widgets/interview_detail_parts.dart';
import 'package:sevanest_customer/features/notifications/presentation/providers/notification_providers.dart';
import 'package:sevanest_customer/features/replacement/presentation/replacement_links.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/engagement_labels.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/schedule_format.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/features/support/presentation/widgets/safety_actions.dart';
import 'package:sevanest_customer/features/worker_profile/presentation/providers/worker_profile_providers.dart';
import 'package:sevanest_customer/features/worker_search/presentation/providers/worker_search_providers.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_page.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_parts.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/worker_card.dart'
    show experienceLabel, ratingText;
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// `/services/current?bookingId=` (module doc 10.1, design: Find a Worker > Active service).
/// Without an id: one active booking opens directly, several show a picker. Everything shown is
/// what the backend sent.
class ActiveServiceScreen extends ConsumerStatefulWidget {
  const ActiveServiceScreen({this.bookingId, super.key});
  final String? bookingId;

  @override
  ConsumerState<ActiveServiceScreen> createState() => _State();
}

class _State extends ConsumerState<ActiveServiceScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Attendance changes while the app is in the background.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _reload();
  }

  void _reload() {
    final id = widget.bookingId;
    if (id == null) {
      ref.invalidate(bookingListProvider);
    } else {
      ref
        ..invalidate(bookingProvider(id))
        ..invalidate(attendanceProvider(id))
        ..invalidate(attendanceSummaryProvider(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final id = widget.bookingId;
    // A notification arrived (attendance, replacement...): read the service again.
    ref.listen(notificationTickProvider, (_, _) => _reload());
    return FindGlassPage(
      title: l10n.serviceTitle,
      backLabel: l10n.back,
      onBack: () => context.canPop() ? context.pop() : context.go(Routes.home),
      // Report / block the worker of this service (module 12), named by the booking.
      trailing: id == null
          ? null
          : DiscoverGlass(
              radius: 22,
              child: SafetyMenuButton(bookingId: id, color: dsNavy),
            ),
      body: id == null ? const _Picker() : _Service(bookingId: id),
    );
  }
}

/// A service is "active" while the worker is working: ACTIVE, or a replacement was asked for.
bool _isActive(Booking b) =>
    b.status == BookingStatus.active ||
    b.status == BookingStatus.replacementRequested;

/// "8 AM – 12 PM" from the backend's `HH:mm` pair; null if it is not in that form.
String? _window(AttendanceSummary? s) {
  int? mins(String? v) {
    final m = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(v ?? '');
    return m == null ? null : int.parse(m[1]!) * 60 + int.parse(m[2]!);
  }

  final a = mins(s?.scheduledFrom);
  final b = mins(s?.scheduledTo);
  return a == null || b == null ? null : formatTimeSpan(a, b);
}

/// "House Maid · Part-time".
String _serviceName(AppLocalizations l10n, Booking b) => [
  b.categoryName ?? b.categoryCode,
  if (b.engagement != null) engagementLabels(l10n, b.engagement!).name,
].whereType<String>().join(' · ');

class _Picker extends ConsumerWidget {
  const _Picker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return AsyncValueView(
      value: ref.watch(bookingListProvider),
      onRetry: () => ref.invalidate(bookingListProvider),
      data: (list) {
        final active = list.items.where(_isActive).toList();
        if (active.isEmpty) {
          return GlassEmpty(
            icon: Icons.home_work_outlined,
            iconColor: AppColors.teal,
            discColors: const [Color(0xFFE2EEEC), Colors.white],
            title: l10n.serviceNoneTitle,
            body: l10n.serviceNoneBody,
            actionLabel: l10n.backToHome,
            actionKey: const Key('service_home_btn'),
            onAction: () => context.go(Routes.home),
          );
        }
        if (active.length == 1) return _Service(bookingId: active.single.id);
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 36),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
              child: Text(l10n.servicePickTitle, style: authSerif(20, 1.2)),
            ),
            for (final (i, b) in active.indexed)
              DiscoverRise(
                delayMs: 60.0 + 40 * i.clamp(0, 6),
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: DiscoverGlass(
                    radius: 22,
                    child: Material(
                      type: MaterialType.transparency,
                      child: ListTile(
                        key: Key('service_pick_${b.id}'),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                        title: Text(
                          _serviceName(l10n, b),
                          style: AppText.body.copyWith(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: dsNavy,
                          ),
                        ),
                        subtitle: Text(
                          b.areaName ?? bookingStatusLabel(l10n, b.status),
                          style: AppText.body.copyWith(color: dsText),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: dsMuted,
                        ),
                        onTap: () => context.push(
                          '${Routes.serviceCurrent}?bookingId=${Uri.encodeComponent(b.id)}',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Service extends ConsumerWidget {
  const _Service({required this.bookingId});
  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => AsyncValueView<Booking>(
    value: ref.watch(bookingProvider(bookingId)),
    onRetry: () => ref.invalidate(bookingProvider(bookingId)),
    data: (b) => RefreshIndicator(
      onRefresh: () async {
        ref
          ..invalidate(bookingProvider(bookingId))
          ..invalidate(attendanceProvider(bookingId))
          ..invalidate(attendanceSummaryProvider(bookingId));
        try {
          await ref.read(bookingProvider(bookingId).future);
        } on Object {
          // shown by the view
        }
      },
      child: _Body(booking: b),
    ),
  );
}

class _Body extends ConsumerWidget {
  const _Body({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final b = booking;
    final a = b.actions;
    final attendance = ref.watch(attendanceProvider(b.id));
    final summary = ref.watch(attendanceSummaryProvider(b.id)).asData?.value;
    final now = ref.read(nowProvider)();
    final todayKey =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final today = attendance.asData?.value.items
        .where((e) => e.date == todayKey)
        .firstOrNull;
    final identity = b.identity ?? summary?.worker;
    final worker = identity != null
        ? null
        : b.worker ??
              (b.workerId == null
                  ? null
                  : ref.watch(workerDetailProvider(b.workerId!)).value);
    final scale = ref.watch(ratingScaleMaxProvider).value ?? 5;
    final name = identity?.displayName ?? worker?.title;
    final window = _window(summary);
    final rows = <(String, String, Key?)>[
      (
        l10n.bookingServiceRow,
        [
          _serviceName(l10n, b),
          if (b.startDate != null)
            l10n.serviceSince(formatDate(b.startDate!, locale)),
        ].join(' · '),
        const Key('service_schedule'),
      ),
      if (window != null)
        (l10n.serviceScheduleRow, window, const Key('service_window')),
      if (b.areaName != null)
        (l10n.serviceLocationRow, b.areaName!, const Key('service_location')),
      (
        l10n.serviceBookingRow,
        l10n.serviceViewBooking,
        const Key('service_booking_link'),
      ),
    ];
    final bookingRow = rows.length - 1;

    void openWorker() =>
        context.push(Routes.path(Routes.workerDetail, {'id': b.workerId!}));

    Widget outline(String key, String label, VoidCallback onTap) => Padding(
      padding: const EdgeInsets.only(top: 10),
      child: OutlineAction(key: Key(key), label: label, onPressed: onTap),
    );

    Future<void> reportMissing() async {
      final messenger = ScaffoldMessenger.of(context);
      final done = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (_) => RaiseExceptionSheet(
          bookingId: b.id,
          first: b.startDate ?? now,
          today: DateTime(now.year, now.month, now.day),
        ),
      );
      if (done ?? false) {
        ref
          ..invalidate(attendanceProvider(b.id))
          ..invalidate(attendanceSummaryProvider(b.id));
        messenger.showSnackBar(SnackBar(content: Text(l10n.exceptionSent)));
      }
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DiscoverRise(
            delayMs: 0,
            child: KeyedSubtree(
              key: const Key('service_today_card'),
              child: InterviewHero(
                statusLabel:
                    '${l10n.serviceTodayTitle} · ${formatDate(now, locale)}',
                headline: today == null
                    ? l10n.serviceTodayNone
                    : attendanceLabel(l10n, today.status),
                headlineKey: const Key('service_today_status'),
                copy: today == null ? '' : checkTimes(l10n, today) ?? '',
                copyKey: const Key('service_today_times'),
                progress: null,
                showSteps: false,
                tone: switch (today?.status) {
                  AttendanceStatus.present => HeroTone.ok,
                  AttendanceStatus.absent => HeroTone.bad,
                  _ => HeroTone.waiting,
                },
              ),
            ),
          ),
          if (b.workerId != null) ...[
            const SizedBox(height: 14),
            DiscoverRise(
              delayMs: 60,
              child: KeyedSubtree(
                key: const Key('service_worker_card'),
                child: InterviewWorkerCard(
                  title: name ?? l10n.workerProfileTitle,
                  initials: identity?.initials ?? worker?.initials,
                  photoUrl: identity?.photoUrl ?? worker?.photoUrl,
                  gradient: name == null
                      ? const [Color(0xFF475569), Color(0xFF94A3B8)]
                      : avatarGradientFor(b.workerId!),
                  verified: identity?.verified ?? worker?.verified ?? false,
                  rating: worker != null && worker.hasRating
                      ? ratingText(worker.ratingAverage!, scale)
                      : null,
                  extra: worker?.experienceMonths == null
                      ? null
                      : experienceLabel(l10n, worker!.experienceMonths),
                  onTap: openWorker,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          DiscoverRise(
            delayMs: 100,
            child: InterviewInfoCard(
              rows: [for (final r in rows) (r.$1, r.$2)],
              valueKey: (i) => rows[i].$3,
              valueColor: (i) => i == bookingRow ? AppColors.teal : null,
              onTap: (i) => i == bookingRow
                  ? () => context.push(
                      Routes.path(Routes.bookingDetail, {'id': b.id}),
                    )
                  : null,
            ),
          ),
          if (summary != null) ...[
            const SizedBox(height: 14),
            DiscoverRise(delayMs: 130, child: _MonthCard(summary: summary)),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
            child: DiscoverRise(
              delayMs: 140,
              child: Semantics(
                header: true,
                child: Text(l10n.attendanceTitle, style: authSerif(20, 1.2)),
              ),
            ),
          ),
          DiscoverRise(delayMs: 160, child: AttendanceList(bookingId: b.id)),
          const SizedBox(height: 6),
          DiscoverRise(
            delayMs: 200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (a.contains(BookingAction.rate))
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: AuthCta(
                      key: const Key('service_rate_btn'),
                      clock: DiscoverClock.of(context),
                      label: l10n.bookingRate,
                      loadingLabel: l10n.bookingRate,
                      loading: false,
                      showArrow: false,
                      height: 50,
                      onPressed: () => context.push(
                        Routes.path(Routes.rating, {'id': b.id}),
                      ),
                    ),
                  ),
                if (a.contains(BookingAction.replace))
                  outline(
                    'service_replace_btn',
                    l10n.bookingReplace,
                    () => context.push(
                      '${Routes.replacementNew}?bookingId=${Uri.encodeComponent(b.id)}',
                    ),
                  ),
                ReplacementLinks(booking: b),
                if (b.status == BookingStatus.active)
                  outline(
                    'service_report_missing_btn',
                    l10n.serviceReportMissing,
                    reportMissing,
                  ),
                const SizedBox(height: 4),
                QuietAction(
                  key: const Key('service_support_btn'),
                  label: l10n.serviceSupport,
                  onPressed: () => context.push(
                    '${Routes.supportNew}?bookingId=${Uri.encodeComponent(b.id)}',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "This month": present / late / absent / leave / exception counts.
class _MonthCard extends StatelessWidget {
  const _MonthCard({required this.summary});
  final AttendanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final counts = [
      (l10n.attendancePresent, summary.present),
      (l10n.attendanceLate, summary.late),
      (l10n.attendanceAbsent, summary.absent),
      (l10n.attendanceLeave, summary.leave),
      (l10n.attendanceException, summary.exception),
    ];
    return DiscoverGlass(
      key: const Key('service_summary_card'),
      radius: 26,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.serviceMonthTitle,
              style: AppText.body.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: dsMuted,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.spaceAround,
              spacing: 12,
              runSpacing: 10,
              children: [
                for (final (label, n) in counts)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$n', style: authSerif(22, 1.1)),
                      Text(
                        label,
                        style: AppText.body.copyWith(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: dsMuted,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
