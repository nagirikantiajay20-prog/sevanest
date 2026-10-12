import 'package:flutter/material.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';

enum SnTimelineState { done, current, upcoming, failed }

class SnTimelineItem {
  const SnTimelineItem({
    required this.title,
    required this.state,
    this.subtitle,
    this.timestamp,
  });

  final String title;
  final String? subtitle;
  final String? timestamp;
  final SnTimelineState state;
}

/// Vertical booking-status timeline. Events come from the backend (AGENTS §36).
class SnTimeline extends StatelessWidget {
  const SnTimeline({required this.items, super.key});

  final List<SnTimelineItem> items;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        for (var i = 0; i < items.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 32,
                  child: Column(
                    children: [
                      Icon(
                        _icon(items[i].state),
                        size: 20,
                        color: _color(items[i].state, scheme),
                      ),
                      if (i < items.length - 1)
                        Expanded(
                          child: VerticalDivider(
                            width: 2,
                            thickness: 2,
                            color: scheme.outlineVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          items[i].title,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        if (items[i].subtitle != null) Text(items[i].subtitle!),
                        if (items[i].timestamp != null)
                          Text(
                            items[i].timestamp!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  IconData _icon(SnTimelineState s) => switch (s) {
    SnTimelineState.done => Icons.check_circle,
    SnTimelineState.current => Icons.radio_button_checked,
    SnTimelineState.upcoming => Icons.radio_button_unchecked,
    SnTimelineState.failed => Icons.cancel,
  };

  Color _color(SnTimelineState s, ColorScheme c) => switch (s) {
    SnTimelineState.done => c.primary,
    SnTimelineState.current => c.primary,
    SnTimelineState.upcoming => c.outline,
    SnTimelineState.failed => c.error,
  };
}
