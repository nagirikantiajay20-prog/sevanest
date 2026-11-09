# Form validation and error handling (customer app)

Statuses used here only: **VERIFIED** (code + relevant automated test confirm it), **IMPLEMENTED** (code exists, no test confirms it), **PARTIAL**, **BLOCKED** (needs backend/client confirmation), **NOT IMPLEMENTED**. Anything judged only by reading source is IMPLEMENTED, not VERIFIED.

## 1. Standards
- Validators: `lib/shared/utils/validators.dart` (`isValidName`, `isValidEmail`, `isValidPincode`, `isBlank`, `withinMax`, `isValidOtp`, `isValidRange`). Client checks are advisory; the backend is authoritative. No limit here is invented: lengths are the per-field `maxLength` already in each screen and the Swagger values noted in `BACKEND_REQUESTS.md`.
- Errors: `DioException` -> `mapDioError` (`core/network/error_mapper.dart`) -> `AppFailure` -> `failureMessage` (`core/localization/failure_message.dart`) -> l10n text. Screens never print exception objects.
- A backend `message` is shown only for 400/422/409 and only when `isCustomerSafe` (a sentence, short, no technical tokens, not a bare code like `ERR_STATE`). Otherwise a friendly fallback is used.
- `isOffline(e)` (`core/errors/app_failure.dart`) is true only for real connection loss. A timeout is `NetworkFailure(timedOut: true)`: screens must not say "you're offline" for it, because the server may have received the request. Offline banners/cards now use `isOffline`.
- Submit state: busy flags block double submits; inputs are kept on failure.

## 2. Error mapping reference
| Cause | Failure | Customer text (l10n key) |
|---|---|---|
| Connection error / SocketException | NetworkFailure | errorNetwork |
| Connect/send/receive timeout, HTTP 408 | NetworkFailure(timedOut) | errorTimeout |
| Body not valid JSON | ServerFailure | errorServer |
| 400/422 | ValidationFailure (+fieldErrors, code) | safe backend message, else errorGeneric; OUTSIDE_SERVICE_AREA / AREA_NOT_AVAILABLE / ADDRESS_NOT_SERVICEABLE -> locationNotServed |
| 401 | UnauthorizedFailure | errorSessionExpired |
| 403 | ForbiddenFailure | errorForbidden |
| 404, 410 | NotFoundFailure | errorNotFound |
| 409 | ConflictFailure(code) | DUPLICATE_BOOKING -> errorDuplicateBooking; WORKER_UNAVAILABLE -> errorWorkerUnavailable; safe message; else errorConflictGeneric |
| 429 | RateLimitedFailure | errorRateLimited / errorRateLimitedIn |
| 5xx | ServerFailure | errorServer |
| other | UnknownFailure | errorGeneric |

## 3. Form inventory and verification
Evidence = existing test names (file) plus tests added in this work (marked NEW).

