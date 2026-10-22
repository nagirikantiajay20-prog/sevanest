import 'package:flutter/material.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';

/// Selectable pill (filters, time windows, language, day shortcuts). Selected = teal wash,
/// teal border and a check; the check keeps it readable without colour (AGENTS §55).
class SnChip extends StatelessWidget {
  const SnChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
    this.icon,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  /// Small number badge after the label (e.g. "Cook 1").
  final int? count;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.teal : AppColors.brandInk;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.tealWash : AppColors.surface,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? AppColors.teal : AppColors.hairline,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: kMinTapTarget),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selected || icon != null) ...[
                    Icon(selected ? Icons.check : icon, size: 18, color: fg),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.label.copyWith(color: fg, fontSize: 14),
                    ),
                  ),
                  if (count != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    DecoratedBox(
                      decoration: const BoxDecoration(
                        color: AppColors.slateBg,
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xs + 2),
                        child: Text('$count', style: AppText.meta),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
