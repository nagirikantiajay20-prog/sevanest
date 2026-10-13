import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/core/widgets/async_value_view.dart';
import 'package:sevanest_customer/core/widgets/sn_badge.dart';
import 'package:sevanest_customer/core/widgets/sn_states.dart';
import 'package:sevanest_customer/features/interview_trial/domain/interview.dart';
import 'package:sevanest_customer/features/interview_trial/presentation/interview_labels.dart';
import 'package:sevanest_customer/features/interview_trial/presentation/providers/interview_providers.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/paged_footer.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/worker_card.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';
import 'package:sevanest_customer/shared/models/paged_state.dart';

/// `/interviews` (module 07, screen 7.3).
class InterviewsListScreen extends ConsumerStatefulWidget {
  const InterviewsListScreen({super.key});

  @override
  ConsumerState<InterviewsListScreen> createState() => _State();
}

class _State extends ConsumerState<InterviewsListScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 300) {
        ref.read(interviewListProvider.notifier).loadMore();
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
    final locale = Localizations.localeOf(context).toString();
    final notifier = ref.read(interviewListProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('app_back_btn'),
          tooltip: l10n.back,
          icon: const Icon(Icons.chevron_left, size: 32),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(Routes.home),
        ),
        title: Text(l10n.interviewsTitle),
      ),
      body: AsyncValueView<PagedState<Interview>>(
        value: ref.watch(interviewListProvider),
        onRetry: notifier.refresh,
        isEmpty: (p) => p.items.isEmpty,
        empty: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SnEmptyState(
              title: l10n.interviewsEmptyTitle,
              message: l10n.interviewsEmptyBody,
              actionLabel: l10n.interviewsFind,
              actionKey: const Key('interviews_empty_find_btn'),
              onAction: () => context.push(Routes.discoverCategory),
            ),
          ],
        ),
        data: (p) {
          loadMoreIfShort(_scroll, p, notifier.loadMore);
          return RefreshIndicator(
            onRefresh: notifier.refresh,
            child: ListView.separated(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: p.items.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (_, i) {
                if (i == p.items.length) {
                  return PagedFooter(
                    page: p,
                    onRetry: notifier.loadMore,
                    retryKey: const Key('interviews_load_more_retry_btn'),
                  );
                }
                final iv = p.items[i];
                final when = interviewWhen(iv, locale);
                return Card(
                  key: Key('interview_card_${iv.id}'),
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: iv.worker == null
                        ? const CircleAvatar(child: Icon(Icons.person_outline))
                        : WorkerAvatar(iv.worker!),
                    title: Text(
                      iv.worker?.categories.firstOrNull ??
                          interviewTypeName(l10n, iv.type),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      when == null
                          ? interviewTypeName(l10n, iv.type)
                          : l10n.interviewWhenValue(when.date, when.time),
                    ),
                    trailing: SnBadge(
                      label: interviewStatusLabel(l10n, iv.status),
                      tone: interviewStatusTone(iv.status),
                    ),
                    onTap: () => context.push(
                      Routes.path(Routes.interviewDetail, {'id': iv.id}),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
