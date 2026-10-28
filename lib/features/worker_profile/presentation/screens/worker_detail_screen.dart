import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/localization/failure_message.dart';
import 'package:sevanest_customer/core/widgets/sn_badge.dart';
import 'package:sevanest_customer/core/widgets/sn_bottom_sheet.dart';
import 'package:sevanest_customer/core/widgets/sn_button.dart';
import 'package:sevanest_customer/core/widgets/sn_card.dart';
import 'package:sevanest_customer/core/widgets/sn_states.dart';
import 'package:sevanest_customer/features/favourites/presentation/widgets/favourite_button.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/engagement_labels.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/requirement_draft_provider.dart';
import 'package:sevanest_customer/features/support/presentation/widgets/safety_actions.dart';
import 'package:sevanest_customer/features/worker_profile/presentation/providers/worker_profile_providers.dart';
import 'package:sevanest_customer/features/worker_profile/presentation/widgets/review_tile.dart';
import 'package:sevanest_customer/features/worker_search/domain/worker_search.dart';
import 'package:sevanest_customer/features/worker_search/presentation/providers/worker_search_providers.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/worker_card.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// Request interview from the profile or the shortlist: needs a requirement draft first.
Future<void> requestInterviewFor(
  BuildContext context,
  WidgetRef ref,
  String workerId,
) async {
  // An interview request carries the requirement, so there must be one.
  if (ref.read(requirementDraftProvider).isEmpty) {
    final l10n = AppLocalizations.of(context);
    final start = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.workerStartSearchTitle),
        content: Text(l10n.workerStartSearchBody),
        actions: [
          TextButton(
            key: const Key('worker_start_search_cancel_btn'),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            key: const Key('worker_start_search_btn'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.workerStartSearch),
          ),
        ],
      ),
    );
    if ((start ?? false) && context.mounted) {
      await context.push<Object?>(Routes.discoverCategory);
    }
    return;
  }
  await context.push<Object?>(
    '${Routes.interviewNew}?workerId=${Uri.encodeComponent(workerId)}',
  );
}

/// `/workers/:id` (module 05, screen 5.3). Shows only the allow-listed public card: no KYC, no
/// contact details, no account id.
class WorkerDetailScreen extends ConsumerWidget {
  const WorkerDetailScreen({required this.workerId, super.key});
  final String workerId;

  /// "Find another": refetch the list (the gone worker drops out) and go back to it.
  void _findAnother(BuildContext context, WidgetRef ref) {
    ref.invalidate(workerSearchProvider);
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.workers);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final detail = ref.watch(workerDetailProvider(workerId));
    final gone = detail.error is NotFoundFailure;
    final worker = detail.value;

    return Scaffold(
      backgroundColor: AppColors.canvasCool,
      appBar: AppBar(
        backgroundColor: AppColors.canvasCool,
        leading: IconButton(
          key: const Key('app_back_btn'),
          tooltip: l10n.back,
          icon: const Icon(Icons.chevron_left, size: 32),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(Routes.home),
        ),
        title: Text(l10n.workerProfileTitle),
        actions: [
          // Report / block (module 12): only for a worker that is still there.
          if (worker != null)
            SafetyMenuButton(
              workerId: workerId,
              onBlocked: () =>
                  context.canPop() ? context.pop() : context.go(Routes.workers),
            ),
        ],
      ),
      body: detail.when(
        loading: () => const SnSkeletonList(count: 3),
        error: (e, _) => gone
            ? SnEmptyState(
                title: l10n.workerUnavailableTitle,
                message: l10n.workerUnavailableBody,
                actionLabel: l10n.workerFindAnother,
                actionKey: const Key('worker_find_another_btn'),
                onAction: () => _findAnother(context, ref),
              )
            : e is NetworkFailure
            ? SnOfflineState(
                message: failureMessage(l10n, e),
                onRetry: () => ref.invalidate(workerDetailProvider(workerId)),
              )
            : SnErrorState(
                message: failureMessage(l10n, e),
                onRetry: () => ref.invalidate(workerDetailProvider(workerId)),
              ),
        data: (w) => _Body(worker: w),
      ),
      bottomNavigationBar: worker == null
          ? null
          : _StickyBar(
              workerId: workerId,
              canRequest: worker.canRequestInterview,
              onRequest: () => requestInterviewFor(context, ref, workerId),
            ),
    );
  }
}

/// Shortlist + Request interview, always in reach. A worker the backend will not take requests
/// for (`canRequestInterview` false) gets a disabled button and the reason above it.
class _StickyBar extends StatelessWidget {
  const _StickyBar({
    required this.workerId,
    required this.canRequest,
    required this.onRequest,
  });
  final String workerId;
  final bool canRequest;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: AppShadows.floating,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!canRequest) ...[
                Text(
                  l10n.workerCannotRequestReason,
                  key: const Key('worker_cannot_request_reason'),
                  style: AppText.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: FavouriteButton(
                      workerId: workerId,
                      keyName: 'worker_detail_fav_btn',
                      showLabel: true,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    flex: 3,
                    child: SnButton(
                      key: const Key('worker_request_interview_btn'),
                      label: l10n.workerRequestInterview,
                      variant: SnButtonVariant.deep,
                      onPressed: canRequest ? onRequest : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.trailing});
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => SnCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: AppText.heading)),
            ?trailing,
          ],
        ),
        const SizedBox(height: AppSpacing.s12),
        child,
      ],
    ),
  );
}

