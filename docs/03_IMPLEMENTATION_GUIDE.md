# 03 — Step-by-Step Implementation Guide (Customer App)

> **Claude Code: follow this file in order.** It expands AGENTS.md §76 (Development Order). Do not start a step before the previous step's *Exit criteria* pass. Never skip tests.
> Read first: `AGENTS.md` → `docs/02_TECH_STACK_AND_SETUP.md` → this file → `docs/04_SCREEN_SPECS.md` → `docs/05_API_CONTRACT_ASSUMPTIONS.md`.

## How to execute each step (loop)
1. Read the step. Check `docs/05_API_CONTRACT_ASSUMPTIONS.md` for the endpoint; if a real backend contract exists, it overrides.
2. Create domain entity → DTO + mapper → repository interface → remote impl **and** mock impl → notifier → screens (see §Feature template).
3. Add tests listed in the step.
4. Run `dart format . && flutter analyze && flutter test`. Fix all.
5. Update `docs/PROGRESS.md` (tick step) and `OPEN_QUESTIONS.md` (new unknowns).
6. Only then continue.

## Feature template (apply to every feature)
```
features/<f>/
  domain/entities/*.dart              # pure Dart, freezed
  domain/repositories/<f>_repository.dart   # abstract
  domain/usecases/*.dart              # only if logic beyond pass-through
  data/dto/*.dart                     # json_serializable
  data/mappers/*.dart                 # dto -> entity, status -> presentation
  data/datasources/<f>_remote_ds.dart
  data/repositories/<f>_repository_impl.dart
  data/repositories/<f>_repository_mock.dart   # dev flavor only (AGENTS §63)
  presentation/providers/*.dart       # @riverpod notifiers
  presentation/screens/*.dart
  presentation/widgets/*.dart
test/features/<f>/...                  # mirror tree
```
Mock vs remote chosen in a single provider override keyed on `AppConfig.useMocks` (false in stg/prod; enforce with a unit test that asserts prod config → false).

---

## PHASE 1 — Foundation (Weeks 1–4, parallel with design)

**Step 1.1 Create project** — run bootstrap (doc 02 §3). Commit `.fvmrc`, `analysis_options.yaml`, `.gitignore` (add `config/*.secret.json`, `*.jks`, `key.properties`, `google-services*.json` only if team policy says so).
Exit: app runs on emulator in 3 flavors; `flutter analyze` clean.

**Step 1.2 Config & flavors** — `AppConfig`, 3 `main_*.dart`, `bootstrap()`.
Tests: config selection; prod `useMocks == false`.

**Step 1.3 Design tokens + base widgets** — `tokens.dart`, `app_theme.dart` (light; dark optional/TBD), widgets list in doc 02 §6.6. Build a hidden `/dev/gallery` route (dev flavor only) showing every widget/state.
Tests: widget tests for SnButton (loading disables tap), SnTextField (error text), SnEmptyState, SnErrorState (retry callback).

**Step 1.4 Localization** — `l10n.yaml`, `app_en.arb` seeded with keys as screens are added. Helper `context.l10n`.

**Step 1.5 Errors + API client** — `AppFailure`, `error_mapper`, dio provider, interceptors (doc 02 §6.2).
Tests: error mapper table test (400 w/ field errors→Validation, 401→Unauthorized, 403, 404, 409, 5xx, timeout→Network); 401 refresh single-flight test with mocked dio adapter.

**Step 1.6 Secure session store** — `SecureSessionStore` + `sessionProvider` (`AsyncNotifier<Session?>`).
Tests: store contract with in-memory fake.

**Step 1.7 Router shell** — `routes.dart`, `appRouterProvider`, redirect logic using auth + profile-complete state, placeholder screens, bottom navigation shell (Home, Bookings, Favourites, Account — **tab set TBD with design**).
Tests: redirect matrix (unauth→login; auth+incomplete→setup; auth+complete→home).

**Step 1.8 Shared states** — `PagedState`, `AsyncValueView` widget (maps loading/empty/error/data → skeleton/empty/error+retry/content) so every screen is consistent (AGENTS §86).

Exit Phase 1: gallery shows all states; CI green on Android + iOS build.

---

## PHASE 2 — Authentication (Week 5)

