# PROGRESS (tick a step only when its exit criteria in docs/03 pass: analyzer clean, tests green)

- [x] 1.1 Project (Flutter 3.44.8, `in.sevanest.customer`; analyzer clean, 6 tests green)
- [~] 1.2 Config/flavors — Dart entrypoints, AppConfig, Android dev/stg/prod flavors (dev debug APK builds) DONE. NOT done: iOS schemes/xcconfig (needs Mac/Xcode), per-flavor Firebase files (no Firebase projects yet), release keystore
- [x] 1.3 Tokens + shared widgets + dev widget gallery (`/dev/gallery`, dev flavor only)
- [x] 1.4 l10n (ARB + gen-l10n wired)
- [x] 1.5 API client + errors (auth/refresh interceptor single-flight, safe logging, error mapper) — refresh endpoint is provisional (docs/05)
- [x] 1.6 Session store + AuthNotifier + profileComplete state
- [x] 1.7 Router (all route constants, redirect rules, bottom-nav shell, placeholders; doc-sync test)
- [x] 1.8 Shared states (PagedState, AsyncValueView with loading/empty/error/stale)
- [x] 2.1 Splash (loading / slow / failed states, session restore + GET /customers/me, retry / sign in again / contact support)
- [x] 2.2 Login (design screen 02; real `POST /auth/otp/request`)
- [x] 2.3 OTP (design screen 03; real `POST /auth/otp/verify`; Retry-After honoured; no auto-retries)
- [x] 2.4 Logout - `logoutProvider` (POST /auth/logout best-effort + clear session) plus the Account-screen Log out button with a confirm dialog (tested). FCM unregister joins step 10.3
- [x] 2.5 Profile-complete routing (404 CUSTOMER_PROFILE_NOT_FOUND -> /profile/setup placeholder)
  - Verified live 2026-10-12 against the deployed backend: request, wrong OTP, verify, /customers/me, refresh rotation, logout (`test/live`, run with SEVANEST_LIVE=1). NOT verified live: 429 / Retry-After, the OTP lock-out error code, real SMS delivery (DLT pending -> 503 SMS_NOT_CONFIGURED)
