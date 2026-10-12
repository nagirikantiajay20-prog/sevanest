import 'package:intl/intl.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// "Tomorrow, 5:30 PM" / "Today, 9:00 AM" / "Mon, 12 Oct, 9:00 AM".
String relativeWhen(AppLocalizations l10n, DateTime at, DateTime now) {
  final days = DateTime(
    at.year,
    at.month,
    at.day,
  ).difference(DateTime(now.year, now.month, now.day)).inDays;
  final day = switch (days) {
    0 => l10n.homeToday,
    1 => l10n.homeTomorrow,
    _ => DateFormat('EEE, d MMM').format(at),
  };
  return '$day, ${DateFormat('h:mm a').format(at)}';
}

/// "Starts in 1 day" / "Starts in 3 hours" / "Starts in 20 min" / "Starting now".
String startsIn(AppLocalizations l10n, DateTime at, DateTime now) {
  final diff = at.difference(now);
  if (diff.inMinutes <= 0) return l10n.homeStartingNow;
  if (diff.inHours < 1) return l10n.homeStartsInMinutes(diff.inMinutes);
  if (diff.inHours < 24) return l10n.homeStartsInHours(diff.inHours);
  return l10n.homeStartsInDays(diff.inDays);
}
