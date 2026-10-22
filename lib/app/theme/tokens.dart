import 'package:flutter/material.dart';

/// Design tokens. Brand values are placeholders until design sign-off (OPEN_QUESTIONS #19).
abstract final class AppColors {
  // Auth screens (design: screens 01-03). Sampled from the approved mockups; brand sign-off pending (#19).
  static const navy = Color(
    0xFF1E3A5F,
  ); // design navy-700 (was 0xFF213C61, sampled)
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

  // Figma design tokens (design/tokens.md). Names follow the design's roles.
  static const brandInk = navy; // headings and primary text
  static const actionDeep = Color(0xFF0D655E); // pressed / deep action
  static const actionDeepTeal = Color(0xFF124E52); // dark CTA
  static const tileWell = Color(0xFFE9F4F2);
  static const tileLine = Color(0xFFC9E2DD);
  static const pillActive = Color(0xFFE2EEEC);
  static const canvasCool = Color(0xFFF7F8FB);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate400 = Color(0xFF94A3B8);
  static const slate600 = Color(0xFF475569);
  static const slate700 = Color(0xFF334155);
  static const like = Color(0xFFD6296A);
  static const likeSoft = Color(0xFFFDE8EF);
  static const successText = Color(0xFF166534);
  static const successLine = Color(0xFFBBF7D0);
  static const warnText = Color(0xFF92400E);
  static const warnIcon = Color(0xFFB45309);
  static const dangerText = Color(0xFF7F1D1D);
  static const dangerBorder = Color(0xFFFECACA);
  static const ivory = Color(0xFFFAF8F5);
  static const ivoryLine = Color(0xFFE6DFD5);
  static const heroGradient = LinearGradient(
    begin: Alignment(-0.6, -1),
    end: Alignment(0.6, 1),
    colors: [navy, teal],
  );
}

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 40;
  static const double xxs = 2;

  /// Off-grid steps the design uses a lot.
  static const double s12 = 12;
  static const double s20 = 20;
}

abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 20;
  static const double button = 16;
  static const double field = 14;
  static const double card = 20;
  static const double xl = 24;
  static const double xxl = 28;
  static const double sheet = 32;
  static const double pill = 999;
}

/// Elevations from the design (`--elevation-*`, `--shadow-brand`).
abstract final class AppShadows {
  static const card = [
    BoxShadow(color: Color(0x0D1E3A5F), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0D1E3A5F), blurRadius: 12, offset: Offset(0, 4)),
  ];
  static const raised = [
    BoxShadow(color: Color(0x121E3A5F), blurRadius: 6, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x141E3A5F), blurRadius: 28, offset: Offset(0, 12)),
  ];
  static const floating = [
    BoxShadow(color: Color(0x1A1E3A5F), blurRadius: 24, offset: Offset(0, -6)),
  ];
  static const brand = [
    BoxShadow(color: Color(0x380F766E), blurRadius: 16, offset: Offset(0, 6)),
  ];
}

abstract final class AppMotion {
  static const press = Duration(milliseconds: 120);
  static const base = Duration(milliseconds: 180);
  static const sheet = Duration(milliseconds: 250);
  static const curve = Cubic(0.2, 0.8, 0.2, 1);
}

/// Minimum touch target (AGENTS §55).
const double kMinTapTarget = 48;
