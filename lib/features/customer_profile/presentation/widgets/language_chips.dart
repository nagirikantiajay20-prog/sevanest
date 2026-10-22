import 'package:flutter/material.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/providers/customer_profile_providers.dart';

/// Language pills from the design. Languages the backend doesn't accept yet are shown but disabled.
class LanguageChips extends StatelessWidget {
  const LanguageChips({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final String selected;
  final ValueChanged<String>? onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final l in profileLanguages)
          ChoiceChip(
            key: Key('profile_language_chip_${l.code}'),
            label: Text(l.label),
            selected: selected == l.code,
            showCheckmark: true,
            checkmarkColor: AppColors.teal,
            selectedColor: AppColors.tealWash,
            backgroundColor: AppColors.surface,
            labelStyle: AppText.label.copyWith(
              fontSize: 15,
              color: selected == l.code
                  ? AppColors.teal
                  : l.enabled
                  ? AppColors.brandInk
                  : AppColors.slate400,
            ),
            shape: StadiumBorder(
              side: BorderSide(
                color: selected == l.code ? AppColors.teal : AppColors.hairline,
                width: selected == l.code ? 1.5 : 1,
              ),
            ),
            materialTapTargetSize: MaterialTapTargetSize.padded,
            onSelected: l.enabled && onSelected != null
                ? (_) => onSelected!(l.code)
                : null,
          ),
      ],
    );
  }
}
