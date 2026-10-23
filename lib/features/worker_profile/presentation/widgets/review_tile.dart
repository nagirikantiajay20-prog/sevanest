import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/schedule_format.dart';
import 'package:sevanest_customer/features/worker_profile/domain/worker_review.dart';
import 'package:sevanest_customer/features/worker_search/presentation/providers/worker_search_providers.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/worker_card.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// One review: first name, date, rating and text. Nothing else about the reviewer.
class ReviewTile extends ConsumerWidget {
  const ReviewTile(this.review, {super.key});
  final WorkerReview review;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toString();
    // Design: soft quote card with a teal rule on the left.
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.canvasCool,
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
        border: Border(left: BorderSide(color: AppColors.teal, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, size: 16, color: AppColors.amber),
              Text(
                ' ${ratingText(review.rating, ref.watch(ratingScaleMaxProvider).value ?? 5)}  ',
              ),
              Expanded(
                child: Text(
                  review.reviewerFirstName.isEmpty
                      ? formatDate(review.date, locale)
                      : l10n.reviewByline(
                          review.reviewerFirstName,
                          formatDate(review.date, locale),
                        ),
                  style: text.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (review.text != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(review.text!, style: text.bodyMedium),
          ],
        ],
      ),
    );
  }
}
