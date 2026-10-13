import 'package:sevanest_customer/core/widgets/sn_badge.dart';
import 'package:sevanest_customer/features/booking/domain/booking.dart';
import 'package:sevanest_customer/features/interview_trial/domain/interview.dart';
import 'package:sevanest_customer/features/interview_trial/presentation/interview_labels.dart';
import 'package:sevanest_customer/features/service_discovery/domain/budget.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/schedule_format.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// Chip text. Unknown statuses read "Updated", never a guess.
String bookingStatusLabel(AppLocalizations l, BookingStatus s) => switch (s) {
  BookingStatus.newRequest => l.bookingStatusNewRequest,
  BookingStatus.matched => l.bookingStatusMatched,
  BookingStatus.interviewTrialScheduled => l.bookingStatusScheduled,
  BookingStatus.interviewTrialCompleted => l.bookingStatusInterviewDone,
  BookingStatus.pendingPayment => l.bookingStatusPendingPayment,
  BookingStatus.confirmed => l.bookingStatusConfirmed,
  BookingStatus.active => l.bookingStatusActive,
  BookingStatus.replacementRequested => l.bookingStatusReplacementRequested,
  BookingStatus.replaced => l.bookingStatusReplaced,
  BookingStatus.completed => l.bookingStatusCompleted,
  BookingStatus.cancelled => l.bookingStatusCancelled,
  BookingStatus.unknown => l.bookingStatusUnknown,
};

SnBadgeTone bookingStatusTone(BookingStatus s) => switch (s) {
  BookingStatus.confirmed ||
  BookingStatus.active ||
  BookingStatus.completed => SnBadgeTone.success,
  BookingStatus.newRequest ||
  BookingStatus.matched ||
  BookingStatus.interviewTrialScheduled ||
  BookingStatus.interviewTrialCompleted ||
  BookingStatus.pendingPayment ||
  BookingStatus.replacementRequested => SnBadgeTone.warning,
  BookingStatus.cancelled => SnBadgeTone.error,
  BookingStatus.replaced || BookingStatus.unknown => SnBadgeTone.neutral,
};

/// The plain-language line under the status chip.
String bookingStatusCopy(AppLocalizations l, Booking b, [String? locale]) {
  final at = b.scheduledAt;
  return switch (b.status) {
    BookingStatus.newRequest => l.bookingCopyNewRequest,
    BookingStatus.matched => l.bookingCopyMatched,
    BookingStatus.interviewTrialScheduled =>
      at == null
          ? l.bookingCopyScheduled
          : l.bookingCopyScheduledAt(
              interviewTypeName(l, b.scheduleType ?? InterviewType.interview),
              formatDate(at, locale),
              formatTime(at.hour * 60 + at.minute),
            ),
    BookingStatus.interviewTrialCompleted => l.bookingCopyInterviewDone,
    BookingStatus.pendingPayment => l.bookingCopyPendingPayment,
    BookingStatus.confirmed => l.bookingCopyConfirmed,
    BookingStatus.active => l.bookingCopyActive,
    BookingStatus.replacementRequested => l.bookingCopyReplacementRequested,
    BookingStatus.replaced => l.bookingCopyReplaced,
    BookingStatus.completed => l.bookingCopyCompleted,
    BookingStatus.cancelled => l.bookingCopyCancelled,
    BookingStatus.unknown => l.bookingCopyUnknown,
  };
}

/// "₹6,000 – ₹10,000 per month", or null when the booking has no budget.
String? bookingBudgetLabel(AppLocalizations l, Booking b) {
  final lo = b.budgetMin;
  final hi = b.budgetMax;
  if (lo == null || hi == null) return null;
  final range = '${formatRupees(lo)} – ${formatRupees(hi)}';
  return b.budgetPeriod == BudgetPeriod.hourly
      ? l.budgetRangePerHour(range)
      : l.budgetRangePerMonth(range);
}