class _Body extends ConsumerWidget {
  const _Body({required this.worker});
  final WorkerSummary worker;

  Widget _fact(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 110, child: Text(label, style: AppText.meta)),
        Expanded(child: Text(value, style: AppText.bodyLarge)),
      ],
    ),
  );

  Widget _stat(String value, String label) => Expanded(
    child: Column(
      children: [
        Text(value, style: AppText.heading, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.xxs),
        Text(label, style: AppText.meta, textAlign: TextAlign.center),
      ],
    ),
  );

  void _showVerifiedSheet(BuildContext context, AppLocalizations l10n) =>
      showSnBottomSheet<void>(
        context,
        builder: (ctx) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.workerVerifiedSheetTitle, style: AppText.screenTitle),
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.workerVerifiedSheetBody, style: AppText.bodyLarge),
            const SizedBox(height: AppSpacing.md),
            SnButton(
              key: const Key('worker_verified_sheet_close_btn'),
              label: l10n.workerGotIt,
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final title = worker.title;
    final reviewsAsync = ref.watch(workerReviewsProvider(worker.id));
    final preview = reviewsAsync.value?.items.take(2).toList() ?? const [];
    final months = worker.experienceMonths;
    final scaleMax = ref.watch(ratingScaleMaxProvider).value ?? 5;

    final hasBadge = worker.verified || worker.verificationPending;
    final skills = worker.categories.length > 1 || worker.name != null
        ? worker.categories
        : const <String>[];

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      children: [
        // Hero
        Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.md,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(AppRadius.xxl),
            ),
          ),
          child: Column(
            children: [
              WorkerAvatar(worker, radius: 48, verified: worker.verified),
              const SizedBox(height: AppSpacing.s12),
              Text(title, style: AppText.title, textAlign: TextAlign.center),
              if (worker.name != null && worker.categories.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  worker.categories.first,
                  style: AppText.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ],
              if (worker.areas.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  worker.areas.join(', '),
                  style: AppText.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ],
              if (hasBadge) ...[
                const SizedBox(height: AppSpacing.s12),
                worker.verified
                    ? SnBadge(label: l10n.verified, tone: SnBadgeTone.success)
                    : SnBadge(
                        label: l10n.workerVerificationInProgress,
                        tone: SnBadgeTone.warning,
                      ),
              ],
              TextButton(
                key: const Key('worker_verified_info_btn'),
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, kMinTapTarget),
                ),
                onPressed: () => _showVerifiedSheet(context, l10n),
                child: Text(l10n.workerVerifiedInfo),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Stats (rating and experience; the backend has no jobs-done or repeat-customer data)
              SnCard(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.md,
                  horizontal: AppSpacing.sm,
                ),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      _stat(
                        worker.hasRating
                            ? ratingText(worker.ratingAverage!, scaleMax)
                            : l10n.workerNew,
                        l10n.workerStatReviews(worker.ratingCount),
                      ),
                      const VerticalDivider(width: 1),
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
              if (skills.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                _Section(
                  title: l10n.workerSkillsLabel,
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final s in skills)
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.slateBg,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.s12,
                              vertical: AppSpacing.xs + 2,
                            ),
                            child: Text(s, style: AppText.body),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              if (worker.languages.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                _Section(
                  title: l10n.workerLanguagesLabel,
                  child: Text(
                    worker.languages.map(languageName).join(', '),
                    style: AppText.bodyLarge,
                  ),
                ),
              ],
              if (worker.availability.isNotEmpty ||
                  worker.engagement != null) ...[
                const SizedBox(height: AppSpacing.md),
                _Section(
                  title: l10n.workerAvailabilityLabel,
                  child: Column(
                    children: [
                      if (worker.availability.isNotEmpty)
                        _fact(
                          l10n.workerAvailabilityLabel,
                          worker.availability
                              .map(
                                (a) =>
                                    l10n.workerAvailableWindow(a.start, a.end),
                              )
                              .join('\n'),
                        ),
                      if (worker.engagement != null)
                        _fact(
                          l10n.workerEngagementLabel,
                          engagementLabels(l10n, worker.engagement!).name,
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              _Section(
                title: l10n.reviewsTitle,
                trailing: worker.hasRating
                    ? TextButton(
                        key: const Key('worker_reviews_all_btn'),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(0, kMinTapTarget),
                        ),
                        onPressed: () => context.push(
                          Routes.path(Routes.workerReviews, {'id': worker.id}),
                        ),
                        child: Text(l10n.reviewsSeeAll),
                      )
                    : null,
                child: preview.isNotEmpty
                    ? Column(children: [for (final r in preview) ReviewTile(r)])
                    : reviewsAsync.hasError
                    ? Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.reviewsLoadFailed,
                              style: AppText.bodyLarge,
                            ),
                          ),
                          TextButton(
                            key: const Key('worker_reviews_retry_btn'),
                            onPressed: () => ref.invalidate(
                              workerReviewsProvider(worker.id),
                            ),
                            child: Text(l10n.retry),
                          ),
                        ],
                      )
                    : Text(
                        reviewsAsync.isLoading ? '' : l10n.reviewsEmpty,
                        style: AppText.bodyLarge,
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
