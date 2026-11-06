# Customer App PRD Audit

Date: 2026-11-05. Branch `master`. Scope: `lib/` of the Customer App only.

## Method and honesty notes

- Requirement source: the per-module specs `docs/modules/01..15` (the PRD is split into these; there is no single PRD file), `docs/04_SCREEN_SPECS.md`, `AGENTS.md`, `PRODUCT.md`, `docs/BACKEND_SCREENS_STATUS.md` and `docs/BACKEND_REQUESTS.md`.
- Granularity: **one row per user-visible requirement group (51 rows)**, not per sentence. The module specs hold several hundred interaction-table rows; those were not each re-verified by hand in this pass. Their status is taken from the progress log (`docs/PROGRESS.md`), the code, and the automated test suite.
- Evidence available: widget / unit tests on fakes and seeded mocks, plus read-only and some write live runs against staging recorded in `docs/PROGRESS.md` (2026-10-12..14). **No device or emulator run, no real FCM delivery, no Razorpay SDK run on a phone, and no live run of this pass** (no staging OTP available to the agent).
- Status rule applied: `COMPLETED` only where the feature is implemented, wired to the real repository, covered by tests, and no unverified critical path remains. A feature whose critical external path (FCM, Razorpay SDK, real payloads) has never run is `NEEDS VERIFICATION`.

## Traceability matrix

