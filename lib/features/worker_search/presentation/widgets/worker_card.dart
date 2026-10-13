import 'package:flutter/material.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/core/widgets/sn_badge.dart';
import 'package:sevanest_customer/features/worker_search/domain/worker_search.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// Result card. The backend sends no name, so the title is the category; step 4.5 refines this.
class WorkerCard extends StatelessWidget {
  const WorkerCard({required this.worker, required this.onTap, super.key});

  final WorkerSummary worker;
  final VoidCallback onTap;

  String _experience(AppLocalizations l) {
    final m = worker.experienceMonths;
    if (m == null) return l.workerExperienceUnknown;
    return m >= 12
        ? l.workerExperienceYears(m ~/ 12)
        : l.workerExperienceMonths(m);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final title = worker.categories.isEmpty ? '' : worker.categories.first;
    final window = worker.availability.firstOrNull;
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
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.hairline,
                // Photo links are short-lived and only shown, never stored.
                foregroundImage: worker.photoUrl == null
                    ? null
                    : NetworkImage(worker.photoUrl!),
                child: Text(
                  title.isEmpty ? '?' : title.characters.first.toUpperCase(),
                ),
              ),
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
                    Text(_experience(l10n), style: text.bodyMedium),
                    if (worker.languages.isNotEmpty)
                      Text(
                        worker.languages.map(languageName).join(', '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall,
                      ),
                    if (window != null)
                      Text(
                        l10n.workerAvailableWindow(window.start, window.end),
                        style: text.bodySmall,
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (worker.verified)
                          SnBadge(
                            label: l10n.verified,
                            tone: SnBadgeTone.success,
                          ),
                        worker.hasRating
                            ? Semantics(
                                label: l10n.workerRatingSemantics(
                                  worker.ratingAverage!.toStringAsFixed(1),
                                  worker.ratingCount,
                                ),
                                excludeSemantics: true,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      size: 16,
                                      color: AppColors.amber,
                                    ),
                                    Text(
                                      ' ${worker.ratingAverage!.toStringAsFixed(1)} (${worker.ratingCount})',
                                      style: text.bodySmall,
                                    ),
                                  ],
                                ),
                              )
                            : Text(l10n.workerNew, style: text.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
