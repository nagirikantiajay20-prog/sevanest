import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart'
    show authSerif;
import 'package:sevanest_customer/features/authentication/presentation/widgets/motion.dart'
    show seg;
import 'package:sevanest_customer/features/interview_trial/domain/interview.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_page.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_parts.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// Building blocks of the interview status screen (design 7.2).

/// Navy-to-teal (rose when it ended badly) card: status chip, headline, copy, progress bar.
class InterviewHero extends StatelessWidget {
  const InterviewHero({
    required this.statusLabel,
    required this.headline,
    required this.copy,
    required this.progress,
    required this.tone,
    this.showSteps = true,
    this.chipKey = const Key('interview_status_chip'),
    this.copyKey = const Key('interview_status_copy'),
    this.headlineKey,
    super.key,
  });
  final String statusLabel;
  final String headline;
  final String copy;

  /// 0..1 of the way from Requested to Decision; null hides the bar (Active service).
  final double? progress;
  final HeroTone tone;

  /// The Requested / Scheduled / Done / Decision captions under the bar (interview flow only).
  final bool showSteps;
  final Key chipKey;
  final Key copyKey;
  final Key? headlineKey;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = [
      l10n.interviewStatusRequested,
      l10n.interviewStatusScheduled,
      l10n.interviewPbDone,
      l10n.interviewPbDecision,
    ];
    final small = AppText.body.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: const Color(0xC7FFFFFF),
    );
    final clock = DiscoverClock.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: tone == HeroTone.bad
              ? const [Color(0xFF7F1D1D), Color(0xFF9F1239)]
              : const [dsNavy, AppColors.actionDeepTeal],
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
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  key: chipKey,
                  padding: const EdgeInsets.fromLTRB(12, 6, 14, 6),
                  decoration: BoxDecoration(
                    color: const Color(0x2EFFFFFF),
                    border: Border.all(color: const Color(0x52FFFFFF)),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PingDot(color: tone.dot, clock: clock),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          statusLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.body.copyWith(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Semantics(
                  header: true,
                  child: Text(
                    headline,
                    key: headlineKey,
                    style: authSerif(25, 1.2).copyWith(color: Colors.white),
                  ),
                ),
                if (copy.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    copy,
                    key: copyKey,
                    style: AppText.body.copyWith(
                      fontSize: 15,
                      height: 1.5,
                      color: const Color(0xDBFFFFFF),
                    ),
                  ),
                ],
                if (progress != null) ...[
                  const SizedBox(height: 16),
                  Semantics(
                    value: '${(progress! * 100).round()}%',
                    child: _ProgressBar(progress: progress!, clock: clock),
                  ),
                ],
                if (showSteps && progress != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      for (final (i, l) in labels.indexed)
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: i == 0
                                ? Alignment.centerLeft
                                : i == labels.length - 1
                                ? Alignment.centerRight
                                : Alignment.center,
                            child: Text(l, style: small),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip dot colour of the hero.
enum HeroTone {
  waiting(Color(0xFFFBBF24)),
  ok(Color(0xFF34D399)),
  bad(Color(0xFFFCA5A5));

  const HeroTone(this.dot);
  final Color dot;
}

class _PingDot extends StatelessWidget {
  const _PingDot({required this.color, required this.clock});
  final Color color;
  final ValueListenable<double> clock;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 10,
    height: 10,
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
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress, required this.clock});
  final double progress;
  final ValueListenable<double> clock;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(6),
    child: Container(
      height: 6,
      color: const Color(0x33FFFFFF),
      alignment: Alignment.centerLeft,
      child: ValueListenableBuilder<double>(
        valueListenable: clock,
        builder: (context, t, _) {
          final grow = seg(t, 200, 900, Curves.easeOutCubic);
          final glow = (t / 1800) % 1;
          return FractionallySizedBox(
            widthFactor: progress * grow,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                gradient: LinearGradient(
                  colors: const [
                    Color(0xFF34D399),
                    Color(0xFF38BDF8),
                    Color(0xFF34D399),
                  ],
                  begin: Alignment(-1 + 2 * glow, 0),
                  end: Alignment(1 + 2 * glow, 0),
                  tileMode: TileMode.mirror,
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

/// The worker this interview is with; opens their profile.
class InterviewWorkerCard extends StatelessWidget {
  const InterviewWorkerCard({
    required this.title,
    required this.initials,
    required this.photoUrl,
    required this.gradient,
    required this.verified,
    required this.rating,
    this.extra,
    required this.onTap,
    super.key,
  });
  final String title;
  final String? initials;
  final String? photoUrl;
  final List<Color> gradient;
  final bool verified;

  /// "4.8", or null when there is no rating.
  final String? rating;

  /// Muted caption after the rating (Confirm: "4 years").
  final String? extra;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DiscoverGlass(
      radius: 26,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
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
                  size: 56,
                  fontSize: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: authSerif(20, 1.2),
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (verified)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD6EFEA),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.check_rounded,
                                    size: 12,
                                    color: Color(0xFF0B5A53),
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      l10n.verified,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppText.body.copyWith(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF0B5A53),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (rating != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  rating!,
                                  style: AppText.body.copyWith(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: dsNavy,
                                  ),
                                ),
                                const Icon(
                                  Icons.star_rounded,
                                  size: 15,
                                  color: AppColors.amber,
                                ),
                              ],
                            ),
                          if (extra != null)
                            Text(
                              extra!,
                              style: AppText.body.copyWith(
                                fontSize: 13,
                                color: dsMuted,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: dsMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Type / When / Requirement / Note as dashed-divided rows, with an optional calendar button.
class InterviewInfoCard extends StatelessWidget {
  const InterviewInfoCard({
    required this.rows,
    this.calendarLabel,
    this.onCalendar,
    this.valueColor,
    this.trailing,
    this.valueKey,
    this.onTap,
    super.key,
  });
  final List<(String, String)> rows;
  final String? calendarLabel;
  final VoidCallback? onCalendar;

  /// Tint of a row's value by index (Booking: payment due in amber), null = navy.
  final Color? Function(int index)? valueColor;

  /// A small action after a row's value by index (Booking: copy the reference).
  final Widget? Function(int index)? trailing;

  /// Key of a row's value by index (tests find rows by it).
  final Key? Function(int index)? valueKey;

  /// Makes a row's value a link by index (Active service: the booking).
  final VoidCallback? Function(int index)? onTap;

  @override
  Widget build(BuildContext context) => DiscoverGlass(
    radius: 26,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, r) in rows.indexed) ...[
            if (i > 0) const DashedRule(),
            Padding(
              padding: EdgeInsets.only(
                top: i == 0 ? 0 : 11,
                bottom: i == rows.length - 1 ? 0 : 11,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      r.$1,
                      style: AppText.body.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: dsMuted,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        GestureDetector(
                          onTap: onTap?.call(i),
                          child: Text(
                            r.$2,
                            key: valueKey?.call(i),
                            style: AppText.body.copyWith(
                              fontSize: 15,
                              height: 1.4,
                              fontWeight: FontWeight.w700,
                              color: valueColor?.call(i) ?? dsNavy,
                            ),
                          ),
                        ),
                        ?trailing?.call(i),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (onCalendar != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: OutlinedButton.icon(
                key: const Key('interview_calendar_btn'),
                onPressed: onCalendar,
                icon: const Icon(Icons.edit_calendar_outlined, size: 17),
                label: Text(calendarLabel ?? ''),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  foregroundColor: AppColors.teal,
                  backgroundColor: const Color(0xCCFFFFFF),
                  side: BorderSide(
                    color: AppColors.teal.withValues(alpha: 0.45),
                    width: 1.5,
                  ),
                  shape: const StadiumBorder(),
                  textStyle: AppText.body.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class DashedRule extends StatelessWidget {
  const DashedRule({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 1,
    child: LayoutBuilder(
      builder: (context, box) => Row(
        children: [
          for (var i = 0; i < box.maxWidth ~/ 7; i++)
            Container(
              width: 4,
              height: 1,
              margin: const EdgeInsets.only(right: 3),
              color: dsNavy.withValues(alpha: 0.18),
            ),
        ],
      ),
    ),
  );
}

class TimelineStep {
  const TimelineStep(this.title, this.state, [this.subtitle]);
  final String title;
  final TimelineState state;
  final String? subtitle;
}

/// Vertical progress track: ticks for done steps, a pulsing node for the current one.
class GlassTimeline extends StatelessWidget {
  const GlassTimeline({required this.steps, super.key});
  final List<TimelineStep> steps;

  @override
  Widget build(BuildContext context) {
    final clock = DiscoverClock.of(context);
    return DiscoverGlass(
      radius: 26,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        child: ValueListenableBuilder<double>(
          valueListenable: clock,
          builder: (context, t, _) => Column(
            children: [
              for (final (i, s) in steps.indexed)
                _Step(step: s, last: i == steps.length - 1, t: t, index: i),
            ],
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.step,
    required this.last,
    required this.t,
    required this.index,
  });
  final TimelineStep step;
  final bool last;
  final double t;
  final int index;

  @override
  Widget build(BuildContext context) {
    final s = step.state;
    final done = s == TimelineState.done;
    final cur = s == TimelineState.current;
    final bad = s == TimelineState.failed;
    final pop = seg(t, 300 + index * 150.0, 500, Curves.easeOutBack);
    final line = seg(t, 400 + index * 150.0, 700, Curves.easeOut);
    final ping = ((t - 800) / 2000) % 1;
    final size = cur ? 34.0 : 30.0;
    return Stack(
      children: [
        if (!last)
          Positioned(
            left: 13.5,
            top: 30,
            bottom: 0,
            width: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: ColoredBox(
                color: dsNavy.withValues(alpha: 0.14),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: FractionallySizedBox(
                    heightFactor: done ? line : 0,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [AppColors.teal, dsSky],
                        ),
                      ),
                      child: SizedBox(width: double.infinity),
                    ),
                  ),
                ),
              ),
            ),
          ),
        Padding(
          padding: EdgeInsets.only(bottom: last ? 0 : 22),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 30,
                height: cur ? 30 : 30,
                child: OverflowBox(
                  maxWidth: size + 8,
                  maxHeight: size + 8,
                  child: Transform.scale(
                    scale: (done || cur) ? pop.clamp(0.0, 1.2) : 1,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        if (cur && t > 800)
                          Opacity(
                            opacity: 0.55 * (1 - ping),
                            child: Container(
                              width: size * (0.8 + 1.2 * ping),
                              height: size * (0.8 + 1.2 * ping),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.teal,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        Container(
                          width: size,
                          height: size,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: cur
                                ? const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [AppColors.teal, dsSky],
                                  )
                                : null,
                            color: cur
                                ? null
                                : done
                                ? AppColors.teal
                                : bad
                                ? const Color(0xFFE11D48)
                                : const Color(0xE6FFFFFF),
                            border: cur
                                ? null
                                : Border.all(
                                    color: done
                                        ? AppColors.teal
                                        : bad
                                        ? const Color(0xFFE11D48)
                                        : const Color(0xFFCBD5E1),
                                    width: 2,
                                  ),
                            boxShadow: [
                              BoxShadow(
                                color: cur
                                    ? AppColors.teal.withValues(alpha: 0.45)
                                    : dsNavy.withValues(alpha: 0.1),
                                blurRadius: cur ? 18 : 8,
                                offset: Offset(0, cur ? 8 : 3),
                              ),
                            ],
                          ),
                          child: done
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 16,
                                  color: Colors.white,
                                )
                              : bad
                              ? const Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: Colors.white,
                                )
                              : cur
                              ? const Icon(
                                  Icons.circle,
                                  size: 8,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.title,
                        style: AppText.body.copyWith(
                          fontSize: 16,
                          fontWeight: s == TimelineState.upcoming
                              ? FontWeight.w700
                              : FontWeight.w800,
                          height: 1.3,
                          color: s == TimelineState.upcoming
                              ? const Color(0xFF64748B)
                              : dsNavy,
                        ),
                      ),
                      if (step.subtitle != null && step.subtitle!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            step.subtitle!,
                            style: AppText.body.copyWith(
                              fontSize: 13.5,
                              color: dsMuted,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Outlined teal action (Reschedule, Not a fit, Keep my time).
class OutlineAction extends StatelessWidget {
  const OutlineAction({
    required this.label,
    required this.onPressed,
    super.key,
  });
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 54,
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.teal,
        backgroundColor: const Color(0xC7FFFFFF),
        side: BorderSide(
          color: AppColors.teal.withValues(
            alpha: onPressed == null ? 0.25 : 0.5,
          ),
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
        textStyle: AppText.body.copyWith(
          fontSize: 15.5,
          fontWeight: FontWeight.w700,
        ),
      ),
      child: Text(label),
    ),
  );
}

/// Plain text action (Cancel in rose, Contact support in slate).
class QuietAction extends StatelessWidget {
  const QuietAction({
    required this.label,
    required this.onPressed,
    this.danger = false,
    super.key,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool danger;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: danger ? const Color(0xFFBE123C) : dsMuted,
        textStyle: AppText.body.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
      child: Text(label),
    ),
  );
}