| ID | PRD requirement | Module | Expected behaviour | Status | Evidence / file | Gap | Pri |
|---|---|---|---|---|---|---|---|
| R01 | Splash with session restore | 01 | Restore session, `GET /customers/me`, route to login / home / setup, slow + failed states | COMPLETED | `authentication/presentation/screens/splash_screen.dart`, auth_screens tests | none | - |
| R02 | Force update / maintenance gate | 11 | Block on `minVersion`, maintenance | PARTIALLY COMPLETED | `app_gate/`, 15 tests | Store URL not served (BR-57); never run on a release build | P2 |
| R03 | Login by mobile OTP | 01 | `POST /auth/otp/request`, validation, 429 handling | NEEDS VERIFICATION | `login_screen.dart`; live request verified 2026-10-12 | Real SMS (DLT) pending, 429 shape unverified | P1 |
| R04 | OTP verify + resend timer | 01 | `POST /auth/otp/verify`, tokens to secure storage | COMPLETED | `otp_screen.dart`; live verify 2026-10-12 | lock-out error code unconfirmed | P3 |
| R05 | Token refresh single-flight + 401 handling | 01 | refresh once, else sign out | COMPLETED | `core/network/auth_interceptor.dart`; commit 0f27e6c | none | - |
| R06 | Logout (server + local + providers reset) | 01/14 | best effort `POST /auth/logout`, clear session, device token unregister | NEEDS VERIFICATION | `account_providers.dart`, `session_reset_host.dart` | not run with a real FCM token | P2 |
| R07 | Legal consent gate | 01 | Accept terms before use | PARTIALLY COMPLETED | `features/legal/` | `legal.*.url` null on backend | P2 |
| R08 | Profile setup | 02 | `POST/PATCH /customers/me` | COMPLETED | `profile_setup_screen.dart` | none | - |
| R09 | Profile edit / photo | 02 | edit name, language, photo | PARTIALLY COMPLETED | `profile_screen.dart`, `customer_photo_repository_remote.dart` | photo contract assumed (BR) | P2 |
| R10 | Address create / edit / delete / default | 02 | CRUD on `/customers/me/addresses*` | COMPLETED | `addresses/` + tests | none | - |
| R11 | Location (GPS) + service-area check | 02/04 | current location, `/locations/service-area` | NEEDS VERIFICATION | `location_service.dart` | permission dialogs never run on device | P2 |
| R12 | Address home photo | 02 | upload + show | BLOCKED | `home_photo_field.dart` | endpoint not in API (BACKEND_SCREENS_STATUS #5) | P3 |
| R13 | Address map pin | 02 | pick on map | BLOCKED | `address_map_preview.dart` | no map provider approved | P3 |
| R14 | Home (resume card, active booking, interviews, shortlist, bell) | 03 | `GET /customers/me/home` | COMPLETED | `home/` + tests | promo carousel not served | P3 |
| R15 | Bottom nav shell, back behaviour | 03 | 4 tabs | COMPLETED | `main_shell.dart`, nav tests | no device back-button run | P3 |
| R16 | Service category selection | 04 | `/service-categories` | COMPLETED | `service_screen.dart` | none | - |
| R17 | Engagement type | 04 | per-category `allowedEngagements` | COMPLETED | `engagement_screen.dart` | none | - |
| R18 | Location step | 04 | pick/add address | COMPLETED | `location_screen.dart` | serviceability flag per address not served | P3 |
| R19 | Timing / start date | 04 | client-side schedule rules | PARTIALLY COMPLETED | `timing_screen.dart`, `start_date_screen.dart` | schedule rules not in backend config | P3 |
| R20 | Budget + guidance | 04 | `/pricing/guidance` (404 hides) | PARTIALLY COMPLETED | `budget_screen.dart` | no budget filter in search API | P3 |
| R21 | Review + draft persistence | 04 | validate whole draft, resume | COMPLETED | `review_screen.dart` | none | - |
| R22 | Worker search (cursor paging, cancel) | 05 | `GET /search/workers` | COMPLETED | `results_screen.dart` + tests; live verified | price + distance on cards not served | P3 |
| R23 | Filters + sort | 05 | availability, language, experience, rating | PARTIALLY COMPLETED | results filters | star filter scale open (OQ #40) | P3 |
| R24 | Worker profile + verification display | 05 | only backend verified status | COMPLETED | `worker_detail_screen.dart` | about, price, jobs done not served | P3 |
| R25 | Worker reviews | 05 | paged list | COMPLETED | `worker_reviews_screen.dart` | empty-reviews screen untested | P3 |
| R26 | Shortlist add/remove + sync | 06 | optimistic with rollback | COMPLETED | `favourites/` + tests | none | - |
| R27 | Interview request | 07 | slots, note, idempotency | NEEDS VERIFICATION | `interview_request_screen.dart` | slot length / horizon unconfirmed by backend | P1 |
| R28 | Interview detail + customer decision | 07 | only `allowedActions` buttons | NEEDS VERIFICATION | `interview_detail_screen.dart` | `allowedActions` / timeline not in Swagger | P1 |
| R29 | Trial request | 07 | trial flow | NOT IMPLEMENTED | none | PRD marks trial "wherever applicable"; no trial endpoint or spec | P2 |
| R30 | Video interview join | 07 | join call | BLOCKED | none | V2 per backend | P3 |
| R31 | Booking create / confirm worker | 08 | `confirm-worker` once, 409 handling | COMPLETED | `confirm_worker_screen.dart` + tests | none | - |
| R32 | Fee shown before payment | 08 | server fee, never invented | **FIXED THIS PASS** | `booking_quote.dart`; was a hardcoded Rs 500 + 18% tax fallback | now shows "fee shown on payment step" when `/fees/booking` absent; quote endpoint still wanted (BR) | P1 |
| R33 | Booking detail + timeline + allowed actions | 08 | state-driven buttons | COMPLETED | `booking_detail_screen.dart` | `allowedActions` fallback follows state model | P2 |
| R34 | Booking list Current / Past | 08 | paged | COMPLETED | `bookings_list_screen.dart` | search on bookings not served | P3 |
| R35 | Reschedule booking | 08 | reschedule | NOT IMPLEMENTED | none | no endpoint in backend contract (interview reschedule only) | P2 |
| R36 | Cancel booking | 08 | reason + cancel once | COMPLETED | `cancel_sheet.dart` | refund text from backend not served | P3 |
| R37 | Worker matching / assignment status | 08 | backend states rendered | NEEDS VERIFICATION | booking labels | not exercised with real matching data | P2 |
| R38 | Payment initiate + Razorpay + verify + poll | 09 | server-confirmed success only | NEEDS VERIFICATION | `payment_screen.dart`, `payment_services.dart`; staging `POST /payments` verified 2026-10-14 | SDK on a real phone never run | P0 |
| R39 | Payment failure / pending / recovery | 09 | retry same booking, recovery on launch | COMPLETED | payment tests, `PaymentRecoveryHost` | device kill-test not run | P1 |
| R40 | Receipt view / PDF download / share | 09 | `GET /payments/{id}/receipt` | PARTIALLY COMPLETED | `transaction_detail_screen.dart`, commit eb09161 | `/receipt/pdf` not deployed on staging | P2 |
| R41 | Transactions list | 09 | paged, filters | COMPLETED | `transactions_screen.dart` | month summary / search not served | P3 |
| R42 | Active service (attendance) | 10 | `/attendance/...` | NEEDS VERIFICATION | `active_service_screen.dart` | customer token on `/attendance` unconfirmed (BR-28) | P1 |
| R43 | Service history | 10 | `/customers/me/booking-history` | NEEDS VERIFICATION | `service_history_screen.dart` | no live data for test customer | P2 |
| R44 | Rating / review | 10 | one per booking | NEEDS VERIFICATION | `rating_screen.dart` | `POST /ratings` never run; tags appended to text | P1 |
| R45 | Replacement request / status / choose | 11 | full flow | NEEDS VERIFICATION | `replacement/` | create/select never run live; alternatives delivery open (BR-39) | P1 |
| R46 | Support tickets | 12 | create, reply, link entities | NEEDS VERIFICATION | `support/` | create/message not run live | P2 |
| R47 | Report / block worker | 12 | `/safety/*` | NEEDS VERIFICATION | worker detail menu | not run live | P2 |
| R48 | Push notifications (FCM) | 13 | token, foreground banner, tap routing | NEEDS VERIFICATION | `push_service.dart`; Firebase files local | real FCM delivery never verified; project switched to `sevanest-ab168` in 34850f6 | P1 |
| R49 | Notification centre + deep links | 13 | read, mark all, route | COMPLETED | `notification_centre_screen.dart`, `deep_link_screen.dart` + tests | payload `route.type` values unconfirmed | P2 |
| R50 | Account, settings, language | 14 | rows, masked mobile | COMPLETED | `account_screen.dart` | Hindi/Telugu not shipped (product undecided) | P3 |
| R51 | Account deletion | 14 | request deletion | BLOCKED | `account_deletion_screen.dart` behind flag | retention rules + endpoint (OQ #18) | P2 |

## Totals

51 requirement groups: **COMPLETED 24, PARTIALLY COMPLETED 7, NEEDS VERIFICATION 14, NOT IMPLEMENTED 2, BLOCKED 4, BROKEN 0** (R32 counted under COMPLETED after the fix). Percentages in `CUSTOMER_APP_QA_REPORT.md`.

---

## 2026-11-06 status changes

No requirement was moved to COMPLETED in this pass.

| Req | Change | Status |
|---|---|---|
| R03 (OTP) | OTP at 1.3x now tested and a fixed-dial overflow removed | Unchanged (real SMS still blocked on DLT) |
| R32 (quote) | No quote endpoint in OpenAPI 10-13 | BLOCKED (backend) |
| R35 (booking reschedule) | No booking reschedule endpoint | BLOCKED |
| R40 (receipt PDF) | Server endpoint absent from spec; client PDF tested | PARTIALLY COMPLETED |
| R29 (trial) | Trial is an interview type, implemented | PARTIALLY COMPLETED (product spec open) |
| R02 / R07 (legal URLs, config) | Endpoints integrated; URLs null on backend | PARTIALLY COMPLETED |
| R38 (Razorpay) | Payment loading / duplicate / failure states tested with fakes only | NEEDS VERIFICATION on a device |
| UI polish | 81 screenshots captured, 6 inspected | PARTIALLY COMPLETED |
| Color tokens | Raw colors -> 0 outside `tokens.dart`; names not semantic; no per-batch screenshots | PARTIALLY COMPLETED |

## Status update (2026-11-06)

No requirement changed status to COMPLETED in this pass. Changes: seven UI defects fixed (see UI/UX audit), analyze/test/integration green, APK rebuilt. Visual QA: PARTIALLY COMPLETED (states for five screens and success states not capturable in mock mode). Color-token migration: PARTIALLY VERIFIED (B only, hero-card screens unresolved). Booking quote, reschedule, server receipt: BLOCKED. `/fees/booking`: NEEDS VERIFICATION. Razorpay and FCM: need a real device, NOT VERIFIED.
