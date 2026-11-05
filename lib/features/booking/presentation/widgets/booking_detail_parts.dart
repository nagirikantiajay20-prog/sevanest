import 'package:flutter/material.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/motion.dart'
    show pingPong;
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';

/// Amber "Payment pending" strip over a booking that waits for its fee (design 8.3). It pulses
/// a soft warning ring.
class BookingPayBanner extends StatelessWidget {
  const BookingPayBanner({required this.title, required this.body, super.key});
  final String title;
  final String body;

  static const _ink = AppColors.orange6B3A00;
  static const _warn = AppColors.warn;

  @override
  Widget build(BuildContext context) {
    final clock = DiscoverClock.of(context);
    return ValueListenableBuilder<double>(
      valueListenable: clock,
      builder: (context, t, child) {
        final k = Curves.easeOut.transform(((t / 2400) % 1));
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.warnBg, AppColors.warnLine],
            ),
            border: Border.all(
              color: _warn.withValues(alpha: 0.45),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _warn.withValues(alpha: 0.22 + 0.08 * pingPong(t, 2400)),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: _warn.withValues(alpha: 0.3 * (1 - k)),
                spreadRadius: 8 * k,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
              ),
              child: const Icon(
                Icons.schedule_rounded,
                size: 22,
                color: AppColors.warnIcon,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppText.body.copyWith(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    ),
                  ),
                  Text(
                    body,
                    style: AppText.body.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _ink,
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

/// Small teal "Copy" pill after the booking reference.
class CopyPill extends StatelessWidget {
  const CopyPill({required this.label, required this.onTap, super.key});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: OutlinedButton(
      key: const Key('booking_copy_ref_btn'),
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.teal,
        backgroundColor: AppColors.whiteA80xCC,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        tapTargetSize: MaterialTapTargetSize.padded,
        side: BorderSide(color: AppColors.teal.withValues(alpha: 0.4)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: AppText.body.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      child: Text(label),
    ),
  );
}
