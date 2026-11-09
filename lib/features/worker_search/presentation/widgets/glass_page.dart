import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/features/authentication/presentation/screens/splash_screen.dart'
    show splashHoldProvider;
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/motion.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';

/// Shell of the worker-search screens (Results, Worker profile, Reviews): drifting room photo,
/// frosted top bar and the shared clock that drives every entrance animation below it.
class FindGlassPage extends ConsumerStatefulWidget {
  const FindGlassPage({
    required this.title,
    required this.body,
    this.onBack,
    this.backLabel = '',
    this.subtitle,
    this.trailing,
    this.headerBottom,
    this.bottom,
    this.overlay,
    this.backKey = const Key('app_back_btn'),
    super.key,
  });

  final String title;

  /// Null makes it a tab page: large left-aligned [title] with [subtitle], no back button.
  final VoidCallback? onBack;
  final String backLabel;
  final String? subtitle;
  final Key backKey;

  /// Right-hand slot of the top bar (44 px wide); empty keeps the title centred.
  final Widget? trailing;

  /// Extra row inside the frosted bar (Results: the requirement chips).
  final Widget? headerBottom;
  final Widget body;

  /// Frosted bar pinned under the body (profile: Shortlist + Request interview).
  final Widget? bottom;

  /// Covers the whole page, bars included (Request: the "sent" card).
  final Widget? overlay;

  @override
  ConsumerState<FindGlassPage> createState() => _FindGlassPageState();
}

class _FindGlassPageState extends ConsumerState<FindGlassPage>
    with SingleTickerProviderStateMixin {
  late final _clock = ScreenClock(
    this,
    motion: ref.read(splashHoldProvider) > Duration.zero,
  );

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return DiscoverClock(
      clock: _clock,
      child: Scaffold(
        backgroundColor: AppColors.ivory,
        body: Stack(
          children: [
            Positioned.fill(
              child: RoomBackdrop(clock: _clock, style: discoverBackdrop),
            ),
            Column(
              children: [
                AuthGlass(
                  radius: BorderRadius.zero,
                  blur: 26,
                  gradient: _barGradient,
                  border: const Border(
                    bottom: BorderSide(color: AppColors.whiteA90xE6),
                  ),
                  shadow: [
                    BoxShadow(
                      color: dsNavy.withValues(alpha: 0.1),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(12, top + 14, 12, 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.onBack == null)
                          _TabTitle(
                            title: widget.title,
                            subtitle: widget.subtitle,
                          )
                        else
                          SizedBox(
                            height: 56,
                            child: Row(
                              children: [
                                const SizedBox(width: 6),
                                GlassCircleButton(
                                  key: widget.backKey,
                                  icon: Icons.chevron_left_rounded,
                                  size: 26,
                                  tooltip: widget.backLabel,
                                  onPressed: widget.onBack!,
                                ),
                                Expanded(
                                  child: Semantics(
                                    header: true,
                                    child: Text(
                                      widget.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: authSerif(19, 1.2),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: widget.trailing,
                                ),
                                const SizedBox(width: 6),
                              ],
                            ),
                          ),
                        if (widget.headerBottom != null) widget.headerBottom!,
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                Expanded(child: widget.body),
                if (widget.bottom != null)
                  AuthGlass(
                    radius: BorderRadius.zero,
                    blur: 26,
                    gradient: _barGradient,
                    border: const Border(
                      top: BorderSide(color: AppColors.whiteA90xE6),
                    ),
                    shadow: [
                      BoxShadow(
                        color: dsNavy.withValues(alpha: 0.1),
                        blurRadius: 24,
                        offset: const Offset(0, -8),
                      ),
                    ],
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        14,
                        16,
                        12 + bottomInset,
                      ),
                      child: widget.bottom,
                    ),
                  ),
              ],
            ),
            if (widget.overlay != null) Positioned.fill(child: widget.overlay!),
          ],
        ),
      ),
    );
  }

  static const _barGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.whiteA84xD6, AppColors.whiteA60x99],
  );
}

/// Header of a tab page (Favourites): big serif title over a muted caption.
class _TabTitle extends StatelessWidget {
  const _TabTitle({required this.title, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 2, 8, 2),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Semantics(
            header: true,
            child: Text(title, style: authSerif(30, 1.15)),
          ),
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                subtitle!,
                style: AppText.body.copyWith(fontSize: 14, color: dsMuted),
              ),
            ),
          ),
      ],
    ),
  );
}

