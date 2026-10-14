import 'package:intl/intl.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// "Just now" / "5 min ago" / "2 hours ago" / "3 days ago", then the date.
String timeAgo(AppLocalizations l10n, DateTime at, DateTime now) {
  final d = now.difference(at);
  if (d.inMinutes < 1) return l10n.agoNow;
  if (d.inMinutes < 60) return l10n.agoMinutes(d.inMinutes);
  if (d.inHours < 24) return l10n.agoHours(d.inHours);
  if (d.inDays < 7) return l10n.agoDays(d.inDays);
  return DateFormat('d MMM').format(at);
}

/// "7:58 PM".
String clockTime(DateTime at) => DateFormat('h:mm a').format(at);

/// "9 Oct, 7:58 PM".
String dateTimeShort(DateTime at) => DateFormat('d MMM, h:mm a').format(at);

/// "Today" / "Yesterday" / "Mon, 12 Oct" for list day headers.
String dayHeader(AppLocalizations l10n, DateTime at, DateTime now) {
  final days = DateTime(
    now.year,
    now.month,
    now.day,
  ).difference(DateTime(at.year, at.month, at.day)).inDays;
  return switch (days) {
    0 => l10n.homeToday,
    1 => l10n.dayYesterday,
    _ => DateFormat('EEE, d MMM').format(at),
  };
}

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
