import 'package:flutter/material.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';

/// Design card: white, 20 radius, hairline border, soft navy shadow. [tinted] gives the teal
/// wash used for highlights (banners, "match" cards).
class SnCard extends StatelessWidget {
  const SnCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.tinted = false,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.card);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tinted ? AppColors.tealWash : AppColors.surface,
        borderRadius: radius,
        border: Border.all(
          color: tinted ? AppColors.tealLine : AppColors.hairline,
        ),
        boxShadow: tinted ? null : AppShadows.card,
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
