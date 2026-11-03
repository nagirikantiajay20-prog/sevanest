import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/core/localization/failure_message.dart';
import 'package:sevanest_customer/features/active_service/domain/attendance.dart';
import 'package:sevanest_customer/features/active_service/presentation/providers/service_providers.dart';
import 'package:sevanest_customer/features/interview_trial/presentation/widgets/interview_detail_parts.dart'
    show DashedRule, QuietAction;
import 'package:sevanest_customer/features/service_discovery/presentation/schedule_format.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

String attendanceLabel(AppLocalizations l, AttendanceStatus s) => switch (s) {
  AttendanceStatus.present => l.attendancePresent,
  AttendanceStatus.absent => l.attendanceAbsent,
  AttendanceStatus.late => l.attendanceLate,
  AttendanceStatus.leave => l.attendanceLeave,
  AttendanceStatus.exception => l.attendanceException,
  AttendanceStatus.unknown => l.attendanceUnknown,
};

/// Badge fill and text colour of a status (design: teal done, amber late, rose absent).
(Color, Color) _badge(AttendanceStatus s) => switch (s) {
  AttendanceStatus.present => (
    const Color(0xFFD6EFEA),
    const Color(0xFF0B5A53),
  ),
  AttendanceStatus.late || AttendanceStatus.exception => (
    const Color(0xFFFEF3C7),
    const Color(0xFF8A4B06),
  ),
  AttendanceStatus.absent => (const Color(0xFFFFE4E6), const Color(0xFF9F1239)),
  AttendanceStatus.leave ||
  AttendanceStatus.unknown => (const Color(0xFFE2E8F0), dsText),
};

/// "8:02 AM" for a local time.
String _clock(DateTime t) => formatTime(t.hour * 60 + t.minute);

/// "In 8:02 AM · Out 12:05 PM", or null when the worker has not checked in or out.
String? checkTimes(AppLocalizations l, AttendanceEntry e) {
  final parts = [
    if (e.checkInAt != null) l.attendanceCheckIn(_clock(e.checkInAt!)),
    if (e.checkOutAt != null) l.attendanceCheckOut(_clock(e.checkOutAt!)),
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}

/// The days of a booking, newest first, paged, inside a frosted card.
class AttendanceList extends ConsumerWidget {
  const AttendanceList({required this.bookingId, super.key});
  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final page = ref.watch(attendanceProvider(bookingId));
    final muted = AppText.body.copyWith(fontSize: 14.5, color: dsText);
    Widget child;
    if (page.isLoading && !page.hasValue) {
      child = const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (page.hasError && !page.hasValue) {
      child = Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Text(
              failureMessage(l10n, page.error!),
              textAlign: TextAlign.center,
              style: muted,
            ),
            QuietAction(
              key: const Key('error_retry_btn'),
              label: l10n.retry,
              onPressed: () => ref.invalidate(attendanceProvider(bookingId)),
            ),
          ],
        ),
      );
    } else if (page.requireValue.items.isEmpty) {
      child = Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Text(
          l10n.attendanceEmpty,
          key: const Key('attendance_empty'),
          style: muted,
        ),
      );
    } else {
      final s = page.requireValue;
      child = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, e) in s.items.indexed) ...[
            if (i > 0) const DashedRule(),
            _Row(entry: e),
          ],
          if (s.loadMoreError != null)
            Text(failureMessage(l10n, s.loadMoreError!), style: muted),
          if (s.hasMore || s.isLoadingMore)
            s.isLoadingMore
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : QuietAction(
                    key: const Key('attendance_load_more_btn'),
                    label: l10n.attendanceLoadMore,
                    onPressed: () => ref
                        .read(attendanceProvider(bookingId).notifier)
                        .loadMore(),
                  ),
        ],
      );
    }
    return DiscoverGlass(
      radius: 26,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: child,
      ),
    );
  }
}

/// One day: date and status badge; check times under it. Tapping a day with a note shows it.
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
    final times = checkTimes(l10n, e);
    final (fill, ink) = _badge(e.status);
    final small = AppText.body.copyWith(fontSize: 14, color: dsText);
    return InkWell(
      key: Key('attendance_row_${e.date}'),
      onTap: e.note == null ? null : () => setState(() => _open = !_open),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 32),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      day == null ? e.date : formatDate(day, locale),
                      style: AppText.body.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: dsNavy,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: fill,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      attendanceLabel(l10n, e.status),
                      style: AppText.body.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (times != null)
              Text(times, key: Key('attendance_times_${e.date}'), style: small),
            if (_open && e.note != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  e.note!,
                  key: Key('attendance_note_${e.date}'),
                  style: small.copyWith(height: 1.45),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
