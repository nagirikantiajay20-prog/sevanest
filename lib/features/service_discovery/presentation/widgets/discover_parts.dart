import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart'
    show authSerif;
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';

/// Small building blocks shared by the glass "Find a worker" steps 4-6 and Review.

/// Serif section label (`.lab` in the design).
class DiscoverLabel extends StatelessWidget {
  const DiscoverLabel(this.text, {this.size = 19, super.key});
  final String text;
  final double size;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Semantics(
      header: true,
      child: Text(text, style: authSerif(size, 1.2)),
    ),
  );
}

/// A sweeping light band, [widthFactor] of the parent wide, looping every [periodMs].
class DiscoverSheen extends StatelessWidget {
  const DiscoverSheen({
    this.widthFactor = 0.34,
    this.periodMs = 3000,
    this.alpha = 0.7,
    super.key,
  });
  final double widthFactor;
  final double periodMs;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    final clock = DiscoverClock.of(context);
    return Positioned.fill(
      child: IgnorePointer(
        child: ValueListenableBuilder<double>(
          valueListenable: clock,
          builder: (_, t, _) => LayoutBuilder(
            builder: (_, box) {
              final w = box.maxWidth * widthFactor;
              final k = Curves.easeInOut.transform((t / periodMs) % 1);
              return Stack(
                children: [
                  Positioned(
                    left: w * (-1.2 + 3.8 * k),
                    top: 0,
                    bottom: 0,
                    width: w,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0),
                            Colors.white.withValues(alpha: alpha),
                            Colors.white.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Loading placeholder with a light band sliding across (`.sk`).
class DiscoverShimmer extends StatelessWidget {
  const DiscoverShimmer({
    this.width,
    this.height = 12,
    this.radius = 10,
    this.light = false,
    super.key,
  });

  /// White band for dark surfaces (the guidance card).
  final bool light;
  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<double>(
    valueListenable: DiscoverClock.of(context),
    builder: (_, t, _) {
      final p = (t / 1400) % 1;
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            colors: [
              (light ? Colors.white : dsNavy).withValues(
                alpha: light ? 0.12 : 0.07,
              ),
              (light ? Colors.white : dsNavy).withValues(
                alpha: light ? 0.3 : 0.15,
              ),
              (light ? Colors.white : dsNavy).withValues(
                alpha: light ? 0.12 : 0.07,
              ),
            ],
            transform: _Slide(-1 + 2 * p),
          ),
        ),
      );
    },
  );
}

class _Slide extends GradientTransform {
  const _Slide(this.k);
  final double k;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * k, 0, 0);
}

/// A frosted tile that lifts and gets a coloured border when [selected] (window cards, date
/// shortcuts). Whole tile is the tap target.
class GlassChoice extends StatelessWidget {
  const GlassChoice({
    required this.selected,
    required this.onTap,
    required this.child,
    this.tapKey,
    this.radius = 22,
    this.minHeight = 76,
    this.selectedColor = AppColors.teal,
    this.selectedWash = const [Color(0xF2E2EEEC), Color(0xB8FFFFFF)],
    this.padding = const EdgeInsets.all(12),
    super.key,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final Key? tapKey;
  final double radius;
  final double minHeight;
  final Color selectedColor;
  final List<Color> selectedWash;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      transform: Matrix4.translationValues(0, selected ? -3 : 0, 0),
      child: DiscoverGlass(
        radius: radius,
        borderWidth: 2,
        borderColor: selected ? selectedColor : const Color(0xE6FFFFFF),
        gradient: selected
            ? LinearGradient(
                begin: const Alignment(-0.6, -1),
                end: const Alignment(0.6, 1),
                colors: selectedWash,
              )
            : null,
        child: Stack(
          children: [
            if (selected) const DiscoverSheen(),
            Material(
              type: MaterialType.transparency,
              child: InkWell(
                key: tapKey,
                onTap: onTap,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: minHeight),
                  child: Padding(padding: padding, child: child),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Inline red message line used under fields (the "couldn't load" card is [StepErrorCard]).
class DiscoverInlineError extends StatelessWidget {
  const DiscoverInlineError(this.message, {this.fieldKey, super.key});
  final String message;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.only(top: 1),
        child: Icon(Icons.error_outline, size: 18, color: AppColors.danger),
      ),
      const SizedBox(width: 6),
      Expanded(
        child: Semantics(
          liveRegion: true,
          child: Text(
            message,
            key: fieldKey,
            style: AppText.body.copyWith(
              fontSize: 14.5,
              height: 1.4,
              color: const Color(0xFFB91C1C),
            ),
          ),
        ),
      ),
    ],
  );
}

/// Amber notice (`.warn`): low budget, day outside the chosen days.
class DiscoverWarn extends StatelessWidget {
  const DiscoverWarn({
    required this.child,
    this.radius = 18,
    this.padding,
    super.key,
  });
  final Widget child;
  final double radius;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 450),
    curve: Curves.easeOutCubic,
    builder: (_, v, c) => Opacity(
      opacity: v,
      child: Transform.translate(offset: Offset(0, 12 * (1 - v)), child: c),
    ),
    child: Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.warnBg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: AppColors.warn.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: child,
    ),
  );
}

/// Scale pop (0.6 -> 1.14 -> 1) the moment [active] turns on; steady on first build.
class DiscoverPop extends StatefulWidget {
  const DiscoverPop({required this.active, required this.child, super.key});
  final bool active;
  final Widget child;

  @override
  State<DiscoverPop> createState() => _DiscoverPopState();
}

class _DiscoverPopState extends State<DiscoverPop>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    value: 1,
  );

  @override
  void didUpdateWidget(DiscoverPop old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    child: widget.child,
    builder: (_, c) {
      final v = _c.value;
      return Transform.scale(
        scale: v < 0.6
            ? 0.6 + 0.54 * (v / 0.6)
            : 1.14 - 0.14 * ((v - 0.6) / 0.4),
        child: c,
      );
    },
  );
}

/// Horizontal shake (+-5 px) that plays when [on] turns true.
class DiscoverShake extends StatelessWidget {
  const DiscoverShake({required this.on, required this.child, super.key});
  final bool on;
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    key: ValueKey(on),
    tween: Tween(begin: on ? 0 : 1, end: 1),
    duration: const Duration(milliseconds: 350),
    builder: (_, v, c) => Transform.translate(
      offset: Offset(on ? -5 * math.sin(2 * math.pi * v) : 0, 0),
      child: c,
    ),
    child: child,
  );
}

/// Round-cornered chip button: hours, day presets (`.pill` / `.hr`).
class DiscoverPill extends StatelessWidget {
  const DiscoverPill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.accent = dsNavy,
    this.selectedFill = const Color(0xFFE4E9F2),
    this.weight = FontWeight.w600,
    super.key,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color accent;
  final Color selectedFill;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: DiscoverPop(
      active: selected,
      child: Material(
        color: selected ? selectedFill : Colors.white.withValues(alpha: 0.72),
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? accent : AppColors.slate300,
            width: 1.5,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                widthFactor: 1,
                child: Text(
                  label,
                  style: AppText.body.copyWith(
                    fontSize: 14,
                    fontWeight: weight,
                    color: selected && accent != dsNavy ? accent : dsNavy,
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
