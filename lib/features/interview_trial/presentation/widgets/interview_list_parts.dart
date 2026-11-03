import 'package:flutter/material.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart'
    show authSerif;
import 'package:sevanest_customer/features/interview_trial/domain/interview.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_page.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_parts.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// Colours of one interview status: the card's accent bar and the badge.
typedef InterviewLook = ({Color accent, Color badgeBg, Color badgeFg});

InterviewLook interviewLook(InterviewStatus s) => switch (s) {
  InterviewStatus.scheduled => (
    accent: AppColors.teal,
    badgeBg: const Color(0xFFD6EFEA),
    badgeFg: const Color(0xFF0B5A53),
  ),
  InterviewStatus.requested || InterviewStatus.rescheduleProposed => (
    accent: AppColors.amber,
    badgeBg: const Color(0xFFFEF3C7),
    badgeFg: const Color(0xFF8A4B06),
  ),
  InterviewStatus.completed || InterviewStatus.confirmed => (
    accent: const Color(0xFF2563EB),
    badgeBg: const Color(0xFFDBEAFE),
    badgeFg: const Color(0xFF1E40AF),
  ),
  InterviewStatus.cancelled || InterviewStatus.declined => (
    accent: const Color(0xFFE11D48),
    badgeBg: const Color(0xFFFFE4E6),
    badgeFg: const Color(0xFF9F1239),
  ),
  InterviewStatus.notAFit || InterviewStatus.unknown => (
    accent: const Color(0xFF64748B),
    badgeBg: const Color(0xFFE2E8F0),
    badgeFg: const Color(0xFF475569),
  ),
};

/// Upcoming = still open (asked for, or booked); everything else is past.
bool isUpcoming(InterviewStatus s) =>
    s == InterviewStatus.requested ||
    s == InterviewStatus.scheduled ||
    s == InterviewStatus.rescheduleProposed;

/// When the interview starts, or null while no time is agreed.
DateTime? interviewStart(Interview i) {
  final d = i.date;
  final m = i.slotMinutes;
  return d == null || m == null
      ? null
      : DateTime(d.year, d.month, d.day, m ~/ 60, m % 60);
}

/// All / Upcoming / Past (or any [labels]) as one frosted track with a navy thumb that slides.
class InterviewSegments extends StatelessWidget {
  const InterviewSegments({
    required this.selected,
    required this.counts,
    required this.onChanged,
    this.labels,
    this.tabKey,
    super.key,
  });
  final int selected;
  final List<int> counts;
  final ValueChanged<int> onChanged;

  /// Defaults to All / Upcoming / Past.
  final List<String>? labels;

