import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/core/localization/failure_message.dart';
import 'package:sevanest_customer/core/services/clock.dart';
import 'package:sevanest_customer/core/widgets/async_value_view.dart';
import 'package:sevanest_customer/core/widgets/sn_badge.dart';
import 'package:sevanest_customer/core/widgets/sn_button.dart';
import 'package:sevanest_customer/core/widgets/sn_states.dart';
import 'package:sevanest_customer/features/active_service/domain/attendance.dart';
import 'package:sevanest_customer/features/active_service/presentation/providers/service_providers.dart';
import 'package:sevanest_customer/features/active_service/presentation/widgets/raise_exception_sheet.dart';
import 'package:sevanest_customer/features/booking/domain/booking.dart';
import 'package:sevanest_customer/features/booking/presentation/booking_labels.dart';
import 'package:sevanest_customer/features/booking/presentation/providers/booking_providers.dart';
import 'package:sevanest_customer/features/booking/presentation/widgets/worker_identity_tile.dart';
import 'package:sevanest_customer/features/replacement/presentation/replacement_links.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/engagement_labels.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/schedule_format.dart';
import 'package:sevanest_customer/features/support/presentation/widgets/safety_actions.dart';
import 'package:sevanest_customer/features/worker_profile/presentation/providers/worker_profile_providers.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/worker_card.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

String attendanceLabel(AppLocalizations l, AttendanceStatus s) => switch (s) {
  AttendanceStatus.present => l.attendancePresent,
  AttendanceStatus.absent => l.attendanceAbsent,
  AttendanceStatus.late => l.attendanceLate,
  AttendanceStatus.leave => l.attendanceLeave,
  AttendanceStatus.exception => l.attendanceException,
  AttendanceStatus.unknown => l.attendanceUnknown,
};

SnBadgeTone _tone(AttendanceStatus s) => switch (s) {
  AttendanceStatus.present => SnBadgeTone.success,
  AttendanceStatus.absent => SnBadgeTone.error,
  AttendanceStatus.late => SnBadgeTone.warning,
  AttendanceStatus.leave => SnBadgeTone.neutral,
  AttendanceStatus.exception => SnBadgeTone.warning,
  AttendanceStatus.unknown => SnBadgeTone.neutral,
};

/// `/services/current?bookingId=` (module doc 10.1). Without an id: one active booking opens
/// directly, several show a picker. Everything shown is what the backend sent.
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
    if (state != AppLifecycleState.resumed) return;
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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('app_back_btn'),
          tooltip: l10n.back,
          icon: const Icon(Icons.chevron_left, size: 32),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(Routes.home),
        ),
        title: Text(l10n.serviceTitle),
        actions: [
          // Report / block the worker of this service (module 12), named by the booking.
          if (id != null) SafetyMenuButton(bookingId: id),
        ],
      ),
      body: id == null ? const _Picker() : _Service(bookingId: id),
    );
  }
}

/// A service is "active" while the worker is working: ACTIVE, or a replacement was asked for.
bool _isActive(Booking b) =>
    b.status == BookingStatus.active ||
    b.status == BookingStatus.replacementRequested;

/// "8:02 AM" for a local time.
String _clock(DateTime t) => formatTime(t.hour * 60 + t.minute);

