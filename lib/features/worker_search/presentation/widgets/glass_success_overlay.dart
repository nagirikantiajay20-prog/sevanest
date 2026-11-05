import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart'
    show AuthCta, authSerif;
import 'package:sevanest_customer/features/authentication/presentation/widgets/motion.dart'
    show seg;
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';

/// Success state of the glass flows ("Request sent", "Worker confirmed"): a frosted full-screen
/// card with a popping tick, confetti and a ticket.
class GlassSuccessOverlay extends StatefulWidget {
  const GlassSuccessOverlay({
    required this.title,
    required this.body,
    required this.rows,
    required this.ctaKey,
    required this.ctaLabel,
    required this.onPressed,
    this.secondary,
    super.key,
  });
  final String title;
  final String body;

  /// Ticket lines; the last one is the status and is drawn amber.
  final List<(String, String)> rows;
  final Key ctaKey;
  final String ctaLabel;
  final VoidCallback onPressed;

  /// Optional second action under the main button (Payment: "View receipt").
  final Widget? secondary;

  @override
  State<GlassSuccessOverlay> createState() => _SentState();
}

class _SentState extends State<GlassSuccessOverlay>
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
    return Semantics(
      liveRegion: true,
      container: true,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: ColoredBox(
            color: AppColors.whiteFAF8F5A82,
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
                                  (AppColors.amber, -70.0, 0.5),
                                  (AppColors.sky400, -30.0, 0.6),
                                  (AppColors.teal, 20.0, 0.55),
                                  (AppColors.rose600, 70.0, 0.65),
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
                                    widget.title,
                                    textAlign: TextAlign.center,
                                    style: authSerif(30, 1.15),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    widget.body,
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
                          if (widget.rows.isNotEmpty)
                            Opacity(
                              opacity: ticket,
                              child: Transform.translate(
                                offset: Offset(0, 20 * (1 - ticket)),
                                child: _Ticket(rows: widget.rows),
                              ),
                            ),
                          const SizedBox(height: 28),
                          AuthCta(
                            key: widget.ctaKey,
                            clock: DiscoverClock.of(context),
                            label: widget.ctaLabel,
                            loadingLabel: widget.ctaLabel,
                            loading: false,
                            breathe: true,
                            showArrow: false,
                            radius: 18,
                            height: 58,
                            onPressed: widget.onPressed,
                          ),
                          if (widget.secondary != null) ...[
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: widget.secondary,
                            ),
                          ],
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
      color: AppColors.surface,
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
                      color: i == rows.length - 1 ? AppColors.warnIcon : dsNavy,
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
        ..color = AppColors.surface,
    );
  }

  @override
  bool shouldRepaint(_TickPainter old) => old.progress != progress;
}
