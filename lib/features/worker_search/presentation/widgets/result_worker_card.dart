import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart'
    show authSerif;
import 'package:sevanest_customer/features/service_discovery/presentation/engagement_labels.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/features/worker_search/domain/worker_search.dart';
import 'package:sevanest_customer/features/worker_search/presentation/providers/worker_search_providers.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_page.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/worker_card.dart'
    show ratingText;
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// Frosted result card of the "Find a worker" results list (design 5.1): rating ring, badges,
/// three stats, where / languages / availability, then View profile and Interview.
class ResultWorkerCard extends ConsumerWidget {
  const ResultWorkerCard({
    required this.worker,
    required this.bestMatch,
    required this.onView,
    required this.onInterview,
    this.trailing,
    super.key,
  });

  final WorkerSummary worker;

  /// First card of a default-ordered list gets the amber "Best match" ribbon.
  final bool bestMatch;
  final VoidCallback onView;

  /// Null disables Interview (the backend will not take requests for this worker).
  final VoidCallback? onInterview;
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scale = ref.watch(ratingScaleMaxProvider).value ?? 5;
    final title = worker.title;
    final gradient = avatarGradientFor(worker.id);
    final fraction = worker.hasRating
        ? (worker.ratingAverage! / scale).clamp(0.0, 1.0)
        : 0.0;
    final months = worker.experienceMonths;
    final window = worker.availability.firstOrNull;
    final rating = worker.hasRating
        ? ratingText(worker.ratingAverage!, scale)
        : l10n.workerNew;

    return DiscoverGlass(
      radius: 28,
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -40,
            width: 150,
            height: 150,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      gradient.first.withValues(alpha: 0.32),
                      gradient.first.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SheenSweep(),
          // The whole card opens the profile; the two buttons inside take their own taps.
          InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: onView,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, bestMatch ? 34 : 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          RingAvatar(
                            initials: workerInitials(worker.initials, title),
                            photoUrl: worker.photoUrl,
                            progress: fraction,
                            size: 68,
                            fill: gradient,
                            ringColors: worker.hasRating
                                ? const [AppColors.teal, dsSky]
                                : const [AppColors.amber],
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: -8,
                            child: Center(child: _RatingPill(label: rating)),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: authSerif(22, 1.15),
                              ),
                              const SizedBox(height: 7),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  if (worker.verified)
                                    _Badge(
                                      icon: Icons.check_rounded,
                                      label: l10n.verified,
                                      bg: AppColors.tealD6EFEA,
                                      fg: AppColors.teal0B5A53,
                                    )
                                  else if (worker.verificationPending)
                                    _Badge(
                                      label: l10n.workerVerificationInProgress,
                                      bg: AppColors.warnBg,
                                      fg: AppColors.orange8A4B06,
                                    ),
                                  if (worker.engagement != null)
                                    _Tag(
                                      engagementLabels(
                                        l10n,
                                        worker.engagement!,
                                      ).name,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      ?trailing,
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      _Stat(
                        value: rating,
                        star: worker.hasRating,
                        label: worker.hasRating
                            ? l10n.workerStatReviews(worker.ratingCount)
                            : l10n.reviewsEmpty,
                      ),
                      const SizedBox(width: 8),
                      _Stat(
                        value: months == null
                            ? l10n.workerStatUnknown
                            : months >= 12
                            ? l10n.workerStatYears(months ~/ 12)
                            : l10n.workerStatMonths(months),
                        label: l10n.workerStatExperience,
                      ),
                      const SizedBox(width: 8),
                      _Stat(
                        value: '${worker.areas.length}',
                        label: l10n.resultsAreasNear(worker.areas.length),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (worker.areas.isNotEmpty)
                    _Meta(Icons.place_outlined, worker.areas.join(', ')),
                  if (worker.languages.isNotEmpty)
                    _Meta(
                      Icons.notes_rounded,
                      worker.languages.map(languageName).join(' · '),
                    ),
                  if (window != null)
                    _Meta(
                      Icons.schedule_rounded,
                      l10n.workerAvailableWindow(window.start, window.end),
                    ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        flex: 11,
                        child: _ViewButton(
                          key: Key('worker_card_view_btn_${worker.id}'),
                          label: l10n.resultsViewProfile,
                          onPressed: onView,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 10,
                        child: _InterviewButton(
                          key: Key('worker_card_interview_btn_${worker.id}'),
                          label: l10n.resultsInterview,
                          onPressed: onInterview,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (bestMatch)
            Positioned(
              top: 0,
              left: 16,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 5, 12, 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.amber, AppColors.amber400],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.amber.withValues(alpha: 0.45),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 13,
                      color: AppColors.orange4A2C00,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      AppLocalizations.of(context).resultsSortBest,
                      style: AppText.body.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: AppColors.orange4A2C00,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RatingPill extends StatelessWidget {
  const _RatingPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(999),
      boxShadow: [
        BoxShadow(
          color: dsNavy.withValues(alpha: 0.2),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Text(
      label,
      style: AppText.body.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        height: 1.3,
        color: AppColors.teal,
      ),
    ),
  );
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.bg,
    required this.fg,
    this.icon,
  });
  final String label;
  final Color bg;
  final Color fg;
  final IconData? icon;

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

class _Tag extends StatelessWidget {
  const _Tag(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: dsNavy.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: AppText.body.copyWith(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: dsText,
      ),
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.star = false});
  final String value;
  final String label;
  final bool star;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.whiteA62x9E,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.whiteA95xF2),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value, style: authSerif(18, 1.1)),
                if (star)
                  const Padding(
                    padding: EdgeInsets.only(left: 3),
                    child: Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: AppColors.amber,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppText.body.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.3,
              color: dsMuted,
            ),
          ),
        ],
      ),
    ),
  );
}

class _Meta extends StatelessWidget {
  const _Meta(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 16, color: AppColors.teal),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: AppText.body.copyWith(
              fontSize: 13.5,
              height: 1.35,
              color: dsText,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ViewButton extends StatelessWidget {
  const _ViewButton({required this.label, required this.onPressed, super.key});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: dsNavy.withValues(alpha: 0.3),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Stack(
      children: [
        FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: dsNavy,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: AppText.body.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: Text(label),
        ),
        const Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            child: Stack(children: [SheenSweep(periodMs: 3400, band: 0.4)]),
          ),
        ),
      ],
    ),
  );
}

class _InterviewButton extends StatelessWidget {
  const _InterviewButton({
    required this.label,
    required this.onPressed,
    super.key,
  });
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(50),
      backgroundColor: AppColors.whiteA75xBF,
      foregroundColor: AppColors.teal,
      side: BorderSide(
        color: AppColors.teal.withValues(alpha: onPressed == null ? 0.25 : 0.5),
        width: 1.5,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: AppText.body.copyWith(
        fontSize: 14.5,
        fontWeight: FontWeight.w700,
      ),
    ),
    child: Text(label),
  );
}
