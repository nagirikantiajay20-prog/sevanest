import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_page.dart'
    show workerInitials;

/// Pieces shared by the glass list / status screens (Favourites, Interviews): avatar, empty state
/// and the bottom confirmation sheet.

/// Round initials (or photo) avatar on a gradient, with the white ring of the design.
class GlassAvatar extends StatelessWidget {
  const GlassAvatar({
    required this.title,
    required this.gradient,
    this.initials,
    this.photoUrl,
    this.size = 52,
    this.fontSize = 17,
    super.key,
  });

  final String title;
  final String? initials;
  final String? photoUrl;
  final List<Color> gradient;
  final double size;
  final double fontSize;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        image: photoUrl == null
            ? null
            : DecorationImage(
                image: NetworkImage(photoUrl!),
                fit: BoxFit.cover,
              ),
        boxShadow: [
          BoxShadow(
            color: dsNavy.withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: photoUrl != null
          ? null
          : Text(
              workerInitials(initials, title),
              style: AppText.body.copyWith(
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
    ),
  );
}

/// Centred empty state: a floating icon disc, serif title, body and a navy call to action.
class GlassEmpty extends StatelessWidget {
  const GlassEmpty({
    required this.icon,
    required this.iconColor,
    required this.discColors,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.actionKey,
    required this.onAction,
    this.actionIcon,
    super.key,
  });

  final IconData icon;
  final Color iconColor;
  final List<Color> discColors;
  final String title;
  final String body;
  final String actionLabel;
  final Key actionKey;
  final VoidCallback onAction;

  /// Icon after the button label (none by default).
  final IconData? actionIcon;

  @override
  Widget build(BuildContext context) {
    final clock = DiscoverClock.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 48),
        child: DiscoverRise(
          delayMs: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder<double>(
                valueListenable: clock,
                builder: (context, t, child) => Transform.translate(
                  offset: Offset(0, -5 * math.sin(t / 4000 * math.pi).abs()),
                  child: child,
                ),
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: discColors,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: dsNavy.withValues(alpha: 0.14),
                        blurRadius: 30,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 46, color: iconColor),
                ),
              ),
              const SizedBox(height: 24),
              Semantics(
                header: true,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: authSerif(26, 1.2),
                ),
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 290),
                child: Text(
                  body,
                  textAlign: TextAlign.center,
                  style: AppText.body.copyWith(
                    fontSize: 15.5,
                    height: 1.5,
                    color: dsText,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 220,
                child: AuthCta(
                  key: actionKey,
                  clock: clock,
                  label: actionLabel,
                  loadingLabel: actionLabel,
                  loading: false,
                  breathe: true,
                  showArrow: false,
                  radius: 18,
                  height: 54,
                  onPressed: onAction,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cream bottom sheet of the glass screens: rounded top, grab handle, then [builder]'s content.
Future<T?> showGlassSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  barrierColor: const Color(0x611B3354),
  builder: (ctx) => Container(
    padding: EdgeInsets.fromLTRB(
      20,
      12,
      20,
      24 + MediaQuery.paddingOf(ctx).bottom,
    ),
    decoration: BoxDecoration(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xF7FFFFFF), Color(0xF7FAF8F5)],
      ),
      boxShadow: [
        BoxShadow(
          color: dsNavy.withValues(alpha: 0.25),
          blurRadius: 40,
          offset: const Offset(0, -16),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: dsNavy.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        const SizedBox(height: 16),
        builder(ctx),
      ],
    ),
  ),
);

/// Bottom sheet that asks "are you sure?": serif title, body, a big confirm button and a plain
/// "keep" text button. True only when confirm is tapped.
Future<bool> showGlassConfirm(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  required String keepLabel,
  required Key confirmKey,
  Key keepKey = const Key('dialog_cancel_btn'),
  bool destructive = false,
}) async {
  final yes = await showGlassSheet<bool>(
    context,
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: authSerif(24, 1.15)),
        const SizedBox(height: 12),
        Text(
          body,
          style: AppText.body.copyWith(
            fontSize: 15.5,
            height: 1.55,
            color: dsText,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 58,
          child: FilledButton(
            key: confirmKey,
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: destructive ? const Color(0xFFBE123C) : dsNavy,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              textStyle: AppText.body.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text(confirmLabel),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 48,
          child: TextButton(
            key: keepKey,
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: dsMuted,
              textStyle: AppText.body.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text(keepLabel),
          ),
        ),
      ],
    ),
  );
  return yes ?? false;
}
