# Production readiness remediation, part 2 (security audit follow-up)

Companion to `docs/PRODUCTION_READINESS_REMEDIATION.md`, which another session owns and which covers F1 to F15 (config, offline guard, retry, `listOf`, freezed, and so on). This file covers the security-audit findings and the items this session took. Source audit: `C:\Users\DELL\security-audit-skill\SevaNest\run-1\` (source-only, tree of 2026-11-08, 76 modified files).

Statuses: FIXED (code change plus passing test), PARTIALLY FIXED, BLOCKED, NEEDS VALIDATION, NOT STARTED. Nothing here was run on a device or emulator.

## Work split
The tree is edited by more than one session. Agreed split: the other session ("SevaNest Flutter mobile audit") keeps logout/account cleanup and URL safety; this session took deep links, route parameters, images, mock isolation, the replacement timeout test and the release review. Manifest, iOS plist and CI edits were landed by someone else while this session worked; this session verified them and did not duplicate them.

## Findings

### SN-1 Requirement draft survives logout (audit: low)
- **Evidence now:** `AuthNotifier.signOut` calls `AccountDataCleaner.clear()` (removes `requirement_draft_v1`, saved receipt PDFs, the in-memory image cache); `signIn` calls `clearDraft()`; `RequirementDraftNotifier` discards memory and storage when auth becomes unauthenticated and restores only while authenticated. 401 expiry goes through `signOut`, so it is covered.
- **Owner:** the other session implemented it. Its tests, which the full suite ran: `test/features/service_discovery/draft_session_cleanup_test.dart` (logout clears storage and memory, session expiry, a different account never gets the previous draft, a failed earlier cleanup is dropped at sign-in, a late restore cannot revive a draft, a failing cleanup still ends the session) and `test/core/account_data_cleaner_test.dart`.
- **Status: FIXED** (code plus passing tests; not run on a device). Left alone by design: `pending_payment_id`, device id, notification choices (identifiers only, server-authorised). Offline logout still works because every cleanup step is best effort.

### SN-2 Exported `MainActivity` and deep-link route injection (audit: needs validation)
- **Evidence now:** the manifest has only a MAIN/LAUNCHER filter; `flutter_deeplinking_enabled=false` is set on the activity and `FlutterDeepLinkingEnabled=false` is in `ios/Runner/Info.plist` (added by another actor; confirmed present). The key name is the one in Flutter's deep-linking documentation; the audit suggested a different Android key (`io.flutter.embedding.android.FlutterDeepLinkingEnabled`), which this session could not confirm against embedding sources.
- **Fixed in this session (defence in depth, in the app):** `resolveRedirect` now (a) rejects any path segment or `...Id` query value that is not a plain id (`[A-Za-z0-9_-]{1,64}`, the same shape the push router accepts) by sending the user Home, and (b) closes `/dev/*` routes whenever the build is production (`allowDev: !config.isProd`; previously every `/dev/` path skipped all guards). Signed-out users still land on login for every protected path, including payment and booking links.
- **Tests:** `test/app/router/route_safety_test.dart` (6): safe ids pass, traversal / encoded / over-long / injection-looking ids go Home, a bad id cannot bypass sign-in, protected links need sign-in, dev routes closed in prod.
- **Not changed:** `/payments/new?bookingId=` still starts a payment on first frame when reached by in-app navigation. Adding a confirmation tap would change payment behaviour and was not approved. Booking and payment ids are never treated as authorisation; the backend decides ownership.
- **Status: PARTIALLY FIXED, NEEDS VALIDATION.** Needs an emulator run: `adb shell am start -n com.sevanest.customer/.MainActivity -d '<uri>'` warm and cold, with the dev build and a test account. Backend must confirm start-payment ownership and idempotency per booking.

### URL launching (audit hardening note)
- **Evidence now:** `lib/core/security/safe_url.dart` (https-only allow list, store, tel and mailto sets; rejects control characters, embedded credentials, over-long text) is used by `app_gate.dart`, `account_providers.dart`, `login_screen.dart` and the auth widgets; `test/core/safe_url_test.dart` covers valid and invalid input (other schemes, malformed, store, tel/mailto).
- **Owner:** the other session. Not re-implemented here.
- **Status: PARTIALLY FIXED.** Not confirmed by this session: the presigned PUT URL and photo URLs are still not run through the allow list.

### CI permissions (audit hardening note)
- **Evidence now:** `.github/workflows/ci.yml` has `permissions: contents: read`, plain `pull_request`, a `concurrency` block, no secrets. Edited by another actor; verified by reading only.
- **Status: FIXED (configuration)**, not run on GitHub. Not done: pinning actions by SHA and the Flutter version (needs a version decision), `distributionSha256Sum`, dependency verification. NEEDS VALIDATION on the first CI run; branch protection is a GitHub setting outside the repo.

### Replacement worker-selection timeout
- **Root cause:** `replacement_status_screen` treated any `NetworkFailure` as offline, so a timeout told the customer "you're offline" although the select may have been processed.
- **Fix (previous pass):** only real connection loss shows the offline banner; anything else re-reads the request before saying it failed.
- **Tests (new, `replacement_screens_test.dart`):** (1) timeout where the server did process the select: UI shows the scheduled state, no error, no offline banner, exactly one select call; (2) timeout where nothing changed: no offline banner, "We couldn't confirm the replacement" shown, alternatives kept, one select call, no automatic resend.
- **Status: FIXED.**

### Images (F12)
- **Evidence before:** four `DecorationImage(NetworkImage)` sites had no `onError`; avatars and cards decoded full-size photos; the home-photo preview had no loading state.
- **Fix:** `onError` ignores a failed/expired link (initials or colour stay); worker, home and interview photos are wrapped in `ResizeImage` at display size (160 to 300 px); the home-photo preview decodes at 900 px and shows a spinner while loading. Files: `interview_list_parts.dart`, `glass_page.dart`, `glass_parts.dart`, `worker_card.dart`, `home_attendance.dart`, `home_top_rated.dart`, `home_widgets.dart`, `home_photo_field.dart`.
- **Deliberately not done:** no disk image cache for worker photos. Photo links are short-lived signed URLs ("only shown, never stored"), so a disk cache keyed by URL would not hit and would retain third-party images. The customer's own profile photo stays an uncached `NetworkImage`; logout clears the in-memory image cache through `AccountDataCleaner`.
- **Tests:** `test/core/image_handling_test.dart` (4): a failing link shows the broken-image icon without throwing; source guards require `errorBuilder` on every `Image.network`, `onError` on every `DecorationImage(NetworkImage)`, and no unbounded `NetworkImage` outside the profile avatar.
- **Status: FIXED** for load/error/memory behaviour; `home_shortlist.dart` already had `errorBuilder` and `cacheWidth`.

### Mock and demo isolation (F14)
- **Evidence:** only `AppConfig.mock` enables mocks and nothing in `lib/` selects it; `main_dev/stg/prod` bootstrap their own flavor; `bootstrap` stops on `config.problem` before Firebase; stg/prod have no baked-in URL; the widget gallery route exists only in dev and `/dev/*` is now closed in prod.
- **Tests:** `test/core/mock_isolation_test.dart` (10): dev, stg and prod resolve to remote auth, address and payment repositories with `demoLoginProvider` false; only the test config yields the demo login; stg/prod reject mocks, http, missing URL and the dev backend; source guards for `AppConfig.mock`, entrypoints, bootstrap order and the gallery route.
- **Status: FIXED** for flavor selection. The `*_mock.dart` and `*_demo.dart` files still compile into every build (they are tree-shaken only if unreferenced; they are referenced by the providers). Moving them to a dev-only source set is a larger refactor, not done: **PARTIALLY FIXED**.

## Network reliability, API validation (F2, F9, F10)
Implemented by the other session (`offline_write_guard.dart`, `get_retry_interceptor.dart`, stricter `listOf`, timeouts) with tests in `offline_write_guard_test.dart` and `get_retry_and_list_test.dart`. This session did not change them and re-ran them in the full suite. Cancellation tokens already existed in search and read repositories; mutations carry none.

## Android and iOS review (source only)
Android (`android/app`): application id `com.sevanest.customer` shared by all flavors (Firebase has only this id: BLOCKED for per-flavor ids); `minSdk`/`targetSdk`/`compileSdk` come from the Flutter SDK defaults, not pinned; permissions INTERNET, POST_NOTIFICATIONS, coarse and fine location; only `MainActivity` is exported; `allowBackup=false` present; no `networkSecurityConfig` (cleartext is already off by default at the current target SDK; an explicit file is optional); release minify and resource shrinking on; release signing needs `android/key.properties` and the build fails early without it for stg/prod; dev release is debug-signed by design; `google-services.json` is committed (client keys; restrict them in Google Cloud). APK result: see the delivery report.

iOS (`ios/Runner`, needs macOS to validate): bundle id `com.sevanest.customer`; deployment target 13.0; `aps-environment` is `development` and must be `production` for the archive; no `PrivacyInfo.xcprivacy`; signing is Automatic with no team set; no `Podfile` in the repo; `GoogleService-Info.plist` committed. Not verifiable on Windows: pod install, archive, provisioning, APNs production, privacy manifest completeness, ATS behaviour, TestFlight validation.

## Dependencies
`freezed` was already removed (unused). `freezed_annotation`, `json_annotation`, `riverpod_annotation`, `riverpod_generator`, `build_runner` and `json_serializable` appear unused according to the other session's analysis; not removed here. No vulnerability scan was possible (no network advisory source); run `flutter pub outdated` and a dependency audit in CI. Largest files: `splash_screen.dart` 1274 lines, `login_screen.dart` 1060, `otp_screen.dart` 1056; no refactor was done (no clear benefit versus risk).

## Remaining risks and external dependencies
Backend: start-payment ownership and idempotency, address-create idempotency, photo limits and routes, per-flavor URLs and databases, revocation on `/auth/logout`. Apple: team, signing, APNs production, privacy manifest. Firebase: per-flavor app ids, API key restrictions. GitHub: branch protection and default token permissions. Device: the deep-link run in SN-2.
