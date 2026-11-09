import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
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

/// Rounded tile: the short-lived photo link when there is one, else the worker's initials (the
/// category initial when the card has no name).
/// [verified] adds the teal tick (only from the backend verification status).
class WorkerAvatar extends StatelessWidget {
  const WorkerAvatar(
    this.worker, {
    this.radius = 28,
    this.verified = false,
    super.key,
  });
  final WorkerSummary worker;
  final double radius;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    final title = worker.title;
    final size = radius * 2;
    return ExcludeSemantics(
      child: SizedBox(
        width: size + (verified ? 6 : 0),
        height: size + (verified ? 6 : 0),
        child: Stack(
          children: [
            Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.tileWell,
                borderRadius: BorderRadius.circular(AppRadius.md),
                // Photo links expire, so they are only shown, never stored.
                image: worker.photoUrl == null
                    ? null
                    : DecorationImage(
                        image: ResizeImage(
                          NetworkImage(worker.photoUrl!),
                          width: 300,
                        ),
                        fit: BoxFit.cover,
                        onError: (_, _) {},
                      ),
              ),
              child: worker.photoUrl != null
                  ? null
                  : Text(
                      worker.initials ??
                          (title.isEmpty
                              ? '?'
                              : title.characters.first.toUpperCase()),
                      style: AppText.heading.copyWith(color: AppColors.teal),
                    ),
            ),
            if (verified)
              const Positioned(
                right: 0,
                bottom: 0,
                child: CircleAvatar(
                  radius: 10,
                  backgroundColor: AppColors.teal,
                  child: Icon(Icons.check, size: 13, color: AppColors.surface),
                ),
              ),
          ],
        ),
      ),
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
    final style = AppText.card.copyWith(fontSize: 13);
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

/// Result / shortlist card. The title is the worker's display name, or the category when the
/// backend sent none. Optional rows disappear when their data is missing. [trailing] is the heart.
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
    final title = worker.title;
    final window = worker.availability.firstOrNull;
    final chips = worker.categoryChips;
    final shown = chips.take(_maxChips).toList();
    Widget pill(String label) => Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.slateBg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(label, style: AppText.body.copyWith(fontSize: 12)),
    );
    return Material(
      color: AppColors.surface,
      elevation: 1,
      shadowColor: AppColors.navy.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: AppColors.hairline),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WorkerAvatar(worker, verified: worker.verified),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.heading,
                    ),
                    Text(
                      experienceLabel(l10n, worker.experienceMonths),
                      style: AppText.bodyLarge,
                    ),
                    if (worker.languages.isNotEmpty)
                      Text(
                        worker.languages.map(languageName).join(', '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body,
                      ),
                    if (worker.areas.isNotEmpty)
                      Text(
                        worker.areas.join(', '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body,
                      ),
                    if (window != null)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Icon(
                              Icons.circle,
                              size: 8,
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Flexible(
                            child: Text(
                              l10n.workerAvailableWindow(
                                window.start,
                                window.end,
                              ),
                              style: AppText.body,
                            ),
                          ),
                        ],
                      ),
                    if (shown.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          for (final c in shown) pill(c),
                          if (chips.length > _maxChips)
                            pill(l10n.workerMoreChip(chips.length - _maxChips)),
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
