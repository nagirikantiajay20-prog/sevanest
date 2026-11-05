import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart'
    show authSerif;
import 'package:sevanest_customer/features/service_discovery/presentation/schedule_format.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/features/worker_profile/domain/worker_review.dart';
import 'package:sevanest_customer/features/worker_search/presentation/providers/worker_search_providers.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_page.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/worker_card.dart';

/// Five stars filled to [rating] / [scale] (halves included). Decorative: callers label the value.
class StarRow extends StatelessWidget {
  const StarRow({
    required this.rating,
    this.scale = 5,
    this.size = 14,
    this.empty = AppColors.skyCBD5E1A90,
    this.full = AppColors.amber,
    super.key,
  });
  final double rating;
  final int scale;
  final double size;
  final Color empty;
  final Color full;

  @override
  Widget build(BuildContext context) {
    final stars = (rating / scale * 5).clamp(0.0, 5.0);
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 5; i++)
            Icon(
              stars >= i + 0.75
                  ? Icons.star_rounded
                  : stars >= i + 0.25
                  ? Icons.star_half_rounded
                  : Icons.star_rounded,
              size: size,
              color: stars >= i + 0.25 ? full : empty,
            ),
        ],
      ),
    );
  }
}

/// One review: first name, date, rating and text. Nothing else about the reviewer.
/// [compact] drops the card (a profile section already is one) and separates rows by a dashed rule.
class ReviewTile extends ConsumerWidget {
  const ReviewTile(this.review, {this.compact = false, super.key});
  final WorkerReview review;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context).toString();
    final scale = ref.watch(ratingScaleMaxProvider).value ?? 5;
    final rating = ratingText(review.rating, scale);
    final name = review.reviewerFirstName;
    final date = formatDate(review.date, locale);
    final gradient = avatarGradientFor(name);

    final stars = Semantics(
      label: rating,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            rating,
            style: AppText.body.copyWith(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: dsNavy,
            ),
          ),
          const SizedBox(height: 2),
          StarRow(rating: review.rating, scale: scale, size: 13),
        ],
      ),
    );

    final head = Row(
      children: [
        if (!compact) ...[
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradient,
              ),
              border: Border.all(color: AppColors.surface, width: 2),
              boxShadow: [
                BoxShadow(
                  color: dsNavy.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              name.isEmpty ? '?' : name.characters.first.toUpperCase(),
              style: AppText.body.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.surface,
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.isEmpty ? date : name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.body.copyWith(
                  fontSize: compact ? 15 : 15.5,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  color: dsNavy,
                ),
              ),
              if (name.isNotEmpty && !compact)
                Text(
                  date,
                  style: AppText.body.copyWith(
                    fontSize: 12.5,
                    height: 1.3,
                    color: dsMuted,
                  ),
                ),
            ],
          ),
        ),
        stars,
      ],
    );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        head,
        if (review.text != null) ...[
          const SizedBox(height: 8),
          Text(
            review.text!,
            style: AppText.body.copyWith(
              fontSize: 14.5,
              height: 1.5,
              color: dsText,
            ),
          ),
        ],
      ],
    );

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: dsNavy.withValues(alpha: 0.12)),
          ),
        ),
        child: body,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: DiscoverGlass(
        radius: 24,
        child: Stack(
          children: [
            const Positioned(
              left: 0,
              top: 14,
              bottom: 14,
              width: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.horizontal(
                    right: Radius.circular(4),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.teal, dsSky],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 12,
              top: 2,
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: Text(
                    '“',
                    style: authSerif(
                      64,
                      1,
                    ).copyWith(color: AppColors.teal.withValues(alpha: 0.1)),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
              child: body,
            ),
          ],
        ),
      ),
    );
  }
}
