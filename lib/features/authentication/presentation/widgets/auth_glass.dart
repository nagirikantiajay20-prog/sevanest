import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/motion.dart';

/// Look shared by the glass-style auth screens (login, OTP): drifting room photo, frosted
/// surfaces and the navy call-to-action. All motion is a function of one clock (see motion.dart).

const authNavy = AppColors.navyDeep;

/// Heading face (Source Serif) in the screen's navy.
TextStyle authSerif(double size, double height) => TextStyle(
  fontFamily: AppFonts.heading,
  fontSize: size,
  height: height,
  fontWeight: FontWeight.w700,
  color: authNavy,
);

/// A soft coloured glow drifting behind the content.
class AuthGlow {
  const AuthGlow(
    this.color,
    this.size, {
    required this.top,
    this.left,
    this.right,
    this.delayMs = 0,
  });
  final Color color;
  final double size;
  final double top;
  final double? left;
  final double? right;
  final double delayMs;
}

/// Where the photo is focused, the washes over it, and how its glows move.
class RoomBackdropStyle {
  const RoomBackdropStyle({
    required this.alignment,
    required this.washes,
    required this.glows,
    this.zoomFrom = 1.04,
    this.driftMs = 20000,
    this.drift = const Offset(-6, -3),
    this.glowTravel = const Offset(34, 44),
    this.glowZoom = 0.14,
    this.glowMs = 13000,
  });
  final Alignment alignment;
  final List<Gradient> washes;
  final List<AuthGlow> glows;
  final double zoomFrom;
  final double driftMs;
  final Offset drift;
  final Offset glowTravel;
  final double glowZoom;
  final double glowMs;
}

/// Room photo (slowly drifting) under [RoomBackdropStyle.washes], plus drifting colour glows.
class RoomBackdrop extends StatelessWidget {
  const RoomBackdrop({required this.clock, required this.style, super.key});
  final ValueListenable<double> clock;
  final RoomBackdropStyle style;

  @override
  Widget build(BuildContext context) {
    Widget glow(AuthGlow g) => ValueListenableBuilder<double>(
      valueListenable: clock,
      builder: (context, t, _) {
        final k = Curves.easeInOut.transform(
          pingPong(t + g.delayMs, style.glowMs),
        );
        final big =
            g.size *
            1.5; // the design blurs a disc; a wider soft gradient matches it
        final pad = g.size * 0.25;
        return Positioned(
          top: g.top - pad,
          left: g.left == null ? null : g.left! - pad,
          right: g.right == null ? null : g.right! - pad,
          width: big,
          height: big,
          child: IgnorePointer(
            child: Transform.translate(
              offset: style.glowTravel * k,
              child: Transform.scale(
                scale: 1 + style.glowZoom * k,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [g.color, g.color.withValues(alpha: 0)],
                      stops: const [0.15, 1],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    return ExcludeSemantics(
      child: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.ivory, Colors.white],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: ClipRect(
              child: ValueListenableBuilder<double>(
                valueListenable: clock,
                builder: (context, t, child) {
                  final k = Curves.easeInOut.transform(
                    pingPong(t, style.driftMs),
                  );
                  return Transform.translate(
                    offset: style.drift * k,
                    child: Transform.scale(
                      scale: style.zoomFrom + 0.06 * k,
                      child: child,
                    ),
                  );
                },
                child: Image.asset(
                  'assets/login/room.jpg',
                  fit: BoxFit.cover,
                  alignment: style.alignment,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
          for (final wash in style.washes)
            Positioned.fill(
              child: DecoratedBox(decoration: BoxDecoration(gradient: wash)),
            ),
          for (final g in style.glows) glow(g),
        ],
      ),
    );
  }
}

/// Frosted-glass surface: blurs what is behind it under a tint, with an optional outer shadow.
class AuthGlass extends StatelessWidget {
  const AuthGlass({
    required this.radius,
    required this.blur,
    required this.child,
    this.tint,
    this.gradient,
    this.border,
    this.shadow,
    super.key,
  });
  final BorderRadius radius;
  final double blur;
  final Color? tint;
  final Gradient? gradient;
  final BoxBorder? border;
  final List<BoxShadow>? shadow;
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(borderRadius: radius, boxShadow: shadow),
    child: ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tint,
            gradient: gradient,
            border: border,
            borderRadius: radius,
          ),
          child: child,
        ),
      ),
    ),
  );
}

/// The navy pill under a form: gleams while it can be pressed, optionally breathes, shows a
/// spinner while [loading] and turns teal with a tick once [done].
class AuthCta extends StatelessWidget {
  const AuthCta({
    required this.clock,
    required this.label,
    required this.loadingLabel,
    required this.loading,
    required this.onPressed,
    this.done = false,
    this.breathe = false,
    this.showArrow = true,
    this.radius = 16,
    super.key,
  });

  final ValueListenable<double> clock;
  final String label;
  final String loadingLabel;
  final bool loading;
  final VoidCallback? onPressed;

  /// Finished successfully: teal, tick icon, not pressable.
  final bool done;
  final bool breathe;

  /// Arrow after the label (off for a plain "Save").
  final bool showArrow;
  final double radius;

  static const _idle = Color(0xFF8D9BB3);

  @override
  Widget build(BuildContext context) {
    final live =
        onPressed != null && !loading; // pressable: gleam (and breathe)
    final lit = live || loading || done; // coloured, with its shadow
    final shape = BorderRadius.circular(radius);
    return ValueListenableBuilder<double>(
      valueListenable: clock,
      builder: (context, t, _) {
        final k = live && breathe
            ? Curves.easeInOut.transform(pingPong(t, 2400))
            : 0.0;
        final sheen = Curves.easeInOut.transform((t / 3000) % 1);
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: shape,
            boxShadow: lit
                ? [
                    BoxShadow(
                      color: authNavy.withValues(alpha: 0.32 + 0.08 * k),
                      blurRadius: 24 + 6 * k,
                      offset: Offset(0, 12 + 2 * k),
                    ),
                    if (breathe)
                      BoxShadow(
                        color: authNavy.withValues(alpha: 0.28 * (1 - k)),
                        spreadRadius: 9 * k,
                      ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: shape,
            child: FilledButton(
              onPressed: loading || done ? null : onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: authNavy,
                disabledBackgroundColor: done
                    ? AppColors.teal
                    : loading
                    ? authNavy
                    : _idle,
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white,
                minimumSize: const Size.fromHeight(54),
                padding: EdgeInsets.zero,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: shape),
                textStyle: AppText.body.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (live)
                    Positioned.fill(
                      child: LayoutBuilder(
                        builder: (context, box) {
                          final w = box.maxWidth * 0.4;
                          return Stack(
                            children: [
                              Positioned(
                                left: w * (-1.2 + 3.8 * sheen),
                                top: 0,
                                bottom: 0,
                                width: w,
                                child: const DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0x00FFFFFF),
                                        Color(0x66FFFFFF),
                                        Color(0x00FFFFFF),
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (loading) ...[
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.6,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      if (done) ...[
                        const Icon(Icons.check_rounded, size: 20),
                        const SizedBox(width: 10),
                      ],
                      Text(loading ? loadingLabel : label),
                      if (showArrow && !loading && !done) ...[
                        const SizedBox(width: 10),
                        const Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
