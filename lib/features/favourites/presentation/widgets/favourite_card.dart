import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart'
    show authSerif;
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/features/worker_search/domain/worker_search.dart';
import 'package:sevanest_customer/features/worker_search/presentation/providers/worker_search_providers.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_page.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_parts.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/worker_card.dart'
    show experienceLabel, ratingText;
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// A shortlisted worker (design 6.1): frosted card with a colour glow, name, badges, the heart,
/// rating and areas, then Request interview. [onInterview] null disables it and says why.
class FavouriteCard extends ConsumerWidget {
  const FavouriteCard({
    required this.worker,
    required this.heart,
    required this.onOpen,
    required this.onInterview,
    super.key,
  });

  final WorkerSummary worker;
  final Widget heart;
  final VoidCallback onOpen;
  final VoidCallback? onInterview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scale = ref.watch(ratingScaleMaxProvider).value ?? 5;
    final gradient = avatarGradientFor(worker.id);
    final category = worker.categories.firstOrNull;
    final metaStyle = AppText.body.copyWith(
      fontSize: 13.5,
      height: 1.35,
      color: dsText,
    );
    final facts = [
      if (worker.hasRating) l10n.workerStatReviews(worker.ratingCount),
      if (worker.experienceMonths != null)
        experienceLabel(l10n, worker.experienceMonths),
    ];
    final strong = metaStyle.copyWith(
      fontWeight: FontWeight.w700,
      color: dsNavy,
    );

    return DiscoverGlass(
      radius: 28,
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -40,
            width: 140,
            height: 140,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      gradient.first.withValues(alpha: 0.4),
                      gradient.first.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SheenSweep(periodMs: 7000),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Only the identity row opens the profile; the heart and the button take their own taps.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: onOpen,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GlassAvatar(
                              title: worker.title,
                              initials: worker.initials,
                              photoUrl: worker.photoUrl,
                              gradient: gradient,
                              size: 58,
                              fontSize: 19,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    worker.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: authSerif(21, 1.15),
                                  ),
                                  const SizedBox(height: 7),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      if (worker.verified)
                                        _Pill(
                                          label: l10n.verified,
                                          icon: Icons.check_rounded,
                                          bg: AppColors.tealD6EFEA,
                                          fg: AppColors.teal0B5A53,
                                        )
                                      else if (worker.verificationPending)
                                        _Pill(
                                          label:
                                              l10n.workerVerificationInProgress,
                                          bg: AppColors.warnBg,
                                          fg: AppColors.orange8A4B06,
                                        ),
                                      if (category != null)
                                        _Pill(
                                          label: category,
                                          bg: dsNavy.withValues(alpha: 0.07),
                                          fg: dsText,
                                          weight: FontWeight.w600,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    heart,
                  ],
                ),
                const SizedBox(height: 12),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: worker.hasRating
                            ? ratingText(worker.ratingAverage!, scale)
                            : l10n.workerNew,
                        style: strong,
                      ),
                      if (worker.hasRating)
                        const WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Padding(
                            padding: EdgeInsets.only(left: 2),
                            child: Icon(
                              Icons.star_rounded,
                              size: 15,
                              color: AppColors.amber,
                            ),
                          ),
                        ),
                      if (facts.isNotEmpty)
                        TextSpan(text: ' · ${facts.join(' · ')}'),
                    ],
                  ),
                  style: metaStyle,
                ),
                if (worker.areas.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(worker.areas.join(', '), style: metaStyle),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  height: 50,
                  child: FilledButton(
                    key: Key('favs_request_interview_${worker.id}'),
                    onPressed: onInterview,
                    style: FilledButton.styleFrom(
                      backgroundColor: dsNavy,
                      disabledBackgroundColor: AppColors.slate400Light,
                      foregroundColor: AppColors.surface,
                      disabledForegroundColor: AppColors.surface,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: AppText.body.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Text(l10n.favsRequestInterview),
                  ),
                ),
                if (onInterview == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      l10n.workerCannotRequestReason,
                      key: Key('favs_cannot_request_${worker.id}'),
                      textAlign: TextAlign.center,
                      style: AppText.body.copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.orange8A4B06,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A shortlisted worker who is no longer visible: only the tag and the heart remain.
class UnavailableFavouriteCard extends StatelessWidget {
  const UnavailableFavouriteCard({
    required this.heart,
    required this.onTap,
    super.key,
  });
  final Widget heart;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => DiscoverGlass(
    radius: 28,
    child: InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.hairline,
              ),
              child: const Icon(
                Icons.person_off_outlined,
                size: 26,
                color: AppColors.slate400,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  key: const Key('worker_unavailable_tag'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.hairline,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    AppLocalizations.of(context).workerUnavailableTag,
                    style: AppText.body.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: dsMuted,
                    ),
                  ),
                ),
              ),
            ),
            heart,
          ],
        ),
      ),
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.bg,
    required this.fg,
    this.icon,
    this.weight = FontWeight.w700,
  });
  final String label;
  final Color bg;
  final Color fg;
  final IconData? icon;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            label,
            style: AppText.body.copyWith(
              fontSize: 12,
              fontWeight: weight,
              height: 1.3,
              color: fg,
            ),
          ),
        ),
      ],
    ),
  );
}
