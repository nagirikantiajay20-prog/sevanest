import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/localization/failure_message.dart';
import 'package:sevanest_customer/core/widgets/sn_badge.dart';
import 'package:sevanest_customer/core/widgets/sn_bottom_sheet.dart';
import 'package:sevanest_customer/core/widgets/sn_button.dart';
import 'package:sevanest_customer/core/widgets/sn_states.dart';
import 'package:sevanest_customer/features/favourites/presentation/widgets/favourite_button.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/engagement_labels.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/requirement_draft_provider.dart';
import 'package:sevanest_customer/features/worker_profile/presentation/providers/worker_profile_providers.dart';
import 'package:sevanest_customer/features/worker_profile/presentation/widgets/review_tile.dart';
import 'package:sevanest_customer/features/worker_search/domain/worker_search.dart';
import 'package:sevanest_customer/features/worker_search/presentation/providers/worker_search_providers.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/worker_card.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

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

  Future<void> _requestInterview(BuildContext context, WidgetRef ref) async {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final detail = ref.watch(workerDetailProvider(workerId));
    final gone = detail.error is NotFoundFailure;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('app_back_btn'),
          tooltip: l10n.back,
          icon: const Icon(Icons.chevron_left, size: 32),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(Routes.home),
        ),
        title: Text(l10n.workerProfileTitle),
        actions: [
          // The heart is useless for a worker who is gone (the server would answer 404).
          if (detail.hasValue)
            FavouriteButton(
              workerId: workerId,
              keyName: 'worker_detail_fav_btn',
            ),
        ],
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => gone
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SnEmptyState(
                    title: l10n.workerUnavailableTitle,
                    message: l10n.workerUnavailableBody,
                    actionLabel: l10n.workerFindAnother,
                    actionKey: const Key('worker_find_another_btn'),
                    onAction: () => _findAnother(context, ref),
                  ),
                ],
              )
            : SnErrorState(
                message: failureMessage(l10n, e),
                onRetry: () => ref.invalidate(workerDetailProvider(workerId)),
              ),
        data: (w) => _Body(worker: w),
      ),
      bottomNavigationBar: detail.hasValue
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: SnButton(
                  key: const Key('worker_request_interview_btn'),
                  label: l10n.workerRequestInterview,
                  onPressed: () => _requestInterview(context, ref),
                ),
              ),
            )
          : null,
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.worker});
  final WorkerSummary worker;

  Widget _fact(BuildContext context, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(
          child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final title = worker.categories.isEmpty ? '' : worker.categories.first;
    final reviews = ref.watch(workerReviewsProvider(worker.id)).value;
    final preview = reviews?.items.take(2).toList() ?? const [];

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Row(
          children: [
            WorkerAvatar(worker, radius: 40),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: text.titleLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
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
          ],
        ),
        TextButton(
          key: const Key('worker_verified_info_btn'),
          style: TextButton.styleFrom(alignment: Alignment.centerLeft),
          onPressed: () => showSnBottomSheet<void>(
            context,
            builder: (ctx) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.workerVerifiedSheetTitle, style: text.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                Text(l10n.workerVerifiedSheetBody),
                const SizedBox(height: AppSpacing.md),
                SnButton(
                  key: const Key('worker_verified_sheet_close_btn'),
                  label: l10n.workerGotIt,
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
          ),
          child: Text(l10n.workerVerifiedInfo),
        ),
        const Divider(),
        _fact(
          context,
          l10n.workerExperienceLabel,
          experienceLabel(l10n, worker.experienceMonths),
        ),
        if (worker.categories.length > 1)
          _fact(context, l10n.workerSkillsLabel, worker.categories.join(', ')),
        if (worker.languages.isNotEmpty)
          _fact(
            context,
            l10n.workerLanguagesLabel,
            worker.languages.map(languageName).join(', '),
          ),
        if (worker.areas.isNotEmpty)
          _fact(context, l10n.workerAreasLabel, worker.areas.join(', ')),
        if (worker.availability.isNotEmpty)
          _fact(
            context,
            l10n.workerAvailabilityLabel,
            worker.availability
                .map((a) => l10n.workerAvailableWindow(a.start, a.end))
                .join('\n'),
          ),
        if (worker.engagement != null)
          _fact(
            context,
            l10n.workerEngagementLabel,
            engagementLabels(l10n, worker.engagement!).name,
          ),
        const Divider(),
        Row(
          children: [
            Expanded(child: Text(l10n.reviewsTitle, style: text.titleMedium)),
            if (worker.hasRating)
              TextButton(
                key: const Key('worker_reviews_all_btn'),
                onPressed: () => context.push(
                  Routes.path(Routes.workerReviews, {'id': worker.id}),
                ),
                child: Text(l10n.reviewsSeeAll),
              ),
          ],
        ),
        if (preview.isEmpty)
          Text(l10n.reviewsEmpty, style: text.bodyMedium)
        else
          for (final r in preview) ReviewTile(r),
      ],
    );
  }
}
