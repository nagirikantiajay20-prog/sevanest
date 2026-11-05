import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart'
    show AuthCta, authSerif;
import 'package:sevanest_customer/features/interview_trial/domain/interview.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/schedule_format.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_parts.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// Building blocks of the "Request an interview" form (design 7.1).

/// Frosted section card; a teal-to-sky numbered disc in front of the heading when [number] is set.
class RequestSection extends StatelessWidget {
  const RequestSection({
    required this.title,
    required this.child,
    required this.delayMs,
    this.number,
    this.trailing,
    super.key,
  });
  final int? number;

  /// Action at the right of the heading (Confirm: "Edit").
  final Widget? trailing;
  final String title;
  final Widget child;
  final double delayMs;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 14),
    child: DiscoverRise(
      delayMs: delayMs,
      child: DiscoverGlass(
        radius: 26,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (number != null) ...[
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.teal, dsSky],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.teal.withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        '$number',
                        style: AppText.body.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.surface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(title, style: authSerif(20, 1.2)),
                    ),
                  ),
                  ?trailing,
                ],
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    ),
  );
}

/// Worker strip at the top of the form: initials, name, experience line and rating.
class RequestWorkerCard extends StatelessWidget {
  const RequestWorkerCard({
    required this.title,
    required this.initials,
    required this.photoUrl,
    required this.gradient,
    required this.subtitle,
    required this.rating,
    super.key,
  });
  final String title;
  final String? initials;
  final String? photoUrl;
  final List<Color> gradient;
  final String subtitle;

  /// "4.8" or "New".
  final String rating;

  @override
  Widget build(BuildContext context) => DiscoverRise(
    delayMs: 0,
    child: DiscoverGlass(
      radius: 26,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: authSerif(20, 1.2),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body.copyWith(
                      fontSize: 13.5,
                      color: dsMuted,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              rating,
              style: AppText.body.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: dsNavy,
              ),
            ),
            if (rating != AppLocalizations.of(context).workerNew)
              const Icon(Icons.star_rounded, size: 16, color: AppColors.amber),
          ],
        ),
      ),
    ),
  );
}

/// Interview / Trial radio row.
class TypeOption extends StatelessWidget {
  const TypeOption({
    required this.title,
    required this.hint,
    required this.selected,
    required this.onTap,
    super.key,
  });
  final String title;
  final String hint;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    inMutuallyExclusiveGroup: true,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: selected
            ? AppColors.teal.withValues(alpha: 0.12)
            : AppColors.whiteA70xB3,
        border: Border.all(
          color: selected ? AppColors.teal : dsNavy.withValues(alpha: 0.14),
          width: 1.5,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: AppColors.teal.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 68),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppText.body.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: dsNavy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hint,
                          style: AppText.body.copyWith(
                            fontSize: 13.5,
                            height: 1.35,
                            color: dsMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? AppColors.teal
                            : AppColors.slate400Light,
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: AnimatedScale(
                      scale: selected ? 1 : 0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutBack,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.teal,
                        ),
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
  );
}

/// Horizontal strip of dates, today first. Keys `interview_date_<index>`.
class DateStrip extends StatelessWidget {
  const DateStrip({
    required this.today,
    required this.days,
    required this.selected,
    required this.onSelect,
    super.key,
  });
  final DateTime today;
  final int days;
  final DateTime? selected;
  final ValueChanged<DateTime>? onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    // Chips grow with the text size so the three lines never clip.
    final grow = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6);
    return SizedBox(
      height: 96 * grow,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: days,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final d = DateTime(today.year, today.month, today.day + i);
          final on = selected == d;
          final top = i == 0
              ? l10n.interviewDateToday
              : DateFormat.E(locale).format(d);
          final fg = on ? AppColors.surface : dsText;
          final small = AppText.body.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: fg,
          );
          return Semantics(
            button: true,
            selected: on,
            label:
                '${i == 0 ? '${l10n.interviewDateToday}, ' : ''}${DateFormat('EEE d MMM', locale).format(d)}',
            excludeSemantics: true,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              transform: Matrix4.translationValues(0, on ? -3 : 0, 0),
              width: 60 * grow,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: on
                    ? const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [dsNavy, AppColors.actionDeepTeal],
                      )
                    : null,
                color: on ? null : AppColors.whiteA70xB3,
                border: Border.all(
                  color: on
                      ? Colors.transparent
                      : dsNavy.withValues(alpha: 0.14),
                  width: 1.5,
                ),
                boxShadow: on
                    ? [
                        BoxShadow(
                          color: dsNavy.withValues(alpha: 0.35),
                          blurRadius: 22,
                          offset: const Offset(0, 12),
                        ),
                      ]
                    : null,
              ),
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  key: Key('interview_date_$i'),
                  borderRadius: BorderRadius.circular(20),
                  onTap: onSelect == null ? null : () => onSelect!(d),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        top,
                        style: small.copyWith(
                          color: i == 0 && !on ? AppColors.teal : fg,
                        ),
                      ),
                      Text(
                        '${d.day}',
                        style: authSerif(24, 1.1).copyWith(color: fg),
                      ),
                      Text(DateFormat.MMM(locale).format(d), style: small),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The customer's own start time: a tile that opens the platform time picker (hour, minute, AM/PM),
/// with the worker's free windows and any problem with the chosen time under it.
class InterviewTimeField extends StatelessWidget {
  const InterviewTimeField({
    required this.minutes,
    required this.visitMinutes,
    required this.windows,
    required this.check,
    required this.onTap,
    super.key,
  });

