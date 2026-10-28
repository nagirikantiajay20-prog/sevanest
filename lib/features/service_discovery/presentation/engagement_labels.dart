import 'package:flutter/material.dart';
import 'package:sevanest_customer/features/service_discovery/domain/catalog.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// User-facing copy for an engagement type (shared by step 2, Review and Results).
class EngagementLabels {
  const EngagementLabels(this.name, this.description, this.meta, this.icon);
  final String name;
  final String description;
  final String meta;
  final IconData icon;
}

EngagementLabels engagementLabels(AppLocalizations l, EngagementType t) =>
    switch (t) {
      EngagementType.fullTime => EngagementLabels(
        l.engFullTime,
        l.engFullTimeDesc,
        l.engFullTimeMeta,
        Icons.work_outline,
      ),
      EngagementType.partTime => EngagementLabels(
        l.engPartTime,
        l.engPartTimeDesc,
        l.engPartTimeMeta,
        Icons.schedule,
      ),
      EngagementType.daily => EngagementLabels(
        l.engDaily,
        l.engDailyDesc,
        l.engDailyMeta,
        Icons.calendar_month_outlined,
      ),
      EngagementType.hourly => EngagementLabels(
        l.engHourly,
        l.engHourlyDesc,
        l.engHourlyMeta,
        Icons.hourglass_bottom,
      ),
      EngagementType.liveIn => EngagementLabels(
        l.engLiveIn,
        l.engLiveInDesc,
        l.engLiveInMeta,
        Icons.home_work_outlined,
      ),
      EngagementType.shift => EngagementLabels(
        l.engShift,
        l.engShiftDesc,
        l.engShiftMeta,
        Icons.nights_stay_outlined,
      ),
      EngagementType.oneTime => EngagementLabels(
        l.engOneTime,
        l.engOneTimeDesc,
        l.engOneTimeMeta,
        Icons.event_available_outlined,
      ),
      EngagementType.monthly => EngagementLabels(
        l.engMonthly,
        l.engMonthlyDesc,
        l.engMonthlyMeta,
        Icons.date_range_outlined,
      ),
    };
