import 'package:flutter/material.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/core/localization/time_format.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart'
    show authSerif;
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/features/support/domain/support.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// Pieces of the Ticket detail screen (design: Find a Worker > Ticket).

/// Navy (slate when closed) card with the status chip, the title and "Ticket #ref · Category".
class TicketHero extends StatelessWidget {
  const TicketHero({
    required this.title,
    required this.statusLabel,
    required this.line,
    required this.closed,
    super.key,
  });
  final String title;
  final String statusLabel;
  final String line;
  final bool closed;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(top: 6),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(26),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: closed
            ? const [Color(0xFF334155), Color(0xFF475569)]
            : const [dsNavy, Color(0xFF124E52)],
      ),
      boxShadow: [
        BoxShadow(
          color: dsNavy.withValues(alpha: 0.3),
          blurRadius: 34,
          offset: const Offset(0, 16),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          key: const Key('ticket_status_chip'),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0x33FFFFFF),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0x59FFFFFF)),
          ),
          child: Text(
            statusLabel,
            style: AppText.body.copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Semantics(
          header: true,
          child: Text(
            title,
            key: const Key('ticket_title'),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: authSerif(23, 1.25).copyWith(color: Colors.white),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          line,
          style: AppText.body.copyWith(fontSize: 13.5, color: Colors.white),
        ),
      ],
    ),
  );
}

/// "Raised" and "Related to" rows with dashed-style dividers.
class TicketInfoRows extends StatelessWidget {
  const TicketInfoRows({required this.rows, super.key});
  final List<(String, Widget)> rows;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final (i, r) in rows.indexed)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: i == rows.length - 1
                ? null
                : Border(
                    bottom: BorderSide(color: dsNavy.withValues(alpha: 0.18)),
                  ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 90,
                child: Text(
                  r.$1,
                  style: AppText.body.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: dsMuted,
                  ),
                ),
              ),
              Expanded(child: r.$2),
            ],
          ),
        ),
    ],
  );
}

TextStyle infoValue([Color color = dsNavy]) => AppText.body.copyWith(
  fontSize: 15,
  height: 1.4,
  fontWeight: FontWeight.w700,
  color: color,
);

/// "Conversation" heading.
class ConversationHeading extends StatelessWidget {
  const ConversationHeading(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 22, 4, 0),
    child: Semantics(
      header: true,
      child: Text(text, style: authSerif(20, 1.25)),
    ),
  );
}

/// One chat bubble: the customer's (navy, right) or support's / worker's (white, left).
class TicketBubble extends StatelessWidget {
  const TicketBubble({required this.message, super.key});
  final TicketMessage message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final at = message.createdAt;
    final time = at == null ? '' : clockTime(at);
    final mine = message.isMine;
    final who = mine
        ? l10n.tkdYou
        : message.from == MessageAuthor.worker
        ? l10n.tkdWorkerName
        : l10n.tkdSupportName;
    final fg = mine ? Colors.white : dsNavy;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * .84,
        ),
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: mine ? dsNavy : const Color(0xE6FFFFFF),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(mine ? 20 : 6),
            bottomRight: Radius.circular(mine ? 6 : 20),
          ),
          border: mine ? null : Border.all(color: const Color(0xF2FFFFFF)),
          boxShadow: mine
              ? null
              : [
                  BoxShadow(
                    color: dsNavy.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.body,
              style: AppText.body.copyWith(
                fontSize: 14.5,
                height: 1.5,
                color: fg,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              [who, if (time.isNotEmpty) time].join(' · '),
              style: AppText.body.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: fg.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Day label between messages.
class TicketDayChip extends StatelessWidget {
  const TicketDayChip({required this.label, super.key});
  final String label;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xB3FFFFFF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppText.body.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: dsMuted,
        ),
      ),
    ),
  );
}

/// "Status changed to ..." line in the timeline.
class TicketEventLine extends StatelessWidget {
  const TicketEventLine({required this.text, required this.icon, super.key});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: dsMuted),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: AppText.body.copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: dsMuted,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Teal "Resolved" card at the end of a closed ticket.
class TicketResolution extends StatelessWidget {
  const TicketResolution({required this.text, super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      key: const Key('ticket_resolution_card'),
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFD6EFEA),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.teal.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.tkdResolutionTitle,
            style: AppText.body.copyWith(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0B5A53),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: AppText.body.copyWith(
              fontSize: 14.5,
              height: 1.5,
              color: const Color(0xFF0B5A53),
            ),
          ),
        ],
      ),
    );
  }
}

