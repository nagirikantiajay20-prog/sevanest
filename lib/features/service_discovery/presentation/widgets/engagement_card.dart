import 'package:flutter/material.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart';
import 'package:sevanest_customer/features/service_discovery/domain/catalog.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/engagement_labels.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// Typical week for each arrangement, Monday to Sunday (% of the bar height), as drawn in the
/// design. Purely illustrative; nothing is read from the backend.
const _weeks = <EngagementType, List<int>>{
  EngagementType.fullTime: [90, 90, 90, 90, 90, 90, 6],
  EngagementType.partTime: [45, 45, 45, 45, 45, 45, 6],
  EngagementType.daily: [6, 80, 6, 80, 6, 80, 6],
  EngagementType.hourly: [6, 6, 34, 6, 34, 6, 6],
  EngagementType.liveIn: [100, 100, 100, 100, 100, 100, 100],
  EngagementType.shift: [70, 70, 70, 6, 6, 70, 70],
  EngagementType.oneTime: [6, 6, 6, 60, 6, 6, 6],
  EngagementType.monthly: [60, 60, 60, 60, 60, 60, 60],
};

/// One arrangement: icon well, serif name, description, a meta pill and the week sketch.
/// An option the service can't offer is dimmed and shows its reason.
class EngagementCard extends StatelessWidget {
  const EngagementCard({
    required this.index,
    required this.option,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final int index;
  final EngagementOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = engagementLabels(l10n, option.type);
    final enabled = option.available;
    final heights = _weeks[option.type] ?? const [6, 6, 6, 6, 6, 6, 6];
    return DiscoverRise(
      delayMs: 180.0 + index * 100,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: enabled ? 1 : 0.6,
        child: Semantics(
          selected: selected,
          enabled: enabled,
          inMutuallyExclusiveGroup: true,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            offset: Offset(0, selected ? -0.015 : 0),
            child: DiscoverGlass(
              radius: 26,
              borderColor: selected ? AppColors.teal : const Color(0xE6FFFFFF),
              borderWidth: 2,
              gradient: selected
                  ? const LinearGradient(
                      begin: Alignment(-0.6, -1),
                      end: Alignment(0.6, 1),
                      colors: [Color(0xF2E2EEEC), Color(0xB3FFFFFF)],
                    )
                  : null,
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  key: Key('discover_engagement_${option.type.name}'),
                  onTap: enabled ? onTap : null,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Well(icon: labels.icon, on: selected),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(labels.name, style: authSerif(21, 1.2)),
                                  const SizedBox(height: 3),
                                  Text(
                                    labels.description,
                                    style: AppText.body.copyWith(
                                      fontSize: 14,
                                      height: 1.4,
                                      color: dsText,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _Meta(
                                    text:
                                        option.unavailableReason ?? labels.meta,
                                    reasonKey: enabled
                                        ? null
                                        : Key(
                                            'discover_engagement_reason_${option.type.name}',
                                          ),
                                    off: !enabled,
                                    on: selected,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            _Radio(on: selected),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ExcludeSemantics(
                          child: _Week(heights: heights, on: selected),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Well extends StatelessWidget {
  const _Well({required this.icon, required this.on});
  final IconData icon;
  final bool on;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 250),
    width: 52,
    height: 52,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(17),
      color: on ? null : const Color(0xFFE9F4F2),
      gradient: on
          ? const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.teal, dsSky],
            )
          : null,
    ),
    child: Icon(icon, size: 26, color: on ? Colors.white : AppColors.teal),
  );
}

class _Meta extends StatelessWidget {
  const _Meta({
    required this.text,
    required this.off,
    required this.on,
    this.reasonKey,
  });
  final String text;
  final bool off;
  final bool on;
  final Key? reasonKey;

  @override
  Widget build(BuildContext context) {
    final fg = off ? dsMuted : AppColors.teal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        color: off
            ? const Color(0x4094A3B8)
            : on
            ? const Color(0xFFCCEFE9)
            : const Color(0xFFE2EEEC),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            off ? Icons.lock_outline_rounded : Icons.schedule_rounded,
            size: 14,
            color: fg,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              key: reasonKey,
              style: AppText.body.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.3,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.on});
  final bool on;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    width: 30,
    height: 30,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: on ? AppColors.teal : const Color(0xB3FFFFFF),
      border: Border.all(
        width: 2,
        color: on ? AppColors.teal : const Color(0xFF94A3B8),
      ),
    ),
    child: on
        ? const Icon(Icons.check_rounded, size: 17, color: Colors.white)
        : null,
  );
}

/// Seven bars (M-S) that grow in from the bottom, teal-to-sky when the card is chosen.
class _Week extends StatelessWidget {
  const _Week({required this.heights, required this.on});
  final List<int> heights;
  final bool on;

  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: 34,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < 7; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 700 + 60 * i),
                  curve: Curves.easeOutBack,
                  builder: (context, v, _) => Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      widthFactor: 1,
                      heightFactor: (heights[i] / 100 * v.clamp(0.0, 1.0))
                          .clamp(4 / 34, 1.0),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                            bottom: Radius.circular(3),
                          ),
                          color: on ? null : const Color(0x7364748B),
                          gradient: on
                              ? const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [dsSky, AppColors.teal],
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 5),
      Row(
        children: [
          for (var i = 0; i < 7; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: Text(
                _days[i],
                textAlign: TextAlign.center,
                style: AppText.body.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: dsMuted,
                ),
              ),
            ),
          ],
        ],
      ),
    ],
  );
}

/// Loading placeholder: three card-shaped shimmer blocks.
class EngagementSkeleton extends StatelessWidget {
  const EngagementSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final clock = DiscoverClock.of(context);
    return Semantics(
      label: AppLocalizations.of(context).loading,
      child: ValueListenableBuilder<double>(
        valueListenable: clock,
        builder: (context, t, _) {
          final x = -1 + 2 * ((t / 1400) % 1);
          Widget bar(double h, {double? w, double r = 10}) => Container(
            height: h,
            width: w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(r),
              gradient: LinearGradient(
                begin: Alignment(x - 1, 0),
                end: Alignment(x + 1, 0),
                colors: [
                  dsNavy.withValues(alpha: 0.07),
                  dsNavy.withValues(alpha: 0.15),
                  dsNavy.withValues(alpha: 0.07),
                ],
              ),
            ),
          );
          return Column(
            children: [
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DiscoverGlass(
                    radius: 26,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              bar(52, w: 52, r: 17),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    bar(18, w: 100),
                                    const SizedBox(height: 10),
                                    bar(12),
                                    const SizedBox(height: 10),
                                    bar(22, w: 150, r: 999),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          bar(34),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
