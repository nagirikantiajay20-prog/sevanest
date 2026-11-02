import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart'
    show authSerif;
import 'package:sevanest_customer/features/service_discovery/domain/budget.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_parts.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// Glass pieces of the Budget step (design: Find a Worker 6).

/// Live Indian digit grouping while typing: "600000" -> "6,00,000". Digits only, at most 7.
class RupeeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final capped = digits.length > 7 ? digits.substring(0, 7) : digits;
    final text = capped.isEmpty ? '' : groupIndian(int.parse(capped));
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

const _guideGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [AppColors.navyDeep, AppColors.actionDeepTeal],
);

/// Market guidance for the service + area + engagement: loading, error, or the dark card with
/// "Use this range".
class GuidanceCard extends StatelessWidget {
  const GuidanceCard({
    required this.async,
    required this.engagementName,
    required this.serviceName,
    required this.onUse,
    required this.onRetry,
    super.key,
  });

  final AsyncValue<Guidance> async;
  final String engagementName;
  final String serviceName;
  final ValueChanged<Guidance> onUse;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final g = async.value;

    if (g == null && async.hasError) {
      return DiscoverGlass(
        key: const Key('discover_guidance_error'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.dangerBg,
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 22,
                  color: AppColors.danger,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        l10n.guidanceErrTitle,
                        style: authSerif(18, 1.25),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.guidanceErrBody,
                      style: AppText.body.copyWith(
                        fontSize: 14,
                        height: 1.45,
                        color: dsText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      key: const Key('error_retry_btn'),
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: Text(l10n.tryAgain),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        foregroundColor: dsNavy,
                        side: const BorderSide(color: dsNavy, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: AppText.body.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
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

    final shape = BorderRadius.circular(26);
    if (g == null) {
      return Semantics(
        label: l10n.loading,
        child: Container(
          key: const Key('discover_guidance_loading'),
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            gradient: _guideGradient,
            borderRadius: BorderRadius.all(Radius.circular(26)),
          ),
          child: const Row(
            children: [
              DiscoverShimmer(width: 48, height: 48, radius: 15, light: true),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DiscoverShimmer(width: 180, light: true),
                    SizedBox(height: 10),
                    DiscoverShimmer(width: 130, light: true),
                    SizedBox(height: 10),
                    DiscoverShimmer(width: 100, light: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final range = '${formatRupees(g.min)} – ${formatRupees(g.max)}';
    return Container(
      key: const Key('discover_guidance_card'),
      decoration: BoxDecoration(
        gradient: _guideGradient,
        borderRadius: shape,
        boxShadow: [
          BoxShadow(
            color: dsNavy.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const DiscoverSheen(widthFactor: 0.3, periodMs: 5000, alpha: 0.14),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const _Spark(
                        child: Icon(
                          Icons.trending_up,
                          size: 26,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.guidanceTypical(
                              engagementName,
                              serviceName,
                              g.city,
                            ),
                            style: AppText.body.copyWith(
                              fontSize: 13,
                              height: 1.35,
                              color: Colors.white.withValues(alpha: 0.82),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            g.period == BudgetPeriod.hourly
                                ? l10n.budgetRangePerHour(range)
                                : l10n.budgetRangePerMonth(range),
                            key: const Key('discover_guidance_range'),
                            style: authSerif(
                              22,
                              1.25,
                            ).copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            g.basis,
                            style: AppText.body.copyWith(
                              fontSize: 12.5,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                FilledButton(
                  key: const Key('discover_use_range_btn'),
                  onPressed: () => onUse(g),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: dsNavy,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: AppText.body.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  child: Text(l10n.guidanceUse),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Gentle grow-and-tilt loop on the guidance icon (`spark`).
class _Spark extends StatelessWidget {
  const _Spark({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<double>(
    valueListenable: DiscoverClock.of(context),
    child: child,
    builder: (_, t, c) {
      final k = math.sin(math.pi * ((t / 3000) % 1));
      return Transform.rotate(
        angle: 12 * math.pi / 180 * k,
        child: Transform.scale(scale: 1 + 0.18 * k, child: c),
      );
    },
  );
}

/// Minimum / Maximum read-outs, or "Any budget" when flexible.
class BudgetReadout extends StatelessWidget {
  const BudgetReadout({
    required this.budget,
    required this.flexible,
    super.key,
  });
  final Budget? budget;
  final bool flexible;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (flexible) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.budgetAny,
            key: const Key('discover_any_budget'),
            style: authSerif(32, 1.1),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.budgetAnyBody,
            style: AppText.body.copyWith(
              fontSize: 14,
              height: 1.45,
              color: dsText,
            ),
          ),
        ],
      );
    }
    String v(int? x) => x == null ? '–' : formatRupees(x);
    Widget cell(String label, String value, Key k) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xF2FFFFFF)),
          boxShadow: [
            BoxShadow(
              color: dsNavy.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppText.body.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: dsMuted,
              ),
            ),
            // Scales down instead of overflowing at large text sizes or amounts like ₹4,00,000.
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, key: k, style: authSerif(19, 1.1)),
            ),
          ],
        ),
      ),
    );
    return Row(
      children: [
        cell(
          l10n.budgetMinimum,
          v(budget?.min),
          const Key('discover_readout_min'),
        ),
        const SizedBox(width: 10),
        cell(
          l10n.budgetMaximum,
          v(budget?.max),
          const Key('discover_readout_max'),
        ),
      ],
    );
  }
}

/// 24 bars of price density around the typical range; bars inside the chosen range are teal-navy,
/// bars inside the typical range are amber.
class PriceHistogram extends StatelessWidget {
  const PriceHistogram({
    required this.period,
    required this.low,
    required this.high,
    required this.typical,
    required this.showTypical,
    required this.flexible,
    super.key,
  });
  final BudgetPeriod period;
  final double low;
  final double high;

  /// Centre and spread of the bars; amber only when [showTypical] (real guidance).
  final ({int min, int max}) typical;
  final bool showTypical;
  final bool flexible;

  static const _n = 24;

  @override
  Widget build(BuildContext context) {
    final ceil = budgetCeiling(period).toDouble();
    final mid = (typical.min + typical.max) / 2;
    final sd = math.max(1, (typical.max - typical.min) * 0.9);
    return ExcludeSemantics(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 1100),
        builder: (_, t, _) => SizedBox(
          height: 64,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < _n; i++) ...[
                if (i > 0) const SizedBox(width: 3),
                Expanded(child: _bar(i, ceil, mid, sd.toDouble(), t)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _bar(int i, double ceil, double mid, double sd, double t) {
    final v = (i + 0.5) / _n * ceil;
    final h = 8 + 52 * math.exp(-math.pow((v - mid) / sd, 2));
    final inside = flexible || (v >= low && v <= high);
    final ty = showTypical && !flexible && v >= typical.min && v <= typical.max;
    final grow = Curves.easeOut.transform(
      ((t * 1.1 - i * 0.02) / 0.6).clamp(0.0, 1.0),
    );
    return Align(
      alignment: Alignment.bottomCenter,
      child: Transform.scale(
        scaleY: 0.1 + 0.9 * grow,
        alignment: Alignment.bottomCenter,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: h,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(4),
              bottom: Radius.circular(2),
            ),
            color: inside
                ? null
                : (ty
                      ? AppColors.amber.withValues(alpha: 0.45)
                      : dsNavy.withValues(alpha: 0.14)),
            gradient: inside
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [ty ? AppColors.amber : AppColors.teal, dsNavy],
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

/// Dual-thumb slider: grey rail, amber "typical" band, navy-teal fill, white round thumbs.
class BudgetSlider extends StatelessWidget {
  const BudgetSlider({
    required this.period,
    required this.values,
    required this.enabled,
    required this.onChanged,
    this.typical,
    super.key,
  });

  final BudgetPeriod period;
  final RangeValues values;
  final bool enabled;
  final ({int min, int max})? typical;
  final ValueChanged<RangeValues> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ceiling = budgetCeiling(period);
    final step = period == BudgetPeriod.hourly ? 25 : 500;
    final ticks = period == BudgetPeriod.hourly
        ? ['₹0', '₹250', '₹500', '₹750', '₹1k+']
        : ['₹0', '₹10k', '₹20k', '₹30k', '₹40k+'];
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 8,
              overlayShape: SliderComponentShape.noOverlay,
              rangeTrackShape: _BudgetTrack(
                band: typical == null
                    ? null
                    : (typical!.min / ceiling, typical!.max / ceiling),
              ),
              rangeThumbShape: const _BudgetThumb(),
            ),
            child: Semantics(
              label: l10n.budgetSlider,
              child: SizedBox(
                height: 44,
                child: RangeSlider(
                  values: values,
                  max: ceiling.toDouble(),
                  divisions: ceiling ~/ step,
                  onChanged: enabled ? onChanged : null,
                ),
              ),
            ),
          ),
          ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final t in ticks)
                    Text(
                      t,
                      style: AppText.body.copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: dsMuted,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetTrack extends RangeSliderTrackShape
    with BaseRangeSliderTrackShape {
  const _BudgetTrack({this.band});
  final (double, double)? band;

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset startThumbCenter,
    required Offset endThumbCenter,
    bool isEnabled = false,
    bool isDiscrete = false,
    required TextDirection textDirection,
  }) {
    final rect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isDiscrete: isDiscrete,
    );
    final canvas = context.canvas;
    RRect pill(double l, double r) =>
        RRect.fromLTRBR(l, rect.top, r, rect.bottom, const Radius.circular(8));
    canvas.drawRRect(
      pill(rect.left, rect.right),
      Paint()..color = dsNavy.withValues(alpha: 0.14),
    );
    if (band != null) {
      canvas.drawRRect(
        pill(
          rect.left + rect.width * band!.$1,
          rect.left + rect.width * band!.$2,
        ),
        Paint()..color = AppColors.amber.withValues(alpha: 0.4),
      );
    }
    final fill = Rect.fromLTRB(
      startThumbCenter.dx,
      rect.top,
      endThumbCenter.dx,
      rect.bottom,
    );
    if (fill.width > 0) {
      canvas.drawRRect(
        pill(fill.left, fill.right),
        Paint()
          ..shader = const LinearGradient(
            colors: [dsNavy, AppColors.teal],
          ).createShader(fill),
      );
    }
  }

  @override
  bool operator ==(Object other) => other is _BudgetTrack && other.band == band;

  @override
  int get hashCode => band.hashCode;
}

class _BudgetThumb extends RangeSliderThumbShape {
  const _BudgetThumb();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(28, 28);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    bool isDiscrete = false,
    bool isEnabled = false,
    bool isOnTop = false,
    required SliderThemeData sliderTheme,
    TextDirection textDirection = TextDirection.ltr,
    Thumb thumb = Thumb.start,
    bool isPressed = false,
  }) {
    final canvas = context.canvas;
    final scale = isPressed ? 1.15 : 1.0;
    canvas.drawCircle(
      center + const Offset(0, 4),
      14 * scale,
      Paint()
        ..color = dsNavy.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawCircle(center, 14 * scale, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      12.5 * scale,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = dsNavy,
    );
  }
}

/// "Minimum (₹)" / "Maximum (₹)" typed amounts with live rupee grouping.
class AmountField extends StatelessWidget {
  const AmountField({
    required this.fieldKey,
    required this.label,
    required this.controller,
    required this.error,
    required this.dim,
    required this.onChanged,
    super.key,
  });

  final Key fieldKey;
  final String label;
  final TextEditingController controller;
  final bool error;

  /// Greyed while "Any budget" is on; typing still works and turns Flexible off.
  final bool dim;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c, double w) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: c, width: w),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppText.body.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: dsNavy,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          key: fieldKey,
          controller: controller,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          inputFormatters: [RupeeInputFormatter()],
          onChanged: onChanged,
          style: AppText.body.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: dim ? const Color(0xFF94A3B8) : dsNavy,
          ),
          decoration: InputDecoration(
            isDense: true,
            prefixText: '₹ ',
            prefixStyle: AppText.body.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: dsMuted,
            ),
            hintText: '0',
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.8),
            constraints: const BoxConstraints(minHeight: 44),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 12,
            ),
            enabledBorder: border(
              error ? AppColors.danger : AppColors.slate300,
              1.5,
            ),
            focusedBorder: border(error ? AppColors.danger : dsNavy, 2),
          ),
        ),
      ],
    );
  }
}

/// "Flexible budget" row with the navy toggle (54x32, thumb springs across).
class FlexibleCard extends StatelessWidget {
  const FlexibleCard({required this.value, required this.onChanged, super.key});
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DiscoverGlass(
      radius: 22,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.budgetFlexibleLabel,
                    style: AppText.body.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: dsNavy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.budgetFlexibleBody,
                    style: AppText.body.copyWith(
                      fontSize: 13.5,
                      color: dsMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Semantics(
              toggled: value,
              label: l10n.budgetFlexibleLabel,
              excludeSemantics: true,
              child: GestureDetector(
                key: const Key('discover_flexible_switch'),
                behavior: HitTestBehavior.opaque,
                onTap: onChanged == null ? null : () => onChanged!(!value),
                child: SizedBox(
                  width: 54,
                  height: 44,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 54,
                      height: 32,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: value ? dsNavy : const Color(0xFF94A3B8),
                      ),
                      child: AnimatedAlign(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutBack,
                        alignment: value
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          width: 26,
                          height: 26,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x4D000000),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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