| Module | Form | Verified by tests | Not covered by a test | Status |
|---|---|---|---|---|
| Auth | Login (mobile) | AUTH-02 10 digits + inline error; network failure keeps number, retry (`auth_screens_test`) | whitespace N/A (digits formatter); timeout card only via mapper test | VERIFIED |
| Auth | OTP | wrong code, expired + resend, 429 lock, duplicate tap verifies once, network keeps typed code (`auth_screens_test`, `otp_controller_test`) | non-digit paste | VERIFIED |
| Profile | Setup (name, email) | PROF-02 name gate, empty email, backend field errors, network keeps values, double tap one request, 409 (`profile_screens_test`) | whitespace-only name at widget level (unit: `isValidName`) | VERIFIED |
| Profile | Edit | edit-save PATCH once, backend validation keeps edit mode; NEW: spaces-only name keeps Save disabled, double tap sends one request, offline and timeout keep the typed name and a retry succeeds (`profile_screens_test`) | | VERIFIED |
| Address | Add/Edit | Save disabled until valid, bad pincode inline, network keeps values, 409 dialog (`address_screens_test`) | max-length (40 label) at widget level | VERIFIED |
| Discovery | Budget min/max | min>max, empty field disable Continue (`budget_screen_test`) | max-value | VERIFIED |
| Discovery | Review note (300) | note kept in draft and trimmed; NEW: spaces-only stored empty, field stops at 300 (`review_screen_test`) | submit happens on the Review screen's Search, covered by `discover_flow_test` | VERIFIED |
| Discovery | Service search, booking-history search | service filter, no-result + clear, debounce, search-first (`discover_steps_test`); NEW: spaces-only lists everything; history search sends the term (`service_screens_test`); NEW: history query drops spaces-only and trims (`upload_and_offline_test`) | worker results have filters only, no free-text box | VERIFIED |
| Interview/Trial | Request (note 300) | submit gate, double tap once, slot-taken 409, network failure stays (`interview_test`) | note max length | VERIFIED |
| Booking | Confirm worker | double tap once, loading gate, 409 not confirmable, network failure (`booking_test`) | | VERIFIED |
| Booking | Cancel sheet | reason required, one call, failure keeps reason (`booking_test`) | whitespace-only note | VERIFIED |
| Replacement | Request | reason gate, "Other" note required, double submit key reuse, 409, offline keeps answers, lost answer reconcile (`replacement_screens_test`); NEW: spaces-only note stays invalid; NEW: timeout is not shown as offline and keeps answers | | VERIFIED |
| Ratings | Rating + comment | star gate, double tap once, 409 exists, network keeps stars+comment, limit from config (`service_screens_test`) | | VERIFIED |
| Support | New ticket (4000) | validation gate, double tap once, error keeps details + same key, lost answer found, offline (`support_screens_test`) | | VERIFIED |
| Support | Ticket reply (2000 in Swagger `PostMessageDto`) | one POST on double tap, shown only after success, failed bubble + retry with same key, offline banner, lost answer, TICKET_CLOSED (`support_screens_test`); NEW: spaces-only never sent, timeout keeps bubble with no offline banner | | VERIFIED |
| Support | Report / safety note | double tap once, failure keeps sheet + input (`safety_test`) | | VERIFIED |
| Active service | Report missing day (note 500 = Swagger `RaiseExceptionDto`) | posts once, 409 keeps form; NEW: spaces-only cannot send, note sent trimmed, stops at 500, timeout message keeps the note (`service_screens_test`) | | VERIFIED |
| Payment | Pay / verify | see section 5 | | VERIFIED |
| Uploads | Profile photo, address home photo | client behaviour: `photo_upload_widget_test` (13 tests), see section 4 | limits and endpoints unconfirmed by backend | BLOCKED |

Totals: 19 forms/areas inventoried; 18 VERIFIED, 1 BLOCKED (uploads: client behaviour tested, the 5 MB / JPEG-PNG limits and home-photo endpoints await backend), 0 IMPLEMENTED, 0 PARTIAL. Ticket attachments (not one of the 19) are NOT IMPLEMENTED (section 4).

## 4. File upload audit
| Flow | Format / size | Empty / invalid | Multi-select | Busy / duplicate | Failure + retry | Status |
|---|---|---|---|---|---|---|
| Profile photo (`ProfilePhotoAvatar`, `CustomerPhotoRepositoryRemote`: `POST /customers/me/photo`, `PUT` to link, `confirm`) | JPEG/PNG by file signature, 5 MB. **Fixed in this work:** the 5 MB check was applied to the home photo only; both now share `checkPhoto` | cancelled picker returns quietly; bad format / too big / permission denied each have their own message | single `pickImage` | `_busy` blocks a second tap while uploading | AppFailure -> `failureMessage` snackbar; the tile stays so the customer taps again | PARTIAL |
| Address home photo (`HomePhotoField`) | same | same | single | field disabled while saving | address saves, photo failure reported, "edit the address to try again" (`address_screens_test` "a failed photo upload still saves the address") | PARTIAL |
| Ticket attachments | n/a | n/a | n/a | n/a | backend schema has no attachment fields (`BACKEND_REQUESTS` 46) | NOT IMPLEMENTED (BLOCKED on backend) |

Tests:
- `test/features/customer_profile/photo_upload_widget_test.dart` (13 widget tests, NEW). Profile photo: GIF refused with message and zero uploads; over 5 MB refused; backing out of the picker uploads nothing and shows nothing; while uploading the tile is disabled, a spinner shows and a second tap uploads nothing; timeout, offline and server failures each show their friendly text (no raw server text) and a retry then succeeds. Address home photo: GIF refused and not handed on; over 5 MB refused; backing out is silent; valid PNG handed on; disabled while the address saves. One test asserts both flows judge the same bytes the same way through `checkPhoto`.
- `test/features/upload_and_offline_test.dart`: `checkPhoto` unit tests (formats, empty, GIF renamed, 5 MB boundary).
- Existing: `customer_photo_repository_test` (link, PUT without auth, confirm), `address_screens_test` ("a failed photo upload still saves the address").
- To make the profile flow testable a `debugPickProfilePhoto` seam was added (mirrors the existing `debugPickHomePhoto`); production behaviour is unchanged.

