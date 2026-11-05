import 'package:flutter/material.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart'
    show AuthCta, authSerif;
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_page.dart'
    show SheenSweep;
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_parts.dart'
    show GlassAvatar;

/// Building blocks of "Payment" (design 9.1 - 9.2) and "Receipt" (9.4).

const _teal = AppColors.teal;

/// Navy-to-teal "Amount to pay" card with the sheen sweeping across it.
class PayAmountCard extends StatelessWidget {
  const PayAmountCard({
    required this.label,
    required this.amount,
    this.amountKey,
    super.key,
  });
  final String label;
  final String amount;
  final Key? amountKey;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(30),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [dsNavy, AppColors.actionDeepTeal],
      ),
      boxShadow: [
        BoxShadow(
          color: dsNavy.withValues(alpha: 0.34),
          blurRadius: 40,
          offset: const Offset(0, 20),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: AppText.body.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: AppColors.whiteA78xC7,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  amount,
                  key: amountKey,
                  style: authSerif(52, 1.05).copyWith(color: AppColors.surface),
                ),
              ],
            ),
          ),
          const SheenSweep(periodMs: 5000, band: 0.3),
        ],
      ),
    ),
  );
}

/// One payment method of the "Pay with" card: icon tile, name, hint. Informational: the gateway
/// asks which one to use on the next step.
class PayMethodTile extends StatelessWidget {
  const PayMethodTile({
    required this.icon,
    required this.title,
    required this.note,
    this.badge,
    super.key,
  });
  final IconData icon;
  final String title;
  final String note;
  final String? badge;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 10),
    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
    constraints: const BoxConstraints(minHeight: 68),
    decoration: BoxDecoration(
      color: AppColors.whiteA70xB3,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: dsNavy.withValues(alpha: 0.14), width: 1.5),
    ),
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.pillActive,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, size: 22, color: _teal),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: AppText.body.copyWith(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: dsNavy,
                      ),
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: const LinearGradient(
                          colors: [AppColors.amber, AppColors.amber400],
                        ),
                      ),
                      child: Text(
                        badge!.toUpperCase(),
                        style: AppText.body.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          color: AppColors.orange4A2C00,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                note,
                style: AppText.body.copyWith(fontSize: 13, color: dsMuted),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Teal lock note under the methods.
class PaySecureNote extends StatelessWidget {
  const PaySecureNote(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 14),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: _teal.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        const Icon(Icons.lock_outline_rounded, size: 20, color: _teal),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppText.body.copyWith(
              fontSize: 13.5,
              height: 1.4,
              color: AppColors.actionDeepTeal,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Worker + service line of the payment summary card.
class PayWorkerLine extends StatelessWidget {
  const PayWorkerLine({
    required this.name,
    required this.subtitle,
    required this.gradient,
    super.key,
  });
  final String name;
  final String subtitle;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      GlassAvatar(title: name, gradient: gradient, size: 48, fontSize: 16),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: authSerif(19, 1.2)),
            if (subtitle.isNotEmpty)
              Text(
                subtitle,
                style: AppText.body.copyWith(fontSize: 13.5, color: dsMuted),
              ),
          ],
        ),
      ),
    ],
  );
}

/// Full-page result of a payment that has not been paid (failed, confirming, nothing to pay,
/// load error): gradient icon disc, serif title, body, then the buttons.
class PayResult extends StatelessWidget {
  const PayResult({
    required this.icon,
    required this.colors,
    required this.title,
    required this.body,
    required this.buttons,
    this.extra,
    this.loading = false,
    super.key,
  });
  final IconData icon;
  final List<Color> colors;
  final String title;
  final String body;
  final Widget? extra;
  final List<Widget> buttons;

  /// Replaces the icon with a spinner ring (confirming).
  final bool loading;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: DiscoverRise(
        delayMs: 0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: loading
                  ? Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surface,
                        boxShadow: [
                          BoxShadow(
                            color: dsNavy.withValues(alpha: 0.2),
                            blurRadius: 36,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const SizedBox(
                            width: 104,
                            height: 104,
                            child: CircularProgressIndicator(
                              key: Key('payment_verifying'),
                              strokeWidth: 3,
                              color: _teal,
                            ),
                          ),
                          Icon(icon, size: 44, color: dsNavy),
                        ],
                      ),
                    )
                  : Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: colors,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colors.first.withValues(alpha: 0.42),
                            blurRadius: 36,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      child: Icon(icon, size: 50, color: AppColors.surface),
                    ),
            ),
            const SizedBox(height: 24),
            Semantics(
              header: true,
              liveRegion: true,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: authSerif(30, 1.15),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              body,
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(
                fontSize: 16,
                height: 1.5,
                color: dsText,
              ),
            ),
            ?extra,
            const SizedBox(height: 22),
            for (final b in buttons) ...[b, const SizedBox(height: 10)],
          ],
        ),
      ),
    ),
  );
}

/// Navy call to action used under results and in the bottom bar.
class PayButton extends StatelessWidget {
  const PayButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.danger = false,
    super.key,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    if (danger) {
      return SizedBox(
        height: 58,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.rose700,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            textStyle: AppText.body.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: Text(label),
        ),
      );
    }
    return AuthCta(
      clock: DiscoverClock.of(context),
      label: label,
      loadingLabel: label,
      loading: loading,
      breathe: true,
      showArrow: false,
      icon: icon ?? Icons.arrow_forward_rounded,
      radius: 18,
      height: 58,
      onPressed: onPressed,
    );
  }
}

/// Teal outlined secondary action; [quiet] drops the outline (plain text link).
class PayOutline extends StatelessWidget {
  const PayOutline({
    required this.label,
    required this.onPressed,
    this.quiet = false,
    super.key,
  });
  final String label;
  final VoidCallback onPressed;
  final bool quiet;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: quiet ? 48 : 54,
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: quiet ? dsMuted : _teal,
        backgroundColor: quiet ? Colors.transparent : AppColors.whiteA80xCC,
        side: quiet
            ? BorderSide.none
            : BorderSide(color: _teal.withValues(alpha: 0.5), width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: AppText.body.copyWith(
          fontSize: quiet ? 15 : 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      child: Text(label),
    ),
  );
}
