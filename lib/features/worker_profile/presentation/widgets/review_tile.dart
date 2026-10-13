import 'package:flutter/material.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/schedule_format.dart';
import 'package:sevanest_customer/features/worker_profile/domain/worker_review.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// One review: first name, date, rating and text. Nothing else about the reviewer.
class ReviewTile extends StatelessWidget {
  const ReviewTile(this.review, {super.key});
  final WorkerReview review;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toString();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, size: 16, color: AppColors.amber),
              Text(' ${review.rating.toStringAsFixed(1)}  '),
              Expanded(
                child: Text(
                  l10n.reviewByline(
                    review.reviewerFirstName,
                    formatDate(review.date, locale),
                  ),
                  style: text.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (review.text != null) Text(review.text!, style: text.bodyMedium),
        ],
      ),
    );
  }
}
