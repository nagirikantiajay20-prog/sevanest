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
import 'package:sevanest_customer/features/booking/presentation/providers/booking_providers.dart';
import 'package:sevanest_customer/features/notifications/presentation/providers/notification_providers.dart';
import 'package:sevanest_customer/features/support/domain/support.dart';
import 'package:sevanest_customer/features/support/presentation/providers/support_providers.dart';
import 'package:sevanest_customer/features/support/presentation/support_labels.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';
import 'package:uuid/uuid.dart';

/// A reply that did not go through: the text stays in its bubble until Retry or Remove.
class _Failed {
  const _Failed(this.body, this.key);
  final String body;
  final String key;
}

sealed class _Row {
  const _Row(this.at);
  final DateTime? at;
}

class _MessageRow extends _Row {
  const _MessageRow(this.message) : super(null);
  final TicketMessage message;
  @override
  DateTime? get at => message.createdAt;
}

class _EventRow extends _Row {
  const _EventRow(this.text, DateTime? at, this.icon) : super(at);
  final String text;
  final IconData icon;
}

/// `/support/:id` (module doc 12.3, design screen 29): the ticket, its conversation and, while it
/// is open, a composer. Internal fields (owner, priority, escalation) are never read. NOT built, no
/// backend support: "Waiting for you", resolved feedback, attachments, the overflow menu
/// (BACKEND_REQUESTS 46).
class TicketDetailScreen extends ConsumerStatefulWidget {
  const TicketDetailScreen({required this.ticketId, super.key});
  final String ticketId;

  @override
  ConsumerState<TicketDetailScreen> createState() => _State();
}

