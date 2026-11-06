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

## Visual QA follow-up (2026-11-06)

Inspected 10 of the 81 harness screenshots (A login/home/bookings/interview request/worker profile/add address, C account/payment/new ticket/confirm worker). No new layout defects: no clipping or overflow at 1.0x or 1.3x; the floating nav only overlaps scrolled content as designed.
Harness artifacts, not app defects: `login` shows Home (session already signed in); Payment and Confirm worker show their error states because mock mode has no Razorpay and the seeded draft is not loaded; Account header has no name because the mock profile is not loaded.
Still NOT verified: the welcome-screen fix (needs a signed-out launch; the harness build was not relaunched), and about 70 screenshots remain uninspected.

## Visual QA pass 3 (2026-11-06)

Method: emulator-5554 (debug, `tool/shots/main_mock.dart`, scratch harness, not committed), configs A 360x640 @1.0, B 393x852 @1.0, C 393x852 @1.3 text. 240 screenshots captured and inspected via contact sheets (every capture was looked at; per-screen notes below are what was seen, not a pixel audit).

Harness artifacts (not app bugs), now handled in the harness: booking detail "Something went wrong" = mock API seeded as a new customer (no bookings) -> NotFound; Account without a name = demo profile was never created; Payment shows the real screen (Razorpay itself cannot run in mock mode); Confirm worker loads. Harness now seeds profile, address, returning-user bookings, a full draft (Cook / Monthly, because the mock Cook catalog offers only Part-time and Monthly), signed-out reset and mock modes (loading/empty/error/offline).

Defects found and fixed in `lib/` (re-captured at C afterwards, checked in the new shots):
| Screen | Config | Defect | Fix |
|---|---|---|---|
| Interview detail | C | "Your requirement" label broke mid-word ("requiremen/t") | label column scales with text size |
| Interview detail hero | C | step captions ran together ("RequestedScheduled") | 3 dp padding per caption |
| Worker reviews | C | rating bar label "4 / ★" wrapped | label column scales with text size |
| Budget / Review footer | C | CTA cut to "Review requir..." | CTA width scales with text size |
| Login trust strip | B, C | words broke mid-word ("profession/als", "Dedicate/d") | icon above text, full item width |
| Welcome (splash) | A | Get Started was below the fold; only a sliver showed | smaller logo and tagline under 700 dp height; CTA now on screen (checked by pixel scan: CTA rows 1515-1614 of 1680) |
| Workers results | any | title read " near " with no service/area (deep link) | falls back to "Find a worker" |

Splash/welcome verified from a signed-out cold state at A, B, C (A after the fix). Open, not fixed: tagline sits over the photo (busy background, contrast not measured); "Worker App" link on A may need a scroll (not checked after the fix); Discover summary chips truncate ("Madh...") at C; Timing 8-12 shows "Choose at least 6 hours" because the harness draft used a 4 h window (the validation is correct).

State coverage (B only): loading, empty, error, offline for Bookings, Booking detail, Favourites, History, Home, Interviews, Notifications, Support, Transactions, Addresses, Workers. Favourites, Notifications, Support, Transactions and Addresses do not follow the mock modes (live or device-backed repositories), so their empty/error/loading cannot be shown this way: NEEDS VERIFICATION. Workers search states cannot be toggled after the first request (the search provider does not watch the mock mode); empty state is covered by a widget test only. Success states (payment success, booking confirmed) need Razorpay / a real flow: NOT CAPTURED.
