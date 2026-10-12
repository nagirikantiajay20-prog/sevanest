import 'package:flutter/material.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/core/widgets/sn_badge.dart';
import 'package:sevanest_customer/core/widgets/sn_bottom_sheet.dart';
import 'package:sevanest_customer/core/widgets/sn_button.dart';
import 'package:sevanest_customer/core/widgets/sn_card.dart';
import 'package:sevanest_customer/core/widgets/sn_states.dart';
import 'package:sevanest_customer/core/widgets/sn_text_field.dart';
import 'package:sevanest_customer/core/widgets/sn_timeline.dart';

/// Dev-flavor only (route is not registered otherwise). Visual check of every shared widget/state.
class WidgetGalleryScreen extends StatelessWidget {
  const WidgetGalleryScreen({super.key});

  Widget _section(BuildContext context, String title, Widget child) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Widget gallery (dev)')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _section(
            context,
            'Buttons',
            Column(
              spacing: AppSpacing.sm,
              children: [
                SnButton(label: 'Primary', onPressed: () {}),
                SnButton(
                  label: 'Secondary',
                  variant: SnButtonVariant.secondary,
                  onPressed: () {},
                ),
                SnButton(
                  label: 'Text',
                  variant: SnButtonVariant.text,
                  onPressed: () {},
                ),
                const SnButton(
                  label: 'Loading',
                  isLoading: true,
                  onPressed: null,
                ),
                const SnButton(label: 'Disabled', onPressed: null),
              ],
            ),
          ),
          _section(
            context,
            'Text field',
            const Column(
              spacing: AppSpacing.sm,
              children: [
                SnTextField(label: 'Mobile', prefixText: '+91 '),
                SnTextField(label: 'With error', errorText: 'Required'),
              ],
            ),
          ),
          _section(
            context,
            'Badges',
            const Wrap(
              spacing: AppSpacing.sm,
              children: [
                SnBadge(label: 'Verified', tone: SnBadgeTone.success),
                SnBadge(
                  label: 'Verification in progress',
                  tone: SnBadgeTone.warning,
                ),
                SnBadge(label: 'Failed', tone: SnBadgeTone.error),
                SnBadge(label: 'Updated'),
              ],
            ),
          ),
          _section(
            context,
            'Card',
            SnCard(onTap: () {}, child: const Text('Tappable card')),
          ),
          _section(
            context,
            'Timeline',
            const SnTimeline(
              items: [
                SnTimelineItem(
                  title: 'Request created',
                  timestamp: '10 Oct, 9:00',
                  state: SnTimelineState.done,
                ),
                SnTimelineItem(
                  title: 'Interview scheduled',
                  subtitle: 'Fri 11 Oct, 5 PM',
                  state: SnTimelineState.current,
                ),
                SnTimelineItem(
                  title: 'Service started',
                  state: SnTimelineState.upcoming,
                ),
              ],
            ),
          ),
          _section(
            context,
            'Empty / Error',
            Column(
              children: [
                const SizedBox(
                  height: 220,
                  child: SnEmptyState(
                    title: 'No matching workers found',
                    message:
                        'Try changing your area, timing or engagement type.',
                    actionLabel: 'Edit requirement',
                  ),
                ),
                SizedBox(
                  height: 240,
                  child: SnErrorState(
                    message: 'Network problem',
                    onRetry: () {},
                  ),
                ),
              ],
            ),
          ),
          _section(
            context,
            'Skeleton',
            const SizedBox(height: 240, child: SnSkeletonList(count: 2)),
          ),
          SnButton(
            label: 'Open bottom sheet',
            variant: SnButtonVariant.secondary,
            onPressed: () => showSnBottomSheet<void>(
              context,
              builder: (_) => const Text('Bottom sheet content'),
            ),
          ),
        ],
      ),
    );
  }
}
