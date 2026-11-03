# SevaNest Customer App — Handoff Context

For an AI agent (or developer) taking over this project in a new Claude Code account. Read this first, then follow the read order in section 9.

## 1. What this is
- **Product:** SevaNest — "Verified Help. Trusted Homes." Customers in Hyderabad, India find, interview, book and pay verified household workers (maids, cooks, etc.).
- **This repo:** the **Customer mobile app** (Flutter, Android + iOS). Package `sevanest_customer`, app id `com.sevanest.customer` (provisional). V1 target: 16 weeks.
- **Git:** remote `https://github.com/nagirikantiajay20-prog/sevanest.git`, working branch `master` (PR base `main`), 88 commits (2026-10-12 → 2026-11-02).
- **Backend:** separate team. REST API at `https://sevanest-backend.onrender.com/api/v1` (all flavors currently). OpenAPI snapshots: `docs/backend_openapi_2026-10-12.json`, `..._10-13.json`. Swagger has no success-response schemas, so the app maps defensively.

## 2. Stack (approved, see docs/02)
Flutter 3.44 / Dart ^3.12 · Riverpod 3 (+generator) · go_router 18 · dio 5 · freezed + json_serializable · flutter_secure_storage · Firebase (core, messaging, analytics, crashlytics) · Razorpay behind a `PaymentService` abstraction · geolocator/geocoding behind `LocationService` · l10n via ARB (`lib/l10n`, English only, i18n-ready) · fonts Inter + SourceSerif4 · tests: flutter_test + mocktail + integration_test.
Flavors: dev / stg / prod (`lib/main_dev.dart` etc.). Dev flavor has a dev menu (`/dev/gallery`, API-vs-mock toggle).

## 3. Architecture
`lib/app` (router, theme, dev) · `lib/core` (network, session, storage, security, config, widgets, mock, l10n helpers) · `lib/features/<feature>/{data,domain,presentation}`.
Features: app_gate, onboarding, authentication, customer_profile, addresses, home, service_discovery (find-a-worker wizard), worker_search, favourites (shortlist), interview_trial, booking, payment, active_service, service_history, ratings, replacement, notifications, support, legal, etc.
Mock repositories sit behind the dev-menu API toggle; live repositories hit the backend.

## 4. Business invariants (from AGENTS.md — mandatory)
- Server is the source of truth. **Payment success = only what the server confirms** (`verify` then poll `GET /payments/{id}`); lost answer/offline shows "confirming", never "paid"/"failed".
- An interview/trial is a *state of a booking* (deployed API), not a separate `/interviews` resource.
- Booking actions are derived from backend `allowedActions`; no hardcoded refund/cancel/replacement rules; render backend order for matching.
- Never invent data when the API lacks it — show nothing / "not available".
- Don't copy competitor branding. Unresolved items go to `OPEN_QUESTIONS.md`; deviations go to `docs/DECISIONS.md`; progress ticks go to `docs/PROGRESS.md`.

## 5. Timeline (git history)
- **Oct 12–15** Foundation + modules 1–14 wired to live API: auth/OTP, profile & addresses, home, discovery, worker search/detail, favourites, interviews, bookings, payments (Razorpay), active service/history/rating, replacement, support/safety/push, account/settings, hardening, force-update/maintenance.
- **Oct 22** Platform setup (app id, CI, telemetry), legal consent, account deletion UI, a11y (1.3× text scale), tokens, Flow-A e2e test, quality-gate docs.
- **Oct 22–23** Design integration screen-by-screen from `design/screens/*.jpg` (47 reference images): splash → login → OTP → profile → home → find-a-worker steps → results → worker detail → interview → confirm booking → payment → bookings → rating → replacement → support → notifications → account → history → transactions → global states; offline banner.
- **Oct 28** Core refactor (theme tokens, networking), demo repositories, profile photos, address home photo, test updates.
- **Oct 30** "Glass" redesign: arch-zoom splash, glass login/OTP/profile setup/add-address sheet, confetti.
- **Nov 1–2** Home split into sections + favourite card; discovery step widgets + engagement card; glass results/worker cards; interview widgets extracted.
- **Uncommitted at handoff (Nov 3):** booking list/detail/confirm widget extraction (`booking_*_parts.dart`), payment + transactions refactor and new `transaction_detail_screen.dart`, `glass_success_overlay.dart`, l10n strings, router and test updates. Review with `git status` / `git diff`, run `flutter analyze` + `flutter test`, then commit.

