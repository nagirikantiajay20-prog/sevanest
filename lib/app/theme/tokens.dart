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
  static const slate = Color(
    0xFF475569,
  ); // body/secondary text: 7.5:1 on white, AA on every tint
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
  static const slate400 = Color(
    0xFF64748B,
  ); // hints, disabled text, chevrons: 4.8:1 on white
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
  // Raw values migrated from lib/features/active_service (exact values; names are hue + hex until design sign-off).
  static const slate400Light = Color(0xFF94A3B8);
  static const tealD6EFEA = Color(0xFFD6EFEA);
  static const teal0B5A53 = Color(0xFF0B5A53);
  static const orange8A4B06 = Color(0xFF8A4B06);
  static const rose100 = Color(0xFFFFE4E6);
  static const rose800 = Color(0xFF9F1239);

  // Raw values migrated from lib/features/addresses (exact values; names are hue + hex until design sign-off).
  static const blue0F2340A38 = Color(0x610F2340);
  static const red700 = Color(0xFFB91C1C);
  static const whiteA88xE0 = Color(0xE0FFFFFF);
  static const whiteA66xA8 = Color(0xA8FFFFFF);
  static const whiteA95xF2 = Color(0xF2FFFFFF);
  static const blue0F2340A34 = Color(0x570F2340);
  static const whiteA90xE6 = Color(0xE6FFFFFF);
  static const teal99E6DC = Color(0xFF99E6DC);
  static const whiteClear = Color(0x00FFFFFF);
  static const whiteA65xA6 = Color(0xA6FFFFFF);
  static const whiteA70xB3 = Color(0xB3FFFFFF);
  static const whiteA40x66 = Color(0x66FFFFFF);
  static const blue600 = Color(0xFF2563EB);
  static const blue800 = Color(0xFF1E40AF);
  static const blue100 = Color(0xFFDBEAFE);
  static const rose700 = Color(0xFFBE123C);
  static const grayEAF4F1 = Color(0xFFEAF4F1);
  static const grayF7F2E8 = Color(0xFFF7F2E8);
  static const greenCDEBD6 = Color(0xFFCDEBD6);
  static const orangeF59E0BA70 = Color(0xB3F59E0B);
  static const blue0F2340A25 = Color(0x400F2340);
  static const blue0F2340A0 = Color(0x000F2340);
  static const blue0F2340A60 = Color(0x990F2340);

  // Raw values migrated from lib/features/authentication (exact values; names are hue + hex until design sign-off).
  static const teal0F766EA34 = Color(0x570F766E);
  static const orangeF59E0BA30 = Color(0x4DF59E0B);
  static const cyan38BDF8A30 = Color(0x4D38BDF8);
  static const teal0F766EA0 = Color(0x000F766E);
  static const transparentBlack = Color(0x00000000);
  static const blackA100xFF = Color(0xFF000000);
  static const sky1B3354A22 = Color(0x381B3354);
  static const blue0F2340A55 = Color(0x8C0F2340);
  static const blackA40x66 = Color(0x66000000);
  static const whiteA62x9E = Color(0x9EFFFFFF);
  static const sky1B3354A12 = Color(0x1F1B3354);
  static const whiteA60x99 = Color(0x99FFFFFF);
  static const sky1B3354A20 = Color(0x331B3354);
  static const whiteA72xB8 = Color(0xB8FFFFFF);
  static const teal0F766EA16 = Color(0x290F766E);
  static const teal0F766EA32 = Color(0x520F766E);
  static const whiteA34x57 = Color(0x57FFFFFF);
  static const whiteA85xD9 = Color(0xD9FFFFFF);
  static const sky1B3354A18 = Color(0x2E1B3354);
  static const teal0F766EA36 = Color(0x5C0F766E);
  static const teal0F766EA40 = Color(0x660F766E);
  static const sky400 = Color(0xFF38BDF8);
  static const sky1B3354A14 = Color(0x241B3354);
  static const grayE2E8F0A70 = Color(0xB3E2E8F0);
  static const orangeF59E0BA22 = Color(0x38F59E0B);
  static const orangeF59E0BA0 = Color(0x00F59E0B);
  static const sky1B3354A26 = Color(0x421B3354);
  static const whiteFBF9F6 = Color(0xFFFBF9F6);
  static const grayF4EFE8 = Color(0xFFF4EFE8);
  static const sky1B3354A30 = Color(0x4D1B3354);
  static const teal0F766EA22 = Color(0x380F766E);
  static const orangeF59E0BA24 = Color(0x3CF59E0B);
  static const teal0F766EA28 = Color(0x470F766E);
  static const whiteFBF9F6A88 = Color(0xE0FBF9F6);
  static const whiteFBF9F6A62 = Color(0x9EFBF9F6);
  static const whiteFBF9F6A0 = Color(0x00FBF9F6);
  static const teal0F766EA30 = Color(0x4D0F766E);
  static const sky1B3354A32 = Color(0x521B3354);
  static const whiteA35x59 = Color(0x59FFFFFF);
  static const blue8D9BB3 = Color(0xFF8D9BB3);

  // Raw values migrated from lib/features/booking (exact values; names are hue + hex until design sign-off).
  static const orange7A4300 = Color(0xFF7A4300);
  static const orange6B3A00 = Color(0xFF6B3A00);
  static const whiteA80xCC = Color(0xCCFFFFFF);
  static const sky1B3354A38 = Color(0x611B3354);
  static const whiteA97xF7 = Color(0xF7FFFFFF);
  static const whiteFAF8F5A97 = Color(0xF7FAF8F5);

  // Raw values migrated from lib/features/customer_profile (exact values; names are hue + hex until design sign-off).
  static const whiteA55x8C = Color(0x8CFFFFFF);
  static const whiteA16x29 = Color(0x29FFFFFF);
  static const orange7A4A06 = Color(0xFF7A4A06);
  static const sky1B3354A28 = Color(0x471B3354);
  static const whiteA36x5C = Color(0x5CFFFFFF);
  static const sky1B3354A16 = Color(0x291B3354);
  static const indigoA78BFA = Color(0xFFA78BFA);

  // Raw values migrated from lib/features/favourites (exact values; names are hue + hex until design sign-off).
  static const teal5EEAD4 = Color(0xFF5EEAD4);
  static const rose600 = Color(0xFFE11D48);
  static const redFFE4EA = Color(0xFFFFE4EA);
  static const whiteA78xC7 = Color(0xC7FFFFFF);
  static const whiteA22x38 = Color(0x38FFFFFF);
  static const redE11D48A50 = Color(0x80E11D48);

  // Raw values migrated from lib/features/home (exact values; names are hue + hex until design sign-off).
  static const sky08182BA55 = Color(0x8C08182B);
  static const sky08182BA10 = Color(0x1A08182B);
  static const sky08182BA92 = Color(0xEB08182B);
  static const blackA35x59 = Color(0x59000000);
  static const sky08182BA85 = Color(0xD908182B);
  static const sky08182BA90 = Color(0xE608182B);
  static const sky08182BA50 = Color(0x8008182B);
  static const sky08182BA5 = Color(0x0D08182B);
  static const blackA30x4D = Color(0x4D000000);
  static const sky12263F = Color(0xFF12263F);
  static const sky08182BA0 = Color(0x0008182B);
  static const sky08182BA60 = Color(0x9908182B);

  // Raw values migrated from lib/features/interview_trial (exact values; names are hue + hex until design sign-off).
  static const whiteA18x2E = Color(0x2EFFFFFF);
  static const whiteA32x52 = Color(0x52FFFFFF);
  static const whiteA86xDB = Color(0xDBFFFFFF);
  static const amber400 = Color(0xFFFBBF24);
  static const emerald400 = Color(0xFF34D399);
  static const whiteA20x33 = Color(0x33FFFFFF);
  static const blackA20x33 = Color(0x33000000);
  static const whiteA14x24 = Color(0x24FFFFFF);
  static const whiteA75xBF = Color(0xBFFFFFFF);
  static const whiteA50x80 = Color(0x80FFFFFF);

  // Raw values migrated from lib/features/notifications (exact values; names are hue + hex until design sign-off).
  static const green15803D = Color(0xFF15803D);
  static const whiteA92xEB = Color(0xEBFFFFFF);
  static const grayECF8F6A85 = Color(0xD9ECF8F6);
  static const whiteA38x61 = Color(0x61FFFFFF);

  // Raw values migrated from lib/features/payment (exact values; names are hue + hex until design sign-off).
  static const redF43F5E = Color(0xFFF43F5E);
  static const orange4A2C00 = Color(0xFF4A2C00);
  static const grayF7F4EE = Color(0xFFF7F4EE);
  static const blue1E3A8A = Color(0xFF1E3A8A);

  // Raw values migrated from lib/features/ratings (exact values; names are hue + hex until design sign-off).
  static const teal0F766EA12 = Color(0x1F0F766E);

  // Raw values migrated from lib/features/replacement (exact values; names are hue + hex until design sign-off).
  static const teal0F766EA10 = Color(0x1A0F766E);
  static const sky1B3354A8 = Color(0x141B3354);
  static const teal0F766EA8 = Color(0x140F766E);

  // Raw values migrated from lib/features/support (exact values; names are hue + hex until design sign-off).
  static const whiteFFF1F2A95 = Color(0xF2FFF1F2);
  static const redFFE4E6A85 = Color(0xD9FFE4E6);

  // Raw values migrated from lib/features/worker_profile (exact values; names are hue + hex until design sign-off).
  static const whiteA30x4D = Color(0x4DFFFFFF);
  static const whiteA15x26 = Color(0x26FFFFFF);
  static const skyCBD5E1A90 = Color(0xE6CBD5E1);
  static const sky1B3354A35 = Color(0x591B3354);
  static const whiteA96xF5 = Color(0xF5FFFFFF);
  static const whiteFAF8F5A96 = Color(0xF5FAF8F5);

  // Raw values migrated from lib/features/worker_search (exact values; names are hue + hex until design sign-off).
  static const sky1B3354A25 = Color(0x401B3354);
  static const sky1B3354A42 = Color(0x6B1B3354);
  static const whiteA84xD6 = Color(0xD6FFFFFF);
  static const whiteFAF8F5A82 = Color(0xD1FAF8F5);

  // Raw values migrated from lib/features/service_discovery (exact values; names are hue + hex until design sign-off).
  static const grayE2EEECA95 = Color(0xF2E2EEEC);
  static const orangeF59E0BA28 = Color(0x47F59E0B);
  static const whiteA42x6B = Color(0x6BFFFFFF);
  static const whiteA82xD1 = Color(0xD1FFFFFF);
  static const whiteA58x94 = Color(0x94FFFFFF);
  static const blue0F2340A45 = Color(0x730F2340);
  static const grayE4E9F2 = Color(0xFFE4E9F2);
  static const blue94A3B8A25 = Color(0x4094A3B8);
  static const blue64748BA45 = Color(0x7364748B);
  static const redFEE2E2A90 = Color(0xE6FEE2E2);
  static const grayE4E9F2A95 = Color(0xF2E4E9F2);
  static const blueB6C0CE = Color(0xFFB6C0CE);
  static const orange78350F = Color(0xFF78350F);
  static const skyBAE6FD = Color(0xFFBAE6FD);
  static const blue312E81 = Color(0xFF312E81);
  static const roseF472B6 = Color(0xFFF472B6);
  static const orangeFDBA74 = Color(0xFFFDBA74);
  static const cyan0EA5E9 = Color(0xFF0EA5E9);
  static const cyan7DD3FC = Color(0xFF7DD3FC);
  static const indigo4C1D95 = Color(0xFF4C1D95);
  static const orangeF97316 = Color(0xFFF97316);
  static const blue020617 = Color(0xFF020617);
  static const blue1E1B4B = Color(0xFF1E1B4B);
  static const indigoC4B5FD = Color(0xFFC4B5FD);
  static const orangeFFE4B5 = Color(0xFFFFE4B5);
  static const orangeFB923C = Color(0xFFFB923C);
  static const amberFFF7CC = Color(0xFFFFF7CC);
  static const amberFDE047 = Color(0xFFFDE047);
  static const amberFFD666A95 = Color(0xF2FFD666);
  static const amberFFD666A25 = Color(0x40FFD666);
  static const teal0F766EA55 = Color(0x8C0F766E);
  static const cyan0F3942A85 = Color(0xD90F3942);
  static const grayEEF2F6 = Color(0xFFEEF2F6);

  // Raw values migrated from lib/core (exact values; names are hue + hex until design sign-off).
  static const blue152A48A90 = Color(0xE6152A48);
  static const blue0F2340 = Color(0xFF0F2340);

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
