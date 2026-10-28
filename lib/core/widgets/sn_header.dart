import 'package:flutter/material.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// Screen header from the design: round back button, serif title, optional subtitle, trailing
/// action and a [bottom] slot (e.g. [SnStepBar]). Pass [onBack] null on tab roots.
/// Use as a plain widget at the top of a Column/Scaffold body, not as an AppBar.
class SnHeader extends StatelessWidget {
  const SnHeader({
    required this.title,
    this.subtitle,
    this.onBack,
    this.trailing,
    this.bottom,
    super.key,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? trailing;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (onBack != null) ...[
                    Material(
                      color: AppColors.canvasCool,
                      shape: const CircleBorder(
                        side: BorderSide(color: AppColors.hairline),
                      ),
                      child: IconButton(
                        key: const Key('app_back_btn'),
                        tooltip: AppLocalizations.of(context).back,
                        constraints: const BoxConstraints.tightFor(
                          width: kMinTapTarget,
                          height: kMinTapTarget,
                        ),
                        onPressed: onBack,
                        icon: const Icon(
                          Icons.chevron_left_rounded,
                          color: AppColors.brandInk,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.screenTitle,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.meta,
                          ),
                      ],
                    ),
                  ),
                  ?trailing,
                ],
              ),
              if (bottom != null) ...[
                const SizedBox(height: AppSpacing.s12),
                bottom!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Segmented progress bar (profile setup, "Find a worker" steps).
class SnStepBar extends StatelessWidget {
  const SnStepBar({required this.step, required this.total, super.key});

  /// 1-based current step.
  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$step / $total',
      child: Row(
        children: [
          for (var i = 1; i <= total; i++) ...[
            if (i > 1) const SizedBox(width: AppSpacing.xs + 2),
            Expanded(
              child: AnimatedContainer(
                duration: AppMotion.base,
                height: 4,
                decoration: BoxDecoration(
                  color: i <= step ? AppColors.teal : AppColors.hairline,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
