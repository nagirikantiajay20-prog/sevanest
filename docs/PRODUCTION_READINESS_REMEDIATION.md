# Production readiness remediation register

Status vocabulary: FIXED AND VERIFIED, PARTIALLY FIXED, BLOCKED BY EXTERNAL DEPENDENCY, NOT REPRODUCED, NOT STARTED.
Last updated 2026-11-08. Nothing here is runtime/device verified.

| ID | Finding | Reproduced | Status | Evidence / notes |
|---|---|---|---|---|
| F1 | stg/prod share dev backend URL | CONFIRMED | PARTIALLY FIXED, BLOCKED | `AppConfig` stg/prod now read `--dart-define=API_BASE_URL` with no default; `AppConfig.problem` + `bootstrap` refuse to start on a missing/non-https/dev-URL/mock config. Tests in `test/core/core_foundation_test.dart`. **Needs from backend team:** isolated staging and production URLs and confirmation of separate databases. CI/gradle build commands for stg/prod must now pass the define. |
| F2 | Offline guard only on payment | CONFIRMED | FIXED (unit-verified) | `lib/core/network/offline_write_guard.dart`, registered first in `dioProvider`. Refuses every POST/PUT/PATCH/DELETE offline (exempt: `/auth/logout`, `/auth/device-token`), nothing queued/replayed, new `NetworkFailure.offline` + `errorOffline` message. `test/core/offline_write_guard_test.dart`. Not covered: uploads to pre-signed URLs use separate Dio (preceded by a guarded POST); connectivity != API reachability (timeouts still handled). Per-screen widget tests not added. |
| F3 | No read cache | CONFIRMED | NOT STARTED | Needs a scoped design (profile, addresses, lists); transactional states must stay backend-verified. |
| F4 | Address create / photo upload no idempotency | CONFIRMED (backend side) | PARTIALLY FIXED | OpenAPI (`docs/backend_openapi_2026-10-13.json`) defines `Idempotency-Key` for bookings, interviews, payments, ratings, replacement, support, attendance only, **not addresses**. Client: address form already disables on `form.busy`. Backend dependency: duplicate protection for address create. No new tests added. |
| F5 | allowBackup not disabled | CONFIRMED | FIXED (config only) | `android:allowBackup="false"` in main manifest. Not build-verified; no manifest test. |
| F6 | Placeholder version/description | CONFIRMED | PARTIALLY FIXED, BLOCKED | Description replaced. Version stays `0.1.0+1`: first release number needs approval. Android versionCode/name and iOS CFBundle* already derive from the pubspec version (`flutter.versionCode`, `$(FLUTTER_BUILD_NUMBER)`), so they stay consistent. |
| F7 | iOS privacy manifest/signing/APNs | PARTIALLY CONFIRMED | NOT STARTED | Seen: no `PrivacyInfo.xcprivacy`, entitlement `aps-environment=development`, deployment target 13.0, **no `ios/Podfile` in the repo**. Signing/provisioning cannot be verified on Windows. |
| F8 | freezed pre-release | CONFIRMED | FIXED (by removal; unit-verified) | Usage analysis: zero `@freezed`, `@JsonSerializable`, `@riverpod` or `part` directives in `lib/`, and no `*.freezed.dart`/`*.g.dart` files, so `freezed` was dead weight. Removed `freezed ^4.0.0-dev.3` from `pubspec.yaml` (lock updated by `flutter pub get`: only freezed dropped). No code regeneration needed. Not removed (unused too, optional cleanup): `freezed_annotation`, `json_annotation`, `json_serializable`, `riverpod_annotation`, `riverpod_generator`, `build_runner`. `riverpod_analyzer_utils 1.0.0-dev.12` (transitive pre-release via `riverpod_generator`) remains until that is removed. |
| F9 | Send timeout / GET retry / cancel | CONFIRMED | FIXED (unit-verified) | `core/network/get_retry_interceptor.dart` (new): GET/HEAD only, max 2 retries, 400ms exponential backoff + 25% jitter, retries timeouts/connection errors/502/503/504, 429 only when `Retry-After` <= 5s; never POST/PUT/PATCH/DELETE, 4xx, or cancelled requests. Registered after `AuthInterceptor` (401 refresh stays single-flight, no loop). `dio_provider.dart`: `sendTimeout` 30s; pre-signed photo upload clients (`address_repository_remote.dart`, `customer_photo_repository_remote.dart`) previously had NO timeouts, now `uploadBaseOptions()` (connect 15s, send 90s, receive 30s). Cancellation: already implemented (`CancelToken` in worker search, count, detail, booking and interview reads; disposed with the provider), so no change; mutations carry no token. Offline guard unchanged and still first in the chain. Tests: `test/core/get_retry_and_list_test.dart`. Not tested: retry interplay with a live 401 refresh, upload timeout behaviour against a real storage host. |
| F10 | `listOf` hides malformed bodies | CONFIRMED | FIXED (unit-verified) | `core/network/guarded.dart`: `[]`, `{items:[]}`, `{data:[]}` stay valid empty lists; null, strings, numbers, `{}`, wrong-typed or missing wrapper now throw `ServerFailure` (generic user message, shape-only telemetry, no body). Non-object rows are still skipped (tolerant row parsing kept). All 20 callers inherit this; the only existing test relying on the old behaviour (`address_repository_test`, unexpected body -> empty) was updated to the new contract. Tests: `get_retry_and_list_test.dart` (null, wrong types, `{}`, valid empties). Caveat: a backend that answers a list route with a non-list body (e.g. 204 with no content) now shows an error state instead of empty. |
| F11 | Shared Android application id | CONFIRMED | BLOCKED | Firebase only has `com.sevanest.customer` registered. |
| F12 | `Image.network` uncached | CONFIRMED | NOT STARTED | `home_shortlist.dart`, `home_photo_field.dart`. |
| F13 | Oversized files | CONFIRMED | NOT STARTED | |
| F14 | Mock/demo in prod tree | CONFIRMED | PARTIALLY FIXED | Config validation rejects mocks in stg/prod. Demo repositories not yet isolated. |
| F15 | CI gaps | CONFIRMED | PARTIALLY FIXED (2026-11-09) | Security-audit follow-up: `ci.yml` now has `permissions: contents: read`, `persist-credentials: false`, a concurrency group and a job timeout; still plain `pull_request`, no secrets. Not done: actions pinned by SHA and a pinned Flutter version (needs real SHAs/version), a stg/prod build job. See `SECURITY_REMEDIATION_REPORT.md` section 5. |