  /// Chosen start (minutes since midnight), or null.
  final int? minutes;
  final int visitMinutes;
  final List<({int start, int end})> windows;

  /// Verdict on [minutes]; ignored while it is null.
  final TimeCheck check;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final m = minutes;
    final bad = m != null && check != TimeCheck.ok;
    final hasTime = m != null;
    final accent = bad ? AppColors.error : AppColors.teal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          selected: hasTime && !bad,
          label: hasTime ? formatTime(m) : l10n.interviewTimeChoose,
          excludeSemantics: true,
          child: Material(
            color: AppColors.whiteA75xBF,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: bad ? accent : dsNavy.withValues(alpha: 0.16),
                width: 1.5,
              ),
            ),
            child: InkWell(
              key: const Key('interview_time_btn'),
              borderRadius: BorderRadius.circular(18),
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 72),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.pillActive,
                        ),
                        child: Icon(
                          Icons.schedule_rounded,
                          size: 22,
                          color: accent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasTime
                                  ? DateFormat.jm(locale).format(
                                      DateTime(2000, 1, 1, m ~/ 60, m % 60),
                                    )
                                  : l10n.interviewTimeChoose,
                              key: const Key('interview_time_value'),
                              style: authSerif(
                                hasTime ? 26 : 20,
                                1.1,
                              ).copyWith(color: dsNavy),
                            ),
                            Text(
                              hasTime
                                  ? l10n.interviewTimeLength(visitMinutes)
                                  : l10n.interviewTimeChooseHint,
                              style: AppText.body.copyWith(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: dsMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        hasTime
                            ? l10n.interviewTimeChange
                            : l10n.interviewTimeSet,
                        style: AppText.body.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.teal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (bad)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline_rounded, size: 18, color: accent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    switch (check) {
                      TimeCheck.past => l10n.interviewTimePast,
                      TimeCheck.tooEarly => l10n.interviewTimeTooEarly(
                        formatTime(windows.first.start),
                      ),
                      _ => l10n.interviewTimeUnavailable,
                    },
                    key: const Key('interview_time_error'),
                    style: AppText.body.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (windows.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              l10n.interviewTimeWindows(
                windows.map((w) => formatTimeSpan(w.start, w.end)).join(', '),
              ),
              key: const Key('interview_time_windows'),
              style: AppText.body.copyWith(fontSize: 13, color: dsMuted),
            ),
          ),
      ],
    );
  }
}

/// "Choose a date above to see the free times." placeholder.
class SlotHint extends StatelessWidget {
  const SlotHint(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.whiteA50x80,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: dsNavy.withValues(alpha: 0.25), width: 1.5),
    ),
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.pillActive,
          ),
          child: const Icon(
            Icons.schedule_rounded,
            size: 22,
            color: AppColors.teal,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: AppText.body.copyWith(
              fontSize: 14.5,
              height: 1.4,
              color: dsMuted,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Bottom bar: the chosen date and time (or what is still missing) over the send button.
class RequestSubmitBar extends StatelessWidget {
  const RequestSubmitBar({
    required this.summary,
    required this.hint,
    required this.label,
    required this.loadingLabel,
    required this.loading,
    required this.onPressed,
    super.key,
  });

  /// "Thu, 29 Oct · 10 AM – 11 AM" once both are chosen.
  final String? summary;
  final String hint;
  final String label;
  final String loadingLabel;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        height: 30,
        child: Center(
          child: summary == null
              ? Text(
                  hint,
                  style: AppText.body.copyWith(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: dsText,
                  ),
                )
              : Container(
                  key: const Key('interview_summary'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.event_rounded,
                        size: 14,
                        color: AppColors.teal0B5A53,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          summary!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.body.copyWith(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.teal0B5A53,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
      const SizedBox(height: 6),
      AuthCta(
        key: const Key('interview_submit_btn'),
        clock: DiscoverClock.of(context),
        label: label,
        loadingLabel: loadingLabel,
        loading: loading,
        breathe: true,
        showArrow: false,
        radius: 18,
        height: 58,
        onPressed: onPressed,
      ),
    ],
  );
}

/// Frosted note box with the 300-character limit.
class RequestNoteField extends StatelessWidget {
  const RequestNoteField({
    required this.controller,
    required this.enabled,
    required this.label,
    required this.hint,
    required this.onChanged,
    super.key,
  });
  final TextEditingController controller;
  final bool enabled;
  final String label;
  final String hint;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c, double w) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: c, width: w),
    );
    return TextField(
      key: const Key('interview_note_field'),
      controller: controller,
      enabled: enabled,
      maxLength: 300,
      minLines: 3,
      maxLines: 5,
      onChanged: (_) => onChanged(),
      style: AppText.body.copyWith(fontSize: 15, height: 1.45, color: dsNavy),
      decoration: InputDecoration(
        semanticCounterText: null,
        labelText: label,
        hintText: hint,
        hintMaxLines: 3,
        floatingLabelBehavior: FloatingLabelBehavior.never,
        filled: true,
        fillColor: AppColors.whiteA80xCC,
        contentPadding: const EdgeInsets.all(14),
        hintStyle: AppText.body.copyWith(
          fontSize: 15,
          color: AppColors.slate400,
        ),
        enabledBorder: border(dsNavy.withValues(alpha: 0.16), 1.5),
        disabledBorder: border(dsNavy.withValues(alpha: 0.1), 1.5),
        focusedBorder: border(dsNavy, 1.5),
      ),
    );
  }
}
