import 'package:flutter/material.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart'
    show authSerif;
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/features/support/domain/support.dart';
import 'package:sevanest_customer/features/support/presentation/support_labels.dart';
import 'package:sevanest_customer/features/support/presentation/widgets/support_glass_parts.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// Pieces of the Support home screen.

/// Open / Closed switch with the ticket counts.
class TicketFilter extends StatelessWidget {
  const TicketFilter({
    required this.closedTab,
    required this.open,
    required this.closed,
    required this.onChanged,
    super.key,
  });
  final bool closedTab;
  final int open;
  final int closed;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Semantics(
        container: true,
        label: l10n.supFilterLabel,
        child: Row(
          children: [
            Expanded(
              child: _Chip(
                key: const Key('support_filter_open'),
                label: l10n.tkStatusOpen,
                count: open,
                selected: !closedTab,
                onTap: () => onChanged(false),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Chip(
                key: const Key('support_filter_closed'),
                label: l10n.tkStatusClosed,
                count: closed,
                selected: closedTab,
                onTap: () => onChanged(true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
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
      selected: selected,
      button: true,
      child: Material(
        color: selected ? dsNavy : const Color(0xCCFFFFFF),
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? dsNavy : dsNavy.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppText.body.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0x38FFFFFF)
                        : dsNavy.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$count',
                    style: AppText.body.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One ticket: coloured status rule on the left, title, category · updated, status pill.
class TicketCard extends StatelessWidget {
  const TicketCard({
    required this.ticket,
    required this.updated,
    required this.onTap,
    super.key,
  });
  final Ticket ticket;
  final String? updated;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (bar, _, _) = ticketStatusColors(ticket.status);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: DiscoverGlass(
        radius: 22,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 14,
              bottom: 14,
              width: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: bar,
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(4),
                  ),
                ),
              ),
            ),
            Material(
              type: MaterialType.transparency,
              child: InkWell(
                key: Key('ticket_card_${ticket.id}'),
                borderRadius: BorderRadius.circular(22),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ticket.title(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.body.copyWith(
                                fontSize: 15.5,
                                height: 1.3,
                                fontWeight: FontWeight.w800,
                                color: dsNavy,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                [ticket.category.name, ?updated].join(' · '),
                                style: AppText.body.copyWith(
                                  fontSize: 13,
                                  color: dsMuted,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 7),
                              child: TicketStatusPill(
                                label: ticketStatusLabel(l10n, ticket.status),
                                status: ticket.status,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 22,
                        color: dsMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "No tickets yet": a floating-style icon disc, serif title and body.
class EmptyTickets extends StatelessWidget {
  const EmptyTickets({
    required this.title,
    required this.body,
    this.compact = false,
    super.key,
  });
  final String title;
  final String body;
  final bool compact;

  @override
  Widget build(BuildContext context) => Padding(
    key: const Key('support_empty'),
    padding: EdgeInsets.fromLTRB(12, compact ? 28 : 48, 12, compact ? 8 : 24),
    child: DiscoverRise(
      delayMs: 40,
      child: Column(
        children: [
          Container(
            width: compact ? 72 : 96,
            height: compact ? 72 : 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE2EEEC), Colors.white],
              ),
              boxShadow: [
                BoxShadow(
                  color: dsNavy.withValues(alpha: 0.14),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Icon(
              Icons.help_outline_rounded,
              size: compact ? 34 : 46,
              color: AppColors.teal,
            ),
          ),
          SizedBox(height: compact ? 16 : 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: authSerif(compact ? 22 : 26, 1.2),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 290),
            child: Text(
              body,
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(
                fontSize: 15.5,
                height: 1.5,
                color: dsText,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Frosted placeholder rows while a list loads.
class GlassSkeleton extends StatelessWidget {
  const GlassSkeleton({required this.count, super.key});
  final int count;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var i = 0; i < count; i++)
        Container(
          height: 92,
          margin: const EdgeInsets.only(top: 12),
          decoration: BoxDecoration(
            color: const Color(0x99FFFFFF),
            borderRadius: BorderRadius.circular(22),
          ),
        ),
    ],
  );
}

/// Help topic tile: opens a new ticket with that category selected.
class TopicTile extends StatelessWidget {
  const TopicTile({required this.category, required this.onTap, super.key});
  final SupportCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final safety = category.isSafety;
    return DiscoverGlass(
      radius: 22,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: Key('support_topic_${category.id}'),
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: safety ? supportDangerTint : const Color(0xFFD6EFEA),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    supportCategoryIcon(category),
                    size: 22,
                    color: safety ? supportDanger : AppColors.teal,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  category.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body.copyWith(
                    fontSize: 14.5,
                    height: 1.3,
                    fontWeight: FontWeight.w800,
                    color: dsNavy,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Feeling unsafe?" card with the safety report button.
class SafetyCard extends StatelessWidget {
  const SafetyCard({required this.onTap, super.key});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DiscoverGlass(
      key: const Key('support_safety_card'),
      radius: 22,
      borderColor: supportDanger.withValues(alpha: 0.3),
      gradient: const LinearGradient(
        begin: Alignment(-0.6, -1),
        end: Alignment(0.6, 1),
        colors: [Color(0xF2FFF1F2), Color(0xD9FFE4E6)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.gpp_maybe_outlined, color: supportDanger),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.supSafetyTitle,
                        style: AppText.body.copyWith(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: dsNavy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.supSafetyBody,
                        style: AppText.body.copyWith(
                          fontSize: 14,
                          height: 1.4,
                          color: dsText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                key: const Key('support_safety_btn'),
                onPressed: onTap,
                icon: const Icon(Icons.flag_outlined, size: 20),
                label: Text(l10n.supSafetyBtn),
                style: OutlinedButton.styleFrom(
                  foregroundColor: supportDanger,
                  side: BorderSide(
                    color: supportDanger.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: AppText.body.copyWith(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Call / email rows from `GET /app-config`.
class ContactCard extends StatelessWidget {
  const ContactCard({
    required this.contact,
    required this.onCall,
    required this.onEmail,
    super.key,
  });
  final SupportContact? contact;
  final VoidCallback? onCall;
  final VoidCallback? onEmail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget row(
      Key key,
      IconData icon,
      String label,
      String? value,
      VoidCallback? tap,
    ) => InkWell(
      key: key,
      onTap: tap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFD6EFEA),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                size: 22,
                color: tap == null ? dsMuted : AppColors.teal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppText.body.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: dsNavy,
                    ),
                  ),
                  Text(
                    value ?? l10n.supContactNA,
                    style: AppText.body.copyWith(
                      fontSize: 13.5,
                      color: dsMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: dsMuted),
          ],
        ),
      ),
    );
    return SupportSection(
      title: l10n.supContactUs,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Column(
        children: [
          row(
            const Key('support_call_btn'),
            Icons.phone_outlined,
            l10n.supCall,
            contact?.phone,
            onCall,
          ),
          row(
            const Key('support_email_btn'),
            Icons.mail_outline_rounded,
            l10n.supEmail,
            contact?.email,
            onEmail,
          ),
        ],
      ),
    );
  }
}

/// Two equal columns that grow with the text (a grid with a fixed ratio clips at large text sizes).
class TwoColumns extends StatelessWidget {
  const TwoColumns({required this.children, super.key});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final w = (c.maxWidth - 12) / 2;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [for (final x in children) SizedBox(width: w, child: x)],
      );
    },
  );
}
