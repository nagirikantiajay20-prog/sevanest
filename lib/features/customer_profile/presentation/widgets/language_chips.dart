import 'package:flutter/material.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/providers/customer_profile_providers.dart';

/// Language pills from the design. Languages the backend doesn't accept yet are shown but disabled.
class LanguageChips extends StatelessWidget {
  const LanguageChips({
    required this.selected,
    required this.onSelected,
    this.threeColumns = false,
    super.key,
  });

  final String selected;
  final ValueChanged<String>? onSelected;

  /// Equal-width pills, three per row, no tick (the glass profile setup).
  final bool threeColumns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = (box.maxWidth - 2 * AppSpacing.sm) / 3;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final l in profileLanguages)
              SizedBox(width: threeColumns ? w : null, child: _chip(l)),
          ],
        );
      },
    );
  }

  Widget _chip(({String code, String label, bool enabled}) l) {
    final on = selected == l.code;
    return ChoiceChip(
      key: Key('profile_language_chip_${l.code}'),
      label: threeColumns
          ? Center(widthFactor: 1, child: Text(l.label))
          : Text(l.label),
      selected: on,
      showCheckmark: !threeColumns,
      checkmarkColor: AppColors.teal,
      selectedColor: AppColors.tealWash,
      backgroundColor: threeColumns
          ? Colors.white.withValues(alpha: 0.72)
          : AppColors.surface,
      labelStyle: AppText.label.copyWith(
        fontSize: 15,
        color: on
            ? AppColors.teal
            : l.enabled
            ? AppColors.brandInk
            : AppColors.slate400,
      ),
      shape: StadiumBorder(
        side: BorderSide(
          color: on ? AppColors.teal : AppColors.hairline,
          width: on ? 1.5 : 1,
        ),
      ),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      onSelected: l.enabled && onSelected != null
          ? (_) => onSelected!(l.code)
          : null,
    );
  }
}
