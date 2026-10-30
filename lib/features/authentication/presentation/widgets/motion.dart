import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;

/// Shared by the splash and login screens, whose animations are all pure functions of one clock
/// (milliseconds since the screen appeared).

/// Ease used by every "rise" / "pop-in" entrance.
const riseCurve = Cubic(.2, .7, .2, 1);

/// Eased 0..1 progress of a segment that starts at [delay] and lasts [dur] (ms).
double seg(double t, double delay, double dur, Curve c) =>
    c.transform(((t - delay) / dur).clamp(0.0, 1.0));

/// Position (0..1) in a loop of [periodMs] that runs forward then back (CSS `alternate`).
double pingPong(double t, double periodMs) {
  final p = (t / periodMs) % 1;
  return p < 0.5 ? p * 2 : 2 - p * 2;
}

/// Fade + rise-in that starts at [start] ms on [clock].
class Rise extends StatelessWidget {
  const Rise({
    required this.clock,
    required this.start,
    required this.child,
    this.duration = 500,
    super.key,
  });
  final ValueListenable<double> clock;
  final double start;
  final double duration;
  final Widget child;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<double>(
    valueListenable: clock,
    child: child,
    builder: (context, t, c) {
      final p = seg(t, start, duration, riseCurve);
      return Opacity(
        opacity: p,
        child: Transform.translate(offset: Offset(0, 16 * (1 - p)), child: c),
      );
    },
  );
}

/// Milliseconds since a screen appeared, ticking every frame. With [motion] off (tests) or the
/// system's "remove animations" on, it stays at a late fixed time, so every animation shows its
/// finished state and nothing keeps scheduling frames.
class ScreenClock extends ValueNotifier<double> {
  ScreenClock(TickerProvider vsync, {required bool motion})
    : super(_animate(motion) ? 0 : stillMs) {
    if (_animate(motion)) {
      _ticker = vsync.createTicker((d) => value = d.inMicroseconds / 1000)
        ..start();
    }
  }

  static const stillMs = 100000.0;
  Ticker? _ticker;

  /// False when the clock is frozen (tests, reduced motion).
  bool get animating => _ticker != null;

  static bool _animate(bool motion) =>
      motion &&
      !WidgetsBinding
          .instance
          .platformDispatcher
          .accessibilityFeatures
          .disableAnimations;

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }
}
