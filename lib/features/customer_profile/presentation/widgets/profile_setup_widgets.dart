import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/features/addresses/domain/address.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

const setupGlassGradient = LinearGradient(
  begin: Alignment(-0.64, -0.77),
  end: Alignment(0.64, 0.77),
  colors: [AppColors.whiteA66xA8, AppColors.whiteA36x5C],
);
const setupGlassBorder = Border.fromBorderSide(
  BorderSide(color: AppColors.whiteA85xD9),
);
const setupGlassShadow = [
  BoxShadow(
    color: AppColors.sky1B3354A16,
    blurRadius: 36,
    offset: Offset(0, 14),
  ),
];

/// Share of the profile that is filled in: name 35, valid email 15, language 10, address 30, photo 10.
int profileProgress({
  required bool nameOk,
  required bool emailOk,
  required bool hasAddress,
  required bool hasPhoto,
}) =>
    (nameOk ? 35 : 0) +
    (emailOk ? 15 : 0) +
    10 +
    (hasAddress ? 30 : 0) +
    (hasPhoto ? 10 : 0);

/// Frosted pill: progress ring, "Profile N% complete" and the next thing to fill in.
class ProfileProgressPill extends StatelessWidget {
  const ProfileProgressPill({
    required this.percent,
    required this.hint,
    super.key,
  });
  final int percent;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      liveRegion: true,
      container: true,
      child: AuthGlass(
        radius: BorderRadius.circular(26),
        blur: 22,
        gradient: setupGlassGradient,
        border: setupGlassBorder,
        shadow: setupGlassShadow,
        child: Container(
          height: 52,
          padding: const EdgeInsets.fromLTRB(8, 0, 16, 0),
          child: Row(
            children: [
              SizedBox(
                width: 38,
                height: 38,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(end: percent / 100),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOut,
                      builder: (_, v, _) => SizedBox.expand(
                        child: CustomPaint(painter: _RingPainter(v)),
                      ),
                    ),
                    const Icon(
                      Icons.auto_awesome_outlined,
                      size: 16,
                      color: AppColors.teal,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.profileProgress(percent),
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                        color: authNavy,
                      ),
                    ),
                    Text(
                      hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.3,
                        color: AppColors.slate700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Progress ring: navy track, teal -> sky arc starting at 12 o'clock.
class _RingPainter extends CustomPainter {
  _RingPainter(this.value);
  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(2);
    canvas.drawOval(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = authNavy.withValues(alpha: 0.14),
    );
    if (value <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * value,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.teal, AppColors.sky400],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value;
}

/// White ring with a pulsing halo around the profile photo.
class ProfileAvatarHalo extends StatelessWidget {
  const ProfileAvatarHalo({
    required this.clock,
    required this.child,
    super.key,
  });
  final ValueListenable<double> clock;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ExcludeSemantics(
          child: ValueListenableBuilder<double>(
            valueListenable: clock,
            builder: (_, t, _) {
              final k = Curves.easeOut.transform((t / 2600) % 1);
              return Opacity(
                opacity: 0.7 * (1 - k),
                child: Transform.scale(
                  scale: 0.95 + 0.5 * k,
                  child: Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.teal.withValues(alpha: 0.55),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: authNavy.withValues(alpha: 0.25),
                blurRadius: 34,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: child,
        ),
      ],
    );
  }
}

/// Design 04: the "Add your home address" card; shows the address once it is typed.
class ProfileAddressCard extends StatelessWidget {
  const ProfileAddressCard({
    required this.address,
    required this.showError,
    required this.onTap,
    this.clock,
    super.key,
  });

  /// Drives the light sweep across the card (null = no sweep).
  final ValueListenable<double>? clock;
  final AddressInput? address;
  final bool showError;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final a = address;
    final title = a == null
        ? l10n.profileAddAddressTitle
        : '${(a.label ?? '').trim().isEmpty ? 'Home' : a.label!.trim()} · ${a.area}';
    final sub = a == null
        ? l10n.profileAddAddressSub
        : [
            a.line,
            a.line2,
            '${a.city} ${a.pincode}',
          ].where((s) => s != null && s.isNotEmpty).join(', ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          child: InkWell(
            key: const Key('profile_address_card'),
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.s12),
              decoration: BoxDecoration(
                color: a == null ? AppColors.tealMist : AppColors.successBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: showError
                      ? AppColors.danger
                      : a == null
                      ? AppColors.teal99E6DC
                      : AppColors.successLine,
                  width: 1.5,
                ),
              ),
              child: _Sheen(
                clock: clock,
                radius: 18,
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: authNavy.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TweenAnimationBuilder<double>(
                        key: ValueKey(a != null),
                        tween: Tween(begin: a == null ? 1 : 0.3, end: 1),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutBack,
                        builder: (_, v, c) =>
                            Transform.scale(scale: v, child: c),
                        child: const Icon(
                          Icons.home_outlined,
                          size: 24,
                          color: AppColors.teal,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppText.card.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: authNavy,
                            ),
                          ),
                          Text(
                            sub,
                            key: const Key('profile_address_summary'),
                            style: AppText.body.copyWith(
                              fontSize: 13,
                              height: 1.4,
                              color: AppColors.slate700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.slate),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (showError)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              l10n.profileAddressRequired,
              key: const Key('profile_address_error'),
              style: AppText.body.copyWith(color: AppColors.danger),
            ),
          ),
      ],
    );
  }
}

/// Light band sweeping across [child] (the address card).
class _Sheen extends StatelessWidget {
  const _Sheen({
    required this.clock,
    required this.radius,
    required this.child,
  });
  final ValueListenable<double>? clock;
  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = clock;
    if (c == null) return child;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        children: [
          child,
          Positioned.fill(
            child: IgnorePointer(
              child: LayoutBuilder(
                builder: (_, box) {
                  final w = box.maxWidth * 0.36;
                  return ValueListenableBuilder<double>(
                    valueListenable: c,
                    builder: (_, t, _) => Stack(
                      children: [
                        Positioned(
                          left:
                              w *
                              (-1.2 +
                                  3.8 *
                                      Curves.easeInOut.transform(
                                        (t / 3600) % 1,
                                      )),
                          top: 0,
                          bottom: 0,
                          width: w,
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.whiteClear,
                                  AppColors.whiteA65xA6,
                                  AppColors.whiteClear,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One-shot celebration at [origin] as [progress] runs 0 -> 1: a ring pulse, a soft glow and
/// confetti that fans out, tumbles under gravity and fades.
class ConfettiBurst extends StatelessWidget {
  const ConfettiBurst({
    required this.progress,
    required this.origin,
    super.key,
  });
  final Animation<double> progress;
  final Offset origin;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: CustomPaint(
        size: Size.infinite,
        painter: _ConfettiPainter(progress, origin),
      ),
    ),
  );
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.progress, this.origin) : super(repaint: progress);
  final Animation<double> progress;
  final Offset origin;

  static const _colors = [
    AppColors.teal,
    AppColors.sky400,
    AppColors.amber,
    authNavy,
    AppColors.danger,
    AppColors.success,
    AppColors.indigoA78BFA,
  ];
  static const _count = 44;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    if (t <= 0 || t >= 1) return;
    final pulse = Curves.easeOut.transform(t);
    canvas
      ..drawCircle(
        origin,
        24 + 120 * pulse,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 * (1 - pulse)
          ..color = AppColors.teal.withValues(alpha: 0.45 * (1 - pulse)),
      )
      ..drawCircle(
        origin,
        100,
        Paint()
          ..shader = RadialGradient(
            colors: [
              AppColors.teal.withValues(alpha: 0.28 * (1 - pulse)),
              AppColors.teal.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: origin, radius: 100)),
      );
    for (var i = 0; i < _count; i++) {
      final delay = (i % 6) * 0.03;
      final lt = ((t - delay) / (1 - delay)).clamp(0.0, 1.0);
      final out = Curves.easeOutCubic.transform(lt);
      final a = i / _count * 2 * math.pi + (i % 3) * 0.25;
      final d = 110 + (i * 37) % 130;
      final pos =
          origin +
          Offset(
            math.cos(a) * d * out,
            math.sin(a) * d * out - 60 * out + 110 * lt * lt,
          );
      final fade = lt < 0.7 ? 1.0 : (1 - lt) / 0.3;
      final paint = Paint()
        ..color = _colors[i % _colors.length].withValues(alpha: fade);
      canvas
        ..save()
        ..translate(pos.dx, pos.dy)
        ..rotate((i * 67 % 540 - 180) * math.pi / 180 * out)
        ..scale(1 - 0.3 * lt);
      if (i % 4 == 0) {
        canvas.drawCircle(Offset.zero, 5, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-4.5, -7, 9, 14),
            const Radius.circular(2),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.origin != origin;
}
