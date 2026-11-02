import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart'
    show AuthCta, authSerif;
import 'package:sevanest_customer/features/authentication/presentation/widgets/motion.dart'
    show seg;
import 'package:sevanest_customer/features/interview_trial/domain/interview.dart';
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
    super.key,
  });
  final int? number;
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
                          color: Colors.white,
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
            : const Color(0xB3FFFFFF),
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
                            : const Color(0xFF94A3B8),
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
          final fg = on ? Colors.white : dsText;
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
                color: on ? null : const Color(0xB3FFFFFF),
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

/// Free times for the chosen day, grouped Morning / Afternoon & evening, two per row.
class SlotGrid extends StatelessWidget {
  const SlotGrid({
    required this.slots,
    required this.selected,
    required this.onSelect,
    super.key,
  });
  final List<InterviewSlot> slots;
  final String? selected;
  final ValueChanged<InterviewSlot>? onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final morning = slots.where((s) => s.startMinutes < 12 * 60).toList();
    final later = slots.where((s) => s.startMinutes >= 12 * 60).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (morning.isNotEmpty)
          _group(
            Icons.wb_sunny_outlined,
            AppColors.amber,
            l10n.interviewMorning,
            morning,
          ),
        if (later.isNotEmpty)
          _group(
            Icons.nightlight_outlined,
            dsNavy,
            l10n.interviewAfternoon,
            later,
            first: morning.isEmpty,
          ),
      ],
    );
  }

  Widget _group(
    IconData icon,
    Color color,
    String label,
    List<InterviewSlot> list, {
    bool first = true,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: EdgeInsets.only(top: first ? 0 : 14, bottom: 8),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label.toUpperCase(),
              style: AppText.body.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: const Color(0xFF475569),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 1,
                color: dsNavy.withValues(alpha: 0.14),
              ),
            ),
          ],
        ),
      ),
      LayoutBuilder(
        builder: (context, box) {
          final w = (box.maxWidth - 10) / 2;
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final s in list)
                SizedBox(
                  width: w,
                  child: _SlotTile(
                    slot: s,
                    on: selected == s.id,
                    onTap: onSelect == null ? null : () => onSelect!(s),
                  ),
                ),
            ],
          );
        },
      ),
    ],
  );
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({required this.slot, required this.on, required this.onTap});
  final InterviewSlot slot;
  final bool on;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final h24 = slot.startMinutes ~/ 60;
    final m = slot.startMinutes % 60;
    final h = h24 % 12 == 0 ? 12 : h24 % 12;
    final clock = '$h:${m.toString().padLeft(2, '0')}';
    final span = DateFormat.jm().format(DateTime(2000, 1, 1, h24, m));
    final fg = on ? Colors.white : dsNavy;
    return Semantics(
      button: true,
      selected: on,
      label: span,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: on
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.teal, dsSky],
                )
              : null,
          color: on ? null : const Color(0xBFFFFFFF),
          border: Border.all(
            color: on ? Colors.transparent : dsNavy.withValues(alpha: 0.16),
            width: 1.5,
          ),
          boxShadow: on
              ? [
                  BoxShadow(
                    color: AppColors.teal.withValues(alpha: 0.4),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            key: Key('interview_slot_${slot.id}'),
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          clock,
                          style: authSerif(24, 1.1).copyWith(color: fg),
                        ),
                        Text(
                          l10n.interviewSlotMeta(
                            h24 < 12 ? 'AM' : 'PM',
                            slot.minutes,
                          ),
                          style: AppText.body.copyWith(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: on ? Colors.white : dsMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: AnimatedScale(
                      scale: on ? 1 : 0,
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutBack,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 13,
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
      color: const Color(0x80FFFFFF),
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
            color: Color(0xFFE2EEEC),
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
                        color: Color(0xFF0B5A53),
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
                            color: const Color(0xFF0B5A53),
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
        fillColor: const Color(0xCCFFFFFF),
        contentPadding: const EdgeInsets.all(14),
        hintStyle: AppText.body.copyWith(
          fontSize: 15,
          color: const Color(0xFF64748B),
        ),
        enabledBorder: border(dsNavy.withValues(alpha: 0.16), 1.5),
        disabledBorder: border(dsNavy.withValues(alpha: 0.1), 1.5),
        focusedBorder: border(dsNavy, 1.5),
      ),
    );
  }
}

/// "Request sent": frosted full-screen card with a popping tick, confetti and a ticket.
class InterviewSentOverlay extends StatefulWidget {
  const InterviewSentOverlay({
    required this.workerName,
    required this.kind,
    required this.when,
    required this.onView,
    super.key,
  });
  final String workerName;

  /// "interview" or "trial", lower case, for the sentence.
  final String kind;
  final String when;
  final VoidCallback onView;

  @override
  State<InterviewSentOverlay> createState() => _SentState();
}

