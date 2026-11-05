import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/features/authentication/presentation/screens/splash_screen.dart'
    show splashHoldProvider;
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/motion.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart'
    show dsMuted, dsNavy, dsText;
import 'package:sevanest_customer/features/worker_search/domain/worker_search.dart';
import 'package:sevanest_customer/features/worker_search/presentation/providers/worker_search_providers.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// Minimum-experience choices, in months (null = any).
const _experienceMonths = [12, 36, 60];

/// Opens the filter sheet. Returns the filters to apply, or null when closed without applying
/// (unsaved edits are discarded).
Future<WorkerFilters?> showFilterSheet(
  BuildContext context,
  WorkerFilters current,
) => showModalBottomSheet<WorkerFilters>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  barrierColor: AppColors.sky1B3354A42,
  elevation: 0,
  builder: (_) => _FilterSheet(current),
);

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet(this.initial);
  final WorkerFilters initial;

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet>
    with SingleTickerProviderStateMixin {
  late final _clock = ScreenClock(
    this,
    motion: ref.read(splashHoldProvider) > Duration.zero,
  );
  late AvailabilityFilter? _availability = widget.initial.availability;
  late String? _language = widget.initial.language;
  late int? _experience = widget.initial.minExperienceMonths;
  late int? _rating = widget.initial.minRating;
  late WorkerSort? _sort = widget.initial.sort;

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  WorkerFilters get _draft => WorkerFilters(
    availability: _availability,
    language: _language,
    minExperienceMonths: _experience,
    minRating: _rating,
    sort: _sort,
  );

  int get _active => _draft.count;

  String _availabilityLabel(AppLocalizations l, AvailabilityFilter a) =>
      switch (a) {
        AvailabilityFilter.morning => l.filterMorning,
        AvailabilityFilter.afternoon => l.filterAfternoon,
        AvailabilityFilter.evening => l.filterEvening,
      };

  static IconData _availabilityIcon(AvailabilityFilter a) => switch (a) {
    AvailabilityFilter.morning => Icons.wb_twilight_rounded,
    AvailabilityFilter.afternoon => Icons.wb_sunny_outlined,
    AvailabilityFilter.evening => Icons.nightlight_outlined,
  };

  /// A tapped chip selects; tapping the selected one clears it.
  Widget _chip<T>({
    required Key key,
    required String label,
    required T value,
    required T? current,
    required ValueChanged<T?> onChanged,
    IconData? icon,
  }) => FilterChoice(
    key: key,
    label: label,
    icon: icon,
    selected: current == value,
    onTap: () => setState(() => onChanged(current == value ? null : value)),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scale = ref.watch(ratingScaleMaxProvider).value ?? 5;
    // Two thresholds on the backend's scale: 60% and 80% (3+ and 4+ out of 5).
    final ratings = {(scale * 0.6).ceil(), (scale * 0.8).ceil()};
    final active = _active;
    final media = MediaQuery.of(context);
    // Live "Show N workers": the requirement plus the unsaved draft; falls back to a plain label
    // while loading or if the count fails.
    final base = ref.watch(workerQueryProvider);
    final total = base == null
        ? null
        : ref.watch(workerCountProvider(base.withFilters(_draft))).value;

    Widget section(String title, String sub, List<Widget> chips) => _Section(
      title: title,
      sub: sub,
      child: Wrap(spacing: 10, runSpacing: 10, children: chips),
    );

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: media.size.height * 0.88),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.whiteA97xF7, AppColors.whiteFAF8F5A97],
          ),
          boxShadow: [
            BoxShadow(
              color: dsNavy.withValues(alpha: 0.28),
              blurRadius: 44,
              offset: const Offset(0, -18),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              margin: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                color: dsNavy.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Semantics(
                            header: true,
                            child: Text(
                              l10n.filterTitle,
                              style: authSerif(26, 1.2),
                            ),
                          ),
                        ),
                        if (active > 0) ...[
                          const SizedBox(width: 10),
                          _CountBadge(
                            key: const Key('filter_active_badge'),
                            count: active,
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: IconButton(
                      key: const Key('filter_close_btn'),
                      tooltip: l10n.discoverClose,
                      style: IconButton.styleFrom(
                        backgroundColor: dsNavy.withValues(alpha: 0.07),
                      ),
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 22,
                        color: dsNavy,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    section(
                      l10n.filterAvailability,
                      l10n.filterAvailabilitySub,
                      [
                        for (final a in AvailabilityFilter.values)
                          _chip(
                            key: Key('filter_availability_${a.name}'),
                            label: _availabilityLabel(l10n, a),
                            icon: _availabilityIcon(a),
                            value: a,
                            current: _availability,
                            onChanged: (v) => _availability = v,
                          ),
                      ],
                    ),
                    section(l10n.filterLanguage, l10n.filterLanguageSub, [
                      for (final e in workerLanguages.entries)
                        _chip(
                          key: Key('filter_language_${e.key}'),
                          label: e.value,
                          value: e.key,
                          current: _language,
                          onChanged: (v) => _language = v,
                        ),
                    ]),
                    section(l10n.filterExperience, l10n.filterExperienceSub, [
                      for (final m in _experienceMonths)
                        _chip(
                          key: Key('filter_experience_$m'),
                          label: l10n.filterExperienceYears(m ~/ 12),
                          value: m,
                          current: _experience,
                          onChanged: (v) => _experience = v,
                        ),
                    ]),
                    section(l10n.filterRating, l10n.filterRatingSub, [
                      for (final r in ratings)
                        _chip(
                          key: Key('filter_rating_$r'),
                          label: '${scale == 5 ? '$r' : '$r/$scale'}+ ★',
                          value: r,
                          current: _rating,
                          onChanged: (v) => _rating = v,
                        ),
                    ]),
                    section(l10n.filterSort, l10n.filterSortSub, [
                      _chip(
                        key: const Key('filter_sort_bestMatch'),
                        label: l10n.filterSortBest,
                        value: WorkerSort.bestMatch,
                        current: _sort,
                        onChanged: (v) => _sort = v,
                      ),
                      _chip(
                        key: const Key('filter_sort_rating'),
                        label: l10n.filterSortRating,
                        value: WorkerSort.highestRated,
                        current: _sort,
                        onChanged: (v) => _sort = v,
                      ),
                      _chip(
                        key: const Key('filter_sort_mostExperienced'),
                        label: l10n.filterSortExperienced,
                        value: WorkerSort.mostExperienced,
                        current: _sort,
                        onChanged: (v) => _sort = v,
                      ),
                    ]),
                  ],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.whiteA70xB3,
                border: Border(
                  top: BorderSide(color: dsNavy.withValues(alpha: 0.1)),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  14,
                  20,
                  22 + media.padding.bottom,
                ),
                child: Row(
                  children: [
                    OutlinedButton(
                      key: const Key('filter_reset_btn'),
                      onPressed: active == 0
                          ? null
                          : () => setState(() {
                              _availability = null;
                              _language = null;
                              _experience = null;
                              _rating = null;
                              _sort = null;
                            }),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 56),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        foregroundColor: dsNavy,
                        backgroundColor: AppColors.surface,
                        side: BorderSide(
                          color: dsNavy.withValues(
                            alpha: active == 0 ? 0.12 : 0.25,
                          ),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        textStyle: AppText.body.copyWith(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: Text(l10n.filterReset),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AuthCta(
                        key: const Key('filter_apply_btn'),
                        clock: _clock,
                        label: total != null
                            ? l10n.filterShowCount(total)
                            : active == 0
                            ? l10n.filterShowAll
                            : l10n.filterShowResults,
                        loadingLabel: l10n.filterShowResults,
                        loading: false,
                        breathe: true,
                        showArrow: false,
                        radius: 18,
                        height: 56,
                        onPressed: () => Navigator.of(context).pop(_draft),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Heading + caption + the chips of one filter group, closed by a dashed rule.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.sub, required this.child});
  final String title;
  final String sub;
  final Widget child;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: const _DashedRule(),
    child: Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 10,
            children: [
              Text(title, style: authSerif(19, 1.2)),
              Text(
                sub,
                style: AppText.body.copyWith(fontSize: 12.5, color: dsMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    ),
  );
}

class _DashedRule extends CustomPainter {
  const _DashedRule();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dsNavy.withValues(alpha: 0.16)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 7) {
      canvas.drawLine(
        Offset(x, size.height - 0.5),
        Offset((x + 4).clamp(0, size.width), size.height - 0.5),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedRule old) => false;
}

/// Pill choice: ticks in with a springy scale and teal wash when selected.
class FilterChoice extends StatelessWidget {
  const FilterChoice({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    super.key,
  });
  final String label;
  final bool selected;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    inMutuallyExclusiveGroup: true,
    selected: selected,
    checked: selected,
    button: true,
    label: label,
    excludeSemantics: true,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected
            ? AppColors.teal.withValues(alpha: 0.12)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected ? AppColors.teal : dsNavy.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: AppColors.teal.withValues(alpha: 0.2),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 16,
                      color: selected ? AppColors.teal : dsNavy,
                    ),
                    const SizedBox(width: 7),
                  ],
                  Text(
                    label,
                    style: AppText.body.copyWith(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: selected ? AppColors.teal0B5A53 : dsText,
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    child: selected
                        ? const Padding(
                            padding: EdgeInsets.only(left: 7),
                            child: Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: AppColors.teal,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Active-filter count next to the title; pops in when it appears.
class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count, super.key});
  final int count;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    key: ValueKey(count),
    tween: Tween(begin: 0.7, end: 1),
    duration: const Duration(milliseconds: 400),
    curve: Curves.elasticOut,
    builder: (context, s, child) => Transform.scale(scale: s, child: child),
    child: Container(
      constraints: const BoxConstraints(minWidth: 24),
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [AppColors.teal, AppColors.sky400],
        ),
      ),
      child: Text(
        '$count',
        style: AppText.body.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          height: 1,
          color: AppColors.surface,
        ),
      ),
    ),
  );
}
