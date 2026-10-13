import 'package:sevanest_customer/core/widgets/sn_badge.dart';
import 'package:sevanest_customer/features/interview_trial/domain/interview.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/schedule_format.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

String interviewTypeName(AppLocalizations l, InterviewType t) =>
    t == InterviewType.trial ? l.interviewTypeTrial : l.interviewTypeInterview;

/// Chip text. Unknown statuses read "Updated", never a guess.
String interviewStatusLabel(AppLocalizations l, InterviewStatus s) =>
    switch (s) {
      InterviewStatus.requested => l.interviewStatusRequested,
      InterviewStatus.scheduled => l.interviewStatusScheduled,
      InterviewStatus.rescheduleProposed => l.interviewStatusProposed,
      InterviewStatus.completed => l.interviewStatusCompleted,
      InterviewStatus.cancelled => l.interviewStatusCancelled,
      InterviewStatus.declined => l.interviewStatusDeclined,
      InterviewStatus.confirmed => l.interviewStatusConfirmed,
      InterviewStatus.notAFit => l.interviewStatusNotAFit,
      InterviewStatus.unknown => l.interviewStatusUnknown,
    };

SnBadgeTone interviewStatusTone(InterviewStatus s) => switch (s) {
  InterviewStatus.scheduled || InterviewStatus.confirmed => SnBadgeTone.success,
  InterviewStatus.requested ||
  InterviewStatus.rescheduleProposed ||
  InterviewStatus.completed => SnBadgeTone.warning,
  InterviewStatus.cancelled || InterviewStatus.declined => SnBadgeTone.error,
  InterviewStatus.notAFit || InterviewStatus.unknown => SnBadgeTone.neutral,
};

/// "Tue, 13 Oct" + "5:30 PM", or null when the backend gave no date.
({String date, String time})? interviewWhen(Interview i, [String? locale]) {
  final d = i.date;
  if (d == null) return null;
  final m = i.slotMinutes;
  return (date: formatDate(d, locale), time: m == null ? '' : formatTime(m));
}

/// One-line explanation under the status chip.
String interviewStatusCopy(AppLocalizations l, Interview i, [String? locale]) {
  final when = interviewWhen(i, locale);
  return switch (i.status) {
    InterviewStatus.requested => l.interviewCopyRequested,
    InterviewStatus.scheduled =>
      when == null
          ? l.interviewStatusScheduled
          : l.interviewCopyScheduled(
              interviewTypeName(l, i.type),
              when.date,
              when.time,
            ),
    InterviewStatus.rescheduleProposed => _proposedCopy(l, i, locale),
    InterviewStatus.completed => l.interviewCopyCompleted,
    InterviewStatus.cancelled => l.interviewCopyCancelled,
    InterviewStatus.declined => l.interviewCopyDeclined,
    InterviewStatus.confirmed => l.interviewCopyConfirmed,
    InterviewStatus.notAFit => l.interviewCopyNotAFit,
    InterviewStatus.unknown => l.interviewCopyUnknown,
  };
}

String _proposedCopy(AppLocalizations l, Interview i, String? locale) {
  final p = i.proposedAt;
  if (p == null) return l.interviewStatusProposed;
  return l.interviewCopyProposed(
    formatDate(p, locale),
    formatTime(p.hour * 60 + p.minute),
  );
}