class _SentState extends State<InterviewSentOverlay>
    with SingleTickerProviderStateMixin {
  static const _ms = 2000.0;
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  );

  @override
  void initState() {
    super.initState();
    if (!WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations) {
      _c.forward();
    } else {
      _c.value = 1;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final kindName = widget.kind;
    return Semantics(
      liveRegion: true,
      container: true,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: ColoredBox(
            color: const Color(0xD1FAF8F5),
            child: Material(
              type: MaterialType.transparency,
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) {
                  final t = _c.value * _ms;
                  final pop = seg(t, 0, 700, Curves.easeOutBack);
                  final tick = seg(t, 400, 600, Curves.easeOut);
                  final rise = seg(t, 250, 500, Curves.easeOut);
                  final ticket = seg(t, 500, 700, Curves.easeOutCubic);
                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 140,
                            height: 130,
                            child: Stack(
                              alignment: Alignment.center,
                              clipBehavior: Clip.none,
                              children: [
                                for (final (i, c) in const [
                                  (Color(0xFFF59E0B), -70.0, 0.5),
                                  (Color(0xFF38BDF8), -30.0, 0.6),
                                  (Color(0xFF0F766E), 20.0, 0.55),
                                  (Color(0xFFE11D48), 70.0, 0.65),
                                ].indexed)
                                  _Confetti(
                                    t: t,
                                    color: c.$1,
                                    dx: c.$2,
                                    startMs: c.$3 * 1000 + i,
                                  ),
                                Transform.scale(
                                  scale: pop,
                                  child: Container(
                                    width: 104,
                                    height: 104,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [AppColors.teal, dsSky],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.teal.withValues(
                                            alpha: 0.45,
                                          ),
                                          blurRadius: 36,
                                          offset: const Offset(0, 18),
                                        ),
                                      ],
                                    ),
                                    child: CustomPaint(
                                      painter: _TickPainter(tick),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Opacity(
                            opacity: rise,
                            child: Transform.translate(
                              offset: Offset(0, 16 * (1 - rise)),
                              child: Column(
                                children: [
                                  const SizedBox(height: 24),
                                  Text(
                                    l10n.interviewSentTitle,
                                    textAlign: TextAlign.center,
                                    style: authSerif(30, 1.15),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    l10n.interviewSentBody(
                                      widget.workerName,
                                      kindName,
                                      widget.when,
                                    ),
                                    textAlign: TextAlign.center,
                                    style: AppText.body.copyWith(
                                      fontSize: 16,
                                      height: 1.5,
                                      color: dsText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Opacity(
                            opacity: ticket,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - ticket)),
                              child: _Ticket(
                                rows: [
                                  (l10n.interviewTkWorker, widget.workerName),
                                  (
                                    l10n.interviewTypeRow,
                                    '${kindName[0].toUpperCase()}${kindName.substring(1)}',
                                  ),
                                  (l10n.interviewWhenRow, widget.when),
                                  (
                                    l10n.interviewTkStatus,
                                    l10n.interviewTkWaiting,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          AuthCta(
                            key: const Key('interview_view_request_btn'),
                            clock: DiscoverClock.of(context),
                            label: l10n.interviewViewRequest,
                            loadingLabel: l10n.interviewViewRequest,
                            loading: false,
                            breathe: true,
                            showArrow: false,
                            radius: 18,
                            height: 58,
                            onPressed: widget.onView,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Ticket extends StatelessWidget {
  const _Ticket({required this.rows});
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(top: 20),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: dsNavy.withValues(alpha: 0.3)),
      boxShadow: [
        BoxShadow(
          color: dsNavy.withValues(alpha: 0.12),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      children: [
        for (final (i, r) in rows.indexed)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  r.$1,
                  style: AppText.body.copyWith(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: dsMuted,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    r.$2,
                    textAlign: TextAlign.right,
                    style: AppText.body.copyWith(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: i == rows.length - 1
                          ? const Color(0xFFB45309)
                          : dsNavy,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

class _Confetti extends StatelessWidget {
  const _Confetti({
    required this.t,
    required this.color,
    required this.dx,
    required this.startMs,
  });
  final double t;
  final Color color;
  final double dx;
  final double startMs;

  @override
  Widget build(BuildContext context) {
    final k = ((t - startMs) / 1400).clamp(0.0, 1.0);
    if (k <= 0) return const SizedBox.shrink();
    return Transform.translate(
      offset: Offset(dx * k, -90 * k),
      child: Opacity(
        opacity: k < 0.2 ? k / 0.2 : 1 - (k - 0.2) / 0.8,
        child: Transform.scale(
          scale: 0.4 + 0.6 * k,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
        ),
      ),
    );
  }
}

/// The white tick, drawn stroke by stroke as [progress] goes 0 to 1.
class _TickPainter extends CustomPainter {
  _TickPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final a = c + const Offset(-14, 1);
    final b = c + const Offset(-4, 12);
    final d = c + const Offset(16, -11);
    final first = (b - a).distance;
    final total = first + (d - b).distance;
    final len = total * progress;
    final path = Path()..moveTo(a.dx, a.dy);
    if (len <= first) {
      final p = a + (b - a) * (len / first);
      path.lineTo(p.dx, p.dy);
    } else {
      path.lineTo(b.dx, b.dy);
      final p = b + (d - b) * math.min(1, (len - first) / (total - first));
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_TickPainter old) => old.progress != progress;
}
