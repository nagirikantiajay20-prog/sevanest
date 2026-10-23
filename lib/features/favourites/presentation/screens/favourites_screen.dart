import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/core/widgets/async_value_view.dart';
import 'package:sevanest_customer/core/widgets/sn_badge.dart';
import 'package:sevanest_customer/core/widgets/sn_button.dart';
import 'package:sevanest_customer/core/widgets/sn_card.dart';
import 'package:sevanest_customer/core/widgets/sn_chip.dart';
import 'package:sevanest_customer/core/widgets/sn_header.dart';
import 'package:sevanest_customer/core/widgets/sn_states.dart';
import 'package:sevanest_customer/features/favourites/domain/favourites.dart';
import 'package:sevanest_customer/features/favourites/presentation/providers/favourites_providers.dart';
import 'package:sevanest_customer/features/favourites/presentation/widgets/favourite_button.dart';
import 'package:sevanest_customer/features/worker_profile/presentation/screens/worker_detail_screen.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/paged_footer.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/worker_card.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';
import 'package:sevanest_customer/shared/models/paged_state.dart';

/// `/favourites` tab (module 06, screen 6.1): the customer's shortlist.
class FavouritesScreen extends ConsumerStatefulWidget {
  const FavouritesScreen({super.key});

  @override
  ConsumerState<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends ConsumerState<FavouritesScreen> {
  final _scroll = ScrollController();

  /// Category filter chip (null = All); counts come from the loaded entries.
  String? _category;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 300) {
        ref.read(favouritesListProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// "Removed" with Undo, which shortlists the worker again.
  void _removed(String workerId) {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.favouriteRemoved),
          action: SnackBarAction(
            label: l10n.favouriteUndo,
            textColor: Colors.white,
            key: const Key('fav_undo_btn'),
            onPressed: () async {
              final ok = await ref
                  .read(favouriteProvider.notifier)
                  .toggle(workerId);
              if (!ok && mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(l10n.favouriteFailed)));
              }
            },
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final list = ref.watch(favouritesListProvider);
    final notifier = ref.read(favouritesListProvider.notifier);
    // Hide a card the moment it is un-shortlisted; the list refetch then makes it permanent.
    final ids = ref.watch(favouriteProvider).value?.ids;
    bool shown(FavouriteEntry e) => ids == null || ids.contains(e.workerId);

    return Scaffold(
      backgroundColor: AppColors.canvasCool,
      body: Column(
        children: [
          SnHeader(title: l10n.favsTitle, subtitle: l10n.favsSubtitle),
          Expanded(
            child: AsyncValueView<PagedState<FavouriteEntry>>(
              value: list,
              onRetry: notifier.refresh,
              isEmpty: (p) => p.items.where(shown).isEmpty && !p.hasMore,
              empty: SnEmptyState(
                title: l10n.favsEmptyTitle,
                message: l10n.favsEmptyBody,
                actionLabel: l10n.favsFindWorker,
                actionKey: const Key('favs_empty_find_btn'),
                onAction: () => context.push(Routes.discoverCategory),
              ),
              data: (p) {
                final all = p.items.where(shown).toList();
                String? cat(FavouriteEntry e) =>
                    e.worker?.categories.firstOrNull;
                final counts = <String, int>{};
                for (final e in all) {
                  final c = cat(e);
                  if (c != null) counts[c] = (counts[c] ?? 0) + 1;
                }
                final active = counts.containsKey(_category) ? _category : null;
                final items = active == null
                    ? all
                    : all.where((e) => cat(e) == active).toList();
                loadMoreIfShort(_scroll, p, notifier.loadMore);
                return Column(
                  children: [
                    if (counts.length > 1)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.md,
                          AppSpacing.md,
                          0,
                        ),
                        child: Row(
                          children: [
                            SnChip(
                              key: const Key('favs_filter_all'),
                              label: l10n.favsFilterAll,
                              count: all.length,
                              selected: active == null,
                              onTap: () => setState(() => _category = null),
                            ),
                            for (final c in counts.keys) ...[
                              const SizedBox(width: AppSpacing.sm),
                              SnChip(
                                key: Key('favs_filter_$c'),
                                label: c,
                                count: counts[c],
                                selected: active == c,
                                onTap: () => setState(() => _category = c),
                              ),
                            ],
                          ],
                        ),
                      ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: notifier.refresh,
                        child: ListView.separated(
                          controller: _scroll,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: items.length + 1,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.md),
                          itemBuilder: (_, i) {
                            if (i == items.length) {
                              return PagedFooter(
                                page: p,
                                onRetry: notifier.loadMore,
                                retryKey: const Key('favs_load_more_retry_btn'),
                              );
                            }
                            final e = items[i];
                            void open() => context.push(
                              Routes.path(Routes.workerDetail, {
                                'id': e.workerId,
                              }),
                            );
                            final heart = FavouriteButton(
                              workerId: e.workerId,
                              keyName: 'worker_card_fav_btn_${e.workerId}',
                              onChanged: (nowFav) {
                                if (!nowFav) _removed(e.workerId);
                              },
                            );
                            return KeyedSubtree(
                              key: Key('worker_card_${e.workerId}'),
                              child: e.worker == null
                                  ? _UnavailableCard(onTap: open, heart: heart)
                                  : Column(
                                      children: [
                                        WorkerCard(
                                          worker: e.worker!,
                                          onTap: open,
                                          trailing: heart,
                                        ),
                                        const SizedBox(height: AppSpacing.sm),
                                        SnButton(
                                          key: Key(
                                            'favs_request_interview_${e.workerId}',
                                          ),
                                          label: l10n.favsRequestInterview,
                                          variant: SnButtonVariant.deep,
                                          onPressed:
                                              e.worker!.canRequestInterview
                                              ? () => requestInterviewFor(
                                                  context,
                                                  ref,
                                                  e.workerId,
                                                )
                                              : null,
                                        ),
                                      ],
                                    ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// A shortlisted worker who is no longer visible: tag + remove only; tapping explains why.
class _UnavailableCard extends StatelessWidget {
  const _UnavailableCard({required this.onTap, required this.heart});
  final VoidCallback onTap;
  final Widget heart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SnCard(
      onTap: onTap,
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.slateBg,
            child: Icon(Icons.person_off_outlined, color: AppColors.slate),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: SnBadge(
                key: const Key('worker_unavailable_tag'),
                label: l10n.workerUnavailableTag,
              ),
            ),
          ),
          heart,
        ],
      ),
    );
  }
}
