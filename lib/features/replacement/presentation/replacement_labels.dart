import 'package:sevanest_customer/core/widgets/sn_badge.dart';
import 'package:sevanest_customer/features/replacement/domain/replacement.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// Chip text. Unknown statuses read "Updated", never a guess or the raw code.
String replacementStatusLabel(AppLocalizations l, ReplacementStatus s) =>
    switch (s) {
      ReplacementStatus.requested => l.repStatusRequested,
      ReplacementStatus.approved => l.repStatusApproved,
      ReplacementStatus.rejected => l.repStatusRejected,
      ReplacementStatus.cancelled => l.repStatusCancelled,
      ReplacementStatus.completed => l.repStatusCompleted,
      ReplacementStatus.unknown => l.repStatusUnknown,
    };

SnBadgeTone replacementStatusTone(ReplacementStatus s) => switch (s) {
  ReplacementStatus.completed => SnBadgeTone.success,
  ReplacementStatus.requested ||
  ReplacementStatus.approved => SnBadgeTone.warning,
  ReplacementStatus.rejected => SnBadgeTone.error,
  ReplacementStatus.cancelled ||
  ReplacementStatus.unknown => SnBadgeTone.neutral,
};

String replacementReasonLabel(AppLocalizations l, ReplacementReason r) =>
    switch (r) {
      ReplacementReason.notOnTime => l.repReasonNotOnTime,
      ReplacementReason.frequentAbsences => l.repReasonFrequentAbsences,
      ReplacementReason.workQuality => l.repReasonWorkQuality,
      ReplacementReason.behaviour => l.repReasonBehaviour,
      ReplacementReason.scheduleChanged => l.repReasonScheduleChanged,
      ReplacementReason.workerLeft => l.repReasonWorkerLeft,
      ReplacementReason.safety => l.repReasonSafety,
      ReplacementReason.other => l.repReasonOther,
    };

/// A reason the app sent shows in the customer's language; their own words show as written.
String replacementReasonText(AppLocalizations l, String stored) {
  final r = ReplacementReason.fromText(stored);
  return r == null ? stored : replacementReasonLabel(l, r);
}
