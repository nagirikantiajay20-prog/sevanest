import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/features/service_discovery/domain/timing.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/schedule_format.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_parts.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// Glass pieces of the Timing step (design: Find a Worker 4).

const windowIcons = {
  TimeWindow.earlyMorning: Icons.wb_twilight,
  TimeWindow.morning: Icons.wb_sunny_outlined,
  TimeWindow.afternoon: Icons.light_mode_outlined,
  TimeWindow.evening: Icons.wb_twilight,
  TimeWindow.night: Icons.nightlight_outlined,
  TimeWindow.flexible: Icons.schedule,
};

LinearGradient _sky(List<Color> c, {bool horizontal = false}) => LinearGradient(
  begin: horizontal ? Alignment.centerLeft : Alignment.topCenter,
  end: horizontal ? Alignment.centerRight : Alignment.bottomCenter,
  colors: c,
  stops: c.length == 3 ? const [0, 0.6, 1] : null,
);

final _scenes = <TimeWindow?, LinearGradient>{
  null: _sky(const [AppColors.skyBAE6FD, AppColors.warnBg]),
  TimeWindow.earlyMorning: _sky(const [
    AppColors.blue312E81,
    AppColors.roseF472B6,
    AppColors.orangeFDBA74,
  ]),
  TimeWindow.morning: _sky(const [
    AppColors.sky400,
    AppColors.skyBAE6FD,
    AppColors.warnBg,
  ]),
  TimeWindow.afternoon: _sky(const [
    AppColors.cyan0EA5E9,
    AppColors.cyan7DD3FC,
    AppColors.warnLine,
  ]),
  TimeWindow.evening: _sky(const [
    AppColors.indigo4C1D95,
    AppColors.orangeF97316,
    AppColors.orangeFDBA74,
  ]),
  TimeWindow.night: _sky(const [
    AppColors.blue020617,
    AppColors.blue1E1B4B,
    AppColors.blue312E81,
  ]),
  TimeWindow.flexible: _sky(const [
    AppColors.orangeFDBA74,
    AppColors.cyan7DD3FC,
    AppColors.indigoC4B5FD,
    AppColors.blue1E1B4B,
  ], horizontal: true),
};

/// The animated sky: sun or moon glides along a dotted arc to the chosen window, clouds drift,
/// stars twinkle at night and early morning, a house sits on the hills.
class SkyScene extends StatelessWidget {
  const SkyScene({
    required this.window,
    required this.slot,
    required this.label,
    super.key,
  });
  final TimeWindow? window;
  final WindowSlot? slot;
  final String label;

  static const _stars = [
    (0.14, 0.18, 0.0),
    (0.30, 0.42, 0.6),
    (0.52, 0.14, 1.1),
    (0.70, 0.34, 0.3),
    (0.88, 0.16, 0.9),
  ];