**Step 2.1 Splash** — initialise, read session; if token → call `GET /me` (validate/refresh); route. Timeout fallback → login with message (never hang).
**Step 2.2 Login screen** — +91 prefix, 10-digit validator (`^[6-9]\d{9}$`), CTA disabled until valid, calls `POST /auth/otp/request`. Handle rate-limit error (429 → show backend message + retry-after if given).
**Step 2.3 OTP screen** — OTP field (length from backend response `otpLength`, default 6 **TBD**), autofill (`autofillHints: oneTimeCode`; Android SMS Retriever optional), resend countdown (seconds from backend `resendAfterSeconds`, default **TBD**), verify → `POST /auth/otp/verify` → store tokens → fetch profile.
States: invalid, expired, network, too many attempts.
**Step 2.4 Session & logout** — logout calls `POST /auth/logout` (best effort) then clears store + invalidates all providers (`ref.invalidate` on a root `sessionScope`), unregisters FCM token.
**Step 2.5 Profile-complete routing** — `profileComplete` flag from `GET /me`.

Tests: validator unit; OTP notifier state machine (idle→requesting→sent→verifying→success/failure); resend timer (fake async); widget tests for each error; Flow A skeleton.
Security: never log OTP; clear OTP field on failure after N attempts as per backend.
Exit: Flow A (to Profile Setup) passes on mock + against dev backend if available.

---

## PHASE 3 — Customer basics (Weeks 5–6)

**Step 3.1 Profile setup/edit** — fields: name (required), email (optional/required **TBD**), preferred language, mobile (read-only). `GET/PUT /me/profile`. Basic verification status shown read-only (no invented requirements).
**Step 3.2 Addresses** — list/add/edit/delete/set default. Add-address form: label, line1, line2, area (picker from backend **service areas** if provided), city, state, pincode (6-digit validator), optional map pin via `LocationService`. Deleting default requires picking new default (backend rule if any). Empty state: "Add your first address".
Location permission: request only when "Use current location" tapped; denial → manual entry (AGENTS §17).
**Step 3.3 Home** — sections shown only if backend returns data: active booking card, upcoming interview/trial, quick actions (Find a worker, Shortlist, Support), notifications bell. Single `GET /home` **assumed**; fallback compose from individual endpoints. No fake metrics.

Tests: profile validators; address CRUD repository tests; address form widget tests; home renders each optional section/none.
Exit: Flow A complete to Home.

---

## PHASE 4 — Discovery (Weeks 6–7)

**Step 4.1 Categories** — `GET /catalog/categories` (server-driven; icon URL + name + allowed engagement types). Cache in-memory + disk with TTL (non-sensitive). Skeleton while loading; error+retry.
**Step 4.2 Requirement draft** — `ServiceRequirementDraft` (freezed) held in `requirementDraftProvider` (keepAlive during flow, auto-dispose on exit). Steps (one per screen, progress bar, back preserves values):
 1 Category → 2 Engagement (filtered by category) → 3 Address/Location → 4 Timing → 5 Start date → 6 Budget (shown only if category/engagement requires it per backend `requiresBudget`) → 7 Review.
 - Timing UI: V1 minimal = preferred start time + end time/shift chips from backend (`timeSlots`). **Do not** invent recurrence.
 - Start date: `showDatePicker`, `firstDate = today` (+ backend min lead days if provided).
 - Budget: min/max INR numeric fields, min ≤ max, backend range hints.
 - Exit-flow dialog: "Discard draft?" Draft is in-memory only (no persistence of address) — product decision TBD.
**Step 4.3 Search** — `POST /workers/search` (body = requirement) cursor pagination, page size from backend default. `CancelToken` on re-search. Results state: `PagedState<WorkerSummary>`.
**Step 4.4 Filters** — bottom sheet: availability, budget, language(if backend supports); keeps original requirement; "Reset".
**Step 4.5 Worker card** — photo (placeholder), name (ellipsis), experience, skills chips (max 3 + "+n"), languages, area, availability text, `SnBadge` verification from `verificationStatus`, rating + count (hidden if none → "New"), favourite heart.
**Step 4.6 Worker detail** — `GET /workers/{id}`: sections per AGENTS §26; "What does verified mean?" sheet (copy TBD); reviews list (paginated); CTA bar: Request interview/trial, Favourite. Handle `404/410` "no longer available".
**Step 4.7 Favourites** — `PUT/DELETE /favourites/{workerId}`, `GET /favourites`. Optimistic toggle with rollback + snackbar (AGENTS §28). Invalidate detail+list.
**Step 4.8 Empty search** — criteria summary chips + "Edit requirement" + "Retry".

