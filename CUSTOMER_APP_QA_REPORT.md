# Customer App QA Report

Date: 2026-11-05. Branch `master`, nothing committed.

## Results

| Check | Command | Result |
|---|---|---|
| Static analysis (baseline, before edits) | `flutter analyze` | No issues found |
| Static analysis (after edits) | `flutter analyze` | No issues found |
| Full test suite | `flutter test` | **1067 passed, 12 skipped (live-backend tests), 0 failed**. This run overlapped the edits, so it is not a clean post-change run |
| Post-edit re-run of touched areas | booking, interview_trial, home, payment, notifications, worker_search, accessibility | **346 passed, 0 failed** |
| Dev release APK | `flutter build apk --release --flavor dev -t lib/main_dev.dart` | Built, 74.8 MB, overwrote `build/app/outputs/flutter-apk/app-dev-release.apk` |

Test log noise: many `[api] ... 400` lines come from fake clients in tests, not real calls. A `start_date_screen_test.dart` hit-test warning is non-fatal and pre-existing.

## Test changes

`test/features/booking/booking_test.dart`: the confirm-worker test used to assert the fabricated `₹500` / `₹90`. It now asserts none of those amounts or the total row appear when the backend serves no fee. The existing test for a served fee (`₹300`, no invented tax) is unchanged and passes.

## Not executed (no evidence, so not claimed)

- Any device or emulator run: new customer, returning customer, app restart, background / foreground, session expiry on a real session.
- Razorpay SDK success and failure on a phone; FCM delivery; real SMS OTP.
- Live backend runs (the 12 skipped tests need `SEVANEST_LIVE=1` and a staging OTP).
- Real-network failure injection (covered only by fakes and dev-menu mock modes).
- TalkBack and contrast measurement.
- `integration_test/` is empty.

## Evidence-based completion (from `CUSTOMER_APP_PRD_AUDIT.md`, 51 requirement groups)

| Status | Count | Share |
|---|---|---|
| Completed | 24 | 47% |
| Partially completed | 7 | 14% |
| Needs verification | 14 | 27% |
| Not implemented | 2 | 4% |
| Blocked | 4 | 8% |
| Broken | 0 | 0% |

Code-complete (completed + partial + needs verification) is 45 of 51 (88%), but only 47% is fully evidenced. Most of the verification gap needs a device, Firebase, or backend data.

## Known issues

1. Razorpay checkout and FCM are untested on hardware (P0 / P1).
2. Backend dependencies listed in `CUSTOMER_APP_GAP_ANALYSIS.md`.
3. Token drift: 214 `Colors.white` and about 630 inline `Color(0x..)` outside `tokens.dart`.
4. Release signing key and iOS build still outstanding (owner tasks in `docs/PROGRESS.md` 11.5-11.7).

---

## 2026-11-06 verification

| Check | Result |
|---|---|
| `flutter analyze` (final, after all changes) | No issues found |
| `flutter test` (final) | 1075 passed, 12 skipped, 0 failed |
| Integration test `integration_test/customer_booking_flow_test.dart` | Passed on emulator-5554 (Pixel_8 AVD, API 37). Flow: login (invalid number blocked) -> OTP -> profile setup -> Home -> discovery -> results -> worker -> interview request form -> seeded `iv_302` confirm worker -> booking detail. The step from the interview request form to `iv_302` is a route jump to a seeded booking, not a UI-created one. No backend calls (the log showed none after faking the shortlist) |
| New widget tests | Worker reviews empty; OTP, Budget, Start date, Confirm worker at 1.3x (`test/features/text_scale_coverage_test.dart`); payment loading state, taps while verifying, failure then success (`payment_flow_test.dart`). Payment success, duplicate-tap and failure already had tests |
| Screenshots | 81 captured, 6 inspected (see UI/UX audit). No before/after comparison per token batch |
| APK | `flutter build apk --release --flavor dev -t lib/main_dev.dart` succeeded: `build/app/outputs/flutter-apk/app-dev-release.apk`, 78,402,548 bytes (74.8 MB), same path overwritten |

Defects found by the new tests and fixed: OTP ring overflow at 1.3x, Confirm worker date row overflow at 1.3x, profile-setup address save crash with the photo feature off.
Test-environment notes: the emulator needed 4 GB RAM and software GL; the first integration runs failed from emulator memory pressure and from a shared-helper assumption about a tall surface, not from app code.

## Verification run (2026-11-06)

