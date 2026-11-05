import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/core/widgets/sn_button.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart'
    show authSerif;
import 'package:sevanest_customer/features/booking/domain/booking.dart';
import 'package:sevanest_customer/features/booking/presentation/booking_labels.dart';
import 'package:sevanest_customer/features/booking/presentation/widgets/hire_again_button.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/engagement_labels.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/schedule_format.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_parts.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// Pieces of the Service history screen (design: Find a Worker > Service history).

/// Bar colour, badge background and badge text of a booking status.
(Color, Color, Color) historyStatusColors(BookingStatus s) => switch (s) {
  BookingStatus.active || BookingStatus.confirmed => (
    AppColors.teal,
    AppColors.tealD6EFEA,
    AppColors.teal0B5A53,
  ),
  BookingStatus.completed => (
    AppColors.blue600,
    AppColors.blue100,
    AppColors.blue800,
  ),
  BookingStatus.cancelled => (
    AppColors.rose600,
    AppColors.rose100,
    AppColors.rose800,
  ),
  BookingStatus.unknown => (
    AppColors.slate400,
    AppColors.hairline,
    AppColors.slate700,
  ),
  _ => (AppColors.amber, AppColors.warnBg, AppColors.orange8A4B06),
};

/// Small caps heading of a group of cards (`.hd`).
class HistoryHeading extends StatelessWidget {
  const HistoryHeading(this.text, {this.top = 22, super.key});
  final String text;
  final double top;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(4, top, 4, 0),
    child: Semantics(
      header: true,
      child: Text(
        text.toUpperCase(),
        style: AppText.body.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: dsMuted,
        ),
      ),
    ),
  );
}

/// One past or current service: coloured edge, worker, status and the rating line.
class HistoryCard extends StatelessWidget {
  const HistoryCard({
    required this.booking,
    required this.score,
    required this.scale,
    super.key,
  });
  final Booking booking;
  final int? score;
  final int scale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final b = booking;
    final (bar, badgeBg, badgeFg) = historyStatusColors(b.status);
    final canRate = score == null && b.actions.contains(BookingAction.rate);
    final name = bookingWorkerName(b);
    final category = b.categoryName ?? b.categoryCode;
    final line = [
      if (name != null) category,
      if (b.engagement != null) engagementLabels(l10n, b.engagement!).name,
      if (b.startDate != null)
        bookingIsPast(b.status)
            ? formatDate(b.startDate!, locale)
            : l10n.serviceSince(formatDate(b.startDate!, locale)),
      b.areaName,
    ].whereType<String>().where((p) => p.isNotEmpty).join(' · ');
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: DiscoverGlass(
        key: Key('history_card_${b.id}'),
        radius: 24,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => context.push(
                        Routes.path(Routes.bookingDetail, {'id': b.id}),
                      ),
                      child: Row(
                        children: [
                          bookingAvatar(b),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name ?? category ?? '',
                                  key: Key('history_worker_${b.id}'),
                                  style: authSerif(18, 1.2),
                                ),
                                if (line.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      line,
                                      style: AppText.body.copyWith(
                                        fontSize: 13,
                                        color: dsMuted,
                                      ),
                                    ),
                                  ),
                                _Badge(
                                  label: bookingStatusLabel(l10n, b.status),
                                  bg: badgeBg,
                                  fg: badgeFg,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (score != null || canRate)
                    _RatingRow(
                      bookingId: b.id,
                      score: score,
                      scale: scale,
                      canRate: canRate,
                    ),
                  if (b.actions.contains(BookingAction.rebook))
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: HireAgainButton(
                        bookingId: b.id,
                        variant: SnButtonVariant.text,
                        glass: true,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.bg, required this.fg});
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 6),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(shape: BoxShape.circle, color: fg),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppText.body.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: fg,
          ),
        ),
      ],
    ),
  );
}

/// "Not rated yet" + Rate, or "You rated" + the stars, under a dashed rule.
class _RatingRow extends StatelessWidget {
  const _RatingRow({
    required this.bookingId,
    required this.score,
    required this.scale,
    required this.canRate,
  });
  final String bookingId;
  final int? score;
  final int scale;
  final bool canRate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final style = AppText.body.copyWith(
      fontSize: 13.5,
      fontWeight: FontWeight.w600,
      color: AppColors.slate700,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: CustomPaint(
        painter: _DashedRule(),
        child: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 6,
            children: [
              Text(
                score == null ? l10n.historyNotRated : l10n.historyYouRated,
                style: style,
              ),
              if (score != null)
                Semantics(
                  label: l10n.historyRatedLabel(score!, scale),
                  excludeSemantics: true,
                  child: Row(
                    key: Key('history_stars_$bookingId'),
                    children: [
                      for (var i = 1; i <= scale; i++)
                        Icon(
                          i <= score!
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 20,
                          color: AppColors.amber,
                        ),
                    ],
                  ),
                )
              else
                Material(
                  color: dsNavy,
                  shape: const StadiumBorder(),
                  child: InkWell(
                    key: Key('history_rate_btn_$bookingId'),
                    customBorder: const StadiumBorder(),
                    onTap: () => context.push(
                      Routes.path(Routes.rating, {'id': bookingId}),
                    ),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 44),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.center,
                      child: Text(
                        l10n.historyRate,
                        style: AppText.body.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.surface,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedRule extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = dsNavy.withValues(alpha: 0.18)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 7) {
      canvas.drawLine(Offset(x, 0), Offset(x + 4, 0), p);
    }
  }

  @override
  bool shouldRepaint(_DashedRule old) => false;
}

/// Search box of the history list: white pill with a search icon.
class HistorySearchField extends StatelessWidget {
  const HistorySearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onSubmitted,
    super.key,
  });
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) => TextField(
    key: const Key('history_search_field'),
    controller: controller,
    textInputAction: TextInputAction.search,
    onChanged: onChanged,
    onSubmitted: onSubmitted,
    style: AppText.body.copyWith(fontSize: 15, color: dsNavy),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: AppText.body.copyWith(fontSize: 15, color: dsMuted),
      prefixIcon: const Icon(Icons.search_rounded, color: dsNavy),
      filled: true,
      fillColor: AppColors.whiteA85xD9,
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: const BorderSide(color: AppColors.whiteA90xE6),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: const BorderSide(color: AppColors.whiteA90xE6),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: const BorderSide(color: dsNavy, width: 1.5),
      ),
    ),
  );
}

/// "Year: All ▾" pill that opens a menu of [items]; the first row clears the filter.
class HistoryFilterPill<T> extends StatelessWidget {
  const HistoryFilterPill({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    super.key,
  });
  final String label;
  final T? value;
  final List<(T, String)> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shown = value == null
        ? l10n.historyFilterAll
        : items.firstWhere((i) => i.$1 == value).$2;
    final on = value != null;
    return PopupMenuButton<(T?,)>(
      // Boxed so that "All" (null) is a choice, not a dismissal.
      onSelected: (v) => onChanged(v.$1),
      itemBuilder: (_) => [
        PopupMenuItem(value: (null,), child: Text(l10n.historyFilterAll)),
        for (final (v, t) in items) PopupMenuItem(value: (v,), child: Text(t)),
      ],
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.only(left: 14, right: 8),
        decoration: BoxDecoration(
          color: on ? AppColors.teal0F766EA12 : AppColors.whiteA85xD9,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: on ? AppColors.teal : AppColors.sky1B3354A20,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: $shown',
              style: AppText.body.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: dsNavy,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: dsNavy),
          ],
        ),
      ),
    );
  }
}