/// 44 px frosted round button (back, shortlist, menu), with an optional count badge.
class GlassCircleButton extends StatelessWidget {
  const GlassCircleButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 22,
    this.badge = 0,
    this.color = dsNavy,
    super.key,
  });

  final IconData icon;
  final double size;
  final String tooltip;
  final VoidCallback onPressed;
  final int badge;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 44,
    height: 44,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        DiscoverGlass(
          radius: 22,
          child: IconButton(
            tooltip: tooltip,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 44, height: 44),
            onPressed: onPressed,
            icon: Icon(icon, size: size, color: color),
          ),
        ),
        if (badge > 0)
          Positioned(
            top: -3,
            right: -3,
            child: IgnorePointer(
              child: Container(
                constraints: const BoxConstraints(minWidth: 18),
                height: 18,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.rose600,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  '$badge',
                  style: AppText.body.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    color: AppColors.surface,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

/// A soft white band that sweeps across the card it is stacked in (the design's `::after` sheen).
class SheenSweep extends StatelessWidget {
  const SheenSweep({
    this.periodMs = 6000,
    this.band = 0.26,
    this.peak = AppColors.whiteA50x80,
    super.key,
  });
  final double periodMs;
  final double band;

  /// Colour at the middle of the band (fainter on the navy cards).
  final Color peak;

  @override
  Widget build(BuildContext context) {
    final ValueListenable<double> clock = DiscoverClock.of(context);
    return Positioned.fill(
      child: IgnorePointer(
        child: ValueListenableBuilder<double>(
          valueListenable: clock,
          builder: (context, t, _) => LayoutBuilder(
            builder: (context, box) {
              final w = box.maxWidth * band;
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
                            AppColors.whiteClear,
                            peak,
                            AppColors.whiteClear,
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

/// Teal-to-sky ring around an avatar that draws itself in, with the initials on a navy gradient.
class RingAvatar extends StatelessWidget {
  const RingAvatar({
    required this.initials,
    required this.progress,
    required this.size,
    required this.fill,
    this.photoUrl,
    this.ringColors = const [AppColors.teal, dsSky],
    this.stroke = 4,
    this.fontSize = 19,
    this.tick = false,
    super.key,
  });

  final String initials;
  final String? photoUrl;

  /// 0..1 of the ring that is drawn (rating / scale).
  final double progress;
  final double size;
  final List<Color> fill;
  final List<Color> ringColors;
  final double stroke;
  final double fontSize;

  /// Teal verified tick at the bottom-right.
  final bool tick;

  @override
  Widget build(BuildContext context) {
    final clock = DiscoverClock.of(context);
    final inner = size - stroke * 2 - (size > 100 ? 16 : 6);
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: ValueListenableBuilder<double>(
          valueListenable: clock,
          builder: (context, t, _) {
            final grow = seg(t, 400, 1300, Curves.easeOutCubic);
            return Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size.square(size),
                  painter: _RingPainter(
                    progress: progress * grow,
                    colors: ringColors,
                    stroke: stroke,
                  ),
                ),
                Container(
                  width: inner,
                  height: inner,
                  alignment: Alignment.center,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: fill,
                    ),
                    image: photoUrl == null
                        ? null
                        : DecorationImage(
                            image: ResizeImage(
                              NetworkImage(photoUrl!),
                              width: 240,
                            ),
                            fit: BoxFit.cover,
                            onError: (_, _) {},
                          ),
                    boxShadow: [
                      BoxShadow(
                        color: dsNavy.withValues(alpha: 0.25),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: photoUrl != null
                      ? null
                      : Text(
                          initials,
                          style: AppText.body.copyWith(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w800,
                            color: AppColors.surface,
                          ),
                        ),
                ),
                if (tick)
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: Transform.scale(
                      scale: seg(t, 1000, 600, Curves.easeOutBack),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.teal,
                          border: Border.all(
                            color: AppColors.surface,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.teal.withValues(alpha: 0.45),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: AppColors.surface,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.colors,
    required this.stroke,
  });
  final double progress;
  final List<Color> colors;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = Rect.fromCircle(
      center: rect.center,
      radius: size.width / 2 - stroke,
    );
    canvas.drawArc(
      r,
      0,
      6.2832,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = dsNavy.withValues(alpha: 0.1),
    );
    if (progress <= 0) return;
    canvas.drawArc(
      r,
      -1.5708,
      6.2832 * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          colors: colors.length == 1 ? [colors.first, colors.first] : colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.colors != colors;
}

/// Initials for a worker: backend initials, else the name's first letters, else the first letter
/// of the title.
String workerInitials(String? initials, String title) {
  if (initials != null && initials.isNotEmpty) return initials;
  if (title.isEmpty) return '?';
  final parts = title.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  return parts.take(2).map((p) => p.characters.first.toUpperCase()).join();
}

/// Avatar gradient picked from the worker id so a worker keeps the same colours everywhere.
const kAvatarGradients = <List<Color>>[
  [AppColors.teal, dsNavy],
  [dsNavy, dsSky],
  [AppColors.warnIcon, AppColors.amber],
  [AppColors.slate, AppColors.slate400Light],
  [AppColors.rose800, AppColors.redF43F5E],
];

List<Color> avatarGradientFor(String id) =>
    kAvatarGradients[id.hashCode.abs() % kAvatarGradients.length];
