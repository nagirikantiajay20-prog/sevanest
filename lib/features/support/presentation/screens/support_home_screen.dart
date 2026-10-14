import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/localization/time_format.dart';
import 'package:sevanest_customer/core/services/clock.dart';
import 'package:sevanest_customer/core/widgets/sn_badge.dart';
import 'package:sevanest_customer/core/widgets/sn_button.dart';
import 'package:sevanest_customer/features/support/domain/support.dart';
import 'package:sevanest_customer/features/support/presentation/providers/support_providers.dart';
import 'package:sevanest_customer/features/support/presentation/support_labels.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// `/support` (module doc 12.1, design screen 27): help topics from the backend's ticket
/// categories, the customer's tickets, contact details from `GET /app-config`. NOT built, no
/// backend support: FAQ and help search (BACKEND_REQUESTS 45).
class SupportHomeScreen extends ConsumerStatefulWidget {
  const SupportHomeScreen({super.key});

  @override
  ConsumerState<SupportHomeScreen> createState() => _State();
}

class _State extends ConsumerState<SupportHomeScreen>
    with WidgetsBindingObserver {
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
    final text = Theme.of(context).textTheme;
    final categories = ref.watch(supportCategoriesProvider);
    final tickets = ref.watch(ticketListProvider);
    final contact = ref.watch(supportContactProvider).value;
    final offline =
        categories.error is NetworkFailure || tickets.error is NetworkFailure;
    return Scaffold(
      backgroundColor: AppColors.fieldBg,
      body: Column(
        children: [
          _Header(
            onBack: () =>
                context.canPop() ? context.pop() : context.go(Routes.home),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  if (offline)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _Banner(
                        key: const Key('support_offline_banner'),
                        text: l10n.supOfflineBanner,
                        onRetry: _refresh,
                      ),
                    ),
                  _SafetyCard(
                    onTap: () =>
                        context.push('${Routes.supportNew}?safety=true'),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ..._topics(l10n, text, categories, offline),
                  const SizedBox(height: AppSpacing.lg),
                  _Contact(
                    contact: contact,
                    onCall: contact?.phone == null
                        ? null
                        : () => _open(Uri(scheme: 'tel', path: contact!.phone)),
                    onEmail: contact?.email == null
                        ? null
                        : () => _open(
                            Uri(scheme: 'mailto', path: contact!.email),
                          ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ..._tickets(l10n, text, tickets),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),
          DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.hairline)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (offline)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Text(
                          l10n.supOfflineHint,
                          key: const Key('support_offline_hint'),
                          style: text.bodyMedium,
                        ),
                      ),
                    SnButton(
                      key: const Key('support_new_btn'),
                      label: l10n.supCreate,
                      icon: Icons.add,
                      onPressed: offline
                          ? null
                          : () => context.push(Routes.supportNew),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _topics(
    AppLocalizations l10n,
    TextTheme text,
    AsyncValue<List<SupportCategory>> categories,
    bool offline,
  ) {
    final title = Text(
      l10n.supQuickHelp,
      style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
    );
    if (categories.hasValue) {
      final list = categories.requireValue;
      return [
        title,
        const SizedBox(height: AppSpacing.md),
        _TwoColumns(
          children: [
            for (final c in list)
              _TopicTile(
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
        Card(
          key: const Key('support_error_card'),
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 32,
                  backgroundColor: Color(0xFFFEE2E2),
                  child: Icon(
                    Icons.error_outline,
                    size: 32,
                    color: AppColors.danger,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.supLoadErrorTitle,
                  style: text.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(l10n.supLoadErrorBody, style: text.bodyMedium),
                const SizedBox(height: AppSpacing.md),
                SnButton(
                  key: const Key('error_retry_btn'),
                  label: l10n.tkNewTryAgain,
                  icon: Icons.refresh,
                  onPressed: () => ref.invalidate(supportCategoriesProvider),
                ),
              ],
            ),
          ),
        ),
      ];
    }
    return [
      title,
      const SizedBox(height: AppSpacing.md),
      Semantics(
        label: l10n.loading,
        child: _TwoColumns(
          key: const Key('support_loading'),
          children: [
            for (var i = 0; i < 4; i++)
              const DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.hairline,
                  borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
                ),
                child: SizedBox(height: 104),
              ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _tickets(
    AppLocalizations l10n,
    TextTheme text,
    AsyncValue<dynamic> tickets,
  ) {
    final now = ref.read(nowProvider)();
    final header = Text(
      l10n.supYourTickets,
      style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
    );
    if (tickets.hasValue) {
      final s = ref.watch(ticketListProvider).requireValue;
      if (s.items.isEmpty) {
        return [
          header,
          const SizedBox(height: AppSpacing.sm),
          Card(
            key: const Key('support_empty'),
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.supNoTickets, style: text.titleMedium),
                  Text(l10n.supNoTicketsBody, style: text.bodyMedium),
                ],
              ),
            ),
          ),
        ];
      }
      return [
        header,
        const SizedBox(height: AppSpacing.sm),
        for (final t in s.items)
          _TicketCard(
            ticket: t,
            now: now,
            onTap: () =>
                context.push(Routes.path(Routes.supportDetail, {'id': t.id})),
          ),
        if (s.loadMoreError != null || s.hasMore)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: SnButton(
              key: const Key('support_tickets_more_btn'),
              label: l10n.supLoadMore,
              variant: SnButtonVariant.secondary,
              isLoading: s.isLoadingMore,
              onPressed: () => ref.read(ticketListProvider.notifier).loadMore(),
            ),
          ),
      ];
    }
    if (tickets.hasError) {
      return [
        header,
        const SizedBox(height: AppSpacing.sm),
        Row(
          key: const Key('support_tickets_error'),
          children: [
            Expanded(child: Text(l10n.supTicketsError)),
            TextButton(
              key: const Key('support_tickets_retry_btn'),
              onPressed: () => ref.read(ticketListProvider.notifier).refresh(),
              child: Text(l10n.retry),
            ),
          ],
        ),
      ];
    }
    return [
      header,
      const SizedBox(height: AppSpacing.sm),
      const LinearProgressIndicator(key: Key('support_tickets_loading')),
    ];
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.navy, AppColors.tealDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Material(
                    color: Colors.white10,
                    shape: const CircleBorder(),
                    child: IconButton(
                      key: const Key('app_back_btn'),
                      tooltip: l10n.back,
                      color: Colors.white,
                      icon: const Icon(Icons.chevron_left, size: 32),
                      onPressed: onBack,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      l10n.supTitle,
                      textAlign: TextAlign.center,
                      style: text.titleLarge?.copyWith(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: kMinTapTarget),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.supHeadline,
                style: text.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.supSubtitle,
                style: text.bodyLarge?.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, required this.onRetry, super.key});
  final String text;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.warnBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            const Icon(Icons.wifi_off, color: AppColors.warn),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(text)),
            TextButton(
              key: const Key('support_offline_retry_btn'),
              onPressed: onRetry,
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}

class _SafetyCard extends StatelessWidget {
  const _SafetyCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return DecoratedBox(
      key: const Key('support_safety_card'),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.gpp_maybe_outlined, color: AppColors.danger),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.supSafetyTitle, style: text.titleMedium),
                      const SizedBox(height: AppSpacing.xs),
                      Text(l10n.supSafetyBody, style: text.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SnButton(
              key: const Key('support_safety_btn'),
              label: l10n.supSafetyBtn,
              icon: Icons.flag_outlined,
              variant: SnButtonVariant.secondary,
              onPressed: onTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicTile extends StatelessWidget {
  const _TopicTile({required this.category, required this.onTap});
  final SupportCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Material(
      color: AppColors.surface,
      elevation: 1,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        key: Key('support_topic_${category.id}'),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFE6F7F4),
                child: Icon(
                  supportCategoryIcon(category),
                  color: category.isSafety ? AppColors.danger : AppColors.teal,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                category.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: text.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Contact extends StatelessWidget {
  const _Contact({
    required this.contact,
    required this.onCall,
    required this.onEmail,
  });
  final SupportContact? contact;
  final VoidCallback? onCall;
  final VoidCallback? onEmail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    Widget row(
      Key key,
      IconData icon,
      String label,
      String? value,
      VoidCallback? tap,
    ) => ListTile(
      key: key,
      enabled: tap != null,
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFE6F7F4),
        child: Icon(
          icon,
          color: tap == null ? AppColors.slate : AppColors.teal,
        ),
      ),
      title: Text(label),
      subtitle: Text(value ?? l10n.supContactNA),
      trailing: const Icon(Icons.chevron_right),
      onTap: tap,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.supContactUs,
          style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppSpacing.sm),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              row(
                const Key('support_call_btn'),
                Icons.phone_outlined,
                l10n.supCall,
                contact?.phone,
                onCall,
              ),
              const Divider(height: 1),
              row(
                const Key('support_email_btn'),
                Icons.mail_outline,
                l10n.supEmail,
                contact?.email,
                onEmail,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({
    required this.ticket,
    required this.now,
    required this.onTap,
  });
  final Ticket ticket;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final updated = ticket.updatedAt;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        key: Key('ticket_card_${ticket.id}'),
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('#${ticket.reference}', style: text.bodySmall),
                  ),
                  SnBadge(
                    label: ticketStatusLabel(l10n, ticket.status),
                    tone: ticketStatusTone(ticket.status),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                ticket.title(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: text.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                [
                  ticket.category.name,
                  if (updated != null)
                    l10n.supUpdated(timeAgo(l10n, updated, now)),
                ].join(' · '),
                style: text.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Two equal columns that grow with the text (a grid with a fixed ratio clips at large text sizes).
class _TwoColumns extends StatelessWidget {
  const _TwoColumns({required this.children, super.key});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final w = (c.maxWidth - AppSpacing.md) / 2;
      return Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        children: [for (final x in children) SizedBox(width: w, child: x)],
      );
    },
  );
}
