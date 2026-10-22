import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/core/widgets/sn_bottom_sheet.dart';
import 'package:sevanest_customer/core/widgets/sn_button.dart';
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
) => showSnBottomSheet<WorkerFilters>(
  context,
  builder: (_) => _FilterSheet(current),
);

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet(this.initial);
  final WorkerFilters initial;

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late AvailabilityFilter? _availability = widget.initial.availability;
  late String? _language = widget.initial.language;
  late int? _experience = widget.initial.minExperienceMonths;
  late int? _rating = widget.initial.minRating;
  late WorkerSort? _sort = widget.initial.sort;

  String _availabilityLabel(AppLocalizations l, AvailabilityFilter a) =>
      switch (a) {
        AvailabilityFilter.morning => l.filterMorning,
        AvailabilityFilter.afternoon => l.filterAfternoon,
        AvailabilityFilter.evening => l.filterEvening,
      };

  /// A tapped chip selects; tapping the selected one clears it.
  Widget _chip<T>({
    required Key key,
    required String label,
    required T value,
    required T? current,
    required ValueChanged<T?> onChanged,
  }) => ChoiceChip(
    key: key,
    label: Text(label),
    selected: current == value,
    showCheckmark: true,
    checkmarkColor: AppColors.teal,
    selectedColor: AppColors.tealWash,
    backgroundColor: AppColors.surface,
    labelStyle: AppText.label.copyWith(
      fontSize: 14,
      color: current == value ? AppColors.teal : AppColors.brandInk,
    ),
    shape: StadiumBorder(
      side: BorderSide(
        color: current == value ? AppColors.teal : AppColors.hairline,
      ),
    ),
    onSelected: (on) => setState(() => onChanged(on ? value : null)),
  );

  Widget _section(String title, List<Widget> chips) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(
          top: AppSpacing.md,
          bottom: AppSpacing.sm,
        ),
        child: Text(title, style: AppText.heading.copyWith(fontSize: 16)),
      ),
      Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: chips),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scale = ref.watch(ratingScaleMaxProvider).value ?? 5;
    // Two thresholds on the backend's scale: 60% and 80% (3+ and 4+ out of 5).
    final ratings = {(scale * 0.6).ceil(), (scale * 0.8).ceil()};
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(l10n.filterTitle, style: AppText.screenTitle),
              ),
              IconButton(
                key: const Key('filter_close_btn'),
                tooltip: l10n.discoverClose,
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          _section(l10n.filterAvailability, [
            for (final a in AvailabilityFilter.values)
              _chip(
                key: Key('filter_availability_${a.name}'),
                label: _availabilityLabel(l10n, a),
                value: a,
                current: _availability,
                onChanged: (v) => _availability = v,
              ),
          ]),
          _section(l10n.filterLanguage, [
            for (final e in workerLanguages.entries)
              _chip(
                key: Key('filter_language_${e.key}'),
                label: e.value,
                value: e.key,
                current: _language,
                onChanged: (v) => _language = v,
              ),
          ]),
          _section(l10n.filterExperience, [
            for (final m in _experienceMonths)
              _chip(
                key: Key('filter_experience_$m'),
                label: l10n.filterExperienceYears(m ~/ 12),
                value: m,
                current: _experience,
                onChanged: (v) => _experience = v,
              ),
          ]),
          _section(l10n.filterRating, [
            for (final r in ratings)
              _chip(
                key: Key('filter_rating_$r'),
                label: l10n.filterRatingMin(scale == 5 ? '$r' : '$r/$scale'),
                value: r,
                current: _rating,
                onChanged: (v) => _rating = v,
              ),
          ]),
          _section(l10n.filterSort, [
            _chip(
              key: const Key('filter_sort_rating'),
              label: l10n.filterSortRating,
              value: WorkerSort.highestRated,
              current: _sort,
              onChanged: (v) => _sort = v,
            ),
          ]),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: SnButton(
                  key: const Key('filter_reset_btn'),
                  label: l10n.filterReset,
                  variant: SnButtonVariant.secondary,
                  onPressed: () => setState(() {
                    _availability = null;
                    _language = null;
                    _experience = null;
                    _rating = null;
                    _sort = null;
                  }),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: SnButton(
                  key: const Key('filter_apply_btn'),
                  label: l10n.filterApply,
                  onPressed: () => Navigator.of(context).pop(
                    WorkerFilters(
                      availability: _availability,
                      language: _language,
                      minExperienceMonths: _experience,
                      minRating: _rating,
                      sort: _sort,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
