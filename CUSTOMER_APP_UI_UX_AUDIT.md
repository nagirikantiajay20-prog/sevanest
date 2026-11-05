# Customer App UI/UX Audit (Impeccable polish)

Date: 2026-11-05. Reference: Impeccable `polish` playbook, `DESIGN.md`, `PRODUCT.md`, `design/tokens.md`. Identity preserved: navy `#1E3A5F` / teal `#0F766E`, glass surfaces, Inter + Source Serif 4.

## Scope and limits (read first)

- **40 screen files** under `lib/features/*/presentation/screens` were inventoried. The audit is a **code-level** review plus the existing automated checks: 13-test accessibility suite at 1.3x text (no overflow, 44 dp targets, labelled targets), the states matrix (loading / error / offline / empty) and the 1.3x checks on discovery, address, ticket, replacement and interview request screens.
- **No rendered screenshots, emulator or device pass was done in this session.** Visual judgement (hierarchy, contrast, spacing on real devices) is therefore not claimed. Contrast and TalkBack remain unverified (also noted in `docs/PROGRESS.md` 11.2).
- The polish applied is the set of defects that code scan could prove.

## Changes made

| Area | Change | Files |
|---|---|---|
| Honest data | Booking confirm no longer shows a fabricated fee / tax; note explains the fee appears at payment | `confirm_worker_screen.dart`, `booking_confirm_parts.dart`, `booking_quote.dart`, `app_en.arb` |
| Touch targets | Tappable interview-row values now have a 44 dp target (opaque hit area) | `interview_detail_parts.dart` |
| Typography | Content captions below 12 sp raised to 12 sp on Home hero, promo carousel, Home widgets, interview list, notification rows, payment, worker result card, glass page | 8 files |

## Screen-by-screen review (code scan)

| Group | Screens | Finding | State |
|---|---|---|---|
| Entry | Splash, Login, OTP | Brand captions 10 to 11.5 sp are decorative and kept; all states exist | OK, device visual check pending |
| Profile | Setup, Profile, Account, Deletion | Consistent glass sections; deletion behind flag | OK |
| Addresses | List, Form, sheet | Skeleton / empty / error present | OK |
| Home | Home | Caption sizes fixed | Polished |
| Discovery | Service, Engagement, Location, Timing, Start date, Budget, Review | 1.3x tests pass; budget switch has a 44 dp target and semantics | OK |
| Search | Results, Worker detail, Reviews, Favourites | Caption sizes fixed; reviews empty state untested | Polished |
| Interview | Request, Detail, List | Touch target fixed | Polished |
| Booking | Confirm, Detail, List | Honest price block | Polished |
| Payment | Payment, Transactions, Receipt | Caption size fixed | Polished |
| Service | Active service, History, Rating | States covered by matrix | OK |
| Replacement | Request, Status | 1.3x checked | OK |
| Support | Home, New ticket, Ticket | States covered | OK |
| Notifications | Centre, Deep link | Caption size fixed | Polished |

Screens audited: 40 (code scan). Screens with a change: 8 groups of files above. Screens visually verified on a device: **0**.

## Known design debt (not changed)

- 214 direct `Colors.white` and about 630 inline `Color(0x..)` literals outside `tokens.dart` (values are on-palette per the 2026-10-22 pass but not all tokenised). Mass migration needs a screenshot regression pass.
- Unthemed Android selection handles / scrollbars not reviewed.
- Hindi / Telugu text expansion cannot be tested until those locales exist.

---

## Pass 2 (2026-11-06): emulator capture

Method: a scratch mock-mode entrypoint (`tool/shots/main_mock.dart`, not committed) ran the dev flavor on an Android emulator (Pixel_8 AVD, software GPU, Impeller off because its GLES backend fails on this emulator) and a scripted sweep captured screens at A 360x640 / 1.0x, B 393x852 / 1.0x, C 393x852 / 1.3x (`wm size` + `font_scale`). Screens are seeded mock data; the real backend was not used.

**Captured:** 81 PNGs (27 routes x 3 configs) in `tool/shots/out` (scratch, not committed). **Visually inspected: 6** (A home, B home, C account, C bookings/bk_2048, A workers/cook-2, plus the first-sweep A/B welcome screen). The remaining 75 were captured but NOT inspected. All ~40 screen files were not covered; the 27 routes are the ones reachable by route without a built-up draft.

Findings from the inspected screens:
- Welcome screen at 360x640 (inspected in the first sweep, before sign-in worked): trust row and Get Started were below the fold, the Driver / Elderly Care badge labels were clipped at the right edge, and the headline wrapped over the photo. **Fixed in code** (`splash_screen.dart`: right badges inset 14 dp, hero minimum height 96 on screens under 700 dp). **Not re-captured after the fix**, so the fix is not visually verified.
- Home, worker profile, account at 360 and 393 wide (1.0x and 1.3x): no overflow or clipping seen; the floating bottom bar overlaps the last visible row by design while content scrolls beneath.
- Booking detail route showed the error state ("Something went wrong" + Retry) in the mock harness; the layout of the error state is fine. The seeded booking did not load in this harness, so the detail screen itself was not seen.

Fixed by widget tests at 1.3x (found real overflows): OTP countdown ring (12 px, now text-scale-free fixed dial) and Confirm worker start-date row (52 px, now scales down). Also found by the integration test: saving the profile-setup address with the photo feature off crashed on `_photo!` (now nullable).

**Remaining / not done:** 75 captured screens uninspected; no per-fix recapture except none; draft-dependent discovery steps (engagement, timing, start date, budget, review) were not captured; loading / empty / success states not captured visually; keyboard and safe-area behavior on device not inspected.
