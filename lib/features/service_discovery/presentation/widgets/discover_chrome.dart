import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/motion.dart';

/// Glass look of the "Find a worker" steps (design: Find a Worker 1-6): drifting room photo,
/// frosted bars, a node progress track. Animations are functions of the scaffold's clock.

const dsNavy = AppColors.navyDeep;
const dsText = AppColors.slate700;
const dsMuted = AppColors.slate;
const dsSky = AppColors.sky400;

/// The scaffold's clock for descendants (frozen in tests / reduced motion).
class DiscoverClock extends InheritedWidget {
  const DiscoverClock({required this.clock, required super.child, super.key});
  final ValueListenable<double> clock;

  static ValueListenable<double> of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DiscoverClock>()!.clock;

  @override
  bool updateShouldNotify(DiscoverClock old) => clock != old.clock;
}

final discoverBackdrop = RoomBackdropStyle(
  alignment: const Alignment(0.24, -0.4),
  washes: [
    LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppColors.ivory.withValues(alpha: 0.9),
        AppColors.ivory.withValues(alpha: 0.78),
        AppColors.ivory.withValues(alpha: 0.9),
      ],
      stops: const [0, 0.5, 1],
    ),
  ],
  glows: const [
    AuthGlow(AppColors.teal0F766EA30, 260, top: -70, right: -80),
    AuthGlow(
      AppColors.orangeF59E0BA28,
      260,
      top: 480,
      left: -100,
      delayMs: 6000,
    ),
  ],
);

/// Frosted card surface (`.gl` in the design).
class DiscoverGlass extends StatelessWidget {
  const DiscoverGlass({
    required this.child,
    this.radius = 24,
    this.corners,
    this.borderColor = AppColors.whiteA90xE6,
    this.borderWidth = 1,
    this.gradient,
    super.key,
  });
  final Widget child;
  final double radius;

  /// Overrides [radius] (a sheet rounds only its top corners).
  final BorderRadius? corners;
  final Color borderColor;
  final double borderWidth;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) => AuthGlass(
    radius: corners ?? BorderRadius.circular(radius),
    blur: 20,
    gradient:
        gradient ??
        const LinearGradient(
          begin: Alignment(-0.6, -1),
          end: Alignment(0.6, 1),
          colors: [AppColors.whiteA72xB8, AppColors.whiteA42x6B],
        ),
    border: Border.all(color: borderColor, width: borderWidth),
    shadow: [
      BoxShadow(
        color: dsNavy.withValues(alpha: 0.12),
        blurRadius: 28,
        offset: const Offset(0, 10),
      ),
    ],
    child: child,
  );
}

/// Fade + rise-in, [delayMs] after the screen appears (not replayed on rebuild).
class DiscoverRise extends StatelessWidget {
  const DiscoverRise({required this.delayMs, required this.child, super.key});
  final double delayMs;
  final Widget child;

  @override
  Widget build(BuildContext context) => Rise(
    clock: DiscoverClock.of(context),
    start: delayMs,
    duration: 700,
    child: child,
  );
}

/// Top bar: back, title + step, close, then the six step nodes on a track.
class DiscoverHeader extends StatelessWidget {
  const DiscoverHeader({
    required this.clock,
    required this.title,
    required this.stepLabel,
    required this.step,
    required this.total,
    required this.backLabel,
    required this.closeLabel,
    required this.onBack,
    required this.onClose,
    super.key,
  });

  final ValueListenable<double> clock;
  final String title;
  final String stepLabel;
  final int step;
  final int total;
  final String backLabel;
  final String closeLabel;
  final VoidCallback onBack;
  final VoidCallback onClose;