Tests: draft notifier (step validity, back-preserve); engagement filter by category; DTO null-safety (all optional fields missing); pagination append/cursor end; cancel obsolete search; favourite rollback; card widget golden/overflow with long names; Flow B and C.
Exit: Flows B & C pass.

---

## PHASE 5 — Interview / Trial (Week 8)

**Step 5.1 Request** — from worker detail → sheet/screen: type (interview | trial — if backend distinguishes), preferred date + time slot (backend `availableSlots` if offered, else free pick), optional note. `POST /interviews`. Show submitting state; on success navigate to interview detail (replace, not push → no resubmit via back).
**Step 5.2 List/detail** — `GET /interviews`, `/interviews/{id}`; status chip via mapper `InterviewStatusMapper` (unknown enum → neutral "Updated" label, never crash). Actions shown only if `allowedActions` from backend (cancel, reschedule — **assumed**).
**Step 5.3 Outcome & decision** — after completion: "Confirm worker" / "Not a fit" (`POST /interviews/{id}/decision`, **assumed**).

Tests: status mapper incl. unknown; double-tap submit; date validation; Flow D.

---

## PHASE 6 — Booking (Weeks 8–9)

**Step 6.1 Confirm worker** — review screen: worker, requirement, fee breakdown (backend `POST /bookings/quote`, **assumed**), policy text (backend), consent checkbox if legal requires (TBD). CTA → `POST /bookings` with Idempotency-Key generated once per screen instance.
Backend rejection (unavailable/conflict) → error state offering "Find another worker".
**Step 6.2 Booking detail** — header, worker, schedule, status chip, payment status, `SnTimeline` built from backend `timeline[]`, action buttons from `allowedActions` (support, replace, rate, cancel).
**Step 6.3 Booking list** — tabs Current / Past, paginated, pull-to-refresh.
**Step 6.4 Cancellation (if supported)** — `POST /bookings/{id}/cancel` with reason; show refund info from backend. Hidden unless `allowedActions` has it.

Tests: idempotency key stable across retries, new per new attempt after success; timeline renders unknown events; action visibility from backend; back-nav does not re-submit.

---

## PHASE 7 — Payment (Week 9–10)