  @override
  Widget build(BuildContext context) {
    final w = window;
    final night = w == TimeWindow.night;
    final flexible = w == TimeWindow.flexible;
    final starsOn = night || w == TimeWindow.earlyMorning;
    final early = w == TimeWindow.earlyMorning || w == TimeWindow.evening;
    var mid = 600.0;
    if (slot != null && !flexible) {
      mid = night ? 1470 : (slot!.start + slot!.end) / 2;
    }
    final p = night
        ? ((mid - 1200) / 900).clamp(0.0, 1.0)
        : ((mid - 300) / 900).clamp(0.0, 1.0);
    final bx = 30 + p * 298;
    final by = night
        ? 96 - math.sin(math.pi * p) * 56
        : 100 - math.sin(math.pi * p) * 80;
    final clock = DiscoverClock.of(context);
    const curve = Cubic(0.34, 1.2, 0.64, 1);
    const dur = Duration(milliseconds: 800);

    return Semantics(
      image: true,
      label: label,
      child: Container(
        height: 132,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.surface, width: 2),
          boxShadow: [
            BoxShadow(
              color: dsNavy.withValues(alpha: 0.24),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (_, box) {
            final width = box.maxWidth;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              decoration: BoxDecoration(gradient: _scenes[w] ?? _scenes[null]),
              child: ValueListenableBuilder<double>(
                valueListenable: clock,
                builder: (_, t, _) => Stack(
                  children: [
                    Positioned.fill(child: CustomPaint(painter: _ArcPainter())),
                    for (final (x, y, delay) in _stars)
                      Positioned(
                        left: width * x,
                        top: 132 * y,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 600),
                          opacity: starsOn ? 1 : 0,
                          child: Transform.scale(
                            scale:
                                0.75 +
                                0.25 *
                                    math.cos(2 * math.pi * (t / 2400 - delay)),
                            child: Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.surface,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.surface,
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    for (final (top, period, offset, scale) in const [
                      (22.0, 38000.0, 0.0, 1.0),
                      (58.0, 52000.0, 20000.0, 0.7),
                    ])
                      Positioned(
                        left:
                            -70 + (width + 70) * (((t + offset) / period) % 1),
                        top: top,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 500),
                          opacity: night ? 0.25 : 0.9,
                          child: Transform.scale(
                            scale: scale,
                            child: const _Cloud(),
                          ),
                        ),
                      ),
                    AnimatedPositioned(
                      duration: dur,
                      curve: curve,
                      left: width * bx / 358 - 17,
                      top: by - 17,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: night
                              ? const RadialGradient(
                                  center: Alignment(0.3, -0.2),
                                  colors: [
                                    AppColors.fieldBg,
                                    AppColors.fieldBg,
                                    AppColors.slate300,
                                    AppColors.slate300,
                                  ],
                                  stops: [0, 0.55, 0.56, 1],
                                )
                              : RadialGradient(
                                  center: const Alignment(-0.3, -0.3),
                                  colors: early
                                      ? const [
                                          AppColors.orangeFFE4B5,
                                          AppColors.orangeFB923C,
                                        ]
                                      : const [
                                          AppColors.amberFFF7CC,
                                          AppColors.amberFDE047,
                                        ],
                                ),
                          boxShadow: night
                              ? [
                                  BoxShadow(
                                    color: AppColors.surface.withValues(
                                      alpha: 0.8,
                                    ),
                                    blurRadius: 22,
                                  ),
                                ]
                              : [
                                  const BoxShadow(
                                    color: AppColors.amberFFD666A95,
                                    blurRadius: 26,
                                  ),
                                  const BoxShadow(
                                    color: AppColors.amberFFD666A25,
                                    spreadRadius: 8,
                                  ),
                                ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 60,
                      child: CustomPaint(painter: _HillsPainter()),
                    ),
                    Positioned(
                      left: 10,
                      top: 10,
                      right: 10,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: DiscoverGlass(
                          radius: 20,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.body.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: dsNavy,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Cloud extends StatelessWidget {
  const _Cloud();

  Widget _pill(double l, double t, double w, double h, double a) => Positioned(
    left: l,
    top: t,
    child: Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: a),
        borderRadius: BorderRadius.circular(999),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 64,
    height: 20,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        _pill(0, 0, 64, 20, 0.75),
        _pill(20, -6, 60, 16, 0.75),
        _pill(-12, 6, 56, 12, 0.6),
      ],
    ),
  );
}

class _ArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 358;
    final path = Path()
      ..moveTo(22 * sx, 112)
      ..quadraticBezierTo(179 * sx, -34, 336 * sx, 112);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = AppColors.surface.withValues(alpha: 0.7);
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 11) {
        canvas.drawPath(m.extractPath(d, d + 3), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) => false;
}

class _HillsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 358;
    final sy = size.height / 60;
    canvas.save();
    canvas.scale(sx, sy);
    canvas.drawPath(
      Path()
        ..moveTo(0, 34)
        ..quadraticBezierTo(60, 6, 130, 28)
        ..quadraticBezierTo(200, 50, 260, 24)
        ..quadraticBezierTo(320, -2, 358, 30)
        ..lineTo(358, 60)
        ..lineTo(0, 60)
        ..close(),
      Paint()..color = AppColors.teal0F766EA55,
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, 46)
        ..quadraticBezierTo(70, 24, 150, 42)
        ..quadraticBezierTo(230, 60, 300, 40)
        ..quadraticBezierTo(370, 20, 358, 44)
        ..lineTo(358, 60)
        ..lineTo(0, 60)
        ..close(),
      Paint()..color = AppColors.cyan0F3942A85,
    );
    canvas.restore();
    // The house keeps its own proportions.
    canvas.save();
    canvas.translate(286 * sx, 20 * sy);
    canvas.drawPath(
      Path()
        ..moveTo(0, 18)
        ..lineTo(14, 6)
        ..lineTo(28, 18)
        ..lineTo(28, 32)
        ..lineTo(0, 32)
        ..close(),
      Paint()..color = dsNavy,
    );
    final lit = Paint()..color = AppColors.warnLine;
    canvas.drawRect(const Rect.fromLTWH(11, 20, 6, 12), lit);
    canvas.drawRect(const Rect.fromLTWH(19, 16, 5, 5), lit);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HillsPainter old) => false;
}

/// One time-of-day card: icon well, name, hours; the icon turns while selected.
class WindowCard extends StatelessWidget {
  const WindowCard({
    required this.window,
    required this.caption,
    required this.selected,
    required this.onTap,
    super.key,
  });
  final TimeWindow window;
  final String caption;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final clock = DiscoverClock.of(context);
    final night = window == TimeWindow.night;
    Widget icon = Icon(
      windowIcons[window],
      size: 24,
      color: selected ? AppColors.surface : AppColors.slate400,
    );
    if (selected) {
      icon = ValueListenableBuilder<double>(
        valueListenable: clock,
        child: icon,
        builder: (_, t, c) => night
            ? Transform.scale(
                scale: 0.96 + 0.04 * math.cos(2 * math.pi * t / 2000),
                child: c,
              )
            : Transform.rotate(
                angle: 2 * math.pi * ((t / 10000) % 1),
                child: c,
              ),
      );
    }
    return GlassChoice(
      tapKey: Key('discover_window_${window.name}'),
      selected: selected,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: selected ? null : AppColors.grayEEF2F6,
              gradient: selected
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.teal, dsSky],
                    )
                  : null,
            ),
            alignment: Alignment.center,
            child: icon,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  windowName(l10n, window),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    color: dsNavy,
                  ),
                ),
                Text(
                  caption,
                  style: AppText.body.copyWith(fontSize: 13, color: dsMuted),
                ),
              ],
            ),
          ),
          if (selected)
            const DiscoverPop(
              active: true,
              child: Icon(Icons.check_rounded, size: 20, color: AppColors.teal),
            ),
        ],
      ),
    );
  }
}

