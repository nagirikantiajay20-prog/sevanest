import 'package:sevanest_customer/features/service_discovery/domain/budget.dart';
import 'package:sevanest_customer/features/service_discovery/domain/requirement_draft.dart';
import 'package:sevanest_customer/features/service_discovery/domain/timing.dart';

enum DiscoverStep { service, engagement, location, timing, startDate, budget }

enum DraftGapReason {
  noService,
  noEngagement,
  noAddress,
  timingIncomplete,
  noStartDate,
  startDateOutOfRange,
  budgetIncomplete,
}

class DraftGap {
  const DraftGap(this.step, this.reason);
  final DiscoverStep step;
  final DraftGapReason reason;
}

/// First step whose data is missing or invalid, or null when the whole draft is ready to review.
/// Budget Continue runs this before Review; resume uses it to pick the screen to land on.
DraftGap? firstIncompleteStep(
  RequirementDraft d, {
  required DateTime today,
  required ScheduleConfig config,
  bool requiresBudget = true,
}) {
  if (d.serviceId == null) {
    return const DraftGap(DiscoverStep.service, DraftGapReason.noService);
  }
  if (d.engagement == null) {
    return const DraftGap(DiscoverStep.engagement, DraftGapReason.noEngagement);
  }
  if (d.address == null) {
    return const DraftGap(DiscoverStep.location, DraftGapReason.noAddress);
  }
  final timingIssues = validateTiming(
    variant: timingVariantFor(d.engagement!),
    timing: d.timing,
    date: d.startDate,
    config: config,
  );
  if (timingIssues.isNotEmpty) {
    return const DraftGap(DiscoverStep.timing, DraftGapReason.timingIncomplete);
  }
  final dateIssue = validateStartDate(d.startDate, today, config);
  if (dateIssue != null) {
    // Hourly's date lives on Timing; every other engagement has its own step.
    final step = d.skipsStartDateStep
        ? DiscoverStep.timing
        : DiscoverStep.startDate;
    return DraftGap(
      step,
      dateIssue == StartDateIssue.missing
          ? DraftGapReason.noStartDate
          : DraftGapReason.startDateOutOfRange,
    );
  }
  if (requiresBudget && budgetIssue(d.budget) != null) {
    return const DraftGap(DiscoverStep.budget, DraftGapReason.budgetIncomplete);
  }
  return null;
}
