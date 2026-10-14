# 02 — Approved Tech Stack, Project Setup & Conventions

> Resolves AGENTS.md §8 ("approved state-management") and §58 ("approved routing"). These are the **approved defaults** for the Customer App. Changing any requires recording a decision in `docs/DECISIONS.md`.
> Versions: do **not** copy version numbers from this file. At setup run `flutter pub add <pkg>` to get current stable, then commit the lockfile.

## 1. Stack

| Concern | Choice | Notes |
|---|---|---|
| Language/SDK | Flutter stable (pin with `fvm`), Dart null-safe | `.fvmrc` committed |
| State | **Riverpod** (with `riverpod_annotation` + `riverpod_generator`) | Async state via `AsyncValue`; mutations via `AsyncNotifier` |
| Routing | **go_router** (typed routes) | Auth redirect + deep links |
| HTTP | **dio** + interceptors | auth, refresh, logging(redacted), error mapping |
| Models | **freezed** + **json_serializable** | DTO ≠ entity (AGENTS §60) |
| Secure storage | **flutter_secure_storage** | tokens only. `shared_preferences` for non-sensitive flags |
| Push | **firebase_core**, **firebase_messaging**, **flutter_local_notifications** | FCM; APNs key uploaded in Firebase |
| Payments | **razorpay_flutter** behind `PaymentService` | Provider TBD (AGENTS §37) — keep interface, Razorpay is default adapter |
| Maps/location | **geolocator** + **geocoding** behind `LocationService`; Google Maps adapter optional | Provider TBD |
| Images | **cached_network_image** | placeholders mandatory |
| i18n | `flutter_localizations` + `intl` + ARB (`l10n.yaml`) | `app_en.arb` for V1 |
| Crash/monitoring | **firebase_crashlytics** | production only |
| Lint | `flutter_lints` + stricter `analysis_options.yaml` | no ignored errors |
| Tests | `flutter_test`, `mocktail`, `integration_test`, `golden_toolkit` (optional) | |
| Codegen | `build_runner` | `dart run build_runner build -d` |

## 2. Prerequisites (Windows dev machine)

1. Install Flutter SDK + `fvm`; run `flutter doctor -v` until Android toolchain is green.
2. Android Studio + SDK, an emulator and one physical low-end Android phone.
3. **iOS builds need macOS + Xcode** (or a cloud CI Mac, e.g. Codemagic/GitHub macOS runner). Windows cannot build iOS. Plan CI for iOS from Week 1.
4. Firebase project(s): `sevanest-dev`, `sevanest-stg`, `sevanest-prod`.
5. Apple Developer + Google Play accounts (needed by Week 14 for submission).

## 3. Bootstrap commands

```bash
fvm install stable && fvm use stable
fvm flutter create --org in.sevanest --project-name sevanest_customer --platforms android,ios .
fvm flutter pub add flutter_riverpod riverpod_annotation go_router dio freezed_annotation json_annotation flutter_secure_storage shared_preferences intl cached_network_image firebase_core firebase_messaging flutter_local_notifications razorpay_flutter geolocator geocoding url_launcher
fvm flutter pub add --dev riverpod_generator build_runner freezed json_serializable flutter_lints mocktail integration_test
```
Add `flutter_localizations` (sdk: flutter) manually and set `flutter: generate: true`.

Application IDs: Android `com.sevanest.customer`, iOS bundle `com.sevanest.customer` (confirm with team — **TBD** until trademark/domain verified, PRD §1.1).

## 4. Flavors & environment config

Three flavors: `dev`, `stg`, `prod`.
- Entry points: `lib/main_dev.dart`, `main_stg.dart`, `main_prod.dart` → each builds an `AppConfig` and calls `bootstrap(config)`.
- `AppConfig { env, apiBaseUrl, razorpayPublicKey?, sentryDsn? }` — **client-safe values only**. Pass secrets-free values with `--dart-define-from-file=config/dev.json` (config files contain no secrets; gitignore any that do).
- Android: `productFlavors` in `android/app/build.gradle`; iOS: schemes + xcconfig per flavor; separate `google-services.json` / `GoogleService-Info.plist` per flavor.
- Run: `flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json`

## 5. Folder structure (final)

Follows AGENTS §7 with concrete additions:

