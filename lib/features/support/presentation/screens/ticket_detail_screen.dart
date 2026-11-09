import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/localization/time_format.dart';
import 'package:sevanest_customer/core/services/clock.dart';
import 'package:sevanest_customer/features/booking/presentation/providers/booking_providers.dart';
import 'package:sevanest_customer/features/notifications/presentation/providers/notification_providers.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/features/support/domain/support.dart';
import 'package:sevanest_customer/features/support/presentation/providers/support_providers.dart';
import 'package:sevanest_customer/features/support/presentation/support_labels.dart';
import 'package:sevanest_customer/features/support/presentation/widgets/support_glass_parts.dart';
import 'package:sevanest_customer/features/support/presentation/widgets/ticket_detail_parts.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_page.dart';
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

/// `/support/:id` (module doc 12.3, design screen 29): the ticket card, its conversation and, while it
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
      if (isOffline(e)) _offline = true;
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
    final open = t != null && ticketAcceptsReplies(t.status);
    return FindGlassPage(
      title: l10n.tkdTitle,
      backLabel: l10n.back,
      onBack: () =>
          context.canPop() ? context.pop() : context.go(Routes.support),
      body: t == null
          ? (ticket.hasError
                ? _LoadError(
                    gone: ticket.error is NotFoundFailure,
                    onRetry: _reload,
                  )
                : const TicketSkeleton())
          : _content(l10n, t, msgs),
      bottom: t == null
          ? null
          : open
          ? TicketComposer(
              controller: _text,
              sending: _sending && _failed == null,
              max: ref.watch(ticketMessageMaxProvider),
              onSend: _send,
            )
          : t.status == TicketStatus.closed
          ? TicketClosedBar(
              onNew: () => context.push(
                t.bookingId == null
                    ? Routes.supportNew
                    : '${Routes.supportNew}?bookingId=${Uri.encodeComponent(t.bookingId!)}',
              ),
            )
          : null,
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
            isOffline(ref.watch(ticketProvider(_id)).error));
    final children = <Widget>[];
    DateTime? last;
    for (final r in rows) {
      final at = r.at;
      if (at != null && (last == null || !sameDay(last, at))) {
        children.add(TicketDayChip(label: dayHeader(l10n, at, now)));
        last = at;
      }
      children.add(switch (r) {
        _MessageRow() => TicketBubble(message: r.message),
        _EventRow() => TicketEventLine(text: r.text, icon: r.icon),
      });
    }
    if (t.status == TicketStatus.closed && t.resolution != null) {
      children.add(TicketResolution(text: t.resolution!));
    }
    final failed = _failed;
    if (failed != null) {
      children.add(
        FailedBubble(
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
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            _error!,
            key: const Key('ticket_closed_error'),
            style: AppText.body.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: supportDanger,
            ),
          ),
        ),
      );
    }
    final bookingId = t.bookingId;
    final booking = bookingId == null
        ? null
        : ref.watch(bookingProvider(bookingId)).value;
    final created = t.createdAt;
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        key: const Key('ticket_conversation'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (stale)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: SupportNotice(
                key: const Key('ticket_offline_banner'),
                icon: Icons.wifi_off_rounded,
                iconColor: AppColors.orange8A4B06,
                tint: supportWarnTint,
                title: l10n.tkdOffline,
                trailing: TextButton(
                  key: const Key('ticket_offline_retry_btn'),
                  onPressed: () {
                    setState(() => _offline = false);
                    _reload();
                  },
                  child: Text(l10n.retry),
                ),
              ),
            ),
          TicketHero(
            title: t.title(120),
            statusLabel: ticketStatusLabel(l10n, t.status),
            line: '${l10n.tkNewRef(t.reference)} · ${t.category.name}',
            closed: ticketStatusForCustomer(t.status) == TicketStatus.closed,
          ),
          if (created != null || bookingId != null)
            SupportSection(
              delayMs: 60,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: TicketInfoRows(
                rows: [
                  if (created != null)
                    (
                      l10n.tkdRaised,
                      Text(dateTimeShort(created), style: infoValue()),
                    ),
                  if (bookingId != null)
                    (
                      l10n.tkdRelatedTo,
                      InkWell(
                        key: const Key('ticket_related_link'),
                        onTap: () => context.push(
                          Routes.path(Routes.bookingDetail, {'id': bookingId}),
                        ),
                        child: Text(
                          l10n.tkdBooking(
                            booking?.reference ??
                                (bookingId.length > 6
                                        ? bookingId.substring(
                                            bookingId.length - 6,
                                          )
                                        : bookingId)
                                    .toUpperCase(),
                          ),
                          style: infoValue(AppColors.teal),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ConversationHeading(l10n.tkdConversation),
          ...children,
        ],
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: SupportSection(
        key: const Key('ticket_error'),
        title: gone ? l10n.tkdGone : l10n.tkdLoadErrorTitle,
        child: gone
            ? const SizedBox.shrink()
            : Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.tkdLoadErrorBody,
                      style: AppText.body.copyWith(
                        fontSize: 14.5,
                        color: dsText,
                      ),
                    ),
                  ),
                  TextButton(
                    key: const Key('error_retry_btn'),
                    onPressed: onRetry,
                    child: Text(l10n.tkNewTryAgain),
                  ),
                ],
              ),
      ),
    );
  }
}