  static const _icons = [
    Icons.work_outline_rounded,
    Icons.schedule_rounded,
    Icons.place_outlined,
    Icons.calendar_month_outlined,
    Icons.shopping_cart_outlined,
    Icons.account_balance_wallet_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return AuthGlass(
      radius: BorderRadius.zero,
      blur: 26,
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.whiteA82xD1, AppColors.whiteA58x94],
      ),
      border: const Border(bottom: BorderSide(color: AppColors.whiteA90xE6)),
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
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Row(
                children: [
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: DiscoverGlass(
                      radius: 22,
                      child: IconButton(
                        key: const Key('app_back_btn'),
                        tooltip: backLabel,
                        padding: EdgeInsets.zero,
                        onPressed: onBack,
                        icon: const Icon(
                          Icons.chevron_left_rounded,
                          size: 26,
                          color: dsNavy,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: AppText.body.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                            color: dsNavy,
                          ),
                        ),
                        Text(
                          stepLabel,
                          key: const Key('discover_progress_label'),
                          style: AppText.body.copyWith(
                            fontSize: 12.5,
                            height: 1.2,
                            color: dsMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const Key('discover_close_btn'),
                    tooltip: closeLabel,
                    onPressed: onClose,
                    constraints: const BoxConstraints.tightFor(
                      width: 44,
                      height: 44,
                    ),
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 24,
                      color: dsNavy,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
              ),
            ),
            Semantics(
              label: '${step.clamp(1, total)} / $total',
              child: _Nodes(clock: clock, step: step, total: total),
            ),
          ],
        ),
      ),
    );
  }
}

class _Nodes extends StatelessWidget {
  const _Nodes({required this.clock, required this.step, required this.total});
  final ValueListenable<double> clock;
  final int step;
  final int total;

  static const _teal = AppColors.teal;

