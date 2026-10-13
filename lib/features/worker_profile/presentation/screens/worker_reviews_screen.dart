import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/core/widgets/async_value_view.dart';
import 'package:sevanest_customer/core/widgets/sn_states.dart';
import 'package:sevanest_customer/features/worker_profile/domain/worker_review.dart';
import 'package:sevanest_customer/features/worker_profile/presentation/providers/worker_profile_providers.dart';
import 'package:sevanest_customer/features/worker_profile/presentation/widgets/review_tile.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/paged_footer.dart';
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = workerReviewsProvider(widget.workerId);
    final notifier = ref.read(provider.notifier);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('app_back_btn'),
          tooltip: l10n.back,
          icon: const Icon(Icons.chevron_left, size: 32),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(Routes.home),
        ),
        title: Text(l10n.reviewsTitle),
      ),
      body: AsyncValueView<PagedState<WorkerReview>>(
        value: ref.watch(provider),
        onRetry: notifier.refresh,
        isEmpty: (p) => p.items.isEmpty,
        empty: SnEmptyState(title: l10n.reviewsEmpty),
        data: (p) {
          loadMoreIfShort(_scroll, p, notifier.loadMore);
          return RefreshIndicator(
            onRefresh: notifier.refresh,
            child: ListView.separated(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: p.items.length + 1,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) => i == p.items.length
                  ? PagedFooter(
                      page: p,
                      onRetry: notifier.loadMore,
                      retryKey: const Key('reviews_load_more_retry_btn'),
                    )
                  : ReviewTile(p.items[i]),
            ),
          );
        },
      ),
    );
  }
}