**Step 7.1 `PaymentService` interface**
```dart
abstract class PaymentService {
  Future<PaymentOutcome> pay(PaymentInit init); // SDK result only: success|cancelled|failed(code)
}
```
`RazorpayPaymentService` implements it; `FakePaymentService` for tests.
**Step 7.2 Flow** — `POST /payments/initiate {bookingId}` → `PaymentInit` (orderId, amount, currency, publicKey) → `PaymentService.pay` → regardless of outcome call `POST /payments/{id}/verify` (send SDK payload) **or** poll `GET /payments/{id}` (backoff, max N) until terminal → update booking.
**Step 7.3 Result screens** — Success (after backend SUCCESS only), Failed (retry same order or re-initiate per backend), Pending ("We're confirming your payment" + refresh; don't allow second payment while PENDING/PROCESSING).
**Step 7.4 App-kill recovery** — persist `pendingPaymentId` (non-sensitive) in shared_preferences; on launch/foreground, if present → fetch status and resolve.
**Step 7.5 Receipts & transactions** — `GET /transactions` (paged), `/transactions/{id}` + receipt URL (open via `url_launcher`/in-app viewer; URL is signed/short-lived — don't cache or log). Refund status chip.
Platform config: Razorpay Android min SDK / ProGuard rules and iOS pod install per package README (check at setup).
Tests: all outcomes mapped; SDK success but backend FAILED → shows failure; duplicate callback idempotent; kill-recovery; Flow E, F.
Security: no secret key; public key from backend response or config.

---

## PHASE 8 — Active service, history, rating (Week 10)

**Step 8.1 Active service screen** — worker card, schedule, backend-provided attendance/status list (`GET /bookings/{id}/attendance`, **assumed**; render whatever statuses exist; empty → "No updates yet"). Quick actions: Support, Request replacement, (Rate when eligible).
**Step 8.2 Service history** — `GET /services/history` paged: Completed / Cancelled / Replaced groups.
**Step 8.3 Rating** — eligibility from `allowedActions.rate`; scale/limits from backend config (default 1–5 **TBD**); optional text; `POST /bookings/{id}/rating`; "already rated" state.
Tests: Flows G, H; duplicate rating blocked; empty attendance.

---

## PHASE 9 — Replacement (Week 10–11)

**Step 9.1 Request** — reason (list from backend `replacementReasons`) + notes (+ optional photo? **no, not V1**). `POST /bookings/{id}/replacement`.
**Step 9.2 Status** — `GET /replacements/{id}` mapped to AGENTS §46 states via `ReplacementStatusMapper`; previous engagement stays visible.
**Step 9.3 Alternatives & selection** — when status has alternatives: reuse worker card list (`GET /replacements/{id}/alternatives`), select → `POST /replacements/{id}/select`. Result goes through backend; show pending confirmation.
Tests: mapper; ineligible → button hidden/message; Flow I.

---

## PHASE 10 — Support & notifications (Weeks 10–12)

**Step 10.1 Support** — categories from backend; create ticket (category, related booking optional, description, priority only if backend lets customer set it); list; detail with status + resolution; no internal owner fields. `POST/GET /tickets`.
**Step 10.2 Report/Block worker** — from worker detail / active service (`POST /workers/{id}/report`, **assumed**; PRD §9.1).
**Step 10.3 Push** — `PushService`: permission request at a sensible moment (after first booking intent, not at launch), get FCM token → `POST /devices` on login & on token refresh; delete on logout. Foreground via local notification; background handler top-level with `@pragma('vm:entry-point')`.
**Step 10.4 Notification centre** — `GET /notifications` paged, mark read.
**Step 10.5 Deep links** — payload `{type, entityId}` → route; **always refetch** entity (AGENTS §50). Cold start (`getInitialMessage`), background (`onMessageOpenedApp`), terminated cases tested manually per release checklist.
Tests: payload→route table; unknown type → notifications tab; Flow J.

---

## PHASE 11 — Hardening (Weeks 12–16)

**Step 11.1** Coverage review against AGENTS §67/§68 — all Flows A–J as `integration_test` (run against mock backend server or fakes).
**Step 11.2** Regression suite + device matrix (AGENTS §69), low-RAM Android, large text 200%, slow network (throttle), airplane mode.
**Step 11.3** Performance profile (DevTools): scrolling worker list, startup.
**Step 11.4** Security pass: grep for secrets/logs; verify no OTP/token logging; release build obfuscation; `allowBackup`; deep-link hijack check (validate IDs, require auth).
**Step 11.5** Accessibility: semantics labels on icon buttons, 48dp targets, contrast, text scale.
**Step 11.6** Store readiness: app icons, splash, privacy labels (data safety / App Privacy), permission strings (`NSLocationWhenInUseUsageDescription`, notifications), screenshots, privacy policy URL (legal TBD), versioning.
**Step 11.7** Release builds: `flutter build appbundle --flavor prod -t lib/main_prod.dart --obfuscate --split-debug-info=build/symbols`; `flutter build ipa` on macOS. TestFlight + Play internal track → UAT (Week 14) → submit (Week 15).

---

## Timeline mapping to PRD (16 weeks)
| Weeks | Customer-app work |
|---|---|
| 1–4 | Phase 1 (setup, tokens, API client, router) while design signs off |
| 5 | Phase 2 + start Phase 3 |
| 6–7 | Phase 3 end, Phase 4 |
| 8 | Phase 5, start Phase 6 |
| 9 | Phase 6, Phase 7 start |
| 10 | Phase 7 end, Phase 8, Phase 9 start, Phase 10 start |
| 11–12 | Phases 9–10 finish, integration complete (M4) |
| 13 | Regression, device testing (M5) |
| 14 | UAT fixes (M6) |
| 15–16 | Release, store, stabilisation (M7) |
