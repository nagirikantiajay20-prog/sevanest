import 'package:flutter/material.dart';
import 'package:sevanest_customer/core/widgets/sn_badge.dart';
import 'package:sevanest_customer/features/support/domain/support.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// Chip text. `ESCALATED` is internal and reads "In progress"; unknown reads "Updated".
String ticketStatusLabel(AppLocalizations l, TicketStatus s) =>
    switch (ticketStatusForCustomer(s)) {
      TicketStatus.open => l.tkStatusOpen,
      TicketStatus.inProgress || TicketStatus.escalated => l.tkStatusInProgress,
      TicketStatus.closed => l.tkStatusClosed,
      TicketStatus.unknown => l.tkStatusUnknown,
    };

SnBadgeTone ticketStatusTone(TicketStatus s) =>
    switch (ticketStatusForCustomer(s)) {
      TicketStatus.open => SnBadgeTone.warning,
      TicketStatus.inProgress || TicketStatus.escalated => SnBadgeTone.success,
      TicketStatus.closed || TicketStatus.unknown => SnBadgeTone.neutral,
    };

/// Tile icon by category code. The categories are the backend's; an unknown one gets a help icon.
IconData supportCategoryIcon(SupportCategory c) {
  final code = c.code.toUpperCase();
  if (code.contains('SAFETY')) return Icons.gpp_maybe_outlined;
  if (code.contains('PAY') || code.contains('REFUND')) {
    return Icons.credit_card_outlined;
  }
  if (code.contains('BOOK')) return Icons.calendar_today_outlined;
  if (code.contains('REPLACE')) return Icons.autorenew;
  if (code.contains('WORKER')) return Icons.person_outline;
  if (code.contains('ACCOUNT') || code.contains('PROFILE')) {
    return Icons.badge_outlined;
  }
  return Icons.help_outline;
}

String reportReasonLabel(AppLocalizations l, ReportReason r) => switch (r) {
  ReportReason.noShow => l.safetyReasonNoShow,
  ReportReason.misconduct => l.safetyReasonMisconduct,
  ReportReason.harassment => l.safetyReasonHarassment,
  ReportReason.theft => l.safetyReasonTheft,
  ReportReason.fraud => l.safetyReasonFraud,
  ReportReason.safetyConcern => l.safetyReasonSafety,
  ReportReason.other => l.safetyReasonOther,
};