- `flutter analyze`: No issues found.
- `flutter test`: 1075 passed, 12 skipped, 0 failed.
- `flutter test integration_test/customer_booking_flow_test.dart -d emulator-5554 --flavor dev --no-enable-impeller`: 1 test, passed (~100 s).
- `flutter build apk --release --flavor dev -t lib/main_dev.dart`: built `build/app/outputs/flutter-apk/app-dev-release.apk`, 78,468,084 bytes (74.8 MB), same path, flavor and signing as before.
- Visual QA: 240 screenshots over A/B/C, plus 12 re-captures after fixes; see UI_UX audit for the per-screen list. No new widget tests were added for the 7 fixes (they were verified on the emulator only).
- Not run: real device, Razorpay, FCM.

---

## Master QA gap closure run (2026-11-06)

No emulator, app launch, screenshot or integration test was run in this pass (instructed). `integration_test/customer_booking_flow_test.dart` from the earlier pass was not re-run.

| Check | Command | Result |
|---|---|---|
| Static analysis | `flutter analyze` | No issues found (run before the build, after all edits) |
| Full suite | `flutter test` | **1139 passed, 12 skipped (live-backend tests), 0 failed** (about 31 min). Previous recorded run: 1075 passed. The count includes tests added by another editor working in the same checkout during this pass |
| New test files | `flutter test` on the 5 files below | **51 passed** |
| Dev release APK | `flutter build apk --release --flavor dev -t lib/main_dev.dart` | Built, `build/app/outputs/flutter-apk/app-dev-release.apk`, 78,468,084 bytes (74.8 MB), same path, flavor and signing as before (built 14:07 IST, after the last code change). Not installed or launched |

New tests (all added this pass):

| File | Tests | Covers |
|---|---|---|
| `test/features/module_states_test.dart` | 10 | Favourites loading / empty / error / offline / stale refresh with Retry; Workers search no query, loading, error + Retry, query change, filters to empty + Reset |
| `test/features/visual_qa_regression_test.dart` | 11 | the seven earlier visual-QA fixes at 1.3x with real fonts |
| `test/features/service_discovery/summary_chips_test.dart` | 21 | summary cells at 320 / 360 / 393 / 430 dp, 1.0x and 1.3x |
| `test/features/authentication/splash_a11y_test.dart` | 7 | Worker App link position / size / label / tap, WCAG ratios from colour values |
| `test/core/color_token_guard_test.dart` | 2 | no raw colour literal in `lib/` |
| plus 2 in existing files | 2 | `auth_repository_remote_test.dart` (list-valued OTP message), `backend_contract_2026_10_13_test.dart` (tolerant address parsing) |

Test-suite notes:
- A `Some tests failed` first run of the new splash tests was an artefact: images not yet decoded in the first test of a file make the layout shorter. The tests now pre-decode the logo and load the real fonts (`test/helpers/real_fonts.dart`).
- While the full suite ran, other files in the checkout (timing, schedule rules, payment flow, confirm worker, `docs/DECISIONS.md`) were being edited by someone else. They are not part of this pass, were left as found, and their tests are inside the 1139.
- `[api] ... 400` lines in the log come from fakes, as before.

Not executed, so not claimed: any device or emulator run, Razorpay SDK, FCM delivery, real SMS, live backend (12 skipped), TalkBack, screenshots, the integration test.

Completion (evidence-based, this pass only): the 6 original gap groups are FIXED (D, E, F, C-code) or VERIFIED (A, B) with automated evidence; 7 of 7 earlier fixes are regression-tested and 1 of them (login trust strip) was found incomplete and fixed. 7 external items are BLOCKED. PRD-level completion numbers above are unchanged: this pass closed no device-dependent requirement.

## UX regression pass (2026-11-08)

`flutter analyze`: No issues found. `flutter test`: 1156 passed, 12 skipped, 0 failed (automated only; no emulator, no screenshots, no real-device or OS-dialog verification).

| # | Issue | Root cause | Fix | Status |
|---|---|---|---|---|
| 1 | Two notification prompts | `askForPushAfterAction` showed the custom "Stay in the loop" `AlertDialog`, then `FirebaseMessaging.requestPermission()` | Custom dialog removed. `PushController.shouldAsk()` is true only while the OS state is undecided **and** the one-time `push_permission_asked` flag is unset; `allow()` sets the flag, calls the native request once, then binds the token. Granted, denied, permanently denied and previously granted never re-ask. FCM `start()`, token registration/refresh and unregister are unchanged. Files: `push_prompt.dart`, `push_providers.dart`, `push_host.dart`, `interview_request_screen.dart` | FIXED (automated) |
| 2 | Confusing location errors | `GeolocatorLocationService` mapped GPS-off to `denied` and every exception to `unavailable`; both screens showed one generic text | New outcomes `gpsOff` and `network` (SocketException / geocoder `IO_ERROR`), `openLocationSettings()`, one `locationProblemInfo` mapping used by the address form and the Location step. Messages and actions follow the spec table (Open Settings / Location Settings / Try again). Manual entry stays available; no technical text shown | FIXED (automated) |
| 3 | Technical text in messages | `failureMessage` showed any backend message, including `UnknownFailure('cancelled')`; 404 and 429 fell to generic | `failureMessage` now maps NotFound and RateLimited (with retry seconds) and shows backend text only for Validation/Conflict failures when `isCustomerSafe` (no exception names, SQL, JSON, status codes, > 200 chars). `confirm_worker_screen` and the address-form conflict banner use the same check | FIXED (automated) |
| 4 | Outdated Discard dialog (Add Address, Profile) | Used the Material `confirmDialog` | Both now use the navy `showDiscoverDiscard` (same keys kept); body scrolls so 1.3x text on a short phone does not overflow | FIXED (automated) |
| 5 | Minute picker had 00/15/30/45 | Hard-coded list and `/15` snapping | 12 items `00..55`, snapping and index use 5; the API contract is untouched (Q-141 still open) | FIXED (automated) |
| 6 | Duration row overflow in Timing | `Row` with unconstrained `Text` (found by the tests) | Text wrapped in `Flexible` | FIXED (automated) |

