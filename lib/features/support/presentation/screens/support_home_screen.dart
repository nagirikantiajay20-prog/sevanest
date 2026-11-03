import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/localization/time_format.dart';
import 'package:sevanest_customer/core/services/clock.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart'
    show AuthCta, authSerif;
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/features/support/domain/support.dart';
import 'package:sevanest_customer/features/support/presentation/providers/support_providers.dart';
import 'package:sevanest_customer/features/support/presentation/widgets/support_glass_parts.dart';
import 'package:sevanest_customer/features/support/presentation/widgets/support_home_parts.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_page.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';
import 'package:sevanest_customer/shared/models/paged_state.dart';
import 'package:url_launcher/url_launcher.dart';

/// `/support` (module doc 12.1, design: Find a Worker > Support): "Raise a ticket", the customer's
/// tickets with Open / Closed filters, help topics from the backend's ticket categories and contact
/// details from `GET /app-config`. NOT built, no backend support: FAQ and help search
/// (BACKEND_REQUESTS 45).
class SupportHomeScreen extends ConsumerStatefulWidget {
  const SupportHomeScreen({super.key});

  @override
  ConsumerState<SupportHomeScreen> createState() => _State();
}

class _State extends ConsumerState<SupportHomeScreen>
    with WidgetsBindingObserver {
  var _closedTab = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// A reply may have come while the app was in the background.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(ticketListProvider.notifier).refresh());
    }
  }

  Future<void> _refresh() async {
    ref
      ..invalidate(supportCategoriesProvider)
      ..invalidate(supportContactProvider);
    await ref.read(ticketListProvider.notifier).refresh();
  }

  Future<void> _open(Uri uri) async {
    try {
      await launchUrl(uri);
    } on Object {
      // nothing to open it with
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final categories = ref.watch(supportCategoriesProvider);
    final tickets = ref.watch(ticketListProvider);
    final contact = ref.watch(supportContactProvider).value;
    final offline =
        categories.error is NetworkFailure || tickets.error is NetworkFailure;
    return FindGlassPage(
      title: l10n.supTitle,
      backLabel: l10n.back,
      onBack: () => context.canPop() ? context.pop() : context.go(Routes.home),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
          children: [
            if (offline)
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 8),
                child: SupportNotice(
                  key: const Key('support_offline_banner'),
                  icon: Icons.wifi_off_rounded,
                  iconColor: const Color(0xFF8A4B06),
                  tint: supportWarnTint,
                  title: l10n.supOfflineBanner,
                  body: l10n.supOfflineHint,
                  trailing: TextButton(
                    key: const Key('support_offline_retry_btn'),
                    onPressed: _refresh,
                    child: Text(l10n.retry),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: DiscoverRise(
                delayMs: 0,
                child: Builder(
                  builder: (ctx) => AuthCta(
                    key: const Key('support_new_btn'),
                    clock: DiscoverClock.of(ctx),
                    label: l10n.supRaise,
                    loadingLabel: l10n.supRaise,
                    loading: false,
                    breathe: true,
                    showArrow: false,
                    leadingIcon: Icons.add_rounded,
                    radius: 18,
                    height: 56,
                    onPressed: offline
                        ? null
                        : () => context.push(Routes.supportNew),
                  ),
                ),
              ),
            ),
            ..._tickets(l10n, tickets),
            ..._topics(l10n, categories, offline),
            const SizedBox(height: 14),
            SafetyCard(
              onTap: () => context.push('${Routes.supportNew}?safety=true'),
            ),
            ContactCard(
              contact: contact,
              onCall: contact?.phone == null
                  ? null
                  : () => _open(Uri(scheme: 'tel', path: contact!.phone)),
              onEmail: contact?.email == null
                  ? null
                  : () => _open(Uri(scheme: 'mailto', path: contact!.email)),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _tickets(
    AppLocalizations l10n,
    AsyncValue<PagedState<Ticket>> tickets,
  ) {
    if (tickets.hasValue) {
      final s = tickets.requireValue;
      if (s.items.isEmpty) {
        return [
          EmptyTickets(title: l10n.supNoTickets, body: l10n.supNoTicketsBody),
        ];
      }
      bool closed(Ticket t) =>
          ticketStatusForCustomer(t.status) == TicketStatus.closed;
      final now = ref.read(nowProvider)();
      final shown = s.items.where((t) => closed(t) == _closedTab).toList();
      return [
        TicketFilter(
          closedTab: _closedTab,
          open: s.items.where((t) => !closed(t)).length,
          closed: s.items.where(closed).length,
          onChanged: (v) => setState(() => _closedTab = v),
        ),
        if (shown.isEmpty)
          EmptyTickets(
            compact: true,
            title: _closedTab ? l10n.supNoClosed : l10n.supNoOpen,
            body: l10n.supNoTicketsBody,
          ),
        for (final (i, t) in shown.indexed)
          DiscoverRise(
            delayMs: 60.0 * (i + 1).clamp(0, 8),
            child: TicketCard(
              ticket: t,
              updated: t.updatedAt == null
                  ? null
                  : l10n.supUpdated(timeAgo(l10n, t.updatedAt!, now)),
              onTap: () =>
                  context.push(Routes.path(Routes.supportDetail, {'id': t.id})),
            ),
          ),
        if (s.loadMoreError != null || s.hasMore)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: TextButton(
              key: const Key('support_tickets_more_btn'),
              onPressed: s.isLoadingMore
                  ? null
                  : () => ref.read(ticketListProvider.notifier).loadMore(),
              child: s.isLoadingMore
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    )
                  : Text(l10n.supLoadMore),
            ),
          ),
      ];
    }
    if (tickets.hasError) {
      return [
        SupportSection(
          title: l10n.supYourTickets,
          child: Row(
            key: const Key('support_tickets_error'),
            children: [
              Expanded(
                child: Text(
                  l10n.supTicketsError,
                  style: AppText.body.copyWith(fontSize: 14.5, color: dsText),
                ),
              ),
              TextButton(
                key: const Key('support_tickets_retry_btn'),
                onPressed: () =>
                    ref.read(ticketListProvider.notifier).refresh(),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ];
    }
    return [const GlassSkeleton(key: Key('support_tickets_loading'), count: 2)];
  }

  List<Widget> _topics(
    AppLocalizations l10n,
    AsyncValue<List<SupportCategory>> categories,
    bool offline,
  ) {
    Widget title() => Padding(
      padding: const EdgeInsets.fromLTRB(4, 22, 4, 12),
      child: Semantics(
        header: true,
        child: Text(l10n.supQuickHelp, style: authSerif(20, 1.25)),
      ),
    );
    if (categories.hasValue) {
      return [
        title(),
        TwoColumns(
          children: [
            for (final c in categories.requireValue)
              TopicTile(
                category: c,
                onTap: () => context.push(
                  '${Routes.supportNew}?categoryId=${Uri.encodeComponent(c.id)}',
                ),
              ),
          ],
        ),
      ];
    }
    if (categories.hasError) {
      // Offline is already said by the banner above.
      if (offline) return const [];
      return [
        SupportSection(
          key: const Key('support_error_card'),
          title: l10n.supLoadErrorTitle,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.supLoadErrorBody,
                  style: AppText.body.copyWith(fontSize: 14.5, color: dsText),
                ),
              ),
              TextButton(
                key: const Key('error_retry_btn'),
                onPressed: () => ref.invalidate(supportCategoriesProvider),
                child: Text(l10n.tkNewTryAgain),
              ),
            ],
          ),
        ),
      ];
    }
    return [
      title(),
      Semantics(
        label: l10n.loading,
        child: TwoColumns(
          key: const Key('support_loading'),
          children: [
            for (var i = 0; i < 4; i++)
              const DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0x80FFFFFF),
                  borderRadius: BorderRadius.all(Radius.circular(22)),
                ),
                child: SizedBox(height: 104),
              ),
          ],
        ),
      ),
    ];
  }
}
