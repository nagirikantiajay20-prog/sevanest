# Security remediation report: audit run-1 follow-up

Source audit (unchanged, read-only): `C:\Users\DELL\security-audit-skill\SevaNest\run-1\` (`REPORT.md`, `findings.json`, `NEEDS-VALIDATION.md`, `coverage-ledger.json`). The original findings, severities and wording were **not** edited. This file records what was done about them.

Date: 2026-11-09. Reviewed commit `2d625e7` on `master`, plus an uncommitted working tree that other work was changing at the same time (see "Working tree" below). Nothing was committed, pushed or deployed.

## Decision

| Original finding | Original severity | Status now |
|---|---|---|
| `sevanest/logout-leaves-requirement-draft-address-in-shared-preferences` | Low (confirmed, source-only) | **Fixed in source, covered by automated tests.** Not verified on a device. |
| `android-exported-mainactivity-flutter-default-deeplink-route-injection` | none (needs_validation) | **Still NEEDS_VALIDATION.** A mitigation was added; no runtime evidence exists, so it is not marked resolved. |

The application is **not** declared production-secure. This work closes one low-severity finding and hardens three areas; the backend, release signing, store configuration and runtime behaviour were not assessed.

## 1. Requirement draft kept after logout (Low, confirmed)

**Current source verification (2026-11-09).** Still reproduced before the change: key `requirement_draft_v1` in `requirement_draft_provider.dart`, written on every edit, restored by `HomeScreen`, never removed by `AuthNotifier.signOut` (used by logout, token-refresh expiry and the splash "sign in again"). Lines had shifted slightly from the audit's numbers; the behaviour was identical.

**Root cause.** A per-customer draft (it holds an address snapshot) was stored under one global key, and the single place every session ends (`signOut`) cleared only tokens and the in-memory profile flag. Expiry also never rebuilds the provider scope, so the in-memory draft survived too.

**Fix.**
- `lib/core/storage/account_data_cleaner.dart` (new): `AccountDataCleaner.clear()` removes the draft key, the app's own saved receipt PDFs (`SevaNest_Receipt_*.pdf`) and the in-memory image cache; `clearDraft()` removes only the draft. Every step is best effort and cannot throw, so a failed cleanup never blocks sign-out. This is application-level cleanup only; it does not claim secure erasure from storage media.
- `lib/core/session/auth_state.dart`: `signOut()` calls `clear()`; `signIn()` calls `clearDraft()` first, so a draft left by an earlier failed cleanup cannot reach the next account.
- `requirement_draft_provider.dart`: the notifier listens to `authProvider` and, on `unauthenticated`, empties the in-memory draft and note and removes the stored copy (covers expiry, where no scope reset happens). `restore()` now returns early unless a session exists, and re-checks after its storage read, so a restore that was already running when the session ended cannot bring a draft back.
- `lib/core/storage/receipt_files.dart` (new, pure Dart): the receipt file-name prefix shared by `ReceiptDocument` and the cleaner.

**Deliberately not cleared:** `device_id` (install id, not a secret), notification choices, and the `pending_payment_*` keys. The last are identifiers only; they exist so an interrupted payment can be reconciled after sign-in, and the server authorizes each lookup, so a different account just gets a quiet failure. Removing them could hide a paid-but-unconfirmed payment from the same customer. Left as is, and listed under remaining risks.

**Files.** `lib/core/storage/account_data_cleaner.dart`, `lib/core/storage/receipt_files.dart`, `lib/core/session/auth_state.dart`, `lib/features/service_discovery/presentation/providers/requirement_draft_provider.dart`, `lib/features/payment/domain/receipt_document.dart`.

**Regression tests.**
- `test/features/service_discovery/draft_session_cleanup_test.dart`: saved and restored while signed in; logout clears storage; logout clears memory and note; expiry through the real `AuthInterceptor` clears both without a scope reset; a different account gets nothing; a draft left by a failed cleanup is dropped at sign-in; restore is a no-op without a session; a restore in flight cannot revive a draft after sign-out; a failing cleanup still ends the session.
- `test/core/account_data_cleaner_test.dart`: only the draft, own receipts and image cache are removed; unrelated preferences and files are kept; failures never throw; a missing folder is fine.
- `test/features/service_discovery/requirement_draft_test.dart` (existing): its two restore tests now run as a signed-in customer, because restore requires a session. Their assertions are unchanged.

## 2. Exported `MainActivity` and deep links (needs validation)

**What the source now shows (new evidence).** The compiled Flutter Android embedding for this exact engine was found in the local Gradle cache (`flutter_embedding_release-1.0.0-0cd610717bde95fd88343c64f81c11ba4e5c0010.jar`). Reading its class constants confirms the mechanism the audit could not see: `FlutterActivity` reads the meta-data key `flutter_deeplinking_enabled` (`HANDLE_DEEPLINKING_META_DATA_KEY`) in `shouldHandleDeeplinking()`; `FlutterActivityAndFragmentDelegate` has `maybeGetInitialRouteFromIntent` (uses `getData`) and `onNewIntent`, which forwards the intent and sends `pushRouteInformation`. Neither method name suggests an intent-filter check. **Correction to the audit text:** the opt-out key is `flutter_deeplinking_enabled`, not the `io.flutter.embedding.android.FlutterDeepLinkingEnabled` name used in the audit.

**What was checked.** No intent filter with `<data>`, no URL scheme (Android or iOS), no `app_links`/`uni_links`/WebView package. Notification taps are routed inside the app after validation (`routeForPushData`, an id pattern and a fixed type list), and the Firebase/`flutter_local_notifications` taps use the launcher intent and extras, not a data URI. Nothing found depends on an external app choosing a route. A payment is only *created* by `/payments/new?bookingId=`; the customer still has to press Pay, and the backend decides booking ownership and state (not visible from this repo).

**Change.** Deep-link handling is turned off for the activity: `flutter_deeplinking_enabled=false` in `android/app/src/main/AndroidManifest.xml`, and `FlutterDeepLinkingEnabled=false` in `ios/Runner/Info.plist` (iOS has no URL scheme either). Deep links were not "disabled blindly": there is no deep-link feature to lose. I did not add a payment confirmation step, because that changes payment business logic, and did not add a route allow-list, which would be unneeded if the flag works.

**Status: NEEDS_VALIDATION, unchanged.** No emulator or device was available or authorised, so it is not shown that (a) the old behaviour was exploitable or (b) the new flag blocks it. To close it, on an emulator with a debug build and a test account: warm start, run `adb shell am start -n com.sevanest.customer/.MainActivity -d "sevanest://x/bookings/<test-id>"` and confirm the screen does **not** change, then repeat with the flag removed to confirm the original behaviour. Use a mock or staging backend only.

**Other (not mine).** While this work was running, someone else's uncommitted edit to `lib/app/router/redirect.dart` / `app_router.dart` added a check that rejects route segments and `...Id` values that are not plain ids, and gated `/dev/*` on `!isProd`, with `test/app/router/route_safety_test.dart`. That is a useful in-app defence but it validates shape only, not ownership, and it was not made or reviewed as part of this task.

**Files.** `android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist`. **Test.** `test/regression/platform_security_config_test.dart` (static: flag present, launcher is the only exported component with no `<data>`, backups off, no cleartext opt-in, no URL types).

## 3. Logout and expiry cleanup (review)

| Data | Result |
|---|---|
| Booking/requirement draft (storage and memory) | Cleared on logout, expiry, sign-in (section 1). |
| Receipt PDFs (customer name, amounts) | Own files deleted on sign-out. They were never deleted before. |
| Cached images in memory | Flutter image cache cleared on sign-out. |
| Cached images on disk (`cached_network_image`, worker photos) | **Not cleared.** Clearing the disk cache needs `flutter_cache_manager` as a direct dependency; I did not add a dependency for display-only worker photos in app-private storage (`allowBackup=false`). Listed under remaining risks. |
| Tokens | Cleared as before (secure storage). |
| Push token | Explicit logout still unbinds it. On expiry it cannot be unbound (the session is already invalid); the next account's registration takes over server-side, which the backend must confirm. |
| Other in-memory providers | Explicit logout rebuilds the whole provider scope (unchanged). Expiry does **not**; only the requirement draft was fixed. Other providers that hold per-customer state may still show it until re-fetched. Not audited provider by provider. Recommended follow-up: reset the scope on expiry after the UI settles (risky to do inside the HTTP layer, so not done here). |
| Profile data, search, shortlist | Held only in providers (memory), so covered by logout's scope reset; same expiry caveat. |

## 4. External URL launching

Every `launchUrl` call was listed: store page and "open store" (`app_gate.dart`), terms/privacy (`login_screen.dart`, `account_providers.dart`), policy links (`account_providers.dart`), worker-app link (`splash_screen.dart`), support phone/email (`auth_widgets.dart`, `support_home_screen.dart`), Google Calendar (`interview_detail_screen.dart`). URLs come from the backend `/app-config` response or a build-time define; none come from users or deep links.

Before: a URL was accepted if it merely had a scheme (`hasScheme`), so `intent:`, `file:`, `tel:` or custom app schemes from a compromised or misconfigured config would have been opened.

Now (`lib/core/security/safe_url.dart`): `https` only for terms/privacy/policy; `https` or `market:` for the store and worker-app links; `tel`/`mailto` for the app-built support contacts. Blank, oversized, whitespace/control-character, relative, host-less and credential-bearing URLs are refused, at parse time and again at launch. The Calendar link is built with `Uri.https` and a fixed host, so it is unchanged. Redirect behaviour after the system opens an https page is the browser's, not the app's.

**Files.** `safe_url.dart` (new), `app_gate.dart`, `account_providers.dart`, `login_screen.dart`, `splash_screen.dart`, `auth_widgets.dart`, `support_home_screen.dart`. **Tests.** `test/core/safe_url_test.dart` (allowed and rejected schemes, malformed input, store and contact sets).

**Behaviour change to know about:** a config with an `http:` terms/privacy URL, or a store link with another scheme, now shows the existing "link unavailable" message instead of opening.

## 5. CI workflow

Reviewed `.github/workflows/ci.yml`. Triggers are `push` to main/master and plain `pull_request` (no `pull_request_target`, no `workflow_run`); no secrets are referenced; no artifacts are uploaded; no release or signing step exists.

Changed: top-level `permissions: contents: read`; `persist-credentials: false` on checkout; `concurrency` cancels superseded runs; `timeout-minutes: 30`. Steps are otherwise unchanged (`pub get`, `analyze`, `test`, debug dev APK).

**Not changed, on purpose.** Actions stay on major tags (`@v4`, `@v2`) and Flutter stays on the `stable` channel: pinning needs the real commit SHAs and a chosen Flutter version, and I will not invent them. Pin both when the pipeline gains secrets, signing or publishing. Dependency installation (`flutter pub get`) still resolves from pub.dev with the committed lockfile; no `--enforce-lockfile` flag was added because I could not run the pipeline to prove it still passes. **Test.** `test/regression/platform_security_config_test.dart` (read-only token, no secrets, no privileged triggers).

## 6. Remaining risks and open items

1. Deep-link finding unverified at runtime (section 2).
2. Expiry does not reset all in-memory providers (section 3).
3. Worker photos stay in the on-disk image cache after sign-out (section 3).
4. `pending_payment_*` ids survive sign-out by design (section 1).
5. Presigned photo upload URL and backend photo URLs are not scheme-checked (not a launch path, outside this scope).
6. No certificate pinning; no `networkSecurityConfig`; Android release signing, Play App Signing, iOS APNs production entitlement and Firebase API-key restrictions are unverified (outside the repo).
7. Actions are not pinned to SHAs; the Flutter version is unpinned.
8. All audit and test evidence is source-level; no device, emulator, release build or live backend was used.

## 7. Backend dependencies (not changed, not verified)

Ownership checks on booking, payment, address and interview ids; the start-payment endpoint (ownership, state, idempotency); that a new push registration rebinds a device token from the previous account; `/auth/logout` revocation; that `/app-config` URLs are https (the app now refuses anything else); presigned URL scoping.

## 8. Working tree

At the start there were 76 modified tracked files and 14 untracked paths, and the tree kept changing while this ran (for example `redirect.dart`, `app_router.dart`, several `home_*` and `glass_*` image widgets, `replacement_screens_test.dart`). Those edits were not mine and were left alone. Files this task changed or created are listed in the sections above.

## 9. Verification

Run on 2026-11-09 on Windows, Flutter 3.44.8, offline (`--no-pub`). No emulator, device, release build or live backend was used.

- `flutter analyze --no-pub`: no issues.
- `dart format`: run only on the files this work touched or created (0 further changes). It was **not** run repo-wide, because that would have reformatted files other people are editing.
- `flutter test --no-pub` (full suite): **1331 passed, 12 skipped, 1 failed.**
  - The failure is `test/core/image_handling_test.dart` ("avatars and cards decode network photos at display size": it flags `lib/features/home/presentation/home_widgets.dart` for an unbounded `NetworkImage`). That test file and the image-widget edits it checks are another author's uncommitted work in progress; I did not touch them, and it is unrelated to this remediation. Left failing; not hidden.
  - An earlier full run had 11 failures caused by my first version (sign-out awaited real file/preference I/O, which never finishes under the widget-test clock). Fixed by running the cleanup beside the session change instead of blocking it; the auth, logout and address tests then passed. This also keeps logout from ever waiting on storage.
  - New tests added by this work: `test/core/safe_url_test.dart`, `test/core/account_data_cleaner_test.dart`, `test/features/service_discovery/draft_session_cleanup_test.dart`, `test/regression/platform_security_config_test.dart` (all passing). Existing `requirement_draft_test.dart` adjusted to a signed-in customer.
- Skipped: the 12 pre-existing skips (live-backend tests need `SEVANEST_LIVE=1`; not run).
- Not run / blocked: Android build and manifest merge (no JDK on PATH), emulator deep-link test, iOS anything, the CI workflow itself (GitHub), any dependency vulnerability check (no network).

Design note: because cleanup now runs beside sign-out, the stored draft is removed a moment after the state flips, not before. The in-memory draft is cleared immediately by the auth listener, and the stored copy is also removed again at the next sign-in, so a slow or failed cleanup cannot expose a draft to the next account.
