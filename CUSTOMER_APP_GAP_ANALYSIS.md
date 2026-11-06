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
