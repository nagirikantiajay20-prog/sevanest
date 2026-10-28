# Design tokens (extracted from https://growth-glory-58907994.figma.site/, 2026-10-22)

Source: `:root` CSS variables of the Figma Make prototype (238 vars; opacity ramps `--sn-w-*`, `--sn-navy-a-*`, `--sn-teal-a-*`, `--sn-ink-a-*` and the `--fs-*` size ladder omitted).

## Colour
| Role | Token | Value |
|---|---|---|
| Action / primary | `--brand-action` (= teal-600) | `#0F766E` |
| Action deep / pressed | `--brand-action-deep` | `#0D655E` |
| Action deep teal (dark button) | `--sn-action-deep-teal` / `-active` | `#124E52` / `#0D3B3E` |
| Ink (headings) | `--brand-ink` (= navy-700) | `#1E3A5F` |
| Ink soft / muted | `--brand-ink-soft` / `-muted` | `#64748B` / `#94A3B8` |
| Line / soft line | `--brand-line` / `-soft` | `#E2E8F0` / `#F1F5F9` |
| Surface / sunken | `--brand-surface` / `-sunken` | `#FFFFFF` / `#F8FAFC` |
| Canvas cool | `--sn-canvas-cool` | `#F7F8FB` |
| Teal scale | 50 / 100 / 300 / 400 / 500 / 700 | `#F0FDFA` `#CCFBF1` `#5EEAD4` `#38A69B` `#0F8F87` `#267D7C` |
| Tile well / line | `--tile-well` / `--tile-line` | `#E9F4F2` / `#C9E2DD` |
| Pill active bg | `--sn-pill-active-bg` | `#E2EEEC` |
| Navy | 600 / 650 / 700 | `#214267` `#234367` `#1E3A5F` |
| Slate | 50..900 | Tailwind slate (`#F8FAFC` … `#0F172A`) |
| Success | bg / border / icon / text | `#DCFCE7` `#BBF7D0` `#15803D` `#166534` |
| Warning | bg / bg-alt / icon / text | `#FEF3C7` `#FFFBEB` `#B45309` `#92400E` |
| Danger | base / bg / bg-alt / border / deep | `#DC2626` `#FEE2E2` `#FFF1F2` `#FECACA` `#7F1D1D` |
| Like (heart) | base / soft | `#D6296A` / `#FDE8EF` |
| Attention / amber | `--brand-attention` / soft | `#F59E0B` / `#FBBF24` |
| Blue tint | | `#DBEAFE` |
| Warm (ivory) | 50 / 100 / 200 / border / ink / body / panel | `#FAF8F5` `#F4EFE8` `#ECE5DB` `#E6DFD5` `#1F1B16` `#57504A` `#F5EFEA` |
| Brand gradient | | 140deg `#1E3A5F` → `#0F766E` |
| Brand panel | | 158deg `#22456C` 0% → `#1E3A5F` 52% → `#124E52` 100% |

## Typography
- Headings / display: **Sitka Heading** (fallback Georgia, Noto Serif). Sitka is a Windows font: not bundleable.
- Accent text: Sitka Text / Sitka Banner. UI sans: **Inter** (400/500/600/700) + Noto Sans Devanagari 500. Numerals `tabular-nums`.
- Scale (px): annotation 9, micro 10, meta 11, supporting/label 12, body-sm 13, body 14, body-lg/card-title 15, sub-section 16, section 18, title 20, screen-title 24, page-title 26, display 32.
- Newer `--type-*` set: display 30, title 25, heading 19, card 16, body 14, meta 12, micro 11.
- Weights: 400 / 500 / 600 / 700.

## Spacing
2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 28, 32, 36, 40. Minimum touch target 44.

## Radius
xs 2, sm 3, 7–11, md 12, lg 14, 15–19, 20 (`card`), 22, xl 24, 2xl 28, sheet top 32, pill 999, round 50%.

## Elevation
- card: `0 1px 2px #1E3A5F0D, 0 4px 12px #1E3A5F0D`
- raised: `0 2px 6px #1E3A5F12, 0 12px 28px #1E3A5F14`
- floating (sheet): `0 -6px 24px #1E3A5F1A`
- brand: `0 6px 16px #0F766E38`; focus ring `0 0 0 3px #0F766E1A`; inset hairline `inset 0 0 0 1px #E2E8F0`

## Motion
press .12s, base .18s, sheet .25s, slow .26s; ease standard `cubic-bezier(.2,.8,.2,1)`.

## Screens seen so far
1. Splash: centred house+sprout logo, "SevaNest" wordmark (Seva navy / Nest teal), "TRUSTED HOME SERVICES", "Trusted help for your home", 3 trust icons, "Getting things ready…" loader.
3. OTP: "Verify your number", masked 6-digit boxes, "Resend code in 00:22", "Verify & continue", Change number, demo autofill chip (prototype only).
4. Profile setup: "Tell us about you", Full name*, Email (optional), Preferred language chips (EN/HI/TE/TA/KN/MR), "Add your home address" row, Continue, 18+ note.
2. Login: living-room photo hero, "A safer, happier home starts here", 3 trust rows, bottom sheet "Log in or sign up", +91 field, Get OTP, privacy note. (The prototype also has "Continue with WhatsApp"; dropped by decision.)