Findings:
- **Provisional limits.** JPEG/PNG and 5 MB are client rules from `BACKEND_REQUESTS.md`. They are not in the Swagger: the deployed OpenAPI (2026-10-13) has photo routes only for `/workers/me/photo`, whose response carries a server-sent `maxBytes`. The customer photo response in our fixtures also carries `maxBytes`, which the app does not read. **BLOCKED:** backend must confirm the limits and the customer/home photo routes.
- **Timeouts / network loss** use the shared mapper, so the customer sees the timeout or connection text. Covered by the widget tests above for the profile photo; for the home photo the failure path is covered at state level (`address_screens_test`).
- **Duplicate upload:** the profile `_busy` guard is tested; the home photo is uploaded only as part of the address save, whose own busy state is tested.
- **Temporary files:** the app reads picked bytes into memory and writes no copy; the picker downsizes (1024 px profile, 1600 px home). The dev-flavor `CustomerPhotoRepositoryDemo` keeps a photo in SharedPreferences and is not used in the real flavor.
- **Progress:** a spinner only. Dio offers `onSendProgress`, but the upload goes to a pre-signed link as one byte stream and no meaningful progress is surfaced today. Not added; documented as an improvement.
- **Retry:** profile photo: tap the tile again. Home photo: the address is saved and the customer is told to edit the address to try again (by design).

## 5. Payment safety audit (no payment logic changed)
Reviewed `payment_flow.dart` and its tests (`payment_flow_test.dart`, `payment_lifecycle_test.dart`, about 55 widget tests and 30 state tests).
- Double submission: synchronous busy guard; "double tap opens the checkout once", "many taps open the gateway once", "taps while verifying cannot submit a second verification", "pay is ignored while pending". VERIFIED.
- Timeouts / lost answers: "gateway timeout / server down: unresolved, never failed", "lost answer and offline: pending, not failed". The start key is kept when a start's outcome is unknown, so a retry cannot create a second payment. VERIFIED.
- Success only from the backend: "backend FAILED is the only way to the failed view", "unknown backend status stays pending", success test requires backend SUCCEEDED. VERIFIED.
- App interruption: the opened payment id is stored; resume re-reads it ("app resumed: an unresolved payment is read again", "Back while pending keeps the attempt"). VERIFIED.
- Retry: only after backend FAILED, with a new key. VERIFIED.
- Messaging fixed and tested: the payment screen showed "You're offline" whenever a status read failed with any `NetworkFailure`, including a timeout. `payment_flow.dart` `_read` now sets the offline flag only for `isOffline(e)`; a timeout stays unresolved and the screen shows "We're confirming your payment". Only the message flag changed; no start, verify, retry or reconcile logic was touched. NEW widget test: "lost answer and a TIMEOUT: pending copy, never offline or failed" (also asserts one verify call and no Pay button).
- Not assumed: nothing here treats a timeout as failure, retries an initiation, or shows success without backend SUCCEEDED (see the tests above).
- Reconciliation uses the existing `GET` of the payment; no endpoint was invented. Backend idempotency on `POST /payments` and `/verify` is relied upon but not confirmed (section 6).

## 6. Backend clarifications needed
Swagger = `docs/backend_openapi_2026-10-13.json` (latest in the repo). "Declared" means the header or field appears in the spec; it does not prove the server replays or enforces it.

| # | Question | Frontend now | Contract evidence | Missing confirmation / required decision | Impact if unresolved | Status |
|---|---|---|---|---|---|---|
| 1 | OTP / auth error codes | any code containing `OTP`; `EXPIRED` = expired; `LOCK`/`ATTEMPT`/`MAX`/`TOO_MANY` = locked; else invalid (`auth_repository_remote.dart`) | Swagger lists no OTP error codes | publish the exact codes | a renamed code falls back to "invalid code"; a lock could read as a wrong code | BLOCKED |
| 2 | Authoritative max lengths | see list below | Swagger has maxLength for notes, reasons, descriptions; none for name, email, address line/label/pincode | confirm name (2-60), address label (40), line, area, city, pincode | client rule stricter than server blocks a valid entry; looser gets a 422 | BLOCKED for profile/address; matches Swagger elsewhere |
| 3 | Required vs optional per field | per screen | DTO `required` lists exist per endpoint; not cross-checked field by field | one-off review against the DTOs | validation drift | BLOCKED |
| 4 | Photo formats and size | JPEG/PNG, 5 MB (client) | no customer photo route in Swagger; worker route returns `maxBytes` | confirm limits; consider honouring the response `maxBytes` | valid photos refused or oversize accepted | BLOCKED |
| 5 | Home-photo endpoints | assumed (`POST /customers/me/addresses/{id}/photo` ...) | not in Swagger (`BACKEND_REQUESTS`, "Address home photo") | ship or reject the contract | address saves, photo fails with a message | BLOCKED |
| 6 | Booking idempotency | `Idempotency-Key` per screen instance | declared (optional) on `POST /bookings`, interviews, booking actions | confirm replay returns the same booking and the key's lifetime | duplicate bookings after a lost answer | BLOCKED (declared, behaviour unconfirmed) |
| 7 | Payment idempotency | key on `POST /payments` and `/verify`, kept while the outcome is unknown | declared (optional) on both | confirm replay returns the same payment/order | duplicate payment orders | BLOCKED (declared, behaviour unconfirmed) |
| 8 | Duplicate / conflict codes | `DUPLICATE_BOOKING`, `WORKER_UNAVAILABLE`, `WORKER_NOT_ELIGIBLE`, `BOOKING_NOT_PAYABLE`, `INVALID_TRANSITION`, `TICKET_CLOSED`, `RATING_ALREADY_EXISTS` | seen in live traffic and `BACKEND_REQUESTS`; no enum in Swagger | publish the 409/422 code list | an unknown code shows the generic "already updated" text | BLOCKED |
| 9 | Validation error shape | reads `details:[{field, messages[]}]` first, legacy `fieldErrors` map second | Swagger text contains `details`, never `fieldErrors`; no error schema is declared | confirm one schema for all endpoints | field errors not shown under fields on an endpoint that differs | Frontend matches the available evidence; schema still unconfirmed |
| 10 | HTTP 408 | treated as a timeout | not documented | none needed | wording only | not blocking |
| 11 | Replay behaviour in general | n/a | `BACKEND_REQUESTS` says only rebook returns 200 on a replayed key | state it for all idempotent endpoints | retries after lost answers rely on it | BLOCKED |

