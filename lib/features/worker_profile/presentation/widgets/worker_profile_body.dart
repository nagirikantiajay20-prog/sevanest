import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart'
    show authSerif;
import 'package:sevanest_customer/features/service_discovery/presentation/engagement_labels.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/features/worker_profile/presentation/providers/worker_profile_providers.dart';
import 'package:sevanest_customer/features/worker_profile/presentation/widgets/review_tile.dart';
import 'package:sevanest_customer/features/worker_search/domain/worker_search.dart';
import 'package:sevanest_customer/features/worker_search/presentation/providers/worker_search_providers.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_page.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/worker_card.dart'
    show ratingText;
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// Scrolling content of the worker profile (design 5.3): ring avatar, stats, skills, languages,
/// availability and the latest reviews, each in a frosted section that rises in.
class WorkerProfileBody extends ConsumerWidget {
  const WorkerProfileBody({required this.worker, super.key});
  final WorkerSummary worker;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final title = worker.title;
    final reviewsAsync = ref.watch(workerReviewsProvider(worker.id));
    final preview = reviewsAsync.value?.items.take(2).toList() ?? const [];
    final months = worker.experienceMonths;
    final scale = ref.watch(ratingScaleMaxProvider).value ?? 5;
    final gradient = avatarGradientFor(worker.id);
    final skills = worker.categories.length > 1 || worker.name != null
        ? worker.categories
        : const <String>[];
    final fraction = worker.hasRating
        ? (worker.ratingAverage! / scale).clamp(0.0, 1.0)
        : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DiscoverRise(
            delayMs: 0,
            child: Column(
              children: [
                Center(
                  child: RingAvatar(
                    initials: workerInitials(worker.initials, title),
                    photoUrl: worker.photoUrl,
                    progress: fraction,
                    size: 124,
                    stroke: 5,
                    fontSize: 34,
                    fill: gradient,
                    tick: worker.verified,
                  ),
                ),
                const SizedBox(height: 14),
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: authSerif(32, 1.1),
                  ),
                ),
                if (worker.name != null && worker.categories.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    worker.categories.first,
                    textAlign: TextAlign.center,
                    style: AppText.body.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: dsText,
                    ),
                  ),
                ],
                if (worker.areas.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    worker.areas.join(', '),
                    textAlign: TextAlign.center,
                    style: AppText.body.copyWith(fontSize: 15, color: dsMuted),
                  ),
                ],
                if (worker.verified || worker.verificationPending) ...[
                  const SizedBox(height: 12),
                  _Pill(
                    label: worker.verified
                        ? l10n.verified
                        : l10n.workerVerificationInProgress,
                    icon: worker.verified ? Icons.check_rounded : null,
                    bg: worker.verified
                        ? const Color(0xFFD6EFEA)
                        : const Color(0xFFFEF3C7),
                    fg: worker.verified
                        ? const Color(0xFF0B5A53)
                        : const Color(0xFF8A4B06),
                  ),
                ],
                TextButton(
                  key: const Key('worker_verified_info_btn'),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, kMinTapTarget),
                    foregroundColor: AppColors.teal,
                    textStyle: AppText.body.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  onPressed: () => _showVerifiedSheet(context, l10n),
                  child: Text(l10n.workerVerifiedInfo),
                ),
              ],
            ),
          ),
          _Section(
            delayMs: 100,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  _stat(
                    worker.hasRating
                        ? ratingText(worker.ratingAverage!, scale)
                        : l10n.workerNew,
                    l10n.workerStatReviews(worker.ratingCount),
                    star: worker.hasRating,
                  ),
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: dsNavy.withValues(alpha: 0.14),
                  ),
                  _stat(
                    months == null
                        ? l10n.workerStatUnknown
                        : months >= 12
                        ? l10n.workerStatYears(months ~/ 12)
                        : l10n.workerStatMonths(months),
                    l10n.workerStatExperience,
                  ),
                ],
              ),
            ),
          ),
          if (skills.isNotEmpty)
            _Section(
              delayMs: 160,
              title: l10n.workerSkillsLabel,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [for (final s in skills) _SoftPill(s)],
              ),
            ),
          if (worker.languages.isNotEmpty)
            _Section(
              delayMs: 220,
              title: l10n.workerLanguagesLabel,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final l in worker.languages) _SoftPill(languageName(l)),
                ],
              ),
            ),
          if (worker.availability.isNotEmpty || worker.engagement != null)
            _Section(
              delayMs: 280,
              title: l10n.workerAvailabilityLabel,
              child: Column(
                children: [
                  if (worker.availability.isNotEmpty)
                    _fact(
                      l10n.workerAvailabilityLabel,
                      worker.availability
                          .map(
                            (a) => l10n.workerAvailableWindow(a.start, a.end),
                          )
                          .join('\n'),
                      last: worker.engagement == null,
                    ),
                  if (worker.engagement != null)
                    _fact(
                      l10n.workerEngagementLabel,
                      engagementLabels(l10n, worker.engagement!).name,
                      last: true,
                    ),
                ],
              ),
            ),
          _Section(
            delayMs: 340,
            title: l10n.reviewsTitle,
            trailing: worker.hasRating
                ? TextButton(
                    key: const Key('worker_reviews_all_btn'),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, kMinTapTarget),
                      foregroundColor: AppColors.teal,
                      textStyle: AppText.body.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onPressed: () => context.push(
                      Routes.path(Routes.workerReviews, {'id': worker.id}),
                    ),
                    child: Text(l10n.reviewsSeeAll),
                  )
                : null,
            child: preview.isNotEmpty
                ? Column(
                    children: [
                      for (final r in preview) ReviewTile(r, compact: true),
                    ],
                  )
                : reviewsAsync.hasError
                ? Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.reviewsLoadFailed,
                          style: AppText.body.copyWith(
                            fontSize: 15,
                            color: dsText,
                          ),
                        ),
                      ),
                      TextButton(
                        key: const Key('worker_reviews_retry_btn'),
                        onPressed: () =>
                            ref.invalidate(workerReviewsProvider(worker.id)),
                        child: Text(l10n.retry),
                      ),
                    ],
                  )
                : Text(
                    reviewsAsync.isLoading ? '' : l10n.reviewsEmpty,
                    style: AppText.body.copyWith(fontSize: 15, color: dsText),
                  ),
          ),
        ],
      ),
    );
  }

  static Widget _stat(String value, String label, {bool star = false}) =>
      Expanded(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: authSerif(28, 1.1),
                  ),
                ),
                if (star)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.star_rounded,
                      size: 24,
                      color: AppColors.amber,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: dsMuted,
              ),
            ),
          ],
        ),
      );

  static Widget _fact(String label, String value, {bool last = false}) =>
      Container(
        padding: EdgeInsets.fromLTRB(0, 10, 0, last ? 0 : 10),
        decoration: BoxDecoration(
          border: last
              ? null
              : Border(
                  bottom: BorderSide(color: dsNavy.withValues(alpha: 0.18)),
                ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 104,
              child: Text(
                label,
                style: AppText.body.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: dsMuted,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: AppText.body.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                  color: dsNavy,
                ),
              ),
            ),
          ],
        ),
      );

  void _showVerifiedSheet(BuildContext context, AppLocalizations l10n) =>
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        barrierColor: const Color(0x591B3354),
        elevation: 0,
        builder: (ctx) => DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xF5FFFFFF), Color(0xF5FAF8F5)],
            ),
            boxShadow: [
              BoxShadow(
                color: dsNavy.withValues(alpha: 0.25),
                blurRadius: 40,
                offset: const Offset(0, -16),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: dsNavy.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFD6EFEA),
                        ),
                        child: const Icon(
                          Icons.verified_user_outlined,
                          size: 24,
                          color: AppColors.teal,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.workerVerifiedSheetTitle,
                          style: authSerif(24, 1.15),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l10n.workerVerifiedSheetBody,
                    style: AppText.body.copyWith(
                      fontSize: 15.5,
                      height: 1.55,
                      color: dsText,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      key: const Key('worker_verified_sheet_close_btn'),
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: dsNavy,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: AppText.body.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: Text(l10n.workerGotIt),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

/// Frosted section that rises in, with a sheen sweeping across it.
class _Section extends StatelessWidget {
  const _Section({
    required this.child,
    required this.delayMs,
    this.title,
    this.trailing,
    this.padding = const EdgeInsets.all(16),
  });
  final Widget child;
  final double delayMs;
  final String? title;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 14),
    child: DiscoverRise(
      delayMs: delayMs,
      child: DiscoverGlass(
        radius: 26,
        child: Stack(
          children: [
            const SheenSweep(periodMs: 7000),
            Padding(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Semantics(
                              header: true,
                              child: Text(title!, style: authSerif(20, 1.2)),
                            ),
                          ),
                          ?trailing,
                        ],
                      ),
                    ),
                  child,
                ],
              ),
            ),
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
  });
  final String label;
  final Color bg;
  final Color fg;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5),
        ],
        Text(
          label,
          style: AppText.body.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: fg,
          ),
        ),
      ],
    ),
  );
}

class _SoftPill extends StatelessWidget {
  const _SoftPill(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 36),
    padding: const EdgeInsets.symmetric(horizontal: 14),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: const Color(0xBFFFFFFF),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: const Color(0xF2FFFFFF)),
      boxShadow: [
        BoxShadow(
          color: dsNavy.withValues(alpha: 0.08),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Text(
      label,
      style: AppText.body.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: dsNavy,
      ),
    ),
  );
}
