---
name: SevaNest Customer
description: Verified Help. Trusted Homes.
colors:
  primary: "#0F766E"
  primary-deep: "#0D655E"
  action-deep-teal: "#124E52"
  navy-ink: "#1E3A5F"
  navy-deep: "#1B3354"
  teal-wash: "#EAF8F5"
  teal-mist: "#F0FDFA"
  teal-line: "#CCEFE9"
  tile-well: "#E9F4F2"
  pill-active: "#E2EEEC"
  surface: "#FFFFFF"
  canvas-cool: "#F7F8FB"
  field-bg: "#F8FAFC"
  slate-wash: "#F1F5F9"
  hairline: "#E2E8F0"
  slate-300: "#CBD5E1"
  slate-muted: "#64748B"
  slate-body: "#475569"
  ink: "#0F172A"
  success: "#16A34A"
  success-bg: "#DCFCE7"
  success-text: "#166534"
  warning-amber: "#F59E0B"
  warning-bg: "#FEF3C7"
  warning-text: "#92400E"
  danger: "#DC2626"
  danger-bg: "#FEE2E2"
  danger-text: "#7F1D1D"
  like: "#D6296A"
  ivory: "#FAF8F5"
typography:
  display:
    fontFamily: "SourceSerif4, Georgia, serif"
    fontSize: "30px"
    fontWeight: 700
    lineHeight: 1.15
  title:
    fontFamily: "SourceSerif4, Georgia, serif"
    fontSize: "25px"
    fontWeight: 700
    lineHeight: 1.2
  headline:
    fontFamily: "SourceSerif4, Georgia, serif"
    fontSize: "20px"
    fontWeight: 700
    lineHeight: 1.25
  subhead:
    fontFamily: "SourceSerif4, Georgia, serif"
    fontSize: "19px"
    fontWeight: 600
    lineHeight: 1.25
  card-title:
    fontFamily: "Inter, sans-serif"
    fontSize: "16px"
    fontWeight: 600
    lineHeight: 1.3
  body:
    fontFamily: "Inter, sans-serif"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: 1.4
  label:
    fontFamily: "Inter, sans-serif"
    fontSize: "13px"
    fontWeight: 600
    lineHeight: 1.3
  meta:
    fontFamily: "Inter, sans-serif"
    fontSize: "12px"
    fontWeight: 400
    lineHeight: 1.3
  button:
    fontFamily: "Inter, sans-serif"
    fontSize: "16px"
    fontWeight: 700
rounded:
  sm: "8px"
  md: "12px"
  field: "14px"
  button: "16px"
  card: "20px"
  xl: "24px"
  xxl: "28px"
  sheet: "32px"
  pill: "999px"
spacing:
  xxs: "2px"
  xs: "4px"
  sm: "8px"
  s12: "12px"
  md: "16px"
  s20: "20px"
  lg: "24px"
  xl: "32px"
  xxl: "40px"
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.surface}"
    typography: "{typography.button}"
    rounded: "{rounded.button}"
    height: "52px"
  button-primary-disabled:
    backgroundColor: "{colors.slate-wash}"
    textColor: "{colors.slate-muted}"
  button-outlined:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.navy-ink}"
    rounded: "{rounded.button}"
  button-text:
    textColor: "{colors.primary}"
  input:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.navy-ink}"
    rounded: "{rounded.field}"
    padding: "14px 16px"
  card:
    backgroundColor: "{colors.surface}"
    rounded: "{rounded.card}"
  chip:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.navy-ink}"
    rounded: "{rounded.pill}"
  chip-selected:
    backgroundColor: "{colors.teal-wash}"
  bottom-sheet:
    backgroundColor: "{colors.surface}"
    rounded: "{rounded.sheet}"
  snackbar:
    backgroundColor: "{colors.navy-ink}"
    textColor: "{colors.surface}"
    rounded: "{rounded.md}"
---

# Design System: SevaNest Customer

## Overview

**Creative North Star: "The Trusted Threshold"**

The app is the doorstep where a household decides whether to let someone in. The system is calm and assured: navy carries authority, teal carries reassurance, white and cool-grey canvases keep every screen quiet enough that trust cues (verification badges, fee lines, status timelines) are the loudest things on it. Headings use a serif for human warmth; everything operational is set in Inter.

Density is moderate and mobile-first. Surfaces are white with hairline borders, softly lifted by navy-tinted ambient shadows only where something is a card, sheet, or floating action. Motion is brief and eased; nothing bounces or competes for attention.

The system rejects gig-app urgency (neon discounts, countdowns, loud gradients), clinical enterprise coldness, and lookalikes of competitor apps.

**Key Characteristics:**
- Navy headings, teal actions, slate body text.
- Generous radii (14-20px) with hairline borders.
- Serif headings, sans body.
- Navy-tinted ambient shadows, never black.
- 48px minimum touch targets.

## Colors

A deep navy and teal pair on white, with one warm amber reserved for attention and status colors used strictly semantically.