/// Start / End time button (58 px, glass); red border when the pair is invalid.
class TimeField extends StatelessWidget {
  const TimeField({
    required this.fieldKey,
    required this.label,
    required this.minutes,
    required this.error,
    required this.onTap,
    super.key,
  });
  final Key fieldKey;
  final String label;
  final int? minutes;
  final bool error;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppText.body.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: dsMuted,
          ),
        ),
        const SizedBox(height: 6),
        DiscoverGlass(
          radius: 18,
          borderWidth: 2,
          borderColor: error ? AppColors.danger : AppColors.whiteA90xE6,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              key: fieldKey,
              onTap: onTap,
              child: SizedBox(
                height: 58,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 22,
                        color: error ? AppColors.danger : AppColors.teal,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          minutes == null
                              ? l10n.timingPickTime
                              : formatTime(minutes!),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.body.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: minutes == null
                                ? AppColors.slate400
                                : dsNavy,
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
    );
  }
}

/// Date button of the Hourly layout.
class DateField extends StatelessWidget {
  const DateField({
    required this.text,
    required this.filled,
    required this.onTap,
    super.key,
  });
  final String text;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => DiscoverGlass(
    radius: 18,
    child: Material(
      type: MaterialType.transparency,
      child: InkWell(
        key: const Key('discover_date_btn'),
        onTap: onTap,
        child: SizedBox(
          height: 58,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 22,
                  color: AppColors.teal,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    text,
                    style: AppText.body.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: filled ? dsNavy : AppColors.slate400,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: AppColors.slate400,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Every day / Weekdays / Weekends presets and the seven day tiles.
class DaysPicker extends StatelessWidget {
  const DaysPicker({
    required this.days,
    required this.onChanged,
    required this.locale,
    super.key,
  });
  final Set<int> days;
  final ValueChanged<Set<int>> onChanged;
  final String locale;

  static const _all = {1, 2, 3, 4, 5, 6, 7};
  static const _weekdays = {1, 2, 3, 4, 5};
  static const _weekends = {6, 7};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    bool same(Set<int> a) => a.length == days.length && a.containsAll(days);
    Widget preset(Key k, String label, Set<int> set) => DiscoverPill(
      key: k,
      label: label,
      selected: same(set),
      onTap: () => onChanged({...set}),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            preset(const Key('discover_days_every'), l10n.daysEvery, _all),
            preset(
              const Key('discover_days_weekdays'),
              l10n.daysWeekdays,
              _weekdays,
            ),
            preset(
              const Key('discover_days_weekends'),
              l10n.daysWeekends,
              _weekends,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (var d = 1; d <= 7; d++) ...[
              if (d > 1) const SizedBox(width: 6),
              Expanded(
                child: _DayTile(
                  key: Key('discover_day_$d'),
                  letter: dayShort(d, locale).substring(0, 1),
                  full: dayShort(d, locale),
                  on: days.contains(d),
                  onTap: () => onChanged(
                    days.contains(d) ? ({...days}..remove(d)) : {...days, d},
                  ),
                ),
              ),
            ],
          ],
        ),
        if (days.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              l10n.timingDaysSelected(days.length),
              key: const Key('discover_days_count'),
              style: AppText.body.copyWith(fontSize: 14, color: dsMuted),
            ),
          ),
      ],
    );
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({
    required this.letter,
    required this.full,
    required this.on,
    required this.onTap,
    super.key,
  });
  final String letter;
  final String full;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: on,
    button: true,
    label: full,
    excludeSemantics: true,
    child: DiscoverPop(
      active: on,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: on
              ? [
                  BoxShadow(
                    color: dsNavy.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: on ? dsNavy : AppColors.surface.withValues(alpha: 0.75),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: on ? dsNavy : AppColors.slate300,
              width: 1.5,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: SizedBox(
              height: 52,
              child: Center(
                child: Text(
                  letter,
                  style: AppText.body.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: on ? AppColors.surface : dsNavy,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Loading placeholder: a label bar, the sky and six card outlines.
class TimingSkeleton extends StatelessWidget {
  const TimingSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    label: AppLocalizations.of(context).loading,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DiscoverShimmer(width: 150, height: 18),
        const SizedBox(height: 14),
        const DiscoverShimmer(height: 58, radius: 20),
        const SizedBox(height: 14),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.2,
          children: [
            for (var i = 0; i < 6; i++)
              const DiscoverGlass(
                radius: 22,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      DiscoverShimmer(width: 40, height: 40, radius: 14),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DiscoverShimmer(width: 70, height: 14),
                            SizedBox(height: 8),
                            DiscoverShimmer(width: 50, height: 10),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    ),
  );
}
