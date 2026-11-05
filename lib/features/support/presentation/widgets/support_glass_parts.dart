import 'package:flutter/material.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart'
    show authSerif;
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/features/support/domain/support.dart';

/// Building blocks shared by the three support screens (design: Find a Worker > Support).

/// Bar colour (ticket card), pill background and pill text of a ticket status.
(Color, Color, Color) ticketStatusColors(TicketStatus s) =>
    switch (ticketStatusForCustomer(s)) {
      TicketStatus.open => (
        AppColors.amber,
        AppColors.warnBg,
        AppColors.orange8A4B06,
      ),
      TicketStatus.inProgress || TicketStatus.escalated => (
        AppColors.blue600,
        AppColors.blue100,
        AppColors.blue800,
      ),
      TicketStatus.closed || TicketStatus.unknown => (
        AppColors.slate400,
        AppColors.hairline,
        AppColors.slate700,
      ),
    };

/// Small status pill of a ticket card.
class TicketStatusPill extends StatelessWidget {
  const TicketStatusPill({
    required this.label,
    required this.status,
    super.key,
  });
  final String label;
  final TicketStatus status;

  @override
  Widget build(BuildContext context) {
    final (_, bg, fg) = ticketStatusColors(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppText.body.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

/// Frosted section card with a serif heading (`.sec` in the design).
class SupportSection extends StatelessWidget {
  const SupportSection({
    required this.child,
    this.title,
    this.hint,
    this.delayMs = 0,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });
  final String? title;

  /// Small grey note after the title, e.g. "(optional)".
  final String? hint;
  final Widget child;
  final double delayMs;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 14),
    child: DiscoverRise(
      delayMs: delayMs,
      child: DiscoverGlass(
        radius: 26,
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null) ...[
                Semantics(
                  header: true,
                  child: Text.rich(
                    TextSpan(
                      text: title,
                      style: authSerif(19, 1.25),
                      children: [
                        if (hint != null)
                          TextSpan(
                            text: '  $hint',
                            style: AppText.body.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: dsMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              child,
            ],
          ),
        ),
      ),
    ),
  );
}

/// Small bold grey label over a field or row.
class SupportLabel extends StatelessWidget {
  const SupportLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: AppText.body.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: dsMuted,
      ),
    ),
  );
}

/// Inline notice on a white card: offline, safety, duplicate and error messages.
class SupportNotice extends StatelessWidget {
  const SupportNotice({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.tint = AppColors.whiteA95xF2,
    this.body,
    this.trailing,
    super.key,
  });
  final IconData icon;
  final Color iconColor;
  final Color tint;
  final String title;
  final String? body;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: tint,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: iconColor.withValues(alpha: 0.3)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppText.body.copyWith(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: dsNavy,
                ),
              ),
              if (body != null)
                Text(
                  body!,
                  style: AppText.body.copyWith(
                    fontSize: 14,
                    height: 1.4,
                    color: dsText,
                  ),
                ),
              ?trailing,
            ],
          ),
        ),
      ],
    ),
  );
}

/// Amber / rose tints used by [SupportNotice].
const supportWarnTint = AppColors.warnBg;
const supportDangerTint = AppColors.rose100;
const supportDanger = AppColors.rose700;
