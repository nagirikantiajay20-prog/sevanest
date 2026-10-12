import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/features/service_discovery/domain/draft_validation.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// Route of each requirement-builder step.
String routeForStep(DiscoverStep s) => switch (s) {
  DiscoverStep.service => Routes.discoverCategory,
  DiscoverStep.engagement => Routes.discoverEngagement,
  DiscoverStep.location => Routes.discoverLocation,
  DiscoverStep.timing => Routes.discoverTiming,
  DiscoverStep.startDate => Routes.discoverStartDate,
  DiscoverStep.budget => Routes.discoverBudget,
};

/// 1-based step number shown in "Step n of 6".
int stepNumber(DiscoverStep s) => s.index + 1;

String gapMessage(AppLocalizations l, DraftGapReason r) => switch (r) {
  DraftGapReason.noService => l.gapNoService,
  DraftGapReason.noEngagement => l.gapNoEngagement,
  DraftGapReason.noAddress => l.gapNoAddress,
  DraftGapReason.timingIncomplete => l.gapTiming,
  DraftGapReason.noStartDate => l.gapNoStartDate,
  DraftGapReason.startDateOutOfRange => l.gapStartDateRange,
  DraftGapReason.budgetIncomplete => l.gapBudget,
};

/// Whole-draft check failed: say why, then open the first incomplete step in edit mode (so
/// finishing it returns to the screen that asked).
Future<void> sendToGap(BuildContext context, DraftGap gap) async {
  final l10n = AppLocalizations.of(context);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(gapMessage(l10n, gap.reason))));
  await context.push<Object?>('${routeForStep(gap.step)}?edit=true');
}