- [~] 3.1 Profile - setup (`POST /customers/me`), view/edit (`PATCH`), validation, error/loading states DONE, 14 widget + 10 mocked repository tests (+3 validator). NOT built: profile photo (no customer endpoint). NOT verified live: authenticated success shapes (needs SEVANEST_TEST_MOBILE/OTP; `test/live/profile_address_live_test.dart` is ready)
- [~] 3.2 Addresses - "Use my current location" in the address form (fills area/city/pincode, sends lat/lng) added; list/add/edit/delete/set-default/select-mode/area picker DONE (`/customers/me/addresses*`, `/service-areas`), 24 widget + 12 mocked repository tests. NOT built: map pin (no map provider approved, #15), address label/line2/state (not in backend, see docs/BACKEND_REQUESTS.md)
- [x] 3.3 Home (design screen 05; mock `HomeRepository` behind the dev-menu API toggle, offline cache, 28 tests; shell back-handling; bell/booking/interview/shortlist/support/hero-service wiring; discover/notifications/support/booking/interview/worker routes are placeholders until their modules)
- [x] 4.1 Categories/Service (design 06) + Engagement (07) + Location (08): catalog mock, shared DiscoverScaffold, GPS via geolocator/geocoding behind LocationService, 29 tests. NOT built: add-address *sheet* with map pin (shared full-screen address form reused instead), serviceability check (no backend flag)
- [x] 4.2 Draft (persisted, restored on Home, clearing rules, whole-draft validation) 
- [x] 4.2b Timing (09) / Start date (10) / Budget (11): schedule + guidance mocks behind the API toggle, SnCalendar, time-picker + date sheets, edit mode on all steps, resume card on Home; 129 new tests (350 total, 8 live skipped). Review built in 4.9. TODO(final pass): optionally auto-open the builder at launch instead of the Home Resume card
- [x] 4.3 Search - `/workers` Results screen (summary chips, infinite scroll, pull-to-refresh, empty / error / stale / footer-retry states, CancelToken on re-search), mock + real `GET /search/workers` repositories, basic card; 11 tests (361 total, 8 live skipped). Provider uses the MOCK until the catalogue returns backend category codes.
- [x] 4.4 Filters - bottom sheet (availability window, language, minimum experience) with Apply / Reset / Close, count badge on the Filter button, filters sent to `GET /search/workers`; 6 tests. NOT built: budget filter (not a backend search param), star-rating filter (OPEN_QUESTIONS #40)
- [x] 4.5 Card - category title (backend sends no name), experience, languages, areas, availability window, up to 3 skill chips + "+n", verified badge from backend status, rating or "New", heart; initials avatar; no overflow at 200% text
- [x] 4.6 Detail - `/workers/:id` (`GET /search/workers/{id}`): profile facts, "What does verified mean?" sheet, reviews preview + `/workers/:id/reviews` (paged), sticky Request interview CTA (prompts "Start a search first" when there is no requirement), 404 -> "no longer available" + Find another. NOT built: report/block menu (module 12), replacement "Choose" mode (module 11)
- [x] 4.7 Favourites - shared optimistic heart with rollback + snackbar, one request per tap burst, shortlist tab (`/shortlist`) with pull-to-refresh, paging, remove + Undo, unavailable rows, empty state
- [x] 4.8 Empty search - criteria chips, Edit requirement (back to Review), Retry
- [x] 4.9 Review (step 7) - requirement card with per-row Edit (edit mode, later values kept), Find workers validates the whole draft then opens Results once (module-04 doc, DISC-14..17); 21 new tests (Flow B + C), 388 total, 8 live skipped
- [x] 5.1 Interview request - `/interviews/new?workerId=` (type, date <= today..+14 d, hourly slots, note <= 300, Submit once with one Idempotency-Key per form, 409 slot-taken, worker-gone dialog, lost-answer recovery, discard dialog); reschedule mode (`&rescheduleId=`)
- [x] 5.2 Detail / list - `/interviews/:id` (status chip, backend timeline or a template, only `allowedActions` buttons, cancel with confirm, support) and `/interviews` (also reachable from the Account tab)
- [x] 5.3 Decision - Confirm worker -> `/bookings/confirm?interviewId=` (placeholder until module 6), Not a fit -> Find another
  - Runs on the ASSUMED contract of docs/05 (the deployed Swagger has no interview endpoints): mock in dev, `InterviewRepositoryRemote` in stg/prod answers 404 until the backend publishes them (docs/BACKEND_REQUESTS.md item 7). 33 new tests, 430 total
- [x] 6.1 Confirm worker - `/bookings/confirm?interviewId=` (the booking id): worker, requirement, start date picker, Confirm worker -> `confirm-worker` once (double tap, lost-answer recovery, worker-gone dialog, 409, bad date), then the booking. NO fee/quote screen: the backend has no quote endpoint and sets the fee at payment (module 7)
- [x] 6.2 Booking detail - `/bookings/:id`: chip + plain-language line, worker, schedule, budget, timeline (backend events or the happy path), payment due row, buttons per allowed actions, refetch on app resume
- [x] 6.3 Booking list - `/bookings` tab: Current | Past over one paged list, pay button on payment-due cards, empty state
- [x] 6.4 Cancel - bottom sheet with a required reason (+ note), `cancel` once, inline error on failure
  - Built on the DEPLOYED booking API (`POST /bookings`, `/bookings/{id}/{action}`). Module 5 now runs on it too: an interview is a booking state, driven by `schedule`, `interview-complete`, `reopen-matching`. `allowedActions` and the timeline are not in the Swagger, so buttons follow the state model until the backend sends them. 35 new tests, 468 total
- [x] 7.1 PaymentService - `PaymentService.pay(Payment) -> PaymentPaid | PaymentCancelled | PaymentSdkFailed`; `RazorpayPaymentService` (`razorpay_flutter`) and `FakePaymentService` (mock mode / tests); live-vs-mock switch like the other modules
- [x] 7.2 Flow - `/payments/new?bookingId=` from the booking detail "Complete payment" and the Bookings list card: `POST /payments` (Idempotency-Key), checkout, `POST /payments/{id}/verify` (fresh key), then `GET /payments/{id}` with 2/4/8/16/30 s backoff until settled. Double tap pays once; Back is blocked while confirming; 409 BOOKING_NOT_PAYABLE -> "Nothing to pay"; 422 FEE_NOT_CONFIGURED explained
- [x] 7.3 Results - success (only when the server says SUCCEEDED; booking, lists and Home refetched), failed (Try again = same booking, new key; Get help; Close), pending (Pay hidden; Check again), cancel (stay on the payment with a note)
- [x] 7.4 Recovery - payment id stored when the checkout opens, cleared when the result is known; `PaymentRecoveryHost` checks on launch, sign-in and resume (settled -> snackbar + refresh; still confirming -> snackbar with View). NOT built: a pending banner on Home / Booking detail
- [x] 7.5 Receipts - Account -> Transactions (`GET /payments`, All / Paid / Refunded chips, paged) and `/transactions/:id` (amount, status chip, receipt number, paid date, refund note, booking link, help). NOT built: receipt download (backend has no receipt URL, request 21), payment method / gateway reference (request 22)
  - 27 widget + 10 repository tests; analyzer clean; full suite 521 passed, 9 live skipped. Verified LIVE (test customer 9999900002, 2026-10-13): 401 without a session, `GET /payments` (+ status filter) parses, 404 on an unknown payment for `GET` and `verify`. NOT verified live: `POST /payments`, `verify`, the `checkout` shape, the Razorpay SDK on a phone (the test customer has no PENDING_PAYMENT booking, and a real checkout needs the gateway test keys from the backend). Requests 20-27 in docs/BACKEND_REQUESTS.md.
- [ ] 8.1 Active service  - [ ] 8.2 History  - [ ] 8.3 Rating
- [ ] 9.1 Replacement request  - [ ] 9.2 Status  - [ ] 9.3 Alternatives
- [ ] 10.1 Support  - [ ] 10.2 Report/Block  - [ ] 10.3 Push  - [ ] 10.4 Notification centre  - [ ] 10.5 Deep links
- [ ] 11.1–11.7 Hardening & release

## Live backend switch (2026-10-13)
stg / prod use the real repositories for categories, worker search + profile, shortlist, guidance (none published) and Home (new-customer view until bookings/interviews exist). Dev starts on mocks; the dev menu has a Live / Mock switch. Remaining external blockers are listed in `docs/BACKEND_REQUESTS.md`; 1.2 (iOS schemes, Firebase files, release keystore) and 3.1 (profile photo) cannot be finished from this repo.

## Backend integration of 2026-10-13 (typed OpenAPI: docs/backend_openapi_2026-10-13.json)
Wired and tested (484 tests, analyzer clean): live `/interviews` (booking first, then interview; reschedule, cancel, complete, accept / reject proposal, `/slots`), worker reviews, `ratingScaleMax`, search `minRating` / `sort` / `startDate`, `GET /customers/me/home`, `/pricing/guidance` (404 hides the card), address `label` / `line2` / `state`, `/locations/service-area` after "Use my current location".
Not built by design: budget filter in search, weekday matching, customer profile photo (backend says out of V1).
Not verified: nothing has run against a live customer (backend not deployed, no test customer). Interview request is built on assumptions the backend marked unconfirmed (1-hour slots, 14-day horizon).
Modules 7-11 (payment, active service, replacement, support, push, hardening) are not started. Release APK is debug-signed until `android/key.properties` exists.