/// A reply that did not go through: stays in its bubble until Retry or Remove.
class FailedBubble extends StatelessWidget {
  const FailedBubble({
    required this.body,
    required this.busy,
    required this.onRetry,
    required this.onRemove,
    super.key,
  });
  final String body;
  final bool busy;
  final VoidCallback onRetry;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Align(
      key: const Key('ticket_failed_message'),
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * .84,
              ),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: dsNavy,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(6),
                ),
                border: Border.all(color: const Color(0xFFE11D48), width: 2),
              ),
              child: Text(
                body,
                style: AppText.body.copyWith(
                  fontSize: 14.5,
                  height: 1.5,
                  color: Colors.white,
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 16,
                  color: Color(0xFFBE123C),
                ),
                const SizedBox(width: 4),
                Text(
                  busy ? l10n.tkdSending : l10n.tkdFailed,
                  style: AppText.body.copyWith(fontSize: 13, color: dsText),
                ),
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

/// Reply box and the navy send button (the frosted bottom bar's content).
class TicketComposer extends StatelessWidget {
  const TicketComposer({
    required this.controller,
    required this.sending,
    required this.max,
    required this.onSend,
    super.key,
  });
  final TextEditingController controller;
  final bool sending;
  final int max;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            key: const Key('ticket_reply_field'),
            controller: controller,
            enabled: !sending,
            maxLength: max,
            minLines: 1,
            maxLines: 4,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            style: AppText.body.copyWith(fontSize: 15, color: dsNavy),
            decoration: InputDecoration(
              hintText: l10n.tkdReplyHint,
              hintStyle: AppText.body.copyWith(fontSize: 15, color: dsMuted),
              counterText: '',
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(14),
              border: _line(const Color(0x331B3354), 1.5),
              enabledBorder: _line(const Color(0x331B3354), 1.5),
              disabledBorder: _line(const Color(0x331B3354), 1.5),
              focusedBorder: _line(dsNavy, 2),
            ),
          ),
        ),
        const SizedBox(width: 10),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, v, _) {
            final can = v.text.trim().isNotEmpty && !sending;
            return Opacity(
              opacity: can || sending ? 1 : 0.45,
              child: SizedBox(
                width: 52,
                height: 52,
                child: IconButton.filled(
                  key: const Key('ticket_reply_btn'),
                  tooltip: l10n.tkdSend,
                  onPressed: can ? onSend : null,
                  style: IconButton.styleFrom(
                    backgroundColor: dsNavy,
                    disabledBackgroundColor: dsNavy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.arrow_forward_rounded,
                          size: 22,
                          color: Colors.white,
                        ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  static OutlineInputBorder _line(Color c, double w) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: c, width: w),
  );
}

/// Bottom bar of a closed ticket: a note and "Create a new ticket".
class TicketClosedBar extends StatelessWidget {
  const TicketClosedBar({required this.onNew, super.key});
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      key: const Key('ticket_closed_bar'),
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 8,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline_rounded, color: dsMuted),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                l10n.tkdClosedBar,
                style: AppText.body.copyWith(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: dsNavy,
                ),
              ),
            ),
          ],
        ),
        OutlinedButton(
          key: const Key('ticket_new_from_closed_btn'),
          onPressed: onNew,
          style: OutlinedButton.styleFrom(
            foregroundColor: dsNavy,
            minimumSize: const Size(0, 48),
            side: BorderSide(color: dsNavy.withValues(alpha: 0.3), width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(l10n.tkdClosedNew),
        ),
      ],
    );
  }
}

/// Frosted placeholder while the ticket loads.
class TicketSkeleton extends StatelessWidget {
  const TicketSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    Widget block(double h, {Alignment align = Alignment.center, double? w}) =>
        Align(
          alignment: align,
          child: Container(
            width: w,
            height: h,
            margin: const EdgeInsets.only(top: 14),
            decoration: BoxDecoration(
              color: const Color(0x99FFFFFF),
              borderRadius: BorderRadius.circular(22),
            ),
          ),
        );
    return Semantics(
      label: AppLocalizations.of(context).loading,
      child: Padding(
        key: const Key('ticket_loading'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(
          children: [
            block(110),
            block(96),
            block(70, align: Alignment.centerRight, w: 240),
            block(100, align: Alignment.centerLeft, w: 260),
          ],
        ),
      ),
    );
  }
}
