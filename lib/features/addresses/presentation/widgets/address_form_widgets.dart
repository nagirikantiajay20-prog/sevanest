import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/features/addresses/presentation/widgets/address_map_preview.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/motion.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

const _slate300 = Color(0xFFCBD5E1);
const _mint = Color(0xFFE2EEEC);

/// Frosted bottom sheet of the add-address design: grabber, serif title, round close button.
class AddressSheetFrame extends StatelessWidget {
  const AddressSheetFrame({
    required this.title,
    required this.child,
    super.key,
  });
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AuthGlass(
      radius: const BorderRadius.vertical(top: Radius.circular(34)),
      blur: 30,
      gradient: const LinearGradient(
        begin: Alignment(-0.5, -1),
        end: Alignment(0.5, 1),
        colors: [Color(0xE0FFFFFF), Color(0xA8FFFFFF)],
      ),
      border: const Border(top: BorderSide(color: Color(0xF2FFFFFF))),
      shadow: const [
        BoxShadow(
          color: Color(0x570F2340),
          blurRadius: 50,
          offset: Offset(0, -18),
        ),
      ],
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: authNavy.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(title, style: authSerif(26, 1.2)),
                      ),
                    ),
                    IconButton(
                      key: const Key('address_sheet_close_btn'),
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).closeButtonLabel,
                      style: IconButton.styleFrom(
                        minimumSize: const Size(44, 44),
                        backgroundColor: Colors.white.withValues(alpha: 0.75),
                        foregroundColor: authNavy,
                        side: const BorderSide(color: Color(0xE6FFFFFF)),
                        shadowColor: authNavy,
                        elevation: 3,
                      ),
                      icon: const Icon(Icons.close_rounded, size: 22),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// "Use my current location" card: pulsing radar and sheen while idle, spinner while locating,
