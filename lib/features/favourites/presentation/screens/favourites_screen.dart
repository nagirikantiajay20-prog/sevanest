import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/core/widgets/async_value_view.dart';
import 'package:sevanest_customer/core/widgets/sn_states.dart';
import 'package:sevanest_customer/features/favourites/domain/favourites.dart';
import 'package:sevanest_customer/features/favourites/presentation/providers/favourites_providers.dart';
import 'package:sevanest_customer/features/favourites/presentation/widgets/favourite_button.dart';
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
      appBar: AppBar(title: Text(l10n.favsTitle)),
      body: AsyncValueView<PagedState<FavouriteEntry>>(
        value: list,
        onRetry: notifier.refresh,
        isEmpty: (p) => p.items.where(shown).isEmpty && !p.hasMore,
        empty: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SnEmptyState(
              title: l10n.favsEmptyTitle,
              message: l10n.favsEmptyBody,
              actionLabel: l10n.favsFindWorker,
              actionKey: const Key('favs_empty_find_btn'),
              onAction: () => context.push(Routes.discoverCategory),
            ),
          ],
        ),
        data: (p) {
          final items = p.items.where(shown).toList();
          loadMoreIfShort(_scroll, p, notifier.loadMore);
          return RefreshIndicator(
            onRefresh: notifier.refresh,
            child: ListView.separated(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: items.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
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
                  Routes.path(Routes.workerDetail, {'id': e.workerId}),
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
                      : WorkerCard(
                          worker: e.worker!,
                          onTap: open,
                          trailing: heart,
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

/// A shortlisted worker who is no longer visible: tag + remove only; tapping explains why.
class _UnavailableCard extends StatelessWidget {
  const _UnavailableCard({required this.onTap, required this.heart});
  final VoidCallback onTap;
  final Widget heart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.hairline,
                child: Icon(Icons.person_off_outlined),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Chip(
                  key: const Key('worker_unavailable_tag'),
                  label: Text(l10n.workerUnavailableTag),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              heart,
            ],
          ),
        ),
      ),
    );
  }
}
