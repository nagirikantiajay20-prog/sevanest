import 'dart:ui' show PathMetric;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/core/widgets/sn_button.dart';
import 'package:sevanest_customer/features/addresses/domain/address.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart'
    show authSerif;
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// Widgets of the Location step (design: Find a Worker 3).

const _slate = AppColors.slate400;

/// "Use my current location": frosted row with radar rings while idle, a spinner while finding.
class CurrentLocationButton extends StatelessWidget {
  const CurrentLocationButton({
    required this.finding,
    required this.onTap,
    super.key,
  });
  final bool finding;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final clock = DiscoverClock.of(context);
    return DiscoverGlass(
      radius: 22,
      borderWidth: 2,
      borderColor: finding ? AppColors.teal : AppColors.whiteA90xE6,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: const Key('discover_use_location_btn'),
          borderRadius: BorderRadius.circular(22),
          onTap: finding ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                SizedBox(
                  width: 50,
                  height: 50,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface,
                      boxShadow: [
                        BoxShadow(
                          color: dsNavy.withValues(alpha: 0.14),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: finding
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: AppColors.teal,
                            ),
                          )
                        : Stack(
                            alignment: Alignment.center,
                            clipBehavior: Clip.none,
                            children: [
                              _Radar(clock: clock, delay: 0),
                              _Radar(clock: clock, delay: 1100),
                              const Icon(
                                Icons.my_location_rounded,
                                size: 26,
                                color: AppColors.teal,
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        finding
                            ? l10n.locationFinding
                            : l10n.locationUseCurrent,
                        style: AppText.body.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: dsNavy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        finding
                            ? l10n.locationFindingSub
                            : l10n.locationUseCurrentSub,
                        style: AppText.body.copyWith(
                          fontSize: 13,
                          height: 1.4,
                          color: dsText,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!finding)
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 24,
                    color: AppColors.teal,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Radar extends StatelessWidget {
  const _Radar({required this.clock, required this.delay});
  final ValueListenable<double> clock;
  final double delay;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<double>(
    valueListenable: clock,
    builder: (_, t, _) {
      final p = ((t - delay) / 2200) % 1;
      return IgnorePointer(
        child: Opacity(
          opacity: 0.7 * (1 - p),
          child: Container(
            width: 50 * (0.5 + 1.7 * p),
            height: 50 * (0.5 + 1.7 * p),
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
    },
  );
}

/// Location permission is off: red icon, copy, Open settings and a link back to saved addresses.
class PermissionOffCard extends StatelessWidget {
  const PermissionOffCard({
    required this.onOpenSettings,
    required this.onChooseSaved,
    super.key,
  });
  final VoidCallback onOpenSettings;
  final VoidCallback onChooseSaved;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DiscoverRise(
      delayMs: 0,
      child: DiscoverGlass(
        child: Padding(
          padding: const EdgeInsets.all(14),
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
                  Icons.location_off_outlined,
                  size: 22,
                  color: AppColors.danger,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.locationOffTitle,
                      key: const Key('discover_location_off'),
                      style: authSerif(18, 1.3),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.locationOffBody,
                      style: AppText.body.copyWith(
                        fontSize: 14,
                        height: 1.45,
                        color: dsText,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        OutlinedButton(
                          key: const Key('discover_open_settings_btn'),
                          onPressed: onOpenSettings,
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
                          child: Text(l10n.locationOpenSettings),
                        ),
                        TextButton(
                          key: const Key('discover_choose_saved_btn'),
                          onPressed: onChooseSaved,
                          style: TextButton.styleFrom(
                            minimumSize: const Size(0, 44),
                            foregroundColor: AppColors.teal,
                            textStyle: AppText.body.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: Text(l10n.locationChooseSaved),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The area is outside the service areas: shown above the list.
class NotServedNote extends StatelessWidget {
  const NotServedNote({super.key});

  @override
  Widget build(BuildContext context) => DiscoverRise(
    delayMs: 0,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(Icons.error_outline, size: 20, color: AppColors.danger),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            AppLocalizations.of(context).locationNotServed,
            key: const Key('discover_not_served'),
            style: AppText.body.copyWith(
              fontSize: 14.5,
              height: 1.45,
              color: AppColors.red700,
            ),
          ),
        ),
      ],
    ),
  );
}

/// No saved address yet.
class NoAddressCard extends StatelessWidget {
  const NoAddressCard({required this.onAdd, super.key});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DiscoverRise(
      delayMs: 0,
      child: DiscoverGlass(
        radius: 26,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.pillActive,
                ),
                child: const Icon(
                  Icons.add_home_outlined,
                  size: 32,
                  color: dsNavy,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.locationNoAddressTitle,
                textAlign: TextAlign.center,
                style: authSerif(21, 1.25),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.locationNoAddressBody,
                textAlign: TextAlign.center,
                style: AppText.body.copyWith(
                  fontSize: 14.5,
                  height: 1.45,
                  color: dsText,
                ),
              ),
              const SizedBox(height: 18),
              SnButton(
                key: const Key('discover_empty_add_address_btn'),
                label: l10n.addAddress,
                onPressed: onAdd,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dashed "+ Add address" button under the list.
class AddAddressButton extends StatelessWidget {
  const AddAddressButton({required this.onTap, super.key});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => CustomPaint(
    foregroundPainter: const _DashedBorder(),
    child: Material(
      color: AppColors.whiteA55x8C,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        key: const Key('discover_add_address_btn'),
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_rounded, size: 22, color: AppColors.teal),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).addAddress,
                style: AppText.body.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.teal,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _DashedBorder extends CustomPainter {
  const _DashedBorder();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = AppColors.teal.withValues(alpha: 0.55);
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(20),
        ).deflate(1),
      );
    for (final PathMetric m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 10) {
        canvas.drawPath(m.extractPath(d, d + 6), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => false;
}

/// Saved address: map tile with a pin, title (+ Default), details, options menu and a radio.
/// Selected cards lift, glow teal (red when the area isn't served) and ripple the pin.
class AddressCard extends StatelessWidget {
  const AddressCard({
    required this.address,
    required this.selected,
    required this.served,
    required this.index,
    required this.onTap,
    required this.onEdit,
    required this.onMakeDefault,
    super.key,
  });

  final Address address;
  final bool selected;
  final bool served;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onMakeDefault;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final detail = [
      address.fullLine,
      '${address.city} ${address.pincode}'.trim(),
    ].where((s) => s.isNotEmpty).join(', ');
    final accent = served ? AppColors.teal : AppColors.danger;
    return DiscoverRise(
      delayMs: 240.0 + index * 80,
      child: Semantics(
        selected: selected,
        inMutuallyExclusiveGroup: true,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          offset: Offset(0, selected ? -3 / 92 : 0),
          child: DiscoverGlass(
            radius: 24,
            borderWidth: 2,
            borderColor: selected ? accent : AppColors.whiteA90xE6,
            gradient: selected
                ? LinearGradient(
                    begin: const Alignment(-0.6, -1),
                    end: const Alignment(0.6, 1),
                    colors: [
                      served ? AppColors.grayE2EEECA95 : AppColors.redFEE2E2A90,
                      AppColors.whiteA72xB8,
                    ],
                  )
                : null,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                key: Key('discover_address_${address.id}'),
                borderRadius: BorderRadius.circular(24),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
                  child: Row(
                    children: [
                      _MapTile(id: address.id, selected: selected),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              children: [
                                Text(address.title, style: authSerif(19, 1.2)),
                                if (address.isDefault)
                                  Container(
                                    key: Key(
                                      'discover_default_tag_${address.id}',
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _slate.withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      l10n.defaultTag,
                                      style: AppText.body.copyWith(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: dsText,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              detail,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.body.copyWith(
                                fontSize: 13.5,
                                height: 1.4,
                                color: dsText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          PopupMenuButton<String>(
                            tooltip: l10n.addressMenu,
                            key: Key('discover_address_menu_${address.id}'),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints.tightFor(
                              width: 44,
                              height: 40,
                            ),
                            color: AppColors.whiteA97xF7,
                            elevation: 12,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            icon: const Icon(
                              Icons.more_vert_rounded,
                              size: 20,
                              color: dsMuted,
                            ),
                            onSelected: (v) =>
                                v == 'edit' ? onEdit() : onMakeDefault(),
                            itemBuilder: (_) => [
                              _item('edit', Icons.edit_outlined, l10n.edit),
                              if (!address.isDefault)
                                _item(
                                  'default',
                                  Icons.star_border_rounded,
                                  l10n.locationMakeDefault,
                                ),
                            ],
                          ),
                          _Radio(on: selected, color: accent),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _item(String v, IconData icon, String label) =>
      PopupMenuItem(
        value: v,
        height: 44,
        child: Row(
          children: [
            Icon(icon, size: 18, color: dsNavy),
            const SizedBox(width: 10),
            Text(
              label,
              style: AppText.body.copyWith(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: dsNavy,
              ),
            ),
          ],
        ),
      );
}

class _Radio extends StatelessWidget {
  const _Radio({required this.on, required this.color});
  final bool on;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8, top: 2),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: on ? color : AppColors.whiteA70xB3,
        border: Border.all(
          color: on ? color : AppColors.slate400Light,
          width: 2,
        ),
      ),
      child: on
          ? const Icon(Icons.check_rounded, size: 17, color: AppColors.surface)
          : null,
    ),
  );
}

/// 68px rounded map tile with a pin; selected cards ripple under it.
class _MapTile extends StatelessWidget {
  const _MapTile({required this.id, required this.selected});
  final String id;
  final bool selected;

  // Map windows (x, y of a 100x100 viewBox into the 300x220 street map), picked per address.
  static const _views = [
    Offset(20, 10),
    Offset(170, 100),
    Offset(130, 8),
    Offset(60, 120),
    Offset(190, 30),
  ];

  @override
  Widget build(BuildContext context) {
    final clock = DiscoverClock.of(context);
    final view = _views[id.hashCode.abs() % _views.length];
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surface, width: 2),
        boxShadow: [
          BoxShadow(
            color: dsNavy.withValues(alpha: 0.2),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(child: CustomPaint(painter: _MapPainter(view))),
          if (selected)
            ValueListenableBuilder<double>(
              valueListenable: clock,
              builder: (_, t, _) {
                final p = (t / 1600) % 1;
                return Opacity(
                  opacity: 0.8 * (1 - p),
                  child: Container(
                    width: 30 * (0.3 + 2.1 * p),
                    height: 30 * (0.3 + 2.1 * p),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.teal, width: 2),
                    ),
                  ),
                );
              },
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Icon(
              Icons.location_on_rounded,
              size: 28,
              color: selected ? dsNavy : _slate,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  const _MapPainter(this.view);
  final Offset view;

  static const _block = AppColors.grayF7F2E8;
  static const _park = AppColors.greenCDEBD6;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..scale(size.width / 100)
      ..translate(-view.dx, -view.dy);
    final p = Paint();
    void rect(double x, double y, double w, double h, Color c) =>
        canvas.drawRRect(
          RRect.fromLTRBR(x, y, x + w, y + h, const Radius.circular(8)),
          p..color = c,
        );
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 300, 220),
      p..color = AppColors.grayEAF4F1,
    );
    rect(12, 14, 64, 40, _block);
    rect(96, 14, 70, 40, _block);
    rect(190, 14, 96, 40, _park);
    rect(12, 84, 64, 48, _block);
    rect(96, 84, 70, 48, _block);
    rect(190, 84, 40, 48, _block);
    rect(246, 84, 40, 48, _block);
    rect(12, 160, 100, 48, _park);
    rect(132, 160, 70, 48, _block);
    rect(222, 160, 64, 48, _block);
    final road = Paint()
      ..color = AppColors.surface
      ..style = PaintingStyle.stroke;
    road.strokeWidth = 12;
    for (final y in [69.0, 146.0]) {
      canvas.drawLine(Offset(0, y), Offset(300, y), road);
    }
    road.strokeWidth = 10;
    for (final x in [86.0, 180.0, 238.0]) {
      canvas.drawLine(Offset(x, 0), Offset(x, 220), road);
    }
  }

  @override
  bool shouldRepaint(_MapPainter old) => old.view != view;
}

/// Loading placeholders shaped like [AddressCard].
class AddressSkeleton extends StatelessWidget {
  const AddressSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final clock = DiscoverClock.of(context);
    return Semantics(
      label: AppLocalizations.of(context).loading,
      child: ValueListenableBuilder<double>(
        valueListenable: clock,
        builder: (_, t, _) {
          final k = (t / 1400) % 1;
          Widget bar({double? w, required double h, double r = 10}) =>
              Container(
                width: w,
                height: h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(r),
                  gradient: LinearGradient(
                    begin: Alignment(-1 + 3 * k, 0),
                    end: Alignment(1 + 3 * k, 0),
                    colors: [
                      dsNavy.withValues(alpha: 0.07),
                      dsNavy.withValues(alpha: 0.15),
                      dsNavy.withValues(alpha: 0.07),
                    ],
                  ),
                ),
              );
          return Column(
            children: [
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DiscoverGlass(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          bar(w: 68, h: 68, r: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                bar(w: 110, h: 16),
                                const SizedBox(height: 10),
                                bar(h: 12),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