  @override
  Widget build(BuildContext context) {
    // Step 1 shows a short lead-in on the track, like the design; later steps fill to the node.
    final fill = step <= 1 ? 0.12 : ((step - 1) / (total - 1)).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 2, 10, 0),
      child: SizedBox(
        height: 36,
        child: ValueListenableBuilder<double>(
          valueListenable: clock,
          builder: (context, t, _) {
            final grow = seg(t, 400, 1200, Curves.easeOut);
            final glow = (t / 1600) % 1;
            return Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 16,
                  right: 16,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      height: 4,
                      color: dsNavy.withValues(alpha: 0.14),
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: fill * grow,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: const [_teal, dsSky, _teal],
                              begin: Alignment(-1 + 2 * glow, 0),
                              end: Alignment(1 + 2 * glow, 0),
                              tileMode: TileMode.mirror,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var i = 1; i <= total; i++)
                      _Node(
                        t: t,
                        index: i,
                        active: i == step,
                        done: i < step,
                        icon: DiscoverHeader._icons[i - 1],
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Node extends StatelessWidget {
  const _Node({
    required this.t,
    required this.index,
    required this.active,
    required this.done,
    required this.icon,
  });
  final double t;
  final int index;
  final bool active;
  final bool done;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final p = seg(t, 150.0 + (index - 1) * 80, 500, Curves.easeOutBack);
    final size = active ? 36.0 : 28.0;
    final ping = ((t - 800) / 2000) % 1;
    return Transform.scale(
      scale: p.clamp(0.0, 1.2),
      child: Opacity(
        opacity: p.clamp(0.0, 1.0),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                if (active && t > 800)
                  Opacity(
                    opacity: 0.7 * (1 - ping),
                    child: Container(
                      width: size * (0.8 + 1.2 * ping),
                      height: size * (0.8 + 1.2 * ping),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.teal.withValues(alpha: 0.55),
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
                    gradient: active
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.teal, dsSky],
                          )
                        : null,
                    color: active
                        ? null
                        : done
                        ? AppColors.teal
                        : AppColors.whiteA85xD9,
                    border: active
                        ? null
                        : Border.all(
                            color: done ? AppColors.teal : AppColors.slate300,
                            width: 2,
                          ),
                    boxShadow: [
                      BoxShadow(
                        color: active
                            ? AppColors.teal.withValues(alpha: 0.45)
                            : dsNavy.withValues(alpha: 0.1),
                        blurRadius: active ? 18 : 8,
                        offset: Offset(0, active ? 8 : 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    done ? Icons.check_rounded : icon,
                    size: active ? 17 : 14,
                    color: active || done
                        ? AppColors.surface
                        : AppColors.slate400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Discard this request?" as a frosted dialog over a navy scrim.
Future<bool> showDiscoverDiscard(
  BuildContext context, {
  required String title,
  required String body,
  required String keep,
  required String discard,
}) async {
  final yes = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: keep,
    barrierColor: AppColors.blue0F2340A45,
    transitionDuration: const Duration(milliseconds: 300),
    transitionBuilder: (_, a, _, child) {
      final c = CurvedAnimation(parent: a, curve: Curves.easeOutBack);
      return FadeTransition(
        opacity: a,
        child: ScaleTransition(
          scale: Tween(begin: 0.92, end: 1.0).animate(c),
          child: child,
        ),
      );
    },
    pageBuilder: (ctx, _, _) => Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Material(
          type: MaterialType.transparency,
          child: DiscoverGlass(
            radius: 28,
            gradient: const LinearGradient(
              begin: Alignment(-0.5, -1),
              end: Alignment(0.5, 1),
              colors: [AppColors.whiteA95xF2, AppColors.whiteA82xD1],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.warnBg,
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      size: 26,
                      color: AppColors.warnIcon,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: authSerif(22, 1.2),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    body,
                    textAlign: TextAlign.center,
                    style: AppText.body.copyWith(fontSize: 14.5, color: dsText),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      key: const Key('discover_discard_cancel_btn'),
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: FilledButton.styleFrom(
                        backgroundColor: dsNavy,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: AppText.body.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: Text(keep),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: TextButton(
                      key: const Key('discover_discard_confirm_btn'),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.red700,
                        textStyle: AppText.body.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: Text(discard),
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
  return yes ?? false;
}

/// "Your choice so far" strip under the header: the chosen service as a photo, caption and name,
/// with a pencil to change it. A soft sheen sweeps across it.
class ServiceTicket extends StatelessWidget {
  const ServiceTicket({
    required this.caption,
    required this.name,
    required this.photo,
    required this.icon,
    required this.semanticLabel,
    required this.onChange,
    this.changeKey,
    super.key,
  });

  final String caption;
  final String name;
  final String? photo;
  final IconData icon;
  final String semanticLabel;
  final VoidCallback onChange;
  final Key? changeKey;

  @override
  Widget build(BuildContext context) {
    final clock = DiscoverClock.of(context);
    return DiscoverGlass(
      radius: 24,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: ValueListenableBuilder<double>(
                valueListenable: clock,
                builder: (context, t, _) => LayoutBuilder(
                  builder: (context, box) {
                    final w = box.maxWidth * 0.3;
                    final k = Curves.easeInOut.transform((t / 4500) % 1);
                    return Stack(
                      children: [
                        Positioned(
                          left: w * (-1.2 + 3.8 * k),
                          top: 0,
                          bottom: 0,
                          width: w,
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.whiteClear,
                                  AppColors.whiteA60x99,
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
          ),
          Semantics(
            button: true,
            label: semanticLabel,
            excludeSemantics: true,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                key: changeKey,
                onTap: onChange,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 60),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 12, 8),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.pillActive,
                            border: Border.all(
                              color: AppColors.surface,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: dsNavy.withValues(alpha: 0.18),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: photo == null
                              ? Icon(icon, size: 22, color: AppColors.teal)
                              : Image.asset(
                                  photo!,
                                  fit: BoxFit.cover,
                                  cacheWidth: 140,
                                  errorBuilder: (_, _, _) =>
                                      Icon(icon, color: AppColors.teal),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                caption,
                                style: AppText.body.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.6,
                                  height: 1.2,
                                  color: dsMuted,
                                ),
                              ),
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.body.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  height: 1.25,
                                  color: dsNavy,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.teal.withValues(alpha: 0.12),
                          ),
                          child: const Icon(
                            Icons.edit_outlined,
                            size: 14,
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
        ],
      ),
    );
  }
}