/// "In 8:02 AM · Out 12:05 PM", or null when the worker has not checked in or out.
String? _checkTimes(AppLocalizations l, AttendanceEntry e) {
  final parts = [
    if (e.checkInAt != null) l.attendanceCheckIn(_clock(e.checkInAt!)),
    if (e.checkOutAt != null) l.attendanceCheckOut(_clock(e.checkOutAt!)),
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}

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

class _Picker extends ConsumerWidget {
  const _Picker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final value = ref.watch(bookingListProvider);
    return AsyncValueView(
      value: value,
      onRetry: () => ref.invalidate(bookingListProvider),
      data: (list) {
        final active = list.items.where(_isActive).toList();
        if (active.isEmpty) {
          return SnEmptyState(
            title: l10n.serviceNoneTitle,
            message: l10n.serviceNoneBody,
          );
        }
        if (active.length == 1) return _Service(bookingId: active.single.id);
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              l10n.servicePickTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            for (final b in active)
              Card(
                child: ListTile(
                  key: Key('service_pick_${b.id}'),
                  title: Text(
                    [
                      b.categoryName ?? b.categoryCode,
                      if (b.engagement != null)
                        engagementLabels(l10n, b.engagement!).name,
                    ].whereType<String>().join(' · '),
                  ),
                  subtitle: Text(
                    b.areaName ?? bookingStatusLabel(l10n, b.status),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(
                    '${Routes.serviceCurrent}?bookingId=${Uri.encodeComponent(b.id)}',
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
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(bookingProvider(bookingId));
    return AsyncValueView<Booking>(
      value: value,
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
}

class _Body extends ConsumerWidget {
  const _Body({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
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

    Widget action(
      String key,
      String label,
      VoidCallback onTap, {
      SnButtonVariant variant = SnButtonVariant.secondary,
    }) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: SnButton(
        key: Key(key),
        label: label,
        variant: variant,
        onPressed: onTap,
      ),
    );

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        if (identity != null && b.workerId != null)
          WorkerIdentityTile(
            key: const Key('service_worker_card'),
            identity: identity,
            onTap: () => context.push(
              Routes.path(Routes.workerDetail, {'id': b.workerId!}),
            ),
          )
        else if (worker != null)
          WorkerCard(
            key: const Key('service_worker_card'),
            worker: worker,
            onTap: () => context.push(
              Routes.path(Routes.workerDetail, {'id': worker.id}),
            ),
          )
        else if (b.workerId != null)
          ListTile(
            key: const Key('service_worker_card'),
            leading: const Icon(Icons.person_outline),
            title: Text(l10n.workerProfileTitle),
            onTap: () => context.push(
              Routes.path(Routes.workerDetail, {'id': b.workerId!}),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            SnBadge(
              key: const Key('service_status_chip'),
              label: bookingStatusLabel(l10n, b.status),
              tone: bookingStatusTone(b.status),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          [
            b.categoryName ?? b.categoryCode,
            if (b.engagement != null)
              engagementLabels(l10n, b.engagement!).name,
            if (b.startDate != null)
              l10n.serviceSince(formatDate(b.startDate!, locale)),
          ].whereType<String>().join(' · '),
          key: const Key('service_schedule'),
          style: text.titleMedium,
        ),
        if (b.areaName != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 18),
                const SizedBox(width: AppSpacing.xs),
                Text(b.areaName!, key: const Key('service_location')),
              ],
            ),
          ),
        if (_window(summary) != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              l10n.serviceScheduled(_window(summary)!),
              key: const Key('service_window'),
              style: text.bodyMedium,
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        Card(
          key: const Key('service_today_card'),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                Text(
                  '${l10n.serviceTodayTitle} · ${formatDate(now, locale)}',
                  style: text.bodyMedium,
                ),
                if (today != null)
                  SnBadge(
                    key: const Key('service_today_status'),
                    label: attendanceLabel(l10n, today.status),
                    tone: _tone(today.status),
                  )
                else
                  Text(
                    l10n.serviceTodayNone,
                    key: const Key('service_today_status'),
                    style: text.bodySmall,
                  ),
                if (today != null && _checkTimes(l10n, today) != null)
                  Text(
                    _checkTimes(l10n, today)!,
                    key: const Key('service_today_times'),
                    style: text.bodySmall,
                  ),
              ],
            ),
          ),
        ),
        if (summary != null)
          Card(
            key: const Key('service_summary_card'),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.serviceMonthTitle, style: text.titleSmall),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    alignment: WrapAlignment.spaceAround,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _Count(l10n.attendancePresent, summary.present),
                      _Count(l10n.attendanceLate, summary.late),
                      _Count(l10n.attendanceAbsent, summary.absent),
                      _Count(l10n.attendanceLeave, summary.leave),
                      _Count(l10n.attendanceException, summary.exception),
                    ],
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        Text(l10n.attendanceTitle, style: text.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        _AttendanceList(bookingId: b.id),
        const Divider(height: AppSpacing.lg * 2),
        action(
          'service_booking_link',
          l10n.serviceBookingLink,
          () => context.push(Routes.path(Routes.bookingDetail, {'id': b.id})),
        ),
        if (a.contains(BookingAction.rate))
          action(
            'service_rate_btn',
            l10n.bookingRate,
            () => context.push(Routes.path(Routes.rating, {'id': b.id})),
            variant: SnButtonVariant.primary,
          ),
        if (a.contains(BookingAction.replace))
          action(
            'service_replace_btn',
            l10n.bookingReplace,
            () => context.push(
              '${Routes.replacementNew}?bookingId=${Uri.encodeComponent(b.id)}',
            ),
          ),
        ReplacementLinks(booking: b),
        if (b.status == BookingStatus.active)
          action(
            'service_report_missing_btn',
            l10n.serviceReportMissing,
            () async {
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
                messenger.showSnackBar(
                  SnackBar(content: Text(l10n.exceptionSent)),
                );
              }
            },
          ),
        action(
          'service_support_btn',
          l10n.serviceSupport,
          () => context.push(
            '${Routes.supportNew}?bookingId=${Uri.encodeComponent(b.id)}',
          ),
          variant: SnButtonVariant.text,
        ),
      ],
    );
  }
}

class _Count extends StatelessWidget {
  const _Count(this.label, this.n);
  final String label;
  final int n;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text('$n', style: Theme.of(context).textTheme.headlineSmall),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

class _AttendanceList extends ConsumerWidget {
  const _AttendanceList({required this.bookingId});
  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final page = ref.watch(attendanceProvider(bookingId));
    if (page.isLoading && !page.hasValue) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (page.hasError && !page.hasValue) {
      return SizedBox(
        height: 220,
        child: SnErrorState(
          message: failureMessage(l10n, page.error!),
          onRetry: () => ref.invalidate(attendanceProvider(bookingId)),
        ),
      );
    }
    final s = page.requireValue;
    if (s.items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Text(l10n.attendanceEmpty, key: const Key('attendance_empty')),
      );
    }
    return Column(
      children: [
        for (final e in s.items) _Row(entry: e),
        if (s.loadMoreError != null)
          Text(failureMessage(l10n, s.loadMoreError!)),
        if (s.hasMore || s.isLoadingMore)
          SnButton(
            key: const Key('attendance_load_more_btn'),
            label: l10n.attendanceLoadMore,
            variant: SnButtonVariant.text,
            isLoading: s.isLoadingMore,
            onPressed: () =>
                ref.read(attendanceProvider(bookingId).notifier).loadMore(),
          ),
      ],
    );
  }
}

/// One day. Tapping a row with a note shows or hides the note.
class _Row extends StatefulWidget {
  const _Row({required this.entry});
  final AttendanceEntry entry;

  @override
  State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> {
  var _open = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final e = widget.entry;
    final day = e.day;
    return Column(
      children: [
        ListTile(
          key: Key('attendance_row_${e.date}'),
          contentPadding: EdgeInsets.zero,
          title: Text(day == null ? e.date : formatDate(day, locale)),
          subtitle: _checkTimes(l10n, e) == null
              ? null
              : Text(
                  _checkTimes(l10n, e)!,
                  key: Key('attendance_times_${e.date}'),
                ),
          trailing: SnBadge(
            label: attendanceLabel(l10n, e.status),
            tone: _tone(e.status),
          ),
          onTap: e.note == null ? null : () => setState(() => _open = !_open),
        ),
        if (_open && e.note != null)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(e.note!, key: Key('attendance_note_${e.date}')),
            ),
          ),
      ],
    );
  }
}
