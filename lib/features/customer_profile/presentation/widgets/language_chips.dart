import 'package:flutter/material.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
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
      spacing: AppSpacing.sm + 2,
      runSpacing: AppSpacing.sm + 2,
      children: [
        for (final l in profileLanguages)
          ChoiceChip(
            key: Key('profile_language_chip_${l.code}'),
            label: Text(l.label),
            selected: selected == l.code,
            showCheckmark: true,
            checkmarkColor: AppColors.teal,
            selectedColor: const Color(0xFFF0FDFA),
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: l.enabled ? AppColors.ink : AppColors.slate,
            ),
            shape: StadiumBorder(
              side: BorderSide(
                color: selected == l.code ? AppColors.teal : AppColors.slate,
                width: 1.5,
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
