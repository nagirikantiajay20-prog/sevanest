import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/core/services/clock.dart';
import 'package:sevanest_customer/core/widgets/async_value_view.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart'
    show AuthCta;
import 'package:sevanest_customer/features/booking/presentation/providers/booking_providers.dart';
import 'package:sevanest_customer/features/interview_trial/domain/interview.dart';
import 'package:sevanest_customer/features/interview_trial/presentation/interview_labels.dart';
import 'package:sevanest_customer/features/interview_trial/presentation/providers/interview_providers.dart';
import 'package:sevanest_customer/features/interview_trial/presentation/widgets/interview_list_parts.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/features/worker_profile/presentation/providers/worker_profile_providers.dart';
import 'package:sevanest_customer/features/worker_search/domain/worker_search.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_page.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_parts.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/paged_footer.dart';
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

  /// 0 All, 1 Upcoming, 2 Past.
  int _tab = 0;

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

  void _find() => context.push(Routes.discoverCategory);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(interviewListProvider.notifier);
    return FindGlassPage(
      title: l10n.interviewsTitle,
      backLabel: l10n.back,
      onBack: () => context.canPop() ? context.pop() : context.go(Routes.home),
      body: AsyncValueView<PagedState<Interview>>(
        value: ref.watch(interviewListProvider),
        onRetry: notifier.refresh,
        isEmpty: (p) => p.items.isEmpty,
        empty: GlassEmpty(
          icon: Icons.event_note_rounded,
          iconColor: AppColors.teal,
          discColors: const [AppColors.pillActive, AppColors.surface],
          title: l10n.interviewsEmptyTitle,
          body: l10n.interviewsEmptyBody,
          actionLabel: l10n.interviewsFind,
          actionKey: const Key('interviews_empty_find_btn'),
          actionIcon: Icons.search_rounded,
          onAction: _find,
        ),
        data: (p) {
          loadMoreIfShort(_scroll, p, notifier.loadMore);
          return _List(
            page: p,
            tab: _tab,
            scroll: _scroll,
            onTab: (t) => setState(() => _tab = t),
            onLoadMore: notifier.loadMore,
            onRefresh: notifier.refresh,
            onFind: _find,
          );
        },
      ),
    );
  }
}

/// The worker behind an interview. The live list carries none, so it is looked up through the
/// booking (cached per id).
WorkerSummary? _workerOf(WidgetRef ref, Interview iv) {
  if (iv.worker != null) return iv.worker;
  final id = iv.workerId.isNotEmpty
      ? iv.workerId
      : iv.bookingId.isEmpty
      ? null
      : ref.watch(bookingProvider(iv.bookingId)).value?.workerId;
  return id == null ? null : ref.watch(workerDetailProvider(id)).value;
}

class _List extends ConsumerWidget {
  const _List({
    required this.page,
    required this.tab,
    required this.scroll,
    required this.onTab,
    required this.onLoadMore,
    required this.onRefresh,
    required this.onFind,
  });
  final PagedState<Interview> page;
  final int tab;
  final ScrollController scroll;
  final ValueChanged<int> onTab;
  final VoidCallback onLoadMore;
  final Future<void> Function() onRefresh;
  final VoidCallback onFind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final now = ref.watch(nowProvider)();
    final all = page.items;
    final upcoming = all.where((i) => isUpcoming(i.status)).toList();
    final past = all.where((i) => !isUpcoming(i.status)).toList();
    final shown = [all, upcoming, past][tab];

    // The soonest booked time that has not started yet.
    final booked =
        upcoming
            .where(
              (i) =>
                  i.status == InterviewStatus.scheduled &&
                  (interviewStart(i)?.isAfter(now) ?? false),
            )
            .toList()
          ..sort((a, b) => interviewStart(a)!.compareTo(interviewStart(b)!));
    final next = tab == 2 || booked.isEmpty ? null : booked.first;

