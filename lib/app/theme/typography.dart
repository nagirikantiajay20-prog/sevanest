import 'package:flutter/material.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';

/// The only place fonts are chosen. The design uses Sitka Heading (a Windows font, not
/// bundleable) for headings, so Source Serif 4 stands in; Inter is the text face.
abstract final class AppFonts {
  static const String body = 'Inter';
  static const String heading = 'SourceSerif4';
}

/// Text styles from the design scale (`--type-*`, `--text-*`). Colours come from the theme, so
/// callers only override a colour when a surface needs it.
abstract final class AppText {
  static const display = TextStyle(
    fontFamily: AppFonts.heading,
    fontSize: 30,
    height: 1.15,
    fontWeight: FontWeight.w700,
    color: AppColors.brandInk,
  );
  static const title = TextStyle(
    fontFamily: AppFonts.heading,
    fontSize: 25,
    height: 1.2,
    fontWeight: FontWeight.w700,
    color: AppColors.brandInk,
  );
  static const screenTitle = TextStyle(
    fontFamily: AppFonts.heading,
    fontSize: 20,
    height: 1.25,
    fontWeight: FontWeight.w700,
    color: AppColors.brandInk,
  );
  static const heading = TextStyle(
    fontFamily: AppFonts.heading,
    fontSize: 19,
    height: 1.25,
    fontWeight: FontWeight.w600,
    color: AppColors.brandInk,
  );
  static const card = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 16,
    height: 1.3,
    fontWeight: FontWeight.w600,
    color: AppColors.brandInk,
  );
  static const bodyLarge = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 15,
    height: 1.4,
    color: AppColors.slate,
  );
  static const body = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 14,
    height: 1.4,
    color: AppColors.slate,
  );
  static const label = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 13,
    height: 1.3,
    fontWeight: FontWeight.w600,
    color: AppColors.brandInk,
  );
  static const meta = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 12,
    height: 1.3,
    color: AppColors.slate,
  );
  static const micro = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 12,
    height: 1.3,
    color: AppColors.slate,
  );
  static const button = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  /// Maps the design scale onto Material roles so un-restyled screens pick it up too.
  static TextTheme get theme => const TextTheme(
    displayLarge: display,
    displayMedium: title,
    displaySmall: screenTitle,
    headlineLarge: title,
    headlineMedium: screenTitle,
    headlineSmall: heading,
    titleLarge: screenTitle,
    titleMedium: card,
    titleSmall: label,
    bodyLarge: bodyLarge,
    bodyMedium: body,
    bodySmall: meta,
    labelLarge: button,
    labelMedium: label,
    labelSmall: micro,
  );
}
