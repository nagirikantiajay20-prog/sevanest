# Customer App Gap Analysis

Date: 2026-11-05. Priorities: P0 critical, P1 high, P2 medium, P3 low. IDs refer to `CUSTOMER_APP_PRD_AUDIT.md`.

## Fixed in this pass

| Gap | Pri | Req | Fix | Evidence |
|---|---|---|---|---|
| Confirm booking displayed a hardcoded Rs 500 fee + 18% tax when the backend served no fee, and the success ticket repeated it | P1 | R32 | `bookingQuote()` returns null without a backend fee; price block, total row and ticket amount are omitted and the note reads "The fee is shown on the payment step." `ConfirmPrice.total` is nullable | `booking_quote.dart`, `confirm_worker_screen.dart`, `booking_confirm_parts.dart`; test `booking_test.dart` updated (asserts no invented amounts) |
| Tappable value on the interview detail row had no 44 dp target | P3 | R28 | 12 dp vertical padding only when the value is tappable | `interview_detail_parts.dart` |
| Content captions at 10 to 11.5 sp (home "delivering to", promo, payment, interview list, notification, result card, glass page) | P3 | UI | raised to 12 sp; brand captions on splash / login / OTP left as designed | 8 files |

## Open: needs a device or live account (cannot be closed locally)

| Gap | Pri | Req | Required action |
|---|---|---|---|
| Razorpay SDK never run on a phone | P0 | R38 | Run a staging payment on an Android device in test mode: success, cancel, failure, app kill mid-payment |
| FCM delivery, permission prompts, cold-start tap routing never verified; Firebase project changed to `sevanest-ab168` | P1 | R48 | Device test with the new `google-services.json`; confirm `route.type` values with backend |
| Interview request / decision rely on unconfirmed slot length, horizon and `allowedActions` | P1 | R27, R28 | Backend confirmation (BACKEND_REQUESTS 7) then a live run |
| Rating, replacement, support and safety writes never run live | P1/P2 | R44-R47 | Staging customer with ACTIVE + COMPLETED bookings (BACKEND_SCREENS_STATUS cross-cutting ask 2) |
| Active service with a customer token | P1 | R42 | Backend confirm of `/attendance` access (request 28) |

## Open: missing or blocked by backend / client decision