### Primary
- **Care Teal** (#0F766E): Primary actions, links, focus borders, selected nav, progress. Pressed state is **Deep Teal** (#0D655E); the dark CTA variant is **Harbour Teal** (#124E52).

### Secondary
- **Threshold Navy** (#1E3A5F): All headings and primary text, snackbar background, and the start of the brand gradient (navy to teal, 140deg). **Night Navy** (#1B3354) is its deeper companion.

### Neutral
- **Paper White** (#FFFFFF): default screen and card surface.
- **Cool Canvas** (#F7F8FB) and **Field Mist** (#F8FAFC): grouped backgrounds and field fills.
- **Hairline** (#E2E8F0): borders and dividers.
- **Slate Body** (#475569): body and secondary text (7.5:1 on white). **Slate Muted** (#64748B): hints, disabled text, chevrons (4.8:1).
- **Teal Wash / Mist / Line** (#EAF8F5 / #F0FDFA / #CCEFE9): selected chips, tinted info panels, tile wells (#E9F4F2), active pill (#E2EEEC).
- **Ivory** (#FAF8F5): warm panels, used sparingly.

### Status
- **Success** (#16A34A, bg #DCFCE7, text #166534), **Warning** (amber #F59E0B, bg #FEF3C7, text #92400E), **Danger** (#DC2626, bg #FEE2E2, text #7F1D1D), **Like** (#D6296A) for favourites only.

### Named Rules
**The Quiet Canvas Rule.** Teal appears on actions and selection only; large areas stay white or cool-grey so the primary action is always findable.
**The Semantic Status Rule.** Green, amber, red mean success, caution, error. Never use them decoratively, and never convey status by colour alone.

## Typography

**Display Font:** Source Serif 4 (with Georgia). It stands in for the design's Sitka Heading, which cannot be bundled.
**Body Font:** Inter (with system sans). Devanagari and Telugu text fall back to Noto Sans.

**Character:** A warm serif for moments of welcome and orientation, a neutral sans for work.

### Hierarchy
- **Display** (700, 30px, 1.15): welcome and hero lines.
- **Title** (700, 25px, 1.2): major screen headings.
- **Headline** (700, 20px, 1.25): app bar and dialog titles.
- **Subhead** (600, 19px, 1.25): section headings.
- **Card title** (Inter 600, 16px, 1.3): worker names, list titles.
- **Body** (400, 14-15px, 1.4): copy in Slate Body.
- **Label** (600, 13px): field labels, chips, nav labels (12px).
- **Meta** (400, 12px): timestamps, helper text.
- **Button** (700, 16px).

### Named Rules
**The Serif-for-Welcome Rule.** Serif is for headings only; prices, statuses, fees, and form text are always Inter.

## Layout

Single-column mobile layout on a 4px base. Spacing steps: 2, 4, 8, 12, 16, 20, 24, 32, 40; 16px is the default screen gutter and card padding. Primary actions sit at the bottom of the screen at full width. Keyboard-up states keep the primary action visible. Minimum touch target is 48px.

## Elevation & Depth

Hybrid: hairline borders define surfaces at rest; soft shadows lift only cards, sheets, and floating bars. All shadows are navy-tinted and ambient.

### Shadow Vocabulary
- **Card** (`0 1px 2px #1E3A5F0D, 0 4px 12px #1E3A5F0D`): resting cards.
- **Raised** (`0 2px 6px #1E3A5F12, 0 12px 28px #1E3A5F14`): featured or pressed-up elements.
- **Floating** (`0 -6px 24px #1E3A5F1A`): bottom sheets and sticky action bars.
- **Brand** (`0 6px 16px #0F766E38`): primary CTA glow, used rarely.

### Named Rules
**The Navy Shadow Rule.** Shadows are tinted with navy, never neutral black, and never stack beyond one level per element.

## Shapes

Soft, generous, and consistent: buttons 16px, fields 14px, cards 20px, dialogs 24px, bottom sheets 32px on top corners, chips and pills fully rounded. Borders are 1px Hairline; focus uses a 1.5px teal border.

## Components

### Buttons
- **Shape:** 16px radius, minimum height 52px, full width by default.
- **Primary:** Care Teal fill, white Inter 700/16. Disabled: Slate Wash fill, Slate Muted text.
- **Outlined:** white with 1px Hairline and Navy text. **Text:** teal Inter 700/14.

### Chips
- Pill shape, white with Hairline border, Label text. Selected: Teal Wash fill.

### Cards / Containers
- 20px radius, white, 1px Hairline, no elevation by default (Card shadow when lifted), 16px padding.

### Inputs / Fields
- 14px radius, white fill, 1px Hairline. Focus: 1.5px Care Teal. Error: 1.5px Danger with helper text. Hints in Slate Muted.

### Navigation
- Material navigation bar on white; selected item uses the Active Pill indicator with teal icon and label, unselected Slate Body. App bars are white, flat, with a serif Headline title.

### Sheets, Dialogs, Snackbars
- Sheets: 32px top radius, Floating shadow. Dialogs: 24px radius. Snackbars: floating, Navy fill, white text, 12px radius.

### Motion
- Press 120ms, base 180ms, sheet 250ms, easing `cubic-bezier(0.2, 0.8, 0.2, 1)`.

## Do's and Don'ts

### Do:
- **Do** keep Threshold Navy for headings and Care Teal for actions and selection.
- **Do** show trust cues (verified badge, what-verified-means, fees) at decision points in plain language.
- **Do** use the 48px minimum touch target and the 16px gutter.
- **Do** use tokens from `lib/app/theme/tokens.dart` and `typography.dart`; no hard-coded colours in screens.
- **Do** follow the status colour rules and pair colour with text or an icon.

### Don't:
- **Don't** use countdowns, flashing discount banners, or neon gradients.
- **Don't** use black or neutral-grey shadows, or stack multiple shadows on one element.
- **Don't** set prices, fees, or statuses in the serif face.
- **Don't** copy competitor branding, assets, or layouts.
- **Don't** introduce new radii or colours outside the scales above without updating this file.
