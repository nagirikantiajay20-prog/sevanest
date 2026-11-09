import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/localization/failure_message.dart';
import 'package:sevanest_customer/core/widgets/sn_states.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart'
    show AuthCta;
import 'package:sevanest_customer/features/favourites/presentation/widgets/favourite_button.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/requirement_draft_provider.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/features/support/presentation/widgets/safety_actions.dart';
import 'package:sevanest_customer/features/worker_profile/presentation/providers/worker_profile_providers.dart';
import 'package:sevanest_customer/features/worker_profile/presentation/widgets/worker_profile_body.dart';
import 'package:sevanest_customer/features/worker_search/presentation/providers/worker_search_providers.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_page.dart';
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

    return FindGlassPage(
      title: l10n.workerProfileTitle,
      backLabel: l10n.back,
      onBack: () => context.canPop() ? context.pop() : context.go(Routes.home),
      // Report / block (module 12): only for a worker that is still there.
      trailing: worker == null
          ? null
          : DiscoverGlass(
              radius: 22,
              child: SafetyMenuButton(
                workerId: workerId,
                color: dsNavy,
                onBlocked: () => context.canPop()
                    ? context.pop()
                    : context.go(Routes.workers),
              ),
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
            : isOffline(e)
            ? SnOfflineState(
                message: failureMessage(l10n, e),
                onRetry: () => ref.invalidate(workerDetailProvider(workerId)),
              )
            : SnErrorState(
                message: failureMessage(l10n, e),
                onRetry: () => ref.invalidate(workerDetailProvider(workerId)),
              ),
        data: (w) => WorkerProfileBody(worker: w),
      ),
      bottom: worker == null
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!canRequest) ...[
          Text(
            l10n.workerCannotRequestReason,
            key: const Key('worker_cannot_request_reason'),
            style: const TextStyle(fontSize: 13, height: 1.4, color: dsText),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
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
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: AuthCta(
                key: const Key('worker_request_interview_btn'),
                clock: DiscoverClock.of(context),
                label: l10n.workerRequestInterview,
                loadingLabel: l10n.workerRequestInterview,
                loading: false,
                breathe: true,
                radius: 18,
                height: 58,
                onPressed: canRequest ? onRequest : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