class _State extends ConsumerState<TicketDetailScreen>
    with WidgetsBindingObserver {
  final _text = TextEditingController();
  var _sending = false;
  var _offline = false;
  String? _error;
  _Failed? _failed;

  String get _id => widget.ticketId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _text.dispose();
    super.dispose();
  }

  /// A reply arrives while the app is in the background.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _reload();
  }

  void _reload() => ref
    ..invalidate(ticketProvider(_id))
    ..invalidate(ticketMessagesProvider(_id));

  Future<void> _refresh() async {
    _reload();
    try {
      await ref.read(ticketProvider(_id).future);
      await ref.read(ticketMessagesProvider(_id).future);
    } on Object {
      // shown by the view
    }
  }

  Future<void> _send({_Failed? retry}) async {
    final body = (retry?.body ?? _text.text).trim();
    if (body.isEmpty || _sending) return;
    final key = retry?.key ?? const Uuid().v4();
    setState(() {
      _sending = true;
      _offline = false;
      _error = null;
    });
    final l10n = AppLocalizations.of(context);
    try {
      await ref
          .read(supportRepositoryProvider)
          .post(_id, body, idempotencyKey: key);
      if (!mounted) return;
      _text.clear();
      _failed = null;
      _reload();
      try {
        await ref.read(ticketMessagesProvider(_id).future);
      } on Object {
        // the message went through; the list shows it on the next read
      }
    } on ConflictFailure catch (e) {
      if (!mounted) return;
      _failed = null;
      if (e.code == 'TICKET_CLOSED') {
        _error = l10n.tkdClosedErr;
        ref.invalidate(ticketProvider(_id));
      } else {
        _failed = _Failed(body, key);
      }
      _text.clear();
    } on Object catch (e) {
      if (!mounted) return;
      _failed = _Failed(body, key);
      _text.clear();
      if (e is NetworkFailure) _offline = true;
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  List<_Row> _rows(AppLocalizations l10n, Ticket t, List<TicketMessage> msgs) {
    final rows = <_Row>[
      if (t.createdAt != null)
        _EventRow(
          l10n.tkdEventCreated(clockTime(t.createdAt!)),
          t.createdAt,
          Icons.add_circle_outline,
        ),
    ];
    // The first customer message is the description; show it even if the list omits it.
    final hasFirst = msgs.any(
      (m) => m.isMine && m.body.trim() == t.description.trim(),
    );
    final all = [
      if (!hasFirst && t.description.isNotEmpty)
        TicketMessage(
          id: 'description',
          from: MessageAuthor.customer,
          body: t.description,
          createdAt: t.createdAt,
        ),
      ...msgs,
    ];
    for (final m in all) {
      rows.add(_MessageRow(m));
    }
    for (final e in t.history) {
      final to = e.to;
      if (to == null || to == e.from) continue;
      final shown = ticketStatusForCustomer(to);
      final before = e.from == null ? null : ticketStatusForCustomer(e.from!);
      if (before == null || before == shown) continue;
      final time = e.at == null ? '' : clockTime(e.at!);
      rows.add(
        shown == TicketStatus.closed
            ? _EventRow(l10n.tkdEventClosed(time), e.at, Icons.lock_outline)
            : _EventRow(
                l10n.tkdEventStatus(ticketStatusLabel(l10n, shown), time),
                e.at,
                Icons.sync,
              ),
      );
    }
    // Stable by time; rows with no time stay where they were added.
    final indexed = [for (var i = 0; i < rows.length; i++) (i, rows[i])];
    indexed.sort((a, b) {
      final x = a.$2.at;
      final y = b.$2.at;
      if (x == null || y == null) return a.$1.compareTo(b.$1);
      final c = x.compareTo(y);
      return c != 0 ? c : a.$1.compareTo(b.$1);
    });
    return [for (final r in indexed) r.$2];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // "Support replied" arrived while this ticket is open: read it again.
    ref.listen(notificationTickProvider, (_, _) => _reload());
    final ticket = ref.watch(ticketProvider(_id));
    final msgs = ref.watch(ticketMessagesProvider(_id));
    final t = ticket.value;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('app_back_btn'),
          tooltip: l10n.back,
          icon: const Icon(Icons.chevron_left, size: 32),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(Routes.support),
        ),
        title: Text(t == null ? '' : '#${t.reference}'),
      ),
      body: t == null
          ? (ticket.hasError
                ? _LoadError(
                    gone: ticket.error is NotFoundFailure,
                    onRetry: _reload,
                  )
                : const _Skeleton())
          : _content(l10n, t, msgs),
    );
  }

  Widget _content(
    AppLocalizations l10n,
    Ticket t,
    AsyncValue<List<TicketMessage>> msgs,
  ) {
    final now = ref.read(nowProvider)();
    final rows = _rows(l10n, t, msgs.value ?? const []);
    final stale =
        _offline ||
        (ref.watch(ticketProvider(_id)).hasError &&
            ref.watch(ticketProvider(_id)).error is NetworkFailure);
    final children = <Widget>[];
    DateTime? last;
    for (final r in rows) {
      final at = r.at;
      if (at != null && (last == null || !sameDay(last, at))) {
        children.add(_DayChip(label: dayHeader(l10n, at, now)));
        last = at;
      }
      children.add(switch (r) {
        _MessageRow() => _Bubble(message: r.message),
        _EventRow() => _Event(text: r.text, icon: r.icon),
      });
    }
    if (t.status == TicketStatus.closed && t.resolution != null) {
      children.add(_Resolution(text: t.resolution!));
    }
    final failed = _failed;
    if (failed != null) {
      children.add(
        _FailedBubble(
          body: failed.body,
          busy: _sending,
          onRetry: () => _send(retry: failed),
          onRemove: () => setState(() => _failed = null),
        ),
      );
    }
    if (_error != null) {
      children.add(
        Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Text(
            _error!,
            key: const Key('ticket_closed_error'),
            style: const TextStyle(color: AppColors.danger),
          ),
        ),
      );
    }
    final updated = t.updatedAt;
    return Column(
      children: [
        _Header(ticket: t, updated: updated, now: now),
        if (stale)
          Material(
            color: AppColors.warnBg,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                key: const Key('ticket_offline_banner'),
                children: [
                  const Icon(Icons.wifi_off, color: AppColors.warn),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(l10n.tkdOffline)),
                  TextButton(
                    key: const Key('ticket_offline_retry_btn'),
                    onPressed: () {
                      setState(() => _offline = false);
                      _reload();
                    },
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              key: const Key('ticket_conversation'),
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              children: children,
            ),
          ),
        ),
        if (ticketAcceptsReplies(t.status))
          _Composer(
            controller: _text,
            sending: _sending && _failed == null,
            max: ref.watch(ticketMessageMaxProvider),
            onSend: _send,
          )
        else if (t.status == TicketStatus.closed)
          _ClosedBar(
            onNew: () => context.push(
              t.bookingId == null
                  ? Routes.supportNew
                  : '${Routes.supportNew}?bookingId=${Uri.encodeComponent(t.bookingId!)}',
            ),
          ),
      ],
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({
    required this.ticket,
    required this.updated,
    required this.now,
  });
  final Ticket ticket;
  final DateTime? updated;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final created = ticket.createdAt;
    final bookingId = ticket.bookingId;
    final booking = bookingId == null
        ? null
        : ref.watch(bookingProvider(bookingId)).value;
    return Material(
      color: AppColors.surface,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.hairline)),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ticket.title(120),
              key: const Key('ticket_title'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Chip(
                  label: Text(ticket.category.name),
                  visualDensity: VisualDensity.compact,
                ),
                SnBadge(
                  key: const Key('ticket_status_chip'),
                  label: ticketStatusLabel(l10n, ticket.status),
                  tone: ticketStatusTone(ticket.status),
                ),
                if (bookingId != null)
                  ActionChip(
                    key: const Key('ticket_related_link'),
                    avatar: const Icon(Icons.attach_file, size: 18),
                    label: Text(
                      l10n.tkdBooking(
                        booking?.reference ??
                            (bookingId.length > 6
                                    ? bookingId.substring(bookingId.length - 6)
                                    : bookingId)
                                .toUpperCase(),
                      ),
                    ),
                    onPressed: () => context.push(
                      Routes.path(Routes.bookingDetail, {'id': bookingId}),
                    ),
                  ),
              ],
            ),
            if (created != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.tkdMeta(
                  dateTimeShort(created),
                  updated == null ? '' : timeAgo(l10n, updated!, now),
                ),
                style: text.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Chip(label: Text(label), visualDensity: VisualDensity.compact),
    ),
  );
}