  /// Key of the tab at an index (default `interviews_tab_<i>`).
  final Key Function(int index)? tabKey;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels =
        this.labels ??
        [l10n.interviewsAll, l10n.interviewsUpcoming, l10n.interviewsPast];
    final n = labels.length;
    return DiscoverGlass(
      radius: 18,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: SizedBox(
          height: 48,
          child: Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 400),
                curve: const Cubic(.34, 1.4, .64, 1),
                alignment: Alignment(-1 + 2 * selected / (n - 1), 0),
                child: FractionallySizedBox(
                  widthFactor: 1 / n,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [dsNavy, AppColors.actionDeepTeal],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: dsNavy.withValues(alpha: 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < n; i++)
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: selected == i,
                        child: InkWell(
                          key: tabKey?.call(i) ?? Key('interviews_tab_$i'),
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => onChanged(i),
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 250),
                                    style: AppText.body.copyWith(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: selected == i
                                          ? Colors.white
                                          : dsText,
                                    ),
                                    child: Text(labels[i]),
                                  ),
                                  const SizedBox(width: 5),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(999),
                                      color: selected == i
                                          ? const Color(0x38FFFFFF)
                                          : dsNavy.withValues(alpha: 0.1),
                                    ),
                                    child: Text(
                                      '${counts[i]}',
                                      style: AppText.body.copyWith(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: selected == i
                                            ? Colors.white
                                            : dsText,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Navy "Next interview" card: live dot, who, when, and a days / hours / mins countdown.
class NextInterviewCard extends StatelessWidget {
  const NextInterviewCard({
    required this.name,
    required this.initials,
    required this.photoUrl,
    required this.when,
    required this.remaining,
    required this.onTap,
    super.key,
  });
  final String name;
  final String? initials;
  final String? photoUrl;
  final String when;

  /// Time left, never negative.
  final Duration remaining;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    final mins = remaining.inMinutes % 60;
    final units = [
      (days, l10n.interviewCdDays(days)),
      (hours, l10n.interviewCdHours(hours)),
      (mins, l10n.interviewCdMins(mins)),
    ];
    return Semantics(
      button: true,
      label: l10n.interviewNextSemantics(name),
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [dsNavy, AppColors.actionDeepTeal],
          ),
          boxShadow: [
            BoxShadow(
              color: dsNavy.withValues(alpha: 0.32),
              blurRadius: 38,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Stack(
          children: [
            const SheenSweep(periodMs: 5000, band: 0.3),
            Material(
              type: MaterialType.transparency,
              child: InkWell(
                key: const Key('interviews_next_card'),
                borderRadius: BorderRadius.circular(28),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(10, 5, 12, 5),
                        decoration: BoxDecoration(
                          color: const Color(0x2EFFFFFF),
                          border: Border.all(color: const Color(0x52FFFFFF)),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const _LiveDot(),
                            const SizedBox(width: 8),
                            Text(
                              l10n.interviewNext,
                              style: AppText.body.copyWith(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              image: photoUrl == null
                                  ? null
                                  : DecorationImage(
                                      image: NetworkImage(photoUrl!),
                                      fit: BoxFit.cover,
                                    ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x33000000),
                                  blurRadius: 14,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: photoUrl != null
                                ? null
                                : Text(
                                    workerInitials(initials, name),
                                    style: AppText.body.copyWith(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: dsNavy,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: authSerif(
                                    22,
                                    1.2,
                                  ).copyWith(color: Colors.white),
                                ),
                                Text(
                                  when,
                                  style: AppText.body.copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Semantics(
                        container: true,
                        child: Row(
                          children: [
                            for (final (i, u) in units.indexed) ...[
                              if (i > 0) const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0x24FFFFFF),
                                    border: Border.all(
                                      color: const Color(0x38FFFFFF),
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        '${u.$1}',
                                        style: authSerif(
                                          22,
                                          1.1,
                                        ).copyWith(color: Colors.white),
                                      ),
                                      Text(
                                        u.$2,
                                        style: AppText.body.copyWith(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Green dot with a ping ring, driven by the screen clock.
class _LiveDot extends StatelessWidget {
  const _LiveDot();

  @override
  Widget build(BuildContext context) {
    final clock = DiscoverClock.of(context);
    return SizedBox(
      width: 9,
      height: 9,
      child: ValueListenableBuilder<double>(
        valueListenable: clock,
        builder: (context, t, _) {
          final k = (t / 1800) % 1;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Transform.scale(
                  scale: 0.8 + 1.4 * k,
                  child: Opacity(
                    opacity: 0.7 * (1 - k),
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF34D399),
                      ),
                    ),
                  ),
                ),
              ),
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF34D399),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// One interview row: status accent bar, avatar, who / when, status badge, chevron.
class InterviewTile extends StatelessWidget {
  const InterviewTile({
    required this.title,
    required this.initials,
    required this.photoUrl,
    required this.gradient,
    required this.subtitle,
    required this.statusLabel,
    required this.look,
    required this.onTap,
    this.footer,
    this.titleKey,
    super.key,
  });
  final String title;
  final String? initials;
  final String? photoUrl;
  final List<Color> gradient;
  final String subtitle;
  final String statusLabel;
  final InterviewLook look;
  final VoidCallback onTap;

  /// Dashed-rule strip under the row (Bookings: start date, payment, pay button).
  final Widget? footer;
  final Key? titleKey;

  @override
  Widget build(BuildContext context) => DiscoverGlass(
    radius: 24,
    child: Stack(
      children: [
        Positioned(
          left: 0,
          top: 14,
          bottom: 14,
          width: 4,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: look.accent,
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(4),
              ),
            ),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      GlassAvatar(
                        title: title,
                        initials: initials,
                        photoUrl: photoUrl,
                        gradient: gradient,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              key: titleKey,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: authSerif(19, 1.2),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: AppText.body.copyWith(
                                fontSize: 13.5,
                                height: 1.35,
                                color: dsMuted,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: look.badgeBg,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: look.badgeFg,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      statusLabel,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppText.body.copyWith(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: look.badgeFg,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 24,
                        color: dsMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (footer != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: footer,
              ),
          ],
        ),
      ],
    ),
  );
}