| Gap | Pri | Req | Dependency |
|---|---|---|---|
| Quote endpoint `POST /bookings/quote` | P2 | R32 | Backend; until then fee comes from `GET /fees/booking` or "shown at payment" |
| Receipt PDF on staging | P2 | R40 | Backend deploy of `/payments/{id}/receipt/pdf` |
| Booking reschedule | P2 | R35 | No endpoint; product decision |
| Trial request flow | P2 | R29 | Product spec + endpoint |
| Account deletion | P2 | R51 | Retention rules (OQ #18) |
| Legal URLs, store URL, support contacts null in `/app-config` | P2 | R02, R07 | Backend env values |
| Real SMS delivery | P1 | R03 | DLT registration |
| Address photo, map pin, video interview | P3 | R12, R13, R30 | Endpoint / provider / V2 |
| Hindi / Telugu | P3 | R50 | Product decision |
| Price and distance on worker cards, budget filter, star-rating filter scale | P3 | R22, R23 | Backend fields |

## Not done in this pass (honest scope note)

- A per-screen visual review on a rendered device was not performed; the polish changes are limited to defects found by code scan (see `CUSTOMER_APP_UI_UX_AUDIT.md`).
- Remaining direct `Colors.white` (214) and inline `Color(0x..)` (about 630 outside `tokens.dart`) uses are token drift that was not mass-migrated: doing so blindly across 270 files risks visual regressions without a screenshot pass.

---

## 2026-11-06 update

**Fixed (with evidence):** OTP ring and Confirm worker date overflow at 1.3x (widget tests); profile-setup address save crash when the home-photo feature is off (integration test); welcome-screen badge clipping / short-phone CTA (code fix, not re-captured); raw colors migrated to `AppColors` (213 `Colors.white`, 687 `Color(0x..)` -> 0; see `CUSTOMER_APP_COLOR_TOKEN_AUDIT.md`).

**Backend contract recheck (OpenAPI 10-13 is the newest file; 10-12 is older, 169 vs 215 paths):**

| Capability | Contract | Status |
|---|---|---|
| Quote | No `/bookings/quote` | BLOCKED (backend) |
| Receipt PDF | No `/payments/{id}/receipt/pdf` in the spec | BLOCKED for a server PDF; client-side PDF from verified receipt data already exists and is tested |
| Booking reschedule | No booking endpoint | BLOCKED (backend + product) |
| Interview reschedule | `POST /interviews/{id}/reschedule` exists | Already integrated |
| Trial | Modeled as interview type `trial` | Already integrated |
| App config | `GET /app-config` exists | Already integrated (gate, languages, support, legal URLs) |
| Legal | `/legal/current`, `/legal/status`, `/legal/accept` | Consent integrated; legal URLs stay null until backend sets them; none hardcoded |
| Booking fee | `GET /fees/booking` is used by the app but only `/admin/fees` is in the spec | NEEDS VERIFICATION with backend |

No new integration code was written for these.

**Still open:** all device/live items from the earlier table; 75 of 81 captured screens not inspected; no per-batch token screenshot comparison; token names are not semantic; draft-dependent discovery screens, loading/empty states not visually captured; welcome-screen fix not re-captured.

## Contract recheck (2026-11-06)

Newest spec is still `docs/backend_openapi_2026-10-13.json` (215 paths). Nothing new to implement.
| Item | Contract | Status |
|---|---|---|
| Booking quote | no path | BLOCKED |
| Booking reschedule | none under `/bookings`; only `POST /interviews/{id}/reschedule` (already integrated) | BLOCKED |
| Server receipt PDF | payment schemas carry `receiptNumber` only; no document path | BLOCKED (app builds its own PDF from payment data) |
| `GET /fees/booking` | app calls it (`booking_providers.dart`); spec has only `/admin/fees*` | NEEDS VERIFICATION with backend |
| Legal URLs | `LegalDocumentView.url` is nullable and null on the backend | none hardcoded |
New gaps from this pass: mock modes do not reach Favourites, Notifications, Support, Transactions, Addresses (harness/tooling); worker search states untestable by toggle; token-comparison remainder (see token audit).

---

## Master QA gap closure (2026-11-06)

Status words: **FIXED** = implemented and relevant automated tests pass. **VERIFIED** = existing behaviour confirmed, no fix needed. **BLOCKED** = external dependency. **OPEN** = controllable work left. No emulator, app launch or screenshot was used in this pass (instructed), so nothing below is visually verified.

### Original gaps

| # | Gap | Status | What was done / evidence |
|---|---|---|---|
| A1 | Favourites states | VERIFIED | No code defect. New `test/features/module_states_test.dart`: loading skeleton then rows, empty, error + Retry (one request per tap), offline + Retry, failed refresh keeps rows with the stale banner. Existing FAV-01..08 cover success, remove / undo |
| A2 | Notifications states | VERIFIED | `notification_centre_test.dart` NOT-04: empty, loading skeleton, error + Try again recovers, offline, permission banner |
| A3 | Support states | VERIFIED | `support_screens_test.dart`: loading skeleton, error + Try again, empty tickets, tickets error keeps the page + Retry, ticket detail loading / error / 404 |
| A4 | Transactions states | VERIFIED | `payment_flow_test.dart`: rows + filters, empty, list error + Retry recovers; loading / error / offline via `states_matrix_test.dart` (mock modes). No gate-based loading test on the real provider |
| A5 | Addresses states | VERIFIED | `address_screens_test.dart` ADDR-08: loading skeleton, empty CTA, error + retry reloads |
| B | Workers search states | VERIFIED + tests added | New tests: no requirement means no request; loading (skeleton, one request); error then Retry re-sends the same query and recovers; changing the engagement searches again and replaces the list; filters that match nobody show empty and Reset brings the list back. Existing: pagination, footer retry, stale banner, filter sheet apply / reset / close |
| C | Design tokens (checkpoints A, C, hero cards) | FIXED (code); not screenshot-verified | Source-level equivalence check of the migration (see COLOR_TOKEN_AUDIT): 80 of 95 files identical once colours are normalised, the other 15 differ only by deliberate non-colour edits, no token value changed. One raw multi-line `Color(0xFF1B3354)` was missed by the earlier literal grep (splash dots) and is now `AppColors.navyDeep`. New `color_token_guard_test.dart` fails on any raw colour literal. Hero-card pixel differences from the earlier run are explained by the sheen animation plus the 10 to 12 sp caption change; not pixel-proven |
| D | Splash contrast | FIXED | Measured, see UI_UX audit. Tagline sat on the full-screen photo with worst pixels at 0.66:1 to 1.7:1 (mean about 10:1). Added a light plate under caption + tagline (floor 10.2:1 navy, 4.4:1 teal accent, 6.1:1 slate over a black pixel). Version label slate400 to slate600 (4.16 to 6.62:1 on `F4EFE8`) |
| E | Worker App footer link | FIXED | With the real fonts and decoded logo the link was 23 dp below the fold at 360x640 (never re-checked after the earlier splash fix). Hero gap now 24 dp (was 96) on short phones and 130 dp (was 190) on tall ones, tighter header under 560 dp, target 40 to 48 dp. `splash_a11y_test.dart`: on screen at 360x640 and 393x852 with 24 dp system bars, scrolls into reach at 320x568, labelled button, tap with no configured link says so |
| F | Summary chips at 1.3x | FIXED | "Your choices so far" cells used `maxLines: 1` + ellipsis (the "Madh..." cut). Values now wrap. `summary_chips_test.dart`: 21 tests, 320 / 360 / 393 / 430 dp wide, 1.0x and 1.3x, 3-cell ticket and 4-cell grid, long labels, tap target |

### The seven earlier visual-QA fixes: regression tests

All in `test/features/visual_qa_regression_test.dart` (real Inter / Source Serif fonts, 1.3x text). Result: 11 tests, 11 passed.

| # | Fix | Test | Finding |
|---|---|---|---|
| 1 | Interview detail "Your requirement" label | at most 2 lines, no mid-word break | holds |
| 2 | Interview hero step captions | the four captions never touch | holds |
| 3 | Worker reviews rating-bar label | stays on one line | holds |
| 4 | Budget CTA "Review requirement" | whole at 360 and 393 dp, inside the screen | holds |
| 5 | Login trust strip | no mid-word break at 360 and 393 dp | **incomplete**: "professionals" still broke at 360 dp / 1.3x. Fixed (`FittedBox` scale-down) |
| 6 | Welcome: Get Started on a short phone | on screen at 360x640 and 320x568 with system bars | 320x568 was 6 dp off screen; fixed |
| 7 | Workers results title | deep link never reads " near "; with a requirement names service and area | holds |

Pre-fix failure was observed for #5, #6 and the chips; for #1-#4 and #7 the tests were written against the fixed code and were not run against the old code.

### Additional defects found and fixed

| Defect | Root cause | Fix | Test |
|---|---|---|---|
| Login trust text broke mid-word at 360 dp, 1.3x | incomplete earlier fix | `FittedBox(scaleDown)` | regression #5 |
| Welcome "Worker App" 23 dp below the fold on 360x640; 40 dp target | hero minimum height, header block, small button | see E | `splash_a11y_test.dart` |
| 320x568: Get Started 6 dp off screen | halo block 130 dp regardless of logo | header shrinks under 560 dp | regression #6 |
| Splash text over the photo (contrast) | photo fills the screen behind the tagline on short phones and after the zoom | plate | contrast tests |
| Version label contrast 4.16:1 | slate400 on the `F4EFE8` end of the backdrop | slate600 | contrast test |
| Address parse threw on a non-string `label`, `line2`, `state`, `photoUrl`, `unserviceableReason` | `as String?` casts | typed read helper | `backend_contract_2026_10_13_test.dart` |
| OTP error with a list `message` threw a `TypeError` instead of an `OtpFailure` | `data['message'] as String?` | type check | `auth_repository_remote_test.dart` |
| Raw colour literal left after the token migration | multi-line `Color(` not matched by the grep | token | `color_token_guard_test.dart` |
| Dead `FlowChips` and `SelectionChip` widgets (never used) | left from an earlier design | removed (`changeService` kept) | analyzer clean |
| `docs/BACKEND_REQUESTS.md` still described a mock Rs 500 + 18% tax fee | stale after the fee fix | corrected | n/a |

### External dependencies (re-checked against `docs/backend_openapi_2026-10-13.json`, 215 paths, the newest spec)

| Item | Status | Affected feature | Contract status | Missing capability | Needed from backend / device | Frontend meanwhile |
|---|---|---|---|---|---|---|
| Razorpay payment success | BLOCKED (device) | Pay booking (R38) | `POST /payments`, `/payments/{id}/verify`, `GET /payments/{id}` exist | not a contract gap: the SDK has never run on hardware | Android phone, Razorpay **test mode** keys on staging: success, cancel, failure, kill mid-payment | UI, recovery and polling built and tested on fakes. No success is simulated; the app marks paid only on server `SUCCEEDED` |
| Razorpay E2E | BLOCKED (device + service) | same | same | same | real device + payment service + a booking in `PENDING_PAYMENT` | none further |
| FCM E2E | BLOCKED (device + live service) | Notifications (R48) | `PUT /auth/device-token` exists | delivery and payload keys never observed (Firebase project is now `sevanest-ab168`) | device with the new `google-services.json`, a push sent by the backend, confirm `route.type` values | routing and centre tested on fakes |
| Booking quote | BLOCKED (backend) | Confirm booking (R32) | **no** `/bookings/quote` path | fee / tax / total / expiry quote | backend endpoint | shows only a served fee, otherwise says the fee is shown at payment; no invented amounts |
| Booking reschedule | BLOCKED (backend + product) | Bookings (R35) | **none**: `/bookings/{id}/{action}` lists match, schedule, decline, reopen-matching, interview-complete, confirm-worker, start, complete, cancel. Only `POST /interviews/{id}/reschedule` exists (integrated) | booking reschedule | backend endpoint + product decision | none; no UI invented |
| Server receipt PDF | BLOCKED (backend) | Receipt (R40) | **none**: `receiptNumber` is a field only, no document path | server-generated PDF | backend endpoint | client PDF built from verified payment data is shipped and tested |
| `GET /fees/booking` | BLOCKED (backend confirmation) | Confirm booking fee | **absent** from the spec (only `/admin/fees*`); the app calls it | customer fee read | backend to confirm the path exists for customers, or say where the fee is served | returns null on any failure and shows the note |