## Verification run (2026-11-08, after F8/F9/F10)
- Baseline before changes: the earlier `checkPhoto`/`PhotoCheck` and `ticket_detail_screen.dart:255` analyzer errors were in-progress edits by another author and were complete on re-check; no fix was needed. Baseline full suite: 1239 passed, 12 skipped.
- `flutter analyze`: 0 errors/warnings; 1 info (`directives_ordering` in untracked `test/features/upload_and_offline_test.dart`, not part of this work, left untouched).
- `flutter test test/core`: 83 passed.
- Full `flutter test`: 1283 passed, 12 skipped, 0 failed.
- Not run: any device/emulator, build, or live-backend test.

## Not done / needs external input
Backend URLs and DB isolation (F1); approved release version (F6); Apple team, signing, APNs production setup (F7); Firebase ids per flavor (F11); backend owner-level authorization and address idempotency evidence (IDOR, F4).

## Security audit follow-up (2026-11-09)

Source: external audit `security-audit-skill/SevaNest/run-1` (kept unchanged). Full write-up: [`SECURITY_REMEDIATION_REPORT.md`](SECURITY_REMEDIATION_REPORT.md).

| ID | Finding | Original severity | Status | Notes |
|---|---|---|---|---|
| S1 | Requirement draft (with address) survives logout / expiry | Low, confirmed | FIXED (unit-verified) | Wiped on sign-out and sign-in, in memory and storage; restore requires a session. `account_data_cleaner.dart`, `auth_state.dart`, `requirement_draft_provider.dart`. Not device-verified. |
| S2 | Exported `MainActivity` may accept an external route | not rated (needs validation) | **STILL NEEDS VALIDATION** | `flutter_deeplinking_enabled=false` added (Android) and `FlutterDeepLinkingEnabled=false` (iOS). Static test only. Needs an emulator test to close. |
| S3 | Backend-supplied URLs opened with any scheme | audit hardening note | FIXED (unit-verified) | `core/security/safe_url.dart`: https only (store: https or market:; support: tel/mailto). |
| S4 | Receipts / image cache left after sign-out | audit hardening note | PARTIALLY FIXED | Receipt PDFs and in-memory image cache cleared. On-disk worker-photo cache not cleared (would need a new direct dependency). |
| S5 | CI token permissions | audit hardening note | PARTIALLY FIXED | Least-privilege token; actions not SHA-pinned. |

Verification: analyze clean; full suite 1331 passed, 12 skipped, 1 failed (`image_handling_test.dart`, another author's in-progress work, unrelated). Nothing here is runtime/device verified.
