import 'package:flutter/material.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart'
    show authSerif;
import 'package:sevanest_customer/features/interview_trial/presentation/widgets/interview_detail_parts.dart'
    show DashedRule;
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';

/// Building blocks of "Confirm worker" (design 8.1). The cards are the interview form's
/// `RequestSection`, the worker strip is `InterviewWorkerCard`, the success state is
/// `GlassSuccessOverlay`.

/// Label / value rows split by dashed rules.
class ConfirmRows extends StatelessWidget {
  const ConfirmRows({required this.rows, super.key});
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final (i, r) in rows.indexed) ...[
        if (i > 0) const DashedRule(),
        Padding(
          padding: EdgeInsets.only(
            top: i == 0 ? 0 : 11,
            bottom: i == rows.length - 1 ? 0 : 11,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  r.$1,
                  style: AppText.body.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: dsMuted,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  r.$2,
                  style: AppText.body.copyWith(
                    fontSize: 15,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                    color: dsNavy,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ],
  );
}

/// "Start date": a round step back, the date (tap to open the calendar) and a round step on.
class ConfirmDatePager extends StatelessWidget {
  const ConfirmDatePager({
    required this.label,
    required this.date,
    required this.earlierTip,
    required this.laterTip,
    required this.onEarlier,
    required this.onLater,
    required this.onPick,
    super.key,
  });
  final String label;
  final String date;
  final String earlierTip;
  final String laterTip;

  /// Null at the earliest date (the arrow dims).
  final VoidCallback? onEarlier;
  final VoidCallback? onLater;
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    Widget step(IconData icon, String tip, VoidCallback? onTap, Key key) =>
        SizedBox(
          width: 44,
          height: 44,
          child: Material(
            color: AppColors.whiteA85xD9,
            shape: CircleBorder(
              side: BorderSide(
                color: dsNavy.withValues(alpha: 0.18),
                width: 1.5,
              ),
            ),
            child: IconButton(
              key: key,
              tooltip: tip,
              padding: EdgeInsets.zero,
              onPressed: onTap,
              icon: Icon(icon, size: 22, color: dsNavy),
            ),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppText.body.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: dsMuted,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            step(
              Icons.chevron_left_rounded,
              earlierTip,
              onEarlier,
              const Key('confirm_date_earlier_btn'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: Material(
                  color: AppColors.teal.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(
                      color: AppColors.teal.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: InkWell(
                    key: const Key('confirm_start_date_btn'),
                    customBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    onTap: onPick,
                    child: SizedBox(
                      height: 56,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                            color: AppColors.teal,
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (c, a) => FadeTransition(
                                opacity: a,
                                child: SlideTransition(
                                  position: Tween(
                                    begin: const Offset(0, 0.4),
                                    end: Offset.zero,
                                  ).animate(a),
                                  child: c,
                                ),
                              ),
                              // Scales down instead of overflowing at large text sizes.
                              child: FittedBox(
                                key: ValueKey(date),
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  date,
                                  maxLines: 1,
                                  style: AppText.body.copyWith(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: dsNavy,
                                  ),
                                ),
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
            const SizedBox(width: 8),
            step(
              Icons.chevron_right_rounded,
              laterTip,
              onLater,
              const Key('confirm_date_later_btn'),
            ),
          ],
        ),
      ],
    );
  }
}

/// Booking fee, taxes and the bold total, with the amber "this is an estimate" note.
class ConfirmPrice extends StatelessWidget {
  const ConfirmPrice({
    required this.lines,
    required this.totalLabel,
    this.total,
    this.note,
    super.key,
  });
  final List<(String, String)> lines;
  final String totalLabel;

  /// Null when the backend has not served a fee: only the note is shown, never an invented amount.
  final String? total;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final line = AppText.body.copyWith(fontSize: 15, color: dsText);
    return Column(
      children: [
        for (final r in lines)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(r.$1, style: line),
                Text(
                  r.$2,
                  style: line.copyWith(
                    color: dsNavy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        if (total != null) ...[
          const SizedBox(height: 6),
          const DashedRule(),
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  totalLabel,
                  style: line.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: dsNavy,
                  ),
                ),
                Text(total!, style: authSerif(24, 1)),
              ],
            ),
          ),
        ],
        if (note != null)
          Container(
            key: const Key('confirm_fee_note'),
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: AppColors.warnIcon,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    note!,
                    style: AppText.body.copyWith(
                      fontSize: 13,
                      height: 1.45,
                      color: AppColors.orange7A4300,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