/// green once found (with the map preview under it), red edge on failure.
class AddressLocationCard extends StatelessWidget {
  const AddressLocationCard({
    required this.clock,
    required this.locating,
    required this.found,
    required this.failed,
    required this.onTap,
    super.key,
  });
  final ValueListenable<double> clock;
  final bool locating;
  final bool found;
  final bool failed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = locating
        ? l10n.addressLocating
        : found
        ? l10n.addressLocationFound
        : l10n.locationUseCurrent;
    final sub = locating
        ? l10n.addressLocatingSub
        : found
        ? l10n.addressLocationFoundSub
        : l10n.locationUseCurrentSub;
    final shape = BorderRadius.circular(20);
    return Semantics(
      button: true,
      child: InkWell(
        key: const Key('address_use_location_btn'),
        onTap: onTap,
        borderRadius: shape,
        child: ClipRRect(
          borderRadius: shape,
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: found ? AppColors.successBg : AppColors.tealMist,
                  borderRadius: shape,
                  border: Border.all(
                    color: found
                        ? AppColors.successLine
                        : failed
                        ? const Color(0xFFFCA5A5)
                        : const Color(0xFF99E6DC),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    _Radar(
                      clock: clock,
                      pulse: !locating && !found,
                      child: locating
                          ? const SizedBox.square(
                              dimension: 26,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: AppColors.teal,
                              ),
                            )
                          : Icon(
                              found ? Icons.check_circle : Icons.my_location,
                              size: 26,
                              color: found
                                  ? const Color(0xFF16A34A)
                                  : AppColors.teal,
                            ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: authNavy,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            sub,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: AppColors.slate700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.slate),
                  ],
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: ValueListenableBuilder<double>(
                    valueListenable: clock,
                    builder: (_, t, _) => LayoutBuilder(
                      builder: (_, box) {
                        final w = box.maxWidth * 0.34;
                        final k = Curves.easeInOut.transform((t / 3600) % 1);
                        return Stack(
                          children: [
                            Positioned(
                              left: w * (-1.2 + 3.8 * k),
                              top: 0,
                              bottom: 0,
                              width: w,
                              child: const DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0x00FFFFFF),
                                      Color(0xA6FFFFFF),
                                      Color(0x00FFFFFF),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
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

/// White 50 px disc that sends out two expanding rings while [pulse] is on.
class _Radar extends StatelessWidget {
  const _Radar({required this.clock, required this.pulse, required this.child});
  final ValueListenable<double> clock;
  final bool pulse;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    Widget ring(double t, double offset) {
      final k = ((t + offset) / 2200) % 1;
      return Opacity(
        opacity: 0.7 * (1 - k),
        child: Transform.scale(
          scale: 0.5 + 1.7 * k,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.teal.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: 50,
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: authNavy.withValues(alpha: 0.14),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
          if (pulse)
            Positioned.fill(
              child: ExcludeSemantics(
                child: ValueListenableBuilder<double>(
                  valueListenable: clock,
                  builder: (_, t, _) =>
                      Stack(children: [ring(t, 0), ring(t, 1100)]),
                ),
              ),
            ),
          child,
        ],
      ),
    );
  }
}

/// Animated map card shown under the found location, with an area / city / pincode chip.
class AddressFoundMap extends StatelessWidget {
  const AddressFoundMap({
    required this.clock,
    required this.caption,
    super.key,
  });
  final ValueListenable<double> clock;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: authNavy.withValues(alpha: 0.2),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Semantics(
              image: true,
              label: caption,
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: 1),
                duration: const Duration(milliseconds: 1300),
                builder: (_, drop, _) => ValueListenableBuilder<double>(
                  valueListenable: clock,
                  builder: (_, t, _) => CustomPaint(
                    painter: AddressMapPainter(
                      drop: seg(drop * 1300, 350, 900, Curves.easeOutBack),
                      ring: t < 1200 ? 0 : ((t - 1200) / 2000) % 1,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 10,
              bottom: 10,
              child: AuthGlass(
                radius: BorderRadius.circular(99),
                blur: 18,
                gradient: const LinearGradient(
                  colors: [Color(0xB3FFFFFF), Color(0x66FFFFFF)],
                ),
                border: Border.all(color: const Color(0xE6FFFFFF)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Text(
                    caption,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: authNavy,
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

/// Inline area list that opens under the Area field (glass card, tick on the chosen area).
class AddressAreaList extends StatelessWidget {
  const AddressAreaList({
    required this.names,
    required this.selected,
    required this.onPick,
    super.key,
  });
  final List<String> names;
  final String selected;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xE6FFFFFF)),
        boxShadow: [
          BoxShadow(
            color: authNavy.withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          for (final n in names)
            InkWell(
              key: Key('area_option_$n'),
              borderRadius: BorderRadius.circular(12),
              onTap: () => onPick(n),
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: n == selected ? _mint : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        n,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: n == selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: authNavy,
                        ),
                      ),
                    ),
                    if (n == selected)
                      const Icon(Icons.check, size: 18, color: AppColors.teal),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Quick label pills (Home, Parents' home, Office) under the label field.
class AddressLabelChips extends StatelessWidget {
  const AddressLabelChips({
    required this.current,
    required this.onPick,
    super.key,
  });
  final String current;
  final ValueChanged<String>? onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final t in [
          l10n.addressLabelHome,
          l10n.addressLabelParents,
          l10n.addressLabelOffice,
        ])
          _chip(t, current.trim().toLowerCase() == t.toLowerCase()),
      ],
    );
  }

  Widget _chip(String t, bool on) => ChoiceChip(
    key: Key('address_label_chip_$t'),
    label: Text(t),
    selected: on,
    showCheckmark: false,
    selectedColor: _mint,
    backgroundColor: Colors.white.withValues(alpha: 0.72),
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
    labelStyle: AppText.label.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: on ? AppColors.teal : authNavy,
    ),
    shape: StadiumBorder(
      side: BorderSide(color: on ? AppColors.teal : _slate300, width: 1.5),
    ),
    materialTapTargetSize: MaterialTapTargetSize.padded,
    onSelected: onPick == null ? null : (_) => onPick!(t),
  );
}
