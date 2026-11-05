import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/core/widgets/async_value_view.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart'
    show authSerif;
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/features/worker_profile/domain/worker_review.dart';
import 'package:sevanest_customer/features/worker_profile/presentation/providers/worker_profile_providers.dart';
import 'package:sevanest_customer/features/worker_profile/presentation/widgets/review_tile.dart';
import 'package:sevanest_customer/features/worker_search/domain/worker_search.dart';
import 'package:sevanest_customer/features/worker_search/presentation/providers/worker_search_providers.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_page.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/paged_footer.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/worker_card.dart'
    show ratingText;
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';
import 'package:sevanest_customer/shared/models/paged_state.dart';

/// `/workers/:id/reviews` (module 05, screen 5.4): paginated, reviewer first name only.
class WorkerReviewsScreen extends ConsumerStatefulWidget {
  const WorkerReviewsScreen({required this.workerId, super.key});
  final String workerId;

  @override
  ConsumerState<WorkerReviewsScreen> createState() => _State();
}

class _State extends ConsumerState<WorkerReviewsScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 300) {
        ref.read(workerReviewsProvider(widget.workerId).notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _toProfile() => context.canPop()
      ? context.pop()
      : context.go(Routes.path(Routes.workerDetail, {'id': widget.workerId}));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = workerReviewsProvider(widget.workerId);
    final notifier = ref.read(provider.notifier);
    final worker = ref.watch(workerDetailProvider(widget.workerId)).value;
    return FindGlassPage(
      title: l10n.reviewsTitle,
      backLabel: l10n.back,
      onBack: () => context.canPop() ? context.pop() : context.go(Routes.home),
      body: AsyncValueView<PagedState<WorkerReview>>(
        value: ref.watch(provider),
        onRetry: notifier.refresh,
        isEmpty: (p) => p.items.isEmpty,
        empty: _Empty(name: worker?.title ?? '', onBack: _toProfile),
        data: (p) {
          loadMoreIfShort(_scroll, p, notifier.loadMore);
          final summary = worker != null && worker.hasRating ? worker : null;
          return RefreshIndicator(
            onRefresh: notifier.refresh,
            child: ListView(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
              children: [
                if (summary != null)
                  DiscoverRise(
                    delayMs: 0,
                    child: _Summary(
                      worker: summary,
                      breakdown: notifier.summary,
                    ),
                  ),
                const DiscoverRise(delayMs: 80, child: _PrivacyNote()),
                for (final (i, r) in p.items.indexed)
                  DiscoverRise(
                    delayMs: 140.0 + 70 * i.clamp(0, 6),
                    child: ReviewTile(r),
                  ),
                if (p.isLoadingMore) ...[const _Shimmer(), const _Shimmer()],
                PagedFooter(
                  page: p,
                  onRetry: notifier.loadMore,
                  retryKey: const Key('reviews_load_more_retry_btn'),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: Text(
                    p.canLoadMore
                        ? l10n.reviewsScrollMore
                        : l10n.reviewsAllLoaded,
                    textAlign: TextAlign.center,
                    style: AppText.body.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: dsMuted,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Navy summary card: average, stars, review count and who is being reviewed.
class _Summary extends ConsumerWidget {
  const _Summary({required this.worker, this.breakdown});
  final WorkerSummary worker;
  final ReviewSummary? breakdown;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scale = ref.watch(ratingScaleMaxProvider).value ?? 5;
    final avg = worker.ratingAverage!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [dsNavy, AppColors.actionDeepTeal],
        ),
        boxShadow: [
          BoxShadow(
            color: dsNavy.withValues(alpha: 0.34),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(30)),
              child: Stack(children: [SheenSweep(periodMs: 5000, band: 0.3)]),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                label: l10n.workerRatingSemantics(
                  ratingText(avg, scale),
                  worker.ratingCount,
                ),
                excludeSemantics: true,
                child: Row(
                  children: [
                    Text(
                      ratingText(avg, scale),
                      style: authSerif(
                        60,
                        1,
                      ).copyWith(color: AppColors.surface),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StarRow(
                            rating: avg,
                            scale: scale,
                            size: 21,
                            full: AppColors.amber400,
                            empty: AppColors.whiteA30x4D,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.workerStatReviews(worker.ratingCount),
                            style: AppText.body.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.surface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            [
                              worker.title,
                              if (worker.name != null &&
                                  worker.categories.isNotEmpty)
                                worker.categories.first,
                            ].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.body.copyWith(
                              fontSize: 13,
                              color: AppColors.whiteA80xCC,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (breakdown != null && breakdown!.count > 0) ...[
                const SizedBox(height: 18),
                for (final e in breakdown!.distribution.entries)
                  _BreakdownRow(
                    score: e.key,
                    count: e.value,
                    total: breakdown!.count,
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// One "5★ ▬▬▬ 29" line of the rating breakdown; the bar grows in.
class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.score,
    required this.count,
    required this.total,
  });
  final int score;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final label = AppLocalizations.of(
      context,
    ).reviewsBreakdownRow(score, count);
    final style = AppText.body.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: AppColors.surface,
    );
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(width: 30, child: Text('$score★', style: style)),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: total == 0 ? 0 : count / total),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, _) => LinearProgressIndicator(
                    value: v,
                    minHeight: 8,
                    backgroundColor: AppColors.whiteA15x26,
                    valueColor: const AlwaysStoppedAnimation(
                      AppColors.amber400,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 34,
              child: Text('$count', textAlign: TextAlign.end, style: style),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 14),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: BoxDecoration(
      color: AppColors.teal.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        const Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.teal),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            AppLocalizations.of(context).reviewsPrivacy,
            style: AppText.body.copyWith(
              fontSize: 13,
              height: 1.4,
              color: AppColors.actionDeepTeal,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Placeholder row shown while the next page of reviews loads.
class _Shimmer extends StatelessWidget {
  const _Shimmer();

  @override
  Widget build(BuildContext context) => Container(
    height: 92,
    margin: const EdgeInsets.only(top: 12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.whiteA90xE6),
      gradient: const LinearGradient(
        colors: [
          AppColors.whiteA35x59,
          AppColors.whiteA75xBF,
          AppColors.whiteA35x59,
        ],
      ),
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.name, required this.onBack});
  final String name;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: DiscoverRise(
          delayMs: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.pillActive, AppColors.surface],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: dsNavy.withValues(alpha: 0.14),
                      blurRadius: 30,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.star_border_rounded,
                  size: 46,
                  color: AppColors.teal,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.reviewsEmpty,
                textAlign: TextAlign.center,
                style: authSerif(26, 1.2),
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 290),
                child: Text(
                  l10n.reviewsEmptyBody(name),
                  textAlign: TextAlign.center,
                  style: AppText.body.copyWith(
                    fontSize: 15.5,
                    height: 1.5,
                    color: dsText,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              FilledButton(
                key: const Key('reviews_back_to_profile_btn'),
                onPressed: onBack,
                style: FilledButton.styleFrom(
                  backgroundColor: dsNavy,
                  minimumSize: const Size(0, 54),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  textStyle: AppText.body.copyWith(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Text(l10n.reviewsBackToProfile),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
