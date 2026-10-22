import 'package:flutter/material.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';

/// Modal sheet in the design style: 32 top radius, grabber, keyboard-safe. Pass [title] for the
/// serif heading row with a close button.
Future<T?> showSnBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  String? title,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md + MediaQuery.viewInsetsOf(ctx).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: SnGrabber()),
          if (title != null) ...[
            const SizedBox(height: AppSpacing.s12),
            Row(
              children: [
                Expanded(child: Text(title, style: AppText.screenTitle)),
                IconButton(
                  key: const Key('sheet_close_btn'),
                  tooltip: MaterialLocalizations.of(ctx).closeButtonTooltip,
                  onPressed: () => Navigator.of(ctx).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ],
          Flexible(child: builder(ctx)),
        ],
      ),
    ),
  );
}

/// The small bar at the top of a sheet.
class SnGrabber extends StatelessWidget {
  const SnGrabber({super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 4,
    decoration: BoxDecoration(
      color: AppColors.slate300,
      borderRadius: BorderRadius.circular(AppRadius.pill),
    ),
  );
}
