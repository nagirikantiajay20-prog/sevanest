import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/core/widgets/sn_badge.dart';
import 'package:sevanest_customer/features/worker_search/domain/worker_search.dart';
import 'package:sevanest_customer/features/worker_search/presentation/providers/worker_search_providers.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// "5 yrs experience", "8 months experience" or "Experience not listed".
String experienceLabel(AppLocalizations l, int? months) {
  if (months == null) return l.workerExperienceUnknown;
  return months >= 12
      ? l.workerExperienceYears(months ~/ 12)
      : l.workerExperienceMonths(months);
}

/// Round avatar: the short-lived photo link when there is one, else the category initial.
class WorkerAvatar extends StatelessWidget {
  const WorkerAvatar(this.worker, {this.radius = 28, super.key});
  final WorkerSummary worker;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final title = worker.categories.isEmpty ? '' : worker.categories.first;
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.hairline,
      // Photo links expire, so they are only shown, never stored.
      foregroundImage: worker.photoUrl == null
          ? null
          : NetworkImage(worker.photoUrl!),
      child: Text(title.isEmpty ? '?' : title.characters.first.toUpperCase()),
    );
  }
}

/// "4.6", or "4.6/10" when the backend's scale is not the usual five.
String ratingText(double value, int scaleMax) =>
    '${value.toStringAsFixed(1)}${scaleMax == 5 ? '' : '/$scaleMax'}';

/// "★ 4.6 (23)" or "New" when the worker has no reviews yet.
class RatingLabel extends ConsumerWidget {
  const RatingLabel(this.worker, {super.key});
  final WorkerSummary worker;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final style = Theme.of(context).textTheme.bodySmall;
    if (!worker.hasRating) return Text(l10n.workerNew, style: style);
    final avg = ratingText(
      worker.ratingAverage!,
      ref.watch(ratingScaleMaxProvider).value ?? 5,
    );
    return Semantics(
      label: l10n.workerRatingSemantics(avg, worker.ratingCount),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 16, color: AppColors.amber),
          Flexible(
            child: Text(
              ' $avg (${worker.ratingCount})',
              style: style,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Result / shortlist card. The backend sends no name, so the title is the category. Optional
/// rows disappear when their data is missing. [trailing] is the heart.
class WorkerCard extends StatelessWidget {
  const WorkerCard({
    required this.worker,
    required this.onTap,
    this.trailing,
    super.key,
  });

  final WorkerSummary worker;
  final VoidCallback onTap;
  final Widget? trailing;

  static const _maxChips = 3;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final title = worker.categories.isEmpty ? '' : worker.categories.first;
    final window = worker.availability.firstOrNull;
    final chips = worker.categories.skip(1).toList();
    final shown = chips.take(_maxChips).toList();
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WorkerAvatar(worker),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleMedium,
                    ),
                    Text(
                      experienceLabel(l10n, worker.experienceMonths),
                      style: text.bodyMedium,
                    ),
                    if (worker.languages.isNotEmpty)
                      Text(
                        worker.languages.map(languageName).join(', '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall,
                      ),
                    if (worker.areas.isNotEmpty)
                      Text(
                        worker.areas.join(', '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall,
                      ),
                    if (window != null)
                      Text(
                        l10n.workerAvailableWindow(window.start, window.end),
                        style: text.bodySmall,
                      ),
                    if (shown.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          for (final c in shown)
                            Chip(
                              label: Text(c),
                              visualDensity: VisualDensity.compact,
                            ),
                          if (chips.length > _maxChips)
                            Chip(
                              label: Text(
                                l10n.workerMoreChip(chips.length - _maxChips),
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Verified styling comes only from the backend status.
                        if (worker.verified)
                          SnBadge(
                            label: l10n.verified,
                            tone: SnBadgeTone.success,
                          ),
                        RatingLabel(worker),
                      ],
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}
