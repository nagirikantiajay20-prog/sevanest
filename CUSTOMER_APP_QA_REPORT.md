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
