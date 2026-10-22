import 'package:flutter/material.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';

enum SnBadgeTone { success, warning, error, neutral }

/// Status chip: colour + icon + text (never colour alone). Verified styling must only be fed
/// from backend verification status (AGENTS §27).
class SnBadge extends StatelessWidget {
  const SnBadge({
    required this.label,
    this.tone = SnBadgeTone.neutral,
    super.key,
  });

  final String label;
  final SnBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (Color bg, Color fg, IconData icon) = switch (tone) {
      SnBadgeTone.success => (
        AppColors.successBg,
        AppColors.successText,
        Icons.verified,
      ),
      SnBadgeTone.warning => (
        AppColors.warnBg,
        AppColors.warnText,
        Icons.hourglass_top,
      ),
      SnBadgeTone.error => (
        scheme.errorContainer,
        scheme.onErrorContainer,
        Icons.error_outline,
      ),
      SnBadgeTone.neutral => (
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
        Icons.info_outline,
      ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: fg, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