    void open(Interview iv) =>
        context.push(Routes.path(Routes.interviewDetail, {'id': iv.id}));

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            controller: scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
            children: [
              DiscoverRise(
                delayMs: 0,
                child: InterviewSegments(
                  selected: tab,
                  counts: [all.length, upcoming.length, past.length],
                  onChanged: onTab,
                ),
              ),
              if (next != null)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: DiscoverRise(
                    delayMs: 80,
                    child: _Next(
                      interview: next,
                      now: now,
                      locale: locale,
                      onTap: () => open(next),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(2, 22, 2, 0),
                child: DiscoverRise(
                  delayMs: 140,
                  child: Text(
                    [
                      l10n.interviewsAllTitle,
                      l10n.interviewsUpcoming,
                      l10n.interviewsPast,
                    ][tab].toUpperCase(),
                    style: AppText.body.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: AppColors.slate,
                    ),
                  ),
                ),
              ),
              if (shown.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  child: Text(
                    l10n.interviewsTabEmpty,
                    key: const Key('interviews_tab_empty'),
                    textAlign: TextAlign.center,
                    style: AppText.body.copyWith(
                      fontSize: 15,
                      color: AppColors.slate,
                    ),
                  ),
                ),
              for (final (i, iv) in shown.indexed)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: DiscoverRise(
                    delayMs: 180.0 + 60 * i.clamp(0, 5),
                    child: _Tile(
                      key: Key('interview_card_${iv.id}'),
                      interview: iv,
                      locale: locale,
                      onTap: () => open(iv),
                    ),
                  ),
                ),
              PagedFooter(
                page: page,
                onRetry: onLoadMore,
                retryKey: const Key('interviews_load_more_retry_btn'),
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 22,
          child: Center(child: _FindFab(onPressed: onFind)),
        ),
      ],
    );
  }
}

class _Next extends ConsumerWidget {
  const _Next({
    required this.interview,
    required this.now,
    required this.locale,
    required this.onTap,
  });
  final Interview interview;
  final DateTime now;
  final String locale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final worker = _workerOf(ref, interview);
    final when = interviewWhen(interview, locale);
    final left = interviewStart(interview)!.difference(now);
    return NextInterviewCard(
      name: worker == null || worker.title.isEmpty
          ? interviewTypeName(l10n, interview.type)
          : worker.title,
      initials: worker?.initials,
      photoUrl: worker?.photoUrl,
      when: when == null ? '' : l10n.interviewWhenValue(when.date, when.time),
      remaining: left.isNegative ? Duration.zero : left,
      onTap: onTap,
    );
  }
}

class _Tile extends ConsumerWidget {
  const _Tile({
    required this.interview,
    required this.locale,
    required this.onTap,
    super.key,
  });
  final Interview interview;
  final String locale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final iv = interview;
    final worker = _workerOf(ref, iv);
    final when = interviewWhen(iv, locale);
    final kind = interviewTypeName(l10n, iv.type);
    return InterviewTile(
      title: worker == null || worker.title.isEmpty ? kind : worker.title,
      initials: worker?.initials,
      photoUrl: worker?.photoUrl,
      gradient: avatarGradientFor(iv.workerId.isEmpty ? iv.id : iv.workerId),
      subtitle: when == null
          ? kind
          : '$kind · ${l10n.interviewWhenValue(when.date, when.time)}',
      statusLabel: interviewStatusLabel(l10n, iv.status),
      look: interviewLook(iv.status),
      onTap: onTap,
    );
  }
}

/// "Find another worker", floating over the list.
class _FindFab extends StatelessWidget {
  const _FindFab({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: 250,
      child: AuthCta(
        key: const Key('interviews_find_another_btn'),
        clock: DiscoverClock.of(context),
        label: l10n.workerFindAnother,
        loadingLabel: l10n.workerFindAnother,
        loading: false,
        breathe: true,
        icon: Icons.search_rounded,
        radius: 18,
        height: 54,
        onPressed: onPressed,
      ),
    );
  }
}
