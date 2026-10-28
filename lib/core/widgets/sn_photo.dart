import 'package:flutter/material.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';

/// Photos from the design prototype (`assets/images`, resized for the app).
abstract final class AppPhotos {
  static const room = 'assets/images/login-hero.jpg';
  static const splash = 'assets/images/splash-hero.jpg';

  static const _byService = {
    'cook': 'assets/images/hero-helper.jpg',
    'maid': 'assets/images/service-maid-bed.jpg',
    'nanny': 'assets/images/service-nanny.jpg',
    'baby': 'assets/images/service-nanny.jpg',
    'driver': 'assets/images/service-driver.jpg',
    'elder': 'assets/images/service-elder.jpg',
    'clean': 'assets/images/promo-cleaner.jpg',
  };

  /// The tile photo for a catalogue category, matched on its name or id; null when the design
  /// has none (the tile then keeps its icon).
  static String? forService(String idOrName) {
    final k = idOrName.toLowerCase();
    for (final e in _byService.entries) {
      if (k.contains(e.key)) return e.value;
    }
    return null;
  }
}

/// A photo that fades into [fadeTo] on one side, so text can sit on it. Purely decorative: it
/// is hidden from screen readers and shows nothing if the asset cannot load.
class SnPhotoBackdrop extends StatelessWidget {
  const SnPhotoBackdrop({
    required this.asset,
    this.fadeTo = AppColors.surface,
    this.fadeFromBottom = true,
    this.washAtEdge = 0.8,
    this.leftWash = 0,
    this.alignment = Alignment.center,
    super.key,
  });

  /// Extra wash on the left edge fading to clear on the right, so text sits on the faded side
  /// while the photo stays vivid (designs 04, 09). 0 = none.
  final double leftWash;

  final String asset;
  final Color fadeTo;

  /// True: solid at the bottom (login-style, text below). False: solid at the top (splash-style).
  final bool fadeFromBottom;

  /// How much of [fadeTo] covers the photo at its far edge (0 = none, 1 = solid).
  final double washAtEdge;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final far = fadeTo.withValues(alpha: washAtEdge);
    return ExcludeSemantics(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            asset,
            fit: BoxFit.cover,
            alignment: alignment,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: fadeFromBottom
                    ? [far, fadeTo]
                    : [fadeTo, Colors.transparent],
              ),
            ),
          ),
          if (leftWash > 0)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    fadeTo.withValues(alpha: leftWash),
                    fadeTo.withValues(alpha: leftWash * 0.6),
                    fadeTo.withValues(alpha: 0),
                  ],
                  stops: const [0, 0.5, 0.85],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
