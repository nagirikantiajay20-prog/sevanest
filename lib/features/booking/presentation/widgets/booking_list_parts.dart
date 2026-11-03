import 'package:flutter/material.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/features/booking/domain/booking.dart';
import 'package:sevanest_customer/features/interview_trial/domain/interview.dart';
import 'package:sevanest_customer/features/interview_trial/presentation/widgets/interview_detail_parts.dart'
    show DashedRule;
import 'package:sevanest_customer/features/interview_trial/presentation/widgets/interview_list_parts.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';

/// Building blocks of the bookings list (design 8.2). The tile and the sliding two-way switch are
/// the interview list's ([InterviewTile], [InterviewSegments]); only the colours and the footer
/// differ.

/// Accent bar and badge colours of a booking status: teal (confirmed, active), amber (waiting),
/// blue (completed), rose (cancelled), slate (replaced, unknown).
InterviewLook bookingLook(BookingStatus s) => interviewLook(switch (s) {
  BookingStatus.confirmed || BookingStatus.active => InterviewStatus.scheduled,
  BookingStatus.completed => InterviewStatus.completed,
  BookingStatus.cancelled => InterviewStatus.cancelled,
  BookingStatus.replaced || BookingStatus.unknown => InterviewStatus.notAFit,
  _ => InterviewStatus.requested,
});

/// Dashed rule, a date line with the payment state, and "Complete payment" when it is due.
class BookingTileFooter extends StatelessWidget {
  const BookingTileFooter({
    required this.date,
    this.payment,
    this.payLabel,
    this.payKey,
    this.onPay,
    super.key,
  });
  final String? date;
  final String? payment;
  final String? payLabel;
  final Key? payKey;
  final VoidCallback? onPay;

  @override
  Widget build(BuildContext context) {
    final small = AppText.body.copyWith(
      fontSize: 13.5,
      fontWeight: FontWeight.w600,
      color: dsText,
    );
    return Column(
      children: [
        const DashedRule(),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: Text(date ?? '', style: small)),
            if (payment != null) Text(payment!, style: small),
          ],
        ),
        if (onPay != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: FilledButton(
              key: payKey,
              onPressed: onPay,
              style: FilledButton.styleFrom(
                backgroundColor: dsNavy,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: AppText.body.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: Text(payLabel ?? ''),
            ),
          ),
      ],
    );
  }
}