Field lengths, app vs Swagger: interview note 300 = 300; booking cancel reason (app 300) < 1000; discovery requirement note (app 300, from the design) < `requirementNote` 500; raise exception 500 = 500; replacement notes 2000 and reason 1000; rating review (app, from config) vs 2000; ticket description 4000 = 4000; ticket message (app) vs `PostMessageDto.body` 2000; safety report reason 500, note 1000 (the app's own limits there were not re-checked). A stricter client limit never lets an invalid value through, but may be tighter than needed.

## 7. Error-handling regression audit
All uses of `NetworkFailure` were reviewed.
- `isOffline` (true only for connection loss) now drives: async value view, login card, notification centre, support home, ticket detail, new ticket, replacement request, worker detail, worker search results, payment flow.
- **Fixed in this pass:** `payment_flow._read` (a timeout was flagged offline) and `replacement_status_screen` worker selection (a timeout showed the offline banner; it now re-reads the request like any lost answer, because the write may have gone through).
- Left as is on purpose: `rating_screen` maps any `NetworkFailure` through `failureMessage`, so a timeout shows the timeout text. `failure_message.dart` gives offline, timeout and connection error three different texts (`errorOffline`, `errorTimeout`, `errorNetwork`).
- `NetworkFailure(offline: true)` and `OfflineWriteGuard` were added by another change in this working tree; `isOffline` treats them as offline, which is correct.
- Regression tests: `error_friendly_messages_test`, `upload_and_offline_test` (`isOffline`), and timeout cases for replacement submit, ticket reply, profile edit, active-service note, profile photo and payment.
- Not covered by a widget test: the replacement worker-selection timeout (source change only; IMPLEMENTED).

## 8. Tests added
Previous pass: 16 (9 error-message tests, 4 in `upload_and_offline_test`, 2 replacement widget tests, 1 validator-helper test); the earlier "14" was a miscount.
This pass (executed test cases): payment timeout 1, profile edit 4, review note 2, ticket reply 2, active-service note 4, search 2 (service spaces-only, history query), photo uploads 13 = 28. Final suite totals are in the delivery report.

## 9. Remaining limitations
- Every BLOCKED row in sections 3, 4 and 6.
- No upload progress indicator (improvement, section 4).
- The replacement worker-selection timeout has no widget test.
- Coverage is reported, with no threshold.

## 10. Final run
- `dart format .`: no unformatted files; `flutter analyze`: no issues; `flutter test --coverage`: 1283 passed, 12 skipped, 0 failed.
- Baseline before this pass was 1230 passed; +53 = 28 added here plus 25 from other changes in the working tree (for example `offline_write_guard_test`, `get_retry_and_list_test`) that landed while this work ran.
- Line coverage (`coverage/lcov.info`, whole `lib/`: 90.6 percent, 22909 of 25289 lines): error_mapper 100, failure_message 100, app_failure 100, validators 100, customer_photo_repository_remote 100, home_photo_field 97.7, profile_photo_avatar 94.2, payment_flow 98.7, payment_screen 92.2, raise_exception_sheet 98.6, replacement_status_screen 98.6, offline_write_guard 72.7 (not part of this work). Line coverage does not prove every branch is asserted.