## 6. Working conventions / user preferences
- Commit & push **only as GitHub user `nagirikantiajay20-prog`** (never `Ajay-prog`); set repo-local git user before committing.
- Dev APK: build only `flutter build apk --release --flavor dev -t lib/main_dev.dart`, overwriting `build/app/outputs/flutter-apk/app-dev-release.apk`. No prod/stg builds or renamed copies unless asked.
- Commit style: Conventional Commits (`feat(scope):`, `refactor(scope):`, `fix(scope):`, `chore:`).
- UI work is driven from design artifacts/screenshots (Claude Artifacts, Figma, Canva); match reference designs closely; keep widgets split into `*_parts.dart` files.
- `CLAUDE.md` (in `C:\Users\DELL\`) says to prefer the code-review-graph MCP tools for code exploration.

## 7. Known gaps / open items
- Backend questions & requests: `OPEN_QUESTIONS.md`, `docs/BACKEND_REQUESTS.md` (e.g. worker reviews endpoint for customers, status enums, payment confirmation, refund rules, legal URLs return null).
- Not done: iOS schemes/xcconfig (needs Mac), per-flavor Firebase files, release keystore, map pin (no provider approved), real SMS (DLT pending).
- Store listing notes: `docs/store/`.

## 8. Past Claude Code sessions (31 on this project, newest first)
| Date (UTC) | Title |
|---|---|
| 11-03 | Three screens from Claude Artifacts |
| 11-02 | Three screens Flutter integration · Four screens Flutter integration (×3) · Sevanest repository commits · Flutter screen integration from artifact (×2) · Home screen backend changes · Design implementation and celebration animation · Skill installation |
| 10-30 | Screen design integration from artifact · SevaNest Splash Arch Zoom · Artifact board screens continuation · Screen redesign with animations |
| 10-29 | Canva screen artifact |
| 10-27 | Release APK build · Customer App UI/UX improvements · Engagement screen service category grouping · Service categories engagement mapping · Booking screen issues · Customer requirements response review |
| 10-26 | Splash screen flow · Engagement Type section redesign · Worker card display names · Customer app project status update · Home screen redesign · OTP verification and home page screens |
| 10-23 | Customer app UI integration · Components from design system |
| 10-22 | Design scope reconciliation · Mobile app repository progress update · Figma integration · Customer app completion |

Full raw transcripts (every message/tool call) are in the bundled `sessions.zip` (see section 10); the repo docs above are the distilled version.

## 9. Read order for a new agent
1. This file → 2. `AGENTS.md` → 3. `docs/02_TECH_STACK_AND_SETUP.md` → 4. `docs/03_IMPLEMENTATION_GUIDE.md` → 5. `docs/modules/00_README_HOW_TO_USE.md` and modules 01–09 (+15 route map if present) → 6. `docs/PROGRESS.md`, `docs/DECISIONS.md` (newest first), `OPEN_QUESTIONS.md`, `docs/BACKEND_REQUESTS.md` → 7. `design/tokens.md`, `design/SCREENS.md`, `design/screens/` → 8. `git log --oneline` and `git status`.
Then run: `flutter pub get`, `dart run build_runner build -d`, `flutter gen-l10n`, `flutter analyze`, `flutter test`.

## 10. Moving to the new account
1. Push the repo (commit pending work first) or copy the folder; `node_modules/` and `build/` can be skipped.
2. Copy `docs/HANDOFF.md` along with it (it's in the repo).
3. Unzip `sessions.zip` somewhere in the new project; point the new agent at it only if it needs raw history (grep it, don't load it whole — ~315 MB).
4. Recreate memory: the two preferences in section 6 (APK single file, GitHub identity).
5. Re-add `CLAUDE.md` and the code-review-graph MCP server if wanted; Figma MCP needs re-auth.
