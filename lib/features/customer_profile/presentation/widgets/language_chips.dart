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
        if (threeColumns) return _grid(w);
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

  /// Design grid: 46 px pills, a highlight that glides to the selected one.
  Widget _grid(double w) {
    const h = 46.0;
    const gap = 10.0;
    final i = profileLanguages.indexWhere((l) => l.code == selected);
    return SizedBox(
      height: 2 * h + gap,
      child: Stack(
        children: [
          if (i >= 0)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutBack,
              left: (i % 3) * (w + gap),
              top: (i ~/ 3) * (h + gap),
              width: w,
              height: h,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFE2EEEC),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.teal, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.teal.withValues(alpha: 0.18),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
              ),
            ),
          for (var n = 0; n < profileLanguages.length; n++)
            Positioned(
              left: (n % 3) * (w + gap),
              top: (n ~/ 3) * (h + gap),
              width: w,
              height: h,
              child: _gridChip(profileLanguages[n]),
            ),
        ],
      ),
    );
  }

  Widget _gridChip(({String code, String label, bool enabled}) l) {
    final on = selected == l.code;
    return Semantics(
      button: true,
      selected: on,
      child: InkWell(
        key: Key('profile_language_chip_${l.code}'),
        customBorder: const StadiumBorder(),
        onTap: l.enabled && onSelected != null
            ? () => onSelected!(l.code)
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            color: on
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.72),
            shape: StadiumBorder(
              side: BorderSide(
                color: on ? Colors.transparent : const Color(0xFFCBD5E1),
                width: 1.5,
              ),
            ),
          ),
          child: Text(
            l.label,
            maxLines: 1,
            style: TextStyle(
              fontSize: 15,
              fontWeight: on ? FontWeight.w700 : FontWeight.w500,
              color: on
                  ? AppColors.teal
                  : l.enabled
                  ? AppColors.navyDeep
                  : AppColors.navyDeep.withValues(alpha: 0.55),
            ),
          ),
        ),
      ),
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
