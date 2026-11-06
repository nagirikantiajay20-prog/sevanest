# Customer App Module Status

Date: 2026-11-05. 15 modules (`docs/modules/01..15`). "Verified" means automated test evidence plus any live staging run logged in `docs/PROGRESS.md`; no device run exists for any module.

| # | Module | Status | Why |
|---|---|---|---|
| 01 | Authentication (splash, login, OTP, logout) | **Completed in code, needs verification** | Live request/verify/refresh/logout verified 2026-10-12; real SMS (DLT), 429 shape, logout with a real FCM token unverified |
| 02 | Profile and addresses | **Partially completed** | CRUD done; address home photo and map pin blocked (no endpoint / no provider); customer photo contract assumed |
| 03 | Home and navigation | **Completed** | Live `GET /customers/me/home`; promo carousel not served |
| 04 | Service discovery (7 steps) | **Completed** | Schedule rules and budget filter are client-side / not in the API |
| 05 | Worker search and profile | **Completed** | Live search verified; card price/distance not served |
| 06 | Shortlist | **Completed** | Optimistic with rollback, tested |
| 07 | Interview / trial | **Needs verification; trial missing** | Built on the deployed booking-state model; `allowedActions`/timeline not in Swagger; no trial flow; video join is V2 |
| 08 | Booking | **Completed; reschedule missing** | Invented fee fallback removed this pass; no booking reschedule endpoint |
| 09 | Payment and transactions | **Needs verification** | Staging `POST /payments` verified; Razorpay SDK never run on a phone; receipt PDF endpoint not on staging |
| 10 | Active service, history, rating | **Needs verification** | No ACTIVE/COMPLETED data for the test customer; `POST /ratings` never run |
| 11 | Replacement | **Needs verification** | create/select never run live; alternatives delivery open |
| 12 | Support and safety | **Needs verification** | Reads verified; ticket create/message and report/block never run live |
| 13 | Notifications | **Needs verification** | Centre and deep links tested on fakes; FCM delivery and payload keys unverified |
| 14 | Account and settings | **Partially completed** | Account deletion blocked (retention rules); Hindi/Telugu not shipped |
| 15 | Navigation map / flows | **Completed** | Route-doc sync test exists; no `integration_test` run on a device |

Summary: **Completed 6** (03, 04, 05, 06, 08, 15). **Partially completed 2** (02, 14). **Needs verification 7** (01, 07, 09, 10, 11, 12, 13). **Missing sub-modules**: trial (07), booking reschedule (08). **Broken: none found.** **Blocked pieces**: address photo, map pin, video interview, account deletion.

---

## State coverage and gap closure (2026-11-06)

Per-module automated evidence for initial / loading, success, empty, error and retry. "Mock mode" means `states_matrix_test.dart`, which drives loading / error / offline through the same `MockMode` the dev menu flips.

| Module | Loading | Success | Empty | Error | Retry | Status |
|---|---|---|---|---|---|---|
| Favourites (06) | `module_states_test` | FAV-01..08 | `module_states_test`, FAV-07 | `module_states_test` | `module_states_test` (one request per tap) | VERIFIED (new tests, no code change) |
| Notifications (13) | NOT-04 | centre tests | NOT-04 | NOT-04 | NOT-04 | VERIFIED |
| Support (12) | support_screens_test | support_flow_test | support_screens_test | support_screens_test | support_screens_test | VERIFIED |
| Transactions (09) | mock mode | payment_flow_test | payment_flow_test | payment_flow_test + mock mode | payment_flow_test | VERIFIED |
| Addresses (02) | ADDR-08 | ADDR-08 | ADDR-08 | ADDR-08 | ADDR-08 | VERIFIED |
| Workers search (05) | `module_states_test` + mock mode | worker_search_test | SRCH-07 | SRCH-15, `module_states_test` | SRCH-05/07, `module_states_test` | VERIFIED (new tests for no query, query change, filters to empty and reset) |

Scope: widget tests on fakes. Not run against a live backend or a device (see the 12 skipped live tests).

Fixes this pass that touch modules: 01 Authentication (splash contrast / footer / short-phone layout, login trust strip, OTP error parsing), 02 Addresses (tolerant address parsing), 04 Discovery ("Your choices so far" cells wrap). Status of the 15 modules is unchanged by this pass; no module moved to Completed because the device / live items above are still open.

Blocked items (details in `CUSTOMER_APP_GAP_ANALYSIS.md`): Razorpay and FCM on hardware (09, 13), booking quote and reschedule (08), server receipt PDF (09), `GET /fees/booking` confirmation (08).
