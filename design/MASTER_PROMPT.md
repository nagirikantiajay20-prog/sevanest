# SevaNest customer app: UI integration master prompt

Paste everything below the line into a new Claude Code session opened in `C:\Users\DELL\Documents\SevaNest`.

---

## ROLE AND GOAL
You are finishing the design integration of the SevaNest Flutter customer app (Android and iOS, Hyderabad, V1).
The design says how each screen looks. `AGENTS.md` (PRD) and `docs/modules/00..15` say what must exist and how it behaves. If they conflict, the PRD and modules win on behaviour and the design wins on looks. Ask me when it is genuinely unclear. Do not invent designs.

## SOURCES
- Design screenshots: `design/screens/NN_*.jpg` (prototype https://growth-glory-58907994.figma.site/, 325 px wide, so build responsive and safe-area-aware layouts, not pixel copies). No separate V2 design exists.
- Tokens: `design/tokens.md`. Coverage matrix, decisions, per-screen status: `design/SCREENS.md` (update it after every screen).
- Backend gaps: `docs/BACKEND_REQUESTS.md`. Decisions: `docs/DECISIONS.md`. Progress: `docs/PROGRESS.md`. Open questions: `OPEN_QUESTIONS.md`.

## DECISIONS ALREADY MADE (still apply)
- Fee and tax on Confirm booking: one typed `BookingQuote` service function, a clearly marked mock until the backend has a quote endpoint. No hard-coded numbers in screens. Log it as a backend dependency.
- Video call: not in V1. Trimmed everywhere (no "Join video call", no "video" interview type).
- Filters: the app's real filters (availability, language, experience, rating, highest-rated sort).
- History totals, filter chips and search: hidden until the backend supports them.
- Delete account: keep the existing screen, restyled.
- Fonts: system fonts, chosen only in `lib/app/theme/typography.dart`.
- No mock data in the UI except the approved `BookingQuote`. A design element the backend cannot serve is hidden and logged in `docs/BACKEND_REQUESTS.md`.
- Every button and card must have a working action. Never show a dead control.
- Never remove a PRD-required feature because the design omits it. Never keep a design element the PRD or V1 does not support.
- No new libraries without asking. No backend, provider or admin app changes.

## HOW TO WORK (one screen per turn)
1. Read the screen's code, its module spec in `docs/modules`, and the design screenshots.
2. Restyle with the shared components and tokens (`lib/core/widgets/sn_*.dart`, `lib/app/theme/`). Keep all existing logic, API calls, state, validation, navigation and widget `Key`s. Add loading, empty, error and offline handling and every PRD status for that screen.
3. Run `dart format lib test`, `flutter gen-l10n` when the `.arb` changed, `flutter analyze`, then the full `flutter test`. Fix what you broke. Do not commit while a test fails. Check accessibility at 1.3x text scale (`test/features/accessibility_test.dart`).
4. Update `design/SCREENS.md`, then make one commit: `feat(ui): integrate <screen> design`. Do not commit `design/` (I have not decided whether to commit or git-ignore it). Stage only `lib`, `test` and docs you changed.
5. Report: files changed, what matches the design, what you trimmed and why, backend gaps, how to test. Then stop and wait for my "next".

## REPO RULES AND GOTCHAS
- Git identity must be `nagirikantiajay20-prog` (repo-local config already set). Commit footer: `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`. Never push unless I ask.
- APK: rebuild only the dev release over the same file, nothing else: `flutter build apk --release --flavor dev -t lib/main_dev.dart` gives `build/app/outputs/flutter-apk/app-dev-release.apk`. Prod and staging need `android/key.properties`, which does not exist. Build only when I ask.
- Strings live in `lib/l10n/app_en.arb` (English only in V1). Never hard-code user-facing text in a screen.
- Shared pieces already built: `SnButton`, `SnCard`, `SnChip`, `SnBadge`, `SnAvatar`, `SnHeader`/`SnStepBar`, `SnBottomNav`, `SnBottomSheet`/`SnGrabber`, `SnCalendar`, `SnTimeline`, `SnTextField`, `LabeledField`, `SnEmptyState`/`SnErrorState`/`SnOfflineState`/`SnSkeletonList`. Discovery chrome: `DiscoverScaffold`, `StepHeading`, `SelectionChip`, `FlowChips`, `ChoicePill`.
- Tests find widgets by `Key`. Repeated keys among siblings of one `Wrap`/`Column` crash, so give repeats an index suffix. After a layout change that pushes content down, tests may need `ensureVisible` plus `pump` before `tap`.
- Buttons inherit an infinite minimum width from the app theme: inside a `Row`, set `minimumSize: Size(0, kMinTapTarget)`.
- Shell heredocs break on apostrophes in this environment: write files with the editor tool, not `cat <<EOF`.

## DONE (committed, not pushed)
Step A theme and shared components; Splash; Login; OTP; Profile setup; Home with bottom nav (plus "View all" bookings link); Find a worker: shared header, steps 1 to 6 (Service, Engagement, Location with unserviceable-area check, Timing, Start date, Budget), Review; Results with worker card and Filters sheet.

## REMAINING WORK, IN ORDER (one screen or tight group per turn)
For each: the matrix action in `design/SCREENS.md`, and the module that defines it.
1. **Worker detail** (M05.3, design 24-26): hero, stats, About, skills, languages, verification list, reviews preview, sticky Shortlist and Request interview. Needs: unavailable state with "Find another", "What does verified mean?" sheet, Report/Block menu (M12), pending-verification badge ("Verification in progress"), `canRequestInterview` disabled-with-reason, no KYC fields. Worker reviews list (M05.4): empty, paged, backend reviews are mock-only until served.
2. **Shortlist** (M06, design 43): All/category chips, cards, undo snackbar, unavailable tag, empty state with Find a worker.
3. **Interview request** (M07.1, design 27-29): date strip, slots, note (limit from backend), 409 slot-taken, worker-gone dialog, discard dialog, idempotent submit. Trim the video type and the auto-confirm choreography.
4. **Interview detail and list** (M07.2-7.3, design 30-33): every status (requested, scheduled, reschedule proposed, completed, cancelled, declined, not a fit, unknown), actions only from `allowedActions`, Confirm worker, Not a fit, Contact support. Trim Join video call and the demo completion step. Interview list with empty state.
5. **Confirm booking** (M08.1, design 34-36): worker card, requirement summary with Edit, price rows from typed `BookingQuote` mock, consent, "Confirm & pay", 409 dialog, network-unknown recovery that refetches before showing an error.
6. **Payment** (M09, design 37): ready, verifying (back blocked), success, failed, pending, cancelled, leave dialog, app-kill recovery banner. Success only when the backend says so. Receipt link.
7. **Bookings list and Booking detail and Cancel sheet** (M08.2-8.4, design 38-40, 42): Current/Past, every booking status chip (new request, matched, interview scheduled, interview completed, pending payment, confirmed, active, replacement requested, replaced, completed, cancelled, unknown), pending-payment "Complete payment", timeline, actions strictly from `allowedActions`. Trim search.
8. **Active service** (M10.1, no design): attendance list (present, absent, late, leave, exception, unknown), empty, report a missing day, links to worker, booking, support, replacement, rating.
9. **Rating** (M10.3, design 41): stars, comment (max from config), thank-you, already rated, not eligible, network keeps input.
10. **Replacement** (M11, no design): request form with reason and notes, request received, status for requested, approved, rejected, cancelled, completed, unknown; alternatives, choose and confirm; withdraw only when allowed.
11. **Support** (M12, no design): support home with Open/Closed filter and empty state, new ticket with related-item chip, ticket detail with reply, closed state and resolution, report and block sheets.
12. **Notifications** (M13, no design): centre (unread dot, mark all read, empty, error), push pre-prompt, "this item isn't available" deep-link screen.
13. **Account and sub-screens** (M14, design 44-45): Account rows, Profile view/edit, Addresses list and form (empty state, delete-409 dialog, discard dialog, default switch), About, Terms and Privacy links, Logout dialog, Delete account (kept), Notifications-off row. Trim Reset Demo. Language row hidden (English only).
14. **Service history** (M10.2, design 46): list with grouped sections and rebook. Trim the totals banner, filter chips and search.
15. **Transactions and Receipt** (M09.3-9.4, design 47): list with status chips (success, failed, pending, refund pending, refunded, unknown) and empty state; receipt detail with refund block. Trim search, month picker and month summary.
16. **Global pass:** offline banner, loading skeleton, error with retry, empty states on every list, restyle all `AlertDialog`s (discard, cancel, logout, delete, leave payment) and remaining bottom sheets (`date_sheet.dart`, `time_picker_sheet.dart`, address picker on Home, policy sheet) to the design, 401 and 403 handling messages.

## KNOWN GAPS TO CLOSE ALONG THE WAY
- Hero, tile and promo photos are not in the repo (Splash, Login, OTP, Profile setup, Home use gradients and icons). Ask me for the images or an export.
- Not yet audited against the modules: Splash, Login, OTP, Profile setup, Address screens. Do a PRD audit pass and add anything missing.
- Add to `docs/BACKEND_REQUESTS.md` (section "Figma design integration"): customer photo endpoint, worker total count / price / distance on search results, serviceability flag on addresses, quote endpoint (`BookingQuote`), budget guidance, worker reviews endpoint.
- Build the typed `BookingQuote` mock (one service function, clearly marked) when you reach Confirm booking.
- `design/` is untracked. `docs/BACKEND_REQUESTS.md` has local edits. Firebase config files are untracked. Leave them alone unless I say otherwise.
- The latest dev APK predates Engagement through Results. Rebuild only when I ask.

## DEFINITION OF DONE
Every required screen, state and status in the matrix is integrated or deliberately trimmed or blocked and logged; `flutter analyze` is clean; the full test suite passes including the 1.3x text-scale checks; `design/SCREENS.md` shows every row as Done, Trimmed or Blocked by backend; one commit per screen.

Start with item 1 (Worker detail). Show the plan in one short list, then do it.
