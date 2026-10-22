import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/core/network/dio_provider.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// Navy-to-teal backdrop with the faint arch motif used on screens 01-03.
class AuthBackdrop extends StatelessWidget {
  const AuthBackdrop({
    required this.child,
    this.archAlignment,
    this.archSize = const Size(130, 200),
    super.key,
  });

  final Widget child;

  /// Where the large outlined arch sits; null draws none.
  final Alignment? archAlignment;
  final Size archSize;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [AppColors.navyDeep, AppColors.navy, AppColors.tealDeep],
          stops: [0, 0.6, 1],
        ),
      ),
      child: CustomPaint(
        painter: _ArchPatternPainter(archAlignment, archSize),
        child: child,
      ),
    );
  }
}

class _ArchPatternPainter extends CustomPainter {
  const _ArchPatternPainter(this.bigArch, this.archSize);
  final Alignment? bigArch;
  final Size archSize;

  static Path _arch(Rect r) => Path()
    ..moveTo(r.left, r.bottom)
    ..lineTo(r.left, r.top + r.width / 2)
    ..arcToPoint(
      Offset(r.right, r.top + r.width / 2),
      radius: Radius.circular(r.width / 2),
    )
    ..lineTo(r.right, r.bottom);

  @override
  void paint(Canvas canvas, Size size) {
    final faint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.05);
    const w = 46.0;
    const h = 62.0;
    for (var y = 20.0; y < size.height; y += 100) {
      final shift = ((y / 100).round().isEven) ? 0.0 : 50.0;
      for (var x = -shift; x < size.width; x += 100) {
        canvas.drawPath(_arch(Rect.fromLTWH(x, y, w, h)), faint);
      }
    }
    final alignment = bigArch;
    if (alignment != null) {
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withValues(alpha: 0.18);
      final center = alignment.alongSize(size);
      final rect = Rect.fromCenter(
        center: center,
        width: archSize.width,
        height: archSize.height,
      );
      canvas
        ..drawPath(_arch(rect), stroke)
        ..drawPath(_arch(rect.deflate(14)), stroke);
    }
  }

  @override
  bool shouldRepaint(_ArchPatternPainter old) =>
      old.bigArch != bigArch || old.archSize != archSize;
}

/// Official SevaNest brand mark on a white rounded tile; [full] shows the logo with wordmark and tagline.
class LogoTile extends StatelessWidget {
  const LogoTile({this.size = 48, this.full = false, super.key});

  final double size;
  final bool full;

  @override
  Widget build(BuildContext context) {
    final pad = size * (full ? 0.06 : 0.1);
    return ExcludeSemantics(
      child: Container(
        width: size,
        padding: EdgeInsets.all(pad),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(size * (full ? 0.08 : 0.3)),
        ),
        child: Image.asset(
          full
              ? 'assets/branding/logo_full.png'
              : 'assets/branding/logo_mark.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

/// Round white back button (OTP screen).
class AuthBackButton extends StatelessWidget {
  const AuthBackButton({required this.onPressed, super.key});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 1,
      shadowColor: AppColors.navy.withValues(alpha: 0.2),
      shape: const CircleBorder(side: BorderSide(color: AppColors.hairline)),
      child: IconButton(
        key: const Key('app_back_btn'),
        tooltip: AppLocalizations.of(context).back,
        constraints: const BoxConstraints.tightFor(width: 48, height: 48),
        onPressed: onPressed,
        icon: const Icon(Icons.chevron_left_rounded, color: AppColors.brandInk),
      ),
    );
  }
}

/// White sheet with a rounded top that fills the rest of the page.
class AuthSheet extends StatelessWidget {
  const AuthSheet({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: child,
    );
  }
}

/// Amber-circle icon + title + message, shown for recoverable problems (design: warning cards).
class AuthNoticeCard extends StatelessWidget {
  const AuthNoticeCard({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.hairline),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.warnBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.warn, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: text.bodyMedium?.copyWith(color: AppColors.slate),
                  ),
                  if (action != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    action!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Underlined teal text link (design: "Change number", "Contact support", legal links).
class AuthLink extends StatelessWidget {
  const AuthLink({
    required this.label,
    required this.onTap,
    this.icon,
    this.onDark = false,
    super.key,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final color = onDark ? Colors.white : AppColors.teal;
    final style = TextStyle(
      color: color,
      fontWeight: FontWeight.w600,
      fontSize: 16,
      decoration: icon == null ? TextDecoration.underline : null,
      decorationColor: color,
    );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: kMinTapTarget),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: color),
              const SizedBox(width: AppSpacing.sm),
            ],
            Flexible(child: Text(label, style: style)),
          ],
        ),
      ),
    );
  }
}

/// `GET /app-config` -> `support.phone` / `support.email` (verified live; null until ops set them).
Future<void> openSupport(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  Uri? target;
  try {
    final res = await ref.read(dioProvider).get<dynamic>('/app-config');
    final data = res.data;
    final support = data is Map ? data['support'] : null;
    if (support is Map) {
      final phone = support['phone'];
      final email = support['email'];
      if (phone is String && phone.isNotEmpty) {
        target = Uri(scheme: 'tel', path: phone);
      } else if (email is String && email.isNotEmpty) {
        target = Uri(scheme: 'mailto', path: email);
      }
    }
  } on Object {
    target = null;
  }
  var opened = false;
  if (target != null) {
    try {
      opened = await launchUrl(target);
    } on Object {
      opened = false;
    }
  }
  if (!opened) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.supportUnavailable)));
  }
}

/// `00:28` style countdown text.
String mmss(int seconds) {
  final m = (seconds ~/ 60).toString().padLeft(2, '0');
  final s = (seconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}
