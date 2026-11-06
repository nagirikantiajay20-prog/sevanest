# Customer App Workflow Audit

Date: 2026-11-05. Method: traced through code (`lib/app/router/routes.dart`, screens, repositories), the route map in `docs/modules/15`, and the existing flow tests (Flow A-J widget tests on fakes). **No workflow was driven on a device or emulator in this pass**; "traced" below means code + test evidence only.

| # | Journey | Screens (route) | Backend calls | Trace result |
|---|---|---|---|---|
| 1 | Splash and onboarding | `/splash` -> `/login` / `/home` / `/profile/setup` | `GET /customers/me`, `GET /app-config` | Traced. Loading / slow / failed states exist |
| 2 | Register / login / OTP / logout | `/login` -> `/otp` -> home or setup | `POST /auth/otp/request`, `/auth/otp/verify`, `/auth/token/refresh`, `/auth/logout` | Traced. Flow A has an end-to-end widget test. Real SMS not testable (DLT) |
| 3 | Profile and account | `/profile/setup`, `/profile`, `/account` | `POST/PATCH /customers/me` | Traced |
| 4 | Addresses and location | `/addresses`, `/addresses/new`, add-address sheet | `/customers/me/addresses*`, `/service-areas`, `/locations/service-area` | Traced; GPS permission not run on device |
| 5 | Discovery -> results | `/discover/*` -> `/workers` | `/service-categories`, `/pricing/guidance`, `GET /search/workers` | Traced; Flow B/C tested |
| 6 | Worker detail, shortlist | `/workers/:id`, `/favourites` | `GET /search/workers/{id}`, `/shortlist` | Traced |
| 7 | Interview request -> decision | `/interviews/new`, `/interviews/:id` | booking-first `/bookings`, `/interviews*`, `/slots` | Traced on the documented contract; backend `allowedActions` unconfirmed |
| 8 | Booking confirm | `/bookings/confirm` | `confirm-worker`, `GET /fees/booking` | Traced. **Defect fixed**: price block displayed a fabricated Rs 500 + 18% tax when the fee was not served |
| 9 | Payment | `/payments/new`, `/payments/:id` | `POST /payments`, `/verify`, `GET /payments/{id}` | Traced; success only on server `SUCCEEDED`; recovery on launch/resume. Razorpay SDK not run on device |
| 10 | Booking tracking, cancel | `/bookings`, `/bookings/:id` | `GET /bookings*`, `/cancel` | Traced; reschedule not available |
| 11 | Active service, rating | `/services/current`, `/ratings/:id` | `/attendance/*`, `POST /ratings` | Traced; never run live |
| 12 | Replacement | `/replacements/new`, `/replacements/:id` | `/replacement-requests*` | Traced; never run live |
| 13 | Support / safety | `/support*` | `/support/*`, `/safety/*` | Traced; writes never run live |
| 14 | Notifications | `/notifications`, `/open?to=` | `/notifications*`, `PUT /auth/device-token` | Traced; FCM delivery unverified |
| 15 | History and transactions | `/services/history`, `/transactions*` | `/customers/me/booking-history`, `/payments*` | Traced |

## Cross-cutting checks

- **Duplicate taps**: submit flows use one Idempotency-Key per form and ignore double taps (interview, confirm, payment, rating, replacement, ticket); covered by named tests.
- **401 handling**: single-flight refresh, then sign-out (`auth_interceptor.dart`).
- **App restart**: draft persisted; payment id stored for recovery; session restored on splash.
- **Dead buttons**: searched for `onPressed: () {}` / `onTap: null` in `lib/`: only the dev widget gallery (dev flavor, not user-facing).
- **Mock leakage**: `useMocks` is false for dev/stg/prod; mock repositories are only reachable from the test config. One hardcoded business value was found and removed (fee).

## Workflow failures found and fixed this pass

1. Confirm booking showed an invented fee and tax (P1) -> removed; screen now says the fee is shown on the payment step unless `GET /fees/booking` served one.
2. Interview detail rows with a tappable value had a text-only touch target (P3) -> 44 dp target.

## Not verified

Everything needing a device, FCM, Razorpay's SDK, real SMS, or backend data the test customer lacks (ACTIVE/COMPLETED bookings, tickets, notifications).

## Same-day booking start date (2026-11-06)

**Status: FIXED** (same-day date selection, tests pass) · **BLOCKED** (exact past-time validation, Q-141) · **OPEN** (see below)

**Root cause.** Not a timezone or serialization bug. `ScheduleConfig.fallback.minLeadDays` was `1` (decision of 2026-10-12, "design greys out today"), so `firstStartDate` = today + 1 and `validateStartDate` returned `tooSoon` for today. Backend accepts today and rejects only earlier dates, and the FRD says "today or later". The remote schedule-config repository is not built yet (mock only), so the fallback is the live rule.

**Affected files.** `lib/features/service_discovery/domain/timing.dart` (`minLeadDays: 0`, new `istDate`), `start_date_screen.dart` and `timing_screen.dart` (pass `istDate(now)` as calendar "today"), `lib/features/booking/presentation/screens/confirm_worker_screen.dart` (India today for the picker's `firstDate`).

**Before / after.** Before: calendar greyed out today, first selectable day was tomorrow (Start date step, Hourly date sheet). After: today and later (to +60 days) selectable, earlier days disabled; Tomorrow / In 3 days / Next Monday shortcuts unchanged; Continue reads "Continue with Fri, 9 Oct" for today. The confirm-worker picker already allowed today (`firstDate: today`).

**Timezone.** Rules compare date-only values. `istDate(instant)` = `instant.toUtc() + 5h30` reduced to Y-M-D (Asia/Kolkata has no DST). Selected dates are local date-only values and are never converted to UTC. At 23:59 IST on 9 Oct today is selectable; at 00:00 IST on 10 Oct it is not.

**API payload.** `BookingRepositoryRemote.day()` writes `yyyy-MM-dd` from the date fields; `POST /bookings` and `confirm-worker` send `startDate: "2026-10-09"` for today (tested). Draft JSON round trip keeps today. No API or DTO change.

**Tests.** `schedule_rules_test.dart` (today/yesterday/tomorrow/future, min-lead-1 config, IST midnight 23:59/00:00, shortcuts rollover, `day()` no shift), `start_date_screen_test.dart` (yesterday disabled, today selectable and stays selected, survives Continue/back, draft restore), `timing_screen_test.dart` (Hourly sheet: today selectable), `backend_contract_2026_10_14_test.dart` (create + confirm-worker payload), `mock_api_test.dart` (fallback = 0). Full `flutter test`: all passed.

**BLOCKED, Q-141.** The contract has a start date plus preferred hours (`availableFrom/To`) and no exact start time. The UI still lets a customer pick a time window that has already ended today (e.g. Morning 08:00-12:00 at 15:00 on a same-day booking). No frontend past-time rule was added: it would invent behaviour the backend does not define. Needs an agreed date-time contract (Q-141).

**OPEN.** (1) Confirm the same-day-with-ended-window case with the backend/product once Q-141 is answered. (2) When a real `GET /catalog/time-slots` repository replaces the mock, confirm it serves `minLeadDays: 0`, else the server value wins.
