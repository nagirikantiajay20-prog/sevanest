import 'package:flutter/material.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';

/// Initials tile with an optional verified tick. [verified] must come from backend
/// verification status only (AGENTS §27). Photos are out of V1, so there is no image path.
class SnAvatar extends StatelessWidget {
  const SnAvatar({
    required this.name,
    this.size = 56,
    this.verified = false,
    this.round = false,
    super.key,
  });

  final String name;
  final double size;
  final bool verified;
  final bool round;

  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.tealWash,
                  shape: round ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: round
                      ? null
                      : BorderRadius.circular(AppRadius.md),
                ),
                child: Center(
                  child: Text(
                    initials(name),
                    style: AppText.heading.copyWith(
                      color: AppColors.teal,
                      fontSize: size * 0.34,
                    ),
                  ),
                ),
              ),
            ),
            if (verified)
              Positioned(
                right: -size * 0.06,
                bottom: -size * 0.06,
                child: Container(
                  width: size * 0.34,
                  height: size * 0.34,
                  decoration: BoxDecoration(
                    color: AppColors.teal,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                  child: Icon(
                    Icons.check,
                    size: size * 0.2,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