class _Event extends StatelessWidget {
  const _Event({required this.text, required this.icon});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: AppColors.navy),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.navy),
          ),
        ),
      ],
    ),
  );
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});
  final TicketMessage message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final at = message.createdAt;
    final time = at == null ? '' : clockTime(at);
    if (message.isMine) {
      return Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * .8,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.teal,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      message.body,
                      style: text.bodyLarge?.copyWith(color: Colors.white),
                    ),
                  ),
                ),
                if (time.isNotEmpty) Text(time, style: text.bodySmall),
              ],
            ),
          ),
        ),
      );
    }
    final who = message.from == MessageAuthor.worker
        ? l10n.tkdWorkerName
        : l10n.tkdSupportName;
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * .8,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.navy,
                        child: Icon(Icons.home, size: 14, color: Colors.white),
                      ),
                      Text(who, style: text.titleSmall),
                      Text(time, style: text.bodySmall),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(message.body, style: text.bodyLarge),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FailedBubble extends StatelessWidget {
  const _FailedBubble({
    required this.body,
    required this.busy,
    required this.onRetry,
    required this.onRemove,
  });
  final String body;
  final bool busy;
  final VoidCallback onRetry;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Align(
      key: const Key('ticket_failed_message'),
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.teal,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.danger, width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  body,
                  style: text.bodyLarge?.copyWith(color: Colors.white),
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 16,
                  color: AppColors.danger,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(busy ? l10n.tkdSending : l10n.tkdFailed),
                TextButton(
                  key: const Key('ticket_send_retry_btn'),
                  onPressed: busy ? null : onRetry,
                  child: Text(l10n.tkdRetry),
                ),
                TextButton(
                  key: const Key('ticket_send_remove_btn'),
                  onPressed: busy ? null : onRemove,
                  child: Text(l10n.tkdDismiss),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Resolution extends StatelessWidget {
  const _Resolution({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Card(
        key: const Key('ticket_resolution_card'),
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.successBg,
                child: Icon(
                  Icons.check_circle_outline,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.tkdResolutionTitle, style: t.titleMedium),
                    Text(text, style: t.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.max,
    required this.onSend,
  });
  final TextEditingController controller;
  final bool sending;
  final int max;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Material(
      color: AppColors.surface,
      child: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.hairline)),
          ),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: AppColors.teal,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(child: Text(l10n.tkdPrivacy, style: text.bodySmall)),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: controller,
                      builder: (context, _, _) => TextField(
                        key: const Key('ticket_reply_field'),
                        controller: controller,
                        enabled: !sending,
                        maxLength: max,
                        minLines: 1,
                        maxLines: 4,
                        keyboardType: TextInputType.multiline,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: l10n.tkdReplyHint,
                          counterText: '',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller,
                    builder: (context, v, _) {
                      final can = v.text.trim().isNotEmpty && !sending;
                      return IconButton.filled(
                        key: const Key('ticket_reply_btn'),
                        tooltip: l10n.tkdSend,
                        onPressed: can ? onSend : null,
                        icon: sending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_outlined),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClosedBar extends StatelessWidget {
  const _ClosedBar({required this.onNew});
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: AppColors.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: DecoratedBox(
            key: const Key('ticket_closed_bar'),
            decoration: BoxDecoration(
              color: AppColors.fieldBg,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_outline),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(child: Text(l10n.tkdClosedBar)),
                    ],
                  ),
                  OutlinedButton(
                    key: const Key('ticket_new_from_closed_btn'),
                    onPressed: onNew,
                    child: Text(l10n.tkdClosedNew),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    Widget bar(double w, double h) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: AppColors.hairline,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    );
    return Semantics(
      label: AppLocalizations.of(context).loading,
      child: Padding(
        key: const Key('ticket_loading'),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            bar(240, 20),
            const SizedBox(height: AppSpacing.sm),
            bar(180, 28),
            const SizedBox(height: AppSpacing.lg),
            Align(alignment: Alignment.centerRight, child: bar(240, 80)),
            const SizedBox(height: AppSpacing.md),
            bar(260, 100),
            const SizedBox(height: AppSpacing.md),
            Align(alignment: Alignment.centerRight, child: bar(180, 60)),
          ],
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.gone, required this.onRetry});
  final bool gone;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          key: const Key('ticket_error'),
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.dangerBg,
              child: Icon(
                Icons.error_outline,
                size: 36,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              gone ? l10n.tkdGone : l10n.tkdLoadErrorTitle,
              style: text.titleLarge,
              textAlign: TextAlign.center,
            ),
            if (!gone) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.tkdLoadErrorBody, style: text.bodyMedium),
              const SizedBox(height: AppSpacing.md),
              SnButton(
                key: const Key('error_retry_btn'),
                label: l10n.tkNewTryAgain,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
