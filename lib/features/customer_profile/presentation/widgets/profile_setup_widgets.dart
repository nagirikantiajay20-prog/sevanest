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
  colors: [Color(0xA8FFFFFF), Color(0x5CFFFFFF)],
);
const setupGlassBorder = Border.fromBorderSide(
  BorderSide(color: Color(0xD9FFFFFF)),
);
const setupGlassShadow = [
  BoxShadow(color: Color(0x291B3354), blurRadius: 36, offset: Offset(0, 14)),
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
                        child: CircularProgressIndicator(
                          value: v,
                          strokeWidth: 4,
                          strokeCap: StrokeCap.round,
                          color: AppColors.teal,
                          backgroundColor: authNavy.withValues(alpha: 0.14),
                        ),
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
            color: Colors.white,
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
    super.key,
  });

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
                boxShadow: [
                  BoxShadow(
                    color: AppColors.teal.withValues(alpha: 0.14),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: showError
                      ? AppColors.danger
                      : a == null
                      ? const Color(0xFF99E6DC)
                      : AppColors.successLine,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: authNavy.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.home_outlined,
                      color: AppColors.teal,
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
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          sub,
                          key: const Key('profile_address_summary'),
                          style: AppText.body.copyWith(
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

/// One-shot confetti bursting from [origin] as [progress] runs 0 -> 1 (design: address added).
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
    Color(0xFF38BDF8),
    AppColors.amber,
    authNavy,
    AppColors.danger,
    Color(0xFF16A34A),
    Color(0xFFA78BFA),
  ];
  static const _count = 32;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    if (t <= 0 || t >= 1) return;
    final out = Curves.easeOutCubic.transform(t);
    final fade = t < 0.7 ? 1.0 : (1 - t) / 0.3;
    for (var i = 0; i < _count; i++) {
      final a = i / _count * 2 * math.pi + (i % 3) * 0.25;
      final d = 120 + (i * 37) % 150;
      final pos =
          origin +
          Offset(
            math.cos(a) * d * out,
            math.sin(a) * d * out - 50 * out + 90 * t * t,
          );
      canvas
        ..save()
        ..translate(pos.dx, pos.dy)
        ..rotate((i * 67 % 540 - 180) * math.pi / 180 * out)
        ..drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-4.5, -7, 9, 14),
            const Radius.circular(2),
          ),
          Paint()
            ..color = _colors[i % _colors.length].withValues(
              alpha: fade * (1 - 0.3 * t),
            ),
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.origin != origin;
}