Tests: new `test/regression/customer_ux_regression_test.dart` (single native request, message mapping, five location outcomes with actions and retry, Discard keep/discard and 1.3x, all 12 minutes, 12 AM/PM, AM/PM change); updated `location_service_test`, `push_test`, `notification_centre_test`, `interview_test`, `discover_steps_test`, `timing_screen_test`.

Follow-up (same day): the shared `confirmDialog` (delete address, leave payment, block) now uses the navy dialog too, and the unused `notifPrompt*` strings were removed. A grep found no other place where an exception or backend message reaches the UI unfiltered. `flutter analyze` clean, `flutter test` 1156 passed / 12 skipped / 0 failed.

Limitations (OPEN / not verified): the real Android/iOS permission dialogs and the Android 13 "denied once" state are not exercised (fakes only); the one-time flag is what prevents repeat requests. `infoDialog` (two callers) keeps the plain Material style. Integration tests and on-device checks were not run.


## Interview / Trial / availability / contact (2026-11-08)

**Rules.** Regular booking: unchanged (requirement hours checked by the backend at `POST /bookings`). Interview and Trial: `GET /search/workers/{id}/slots` is the one published rule for both ("interview or trial start times", one-hour slots minus held bookings and confirmed interviews, 14 days). The app checks the picked time against those windows plus "not in the past"; a Trial additionally needs the whole visit inside the free windows. The contract has no separate interview-only rule, so none was invented. Worker acceptance and conflicts stay with the backend.

| # | Issue | Root cause | Fix | Status |
|---|---|---|---|---|
| 1 | "The worker is not available for this requirement." on Trial 7 Nov 4 PM (free 4-7 PM) | Every request first makes a regular `POST /bookings` carrying the customer's requirement hours; the backend checks the worker against those hours (422 `WORKER_NOT_ELIGIBLE`), not the interview time. Intermittent = depends on whether requirement hours overlap the worker's | None possible in the app without altering the requirement. App now shows a specific message and keeps every choice; no list lookup after a definite 422. Backend change documented in `docs/BACKEND_REQUESTS.md` | BLOCKED (backend) |
| 2 | Time zone | `preferredAt` was built from the phone's local zone; worker hours and the slot list are India time | `istInstant` builds the UTC instant from the India wall time (4 PM = `10:30Z`); responses read back as India wall time | FIXED (tests) |
| 3 | Stale availability | Slot list could be old at submit | Slots are re-read right before sending; a taken time is reported without sending | FIXED (tests) |
| 4 | Selections lost / retry | Slot cleared on conflict; interview key reused for a changed time; a retry after the interview step failed made a second booking | Selections kept; interview key follows the payload (same request = same key, changed time = new); the booking made for a form is reused on retry | FIXED (tests) |
| 5 | Customer phone masked for workers | Not in this app; worker booking and interview views carry no customer contact at all | Documented endpoint, field and authorization | BLOCKED (backend + worker app) |

Files: `interview.dart`, `interview_repository_remote.dart`, `interview_request_screen.dart`, `app_en.arb` (+ generated), tests `interview_remote_test.dart`, `interview_test.dart`, `test/regression/customer_contact_privacy_test.dart`.

OPEN: the picker still allows any minute inside a free window (earlier decision); if the backend only accepts hour starts it will refuse 16:30. No real booking, payment or backend write was made; the app was not launched.

Results (2026-11-08): `flutter analyze` no issues. `flutter test` 1164 passed / 12 skipped / 0 failed (the live auth test failed once in an earlier run, passed in the final one; it needs the network). New tests: 7 in `interview_remote_test.dart` (IST payload, INTERVIEW type, retry/keys, 422 refusal) plus a trial window test in `interview_test.dart` and 2 in `customer_contact_privacy_test.dart`; INT-04 and INT-05 updated.