```
lib/
  main_dev.dart main_stg.dart main_prod.dart
  app/
    app.dart                  # MaterialApp.router
    bootstrap.dart            # init Firebase, storage, ProviderScope
    router/app_router.dart    # GoRouter provider, redirect, routes.dart (path constants)
    theme/                    # tokens.dart, app_theme.dart
  core/
    config/app_config.dart
    network/                  # dio_provider.dart, auth_interceptor.dart, error_mapper.dart, api_result.dart
    errors/app_failure.dart   # sealed: Network, Unauthorized, Forbidden, Validation, Server, Unknown
    storage/secure_session_store.dart
    services/                 # payment_service.dart, location_service.dart, push_service.dart
    widgets/                  # sn_button, sn_text_field, sn_card, sn_badge, sn_empty, sn_error, sn_skeleton, sn_timeline
    localization/
  features/<feature>/{data,domain,presentation}
  shared/{models,enums,utils}
l10n/app_en.arb
test/ integration_test/
docs/
```

## 6. Core building blocks (specs)

### 6.1 `AppFailure` (sealed)
`NetworkFailure | UnauthorizedFailure | ForbiddenFailure | ValidationFailure(fieldErrors) | NotFoundFailure | ConflictFailure | ServerFailure | UnknownFailure`. Mapped once in `error_mapper.dart` from `DioException`. UI never sees `DioException`.

### 6.2 Dio setup
- `connectTimeout`/`receiveTimeout` as constants in config (not magic numbers).
- `AuthInterceptor`: attach bearer from `SessionStore`; on 401 → single-flight refresh (queue concurrent requests with a `Completer`); on refresh failure → clear session and emit `sessionExpired` event (router redirects to `/login`).
- `LogInterceptor` only in dev, with redaction of `Authorization`, OTP, KYC, payment fields.
- `Idempotency-Key` header (UUID v4) on booking & payment-initiation mutations — **assumption**, confirm with backend.
- Use `CancelToken` for search requests (cancel obsolete).

### 6.3 Session store
`SecureSessionStore` wraps `flutter_secure_storage`: `read/write/clear` of `{accessToken, refreshToken}`. Android: `encryptedSharedPreferences`; iOS: Keychain `first_unlock`. Never log values.

### 6.4 Result/state convention
Repositories return `Future<T>` and throw `AppFailure`. Notifiers expose `AsyncValue<T>`. Lists use `PagedState<T>{items, nextCursor, isLoadingMore, error}`. Mutations use `AsyncNotifier<void>` and disable buttons while `isLoading`.

### 6.5 Router rules
- `redirect`: unauthenticated → `/login`; authenticated + profile incomplete → `/profile/setup`; else allow.
- Route path constants in one file. Typed `GoRouteData` optional.
- Deep link map (push tap): `booking/:id`, `interview/:id`, `ticket/:id`, `replacement/:id`, `payment/:id`.

### 6.6 Design system (tokens)
Create `tokens.dart` with colors, spacing (4-pt scale), radii, typography; **brand colours TBD** until design sign-off (M2, end Week 4) — use neutral placeholder palette marked `// TBD-BRAND`. Components in `core/widgets`: `SnButton` (primary/secondary/text, loading state, min 48dp), `SnTextField`, `SnCard`, `SnBadge` (verified/pending), `SnChip`, `SnEmptyState`, `SnErrorState(retry)`, `SnSkeleton`, `SnTimeline`, `SnBottomSheet`.

### 6.7 Localization
All strings via `AppLocalizations.of(context)`; keys snake_case (`find_worker`, `confirm_booking`…). Currency/date formatting via `intl` (`₹`, `en_IN`). Lint rule: no string literals in `Text()` (review checklist item).

## 7. Performance budget
- Cold start to login/home < 3 s on mid-range Android (target; measure).
- Worker list: `ListView.builder`, page size from backend, image `memCacheWidth` set.
- Release APK/AAB size tracked in CI; avoid heavy plugins.

## 8. Quality gates (CI)
```
dart format --set-exit-if-changed .
flutter analyze --fatal-infos
flutter test --coverage
```
CI: GitHub Actions (or Codemagic). Android build on Linux; iOS build on macOS runner. Gate: PR cannot merge unless all pass (AGENTS §74). Coverage target ≥ 70% on domain/data/state layers (suggested, adjust).

## 9. Security checklist (client)
- `android:allowBackup="false"`, `usesCleartextTraffic=false`; iOS ATS default.
- Release obfuscation: `--obfuscate --split-debug-info=build/symbols`; upload symbols to Crashlytics.
- Block screenshots on payment/OTP screens is **optional** (product decision, TBD).
- No payment secret keys; Razorpay *key id* only (public).
- Certificate pinning: **TBD**, not V1 default.
- Jailbreak/root detection: not V1.
