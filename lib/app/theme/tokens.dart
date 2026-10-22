import 'package:flutter/material.dart';

/// Design tokens. Brand values are placeholders until design sign-off (OPEN_QUESTIONS #19).
abstract final class AppColors {
  // Auth screens (design: screens 01-03). Sampled from the approved mockups; brand sign-off pending (#19).
  static const navy = Color(0xFF213C61);
  static const navyDeep = Color(0xFF1B3354);
  static const tealDeep = Color(0xFF185968);
  static const teal = Color(0xFF0F766E);
  static const amber = Color(0xFFF59E0B);
  static const warnBg = Color(0xFFFEF3C7);
  static const warn = Color(0xFFD97706);
  static const success = Color(0xFF16A34A);
  static const danger = Color(0xFFDC2626);
  static const ink = Color(0xFF0F172A);
  static const slate = Color(0xFF64748B);
  static const fieldBg = Color(0xFFF8FAFC);
  static const hairline = Color(0xFFE2E8F0);

  static const primary = Color(
    0xFF0F766E,
  ); // TBD-BRAND (matches approved auth designs)
  static const surface = Color(0xFFFFFFFF);
  static const error = Color(0xFFB3261E);

  // Tints and borders used by the feature screens (values moved here unchanged from inline literals).
  static const dangerBg = Color(0xFFFEE2E2);
  static const tealWash = Color(0xFFEAF8F5);
  static const tealMist = Color(0xFFF0FDFA);
  static const successBg = Color(0xFFDCFCE7);
  static const tealSoft = Color(0xFFE6F7F4);
  static const tealSoftAlt = Color(0xFFE6F6F3);
  static const tealLine = Color(0xFFCCEFE9);
  static const amberBg = Color(0xFFFFF1D6);
  static const dangerBgSoft = Color(0xFFFEF2F2);
  static const warnLine = Color(0xFFFDE68A);
  static const dangerLine = Color(0xFFFCA5A5);
  static const slateBg = Color(0xFFF1F5F9);
  static const navyMist = Color(0xFFEFF3F8);
  static const navyMistAlt = Color(0xFFEDF1F7);
  static const successBgAlt = Color(0xFFDFF3E7);
  static const tealLineStrong = Color(0xFFB7E4DC);
  static const amberInk = Color(0xFF7A4B00);
  static const navyMuted = Color(0xFF576C88);
  static const successInk = Color(0xFF14532D);
}

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 20;
  static const double button = 16;
}

/// Minimum touch target (AGENTS §55).
const double kMinTapTarget = 48;
