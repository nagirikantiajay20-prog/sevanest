import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/core/widgets/async_value_view.dart';
import 'package:sevanest_customer/features/favourites/domain/favourites.dart';
import 'package:sevanest_customer/features/favourites/presentation/providers/favourites_providers.dart';
import 'package:sevanest_customer/features/favourites/presentation/widgets/favourite_button.dart';
import 'package:sevanest_customer/features/favourites/presentation/widgets/favourite_card.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/features/worker_profile/presentation/screens/worker_detail_screen.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_page.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_parts.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/paged_footer.dart';
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

  /// "Removed" with Undo, which saves the worker again.
  void _removed(String workerId) {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.favouriteRemoved),
          behavior: SnackBarBehavior.floating,
          backgroundColor: dsNavy,
          // Above the floating nav pill.
          margin: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            MediaQuery.paddingOf(context).bottom + 8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          action: SnackBarAction(
            label: l10n.favouriteUndo,
            textColor: const Color(0xFF5EEAD4),
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
    // The floating nav pill sits over the page (Scaffold extendBody).
    final navClear = MediaQuery.paddingOf(context).bottom + 16;

    return FindGlassPage(
      title: l10n.favsTitle,
      subtitle: l10n.favsSubtitle,
      body: AsyncValueView<PagedState<FavouriteEntry>>(
        value: list,
        onRetry: notifier.refresh,
        isEmpty: (p) => p.items.where(shown).isEmpty && !p.hasMore,
        empty: GlassEmpty(
          icon: Icons.favorite_border_rounded,
          iconColor: const Color(0xFFE11D48),
          discColors: const [Color(0xFFFFE4EA), Colors.white],
          title: l10n.favsEmptyTitle,
          body: l10n.favsEmptyBody,
          actionLabel: l10n.favsFindWorker,
          actionKey: const Key('favs_empty_find_btn'),
          onAction: () => context.push(Routes.discoverCategory),
        ),
        data: (p) {
          final all = p.items.where(shown).toList();
          String? cat(FavouriteEntry e) => e.worker?.categories.firstOrNull;
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
          return RefreshIndicator(
            onRefresh: notifier.refresh,
            child: ListView(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16, 8, 16, navClear),
              children: [
                if (counts.length > 1)
                  DiscoverRise(
                    delayMs: 0,
                    child: SizedBox(
                      height: 52,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        children: [
                          _FilterChip(
                            key: const Key('favs_filter_all'),
                            label: l10n.favsFilterAll,
                            count: all.length,
                            selected: active == null,
                            onTap: () => setState(() => _category = null),
                          ),
                          for (final c in counts.keys) ...[
                            const SizedBox(width: 8),
                            _FilterChip(
                              key: Key('favs_filter_$c'),
                              label: c,
                              count: counts[c]!,
                              selected: active == c,
                              onTap: () => setState(() => _category = c),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                for (final (i, e) in items.indexed)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: DiscoverRise(
                      delayMs: 60.0 + 60 * i.clamp(0, 5),
                      child: KeyedSubtree(
                        key: Key('worker_card_${e.workerId}'),
                        child: _card(context, e),
                      ),
                    ),
                  ),
                PagedFooter(
                  page: p,
                  onRetry: notifier.loadMore,
                  retryKey: const Key('favs_load_more_retry_btn'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _card(BuildContext context, FavouriteEntry e) {
    void open() =>
        context.push(Routes.path(Routes.workerDetail, {'id': e.workerId}));
    final heart = FavouriteButton(
      workerId: e.workerId,
      keyName: 'worker_card_fav_btn_${e.workerId}',
      onChanged: (nowFav) {
        if (!nowFav) _removed(e.workerId);
      },
    );
    final w = e.worker;
    if (w == null) return UnavailableFavouriteCard(onTap: open, heart: heart);
    return FavouriteCard(
      worker: w,
      heart: heart,
      onOpen: open,
      onInterview: w.canRequestInterview
          ? () => requestInterviewFor(context, ref, e.workerId)
          : null,
    );
  }
}

/// Service filter pill with a count bubble; navy gradient when selected.
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    super.key,
  });
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : dsNavy;
    return Semantics(
      button: true,
      selected: selected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: selected
              ? const LinearGradient(colors: [dsNavy, AppColors.actionDeepTeal])
              : null,
          color: selected ? null : const Color(0xC7FFFFFF),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : dsNavy.withValues(alpha: 0.18),
            width: 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: dsNavy.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: AppText.body.copyWith(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: fg,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      constraints: const BoxConstraints(minWidth: 24),
                      height: 24,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0x38FFFFFF)
                            : dsNavy.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$count',
                        style: AppText.body.copyWith(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: fg,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
