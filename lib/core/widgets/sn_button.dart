import 'package:flutter/material.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';

/// [deep] is the darker teal CTA the design uses for the main action on dense screens.
enum SnButtonVariant { primary, deep, secondary, text }

/// The only button style used in the app. While [isLoading] it ignores taps (AGENTS §65).
class SnButton extends StatelessWidget {
  const SnButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.loadingLabel,
    this.icon,
    this.variant = SnButtonVariant.primary,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  /// Text beside the spinner while loading (falls back to the spinner alone).
  final String? loadingLabel;

  /// Optional trailing icon (e.g. the arrow on "Get OTP").
  final IconData? icon;
  final SnButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? tap = isLoading ? null : onPressed;
    final scheme = Theme.of(context).colorScheme;
    final onFilled =
        variant == SnButtonVariant.primary || variant == SnButtonVariant.deep;
    final spinnerColor = onFilled ? scheme.onPrimary : scheme.primary;
    final Widget child = isLoading
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: spinnerColor,
                ),
              ),
              if (loadingLabel != null) ...[
                const SizedBox(width: AppSpacing.sm + 4),
                Flexible(
                  child: Text(
                    loadingLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          )
        : icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(icon, size: 22),
            ],
          );
    const size = Size.fromHeight(kMinTapTarget);

    return switch (variant) {
      SnButtonVariant.primary => FilledButton(
        onPressed: tap,
        // Keep the brand colour while loading (design: spinner on a teal button).
        style: isLoading
            ? FilledButton.styleFrom(
                disabledBackgroundColor: scheme.primary,
                disabledForegroundColor: scheme.onPrimary,
              )
            : null,
        child: child,
      ),
      SnButtonVariant.deep => FilledButton(
        onPressed: tap,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.actionDeepTeal,
          foregroundColor: Colors.white,
          disabledBackgroundColor: isLoading ? AppColors.actionDeepTeal : null,
          disabledForegroundColor: isLoading ? Colors.white : null,
        ),
        child: child,
      ),
      SnButtonVariant.secondary => OutlinedButton(
        onPressed: tap,
        style: OutlinedButton.styleFrom(minimumSize: size),
        child: child,
      ),
      SnButtonVariant.text => TextButton(
        onPressed: tap,
        style: TextButton.styleFrom(minimumSize: size),
        child: child,
      ),
    };
  }
}
