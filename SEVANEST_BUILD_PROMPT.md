# SevaNest: Master Build Prompt (paste into Claude Code)

## Role and goal
You are a senior mobile engineer. Build the complete **SevaNest** app (a marketplace for hiring household workers: cook, driver, maid and similar) from the existing design screens. Build it **module by module**. Each module must be fully working and **wired to the previous and next module** before you start the next one. Do not skip any screen or any state.

## Source of truth
Screens (PNG, one file per state):
- `C:\Users\DELL\Downloads\SevaNest_screens_part1_01-16\SevaNest_screens`
- `C:\Users\DELL\Downloads\SevaNest_screens_part2_17-33\SevaNest_screens`

Before each module, open **every PNG** in its folder and implement exactly what you see: layout, copy, colours, spacing, icons, and every state in the file names. If a screenshot and this prompt disagree, the screenshot wins.

## Stack (assumed; change it only if I say so)
React Native + Expo (TypeScript), Expo Router, Zustand, TanStack Query, React Hook Form + Zod, i18next (English plus Hindi at minimum, per the language sheet), AsyncStorage/MMKV for offline cache, expo-location, expo-image-picker, expo-notifications, expo-file-system/sharing.
- Backend: a mock API layer (`src/api/*`) with in-memory/seeded data and a toggle to simulate loading, error, offline and slow responses. Keep the interfaces REST-shaped so a real backend drops in.
- Payments: a pluggable provider interface with a mock gateway that can return success, failed, cancelled, pending and processing-slow.

## Project rules
1. Design tokens (colours, type, spacing, radii, shadows) are extracted once from the screens into `src/theme`. No hard-coded values in screens.
2. Reusable components first: Button, Input, OTPInput, Sheet, Dialog, Toast/Snackbar, Chip, Tabs, SearchBar, EmptyState, ErrorState, OfflineBanner, Skeleton, StatusBadge, WorkerCard (all variants from `13 Worker card component · variants.png`), Stepper/ProgressHeader, Calendar, TimePicker, RatingStars.
3. **Every screen implements all its states from the file names:** default, focused/keyboard-up, filled, validation error, loading (skeleton), empty, error (retry), offline (cached data plus banner), and the module-specific states. A shared `ScreenState` pattern (loading | error | offline | empty | content) is used everywhere.
4. Accessibility: 44pt touch targets, labels, dynamic type, contrast.
5. Each module ends with: types, API mocks, store, screens, route registration, unit tests for logic (validators, price and refund maths, state machines), and a **wiring checklist** that I can verify.
6. After each module, run typecheck, lint and tests. Fix everything before moving on. Report what is done and what is wired.
7. Use the **code-review-graph** MCP tools (`get_architecture_overview_tool`, `query_graph_tool`, `get_impact_radius_tool`, `detect_changes_tool`) to check callers, dependents and impact before and after each module.
8. Copy, currency (₹), date formats and phone format (+91, 10 digits) follow the screens.

## Global navigation map (wire-up contract)
```
Splash -> Login -> OTP -> (new user) Profile setup -> Home
                       -> (returning)               Home
Home -> Service -> Engagement -> Location -> Timing -> Start date -> Budget
     -> Review -> Worker results -> Worker detail -> (Shortlist | Request interview)
Request interview -> Interview detail -> Confirm & pay -> Payment status
     -> Bookings list -> Booking detail -> Active service
     -> (Rate worker | Request replacement -> Replacement status | Support new ticket)
Service history, Support home -> New ticket -> Ticket detail
Transactions -> Receipt;  Notification centre;  Account
```
Bottom tabs: Home, Bookings, Shortlist, Support, Account (verify against the screens). Notifications live in the Home header. Deep links and push taps route to Interview detail, Booking detail, Ticket detail, Replacement status and Receipt.

Shared state that crosses modules:
- `session` (auth, user, language)
- `requirementDraft` (service, engagement, location, timing, start date, budget). It is built in Modules 3 to 5, read in Review and Results, and persisted so the app can resume.
- `shortlist`, `interviews`, `bookings`, `payments`, `tickets`, `notifications`

---

## MODULE 1: Foundation and Auth (screens 01 to 04)
**01 Splash:** loading, slow connection, failed load (retry). Decides the route: logged out -> Login; logged in with no profile -> Profile; logged in -> Home.
**02 Login:** default, focused with keypad up, filled, inline error, sending code, couldn't send code, language sheet (change app language live). Phone validation; "Get OTP".
**03 OTP:** default, partially filled, filled, verifying, verified, wrong code, resend available (countdown timer), too many attempts (lockout). Auto-advance, paste and SMS autofill.
**04 Profile setup:** default, focused, filled, error, photo sheet (camera/gallery/remove), address added (address form shared with Module 4), saving. Required-field validation.
**Wire:** Splash -> Login -> OTP -> Profile (new) or Home (returning). Profile's saved address is stored in the address book that Module 4 reads. Session persists. Logout returns to Login (Module 12).

## MODULE 2: Home (05)
States: loading, new user (onboarding CTA "Hire help"), returning user (active booking, upcoming interview, recent searches/shortlist), offline, error.
**Wire:** the "Hire" CTA starts a fresh `requirementDraft` and goes to Module 3. Cards deep-link to Interview detail, Booking detail and Active service. The bell icon opens Notifications (Module 11). The tab bar is created here.

## MODULE 3: Requirement builder, part 1 (06 to 08)
**06 Service:** loading, default list, searching with keyboard up, no result, error, Cook selected.
**07 Engagement type:** loading, default, part-time selected, Driver with Live-in unavailable (disabled with reason), error.
**08 Location:** loading, default with Home selected, Office selected, no saved addresses, finding your location (GPS), permission denied (settings deep link), add-address sheet, pincode error, error.
**Wire:** each screen writes its field to `requirementDraft`, shows a progress header (step n of 7) with Back, and Next is disabled until valid. Engagement type changes which Timing variant opens (Module 4). Selecting a service filters the available engagement types.

## MODULE 4: Requirement builder, part 2 (09 to 11)
**09 Timing:** variants by engagement (Part-time default, Hourly, Daily, Full-time), filled, time-picker sheet, time error (end before start, minimum duration), loading, error.
**10 Start date:** loading, default, a date selected, next Monday shortcut, outside selected days (warning), 60-day limit, hourly date sheet, error.
**11 Budget:** loading guidance, default (monthly), hourly variant, typing with keypad up, low budget warning, flexible toggle, guidance error, error. Guidance (market range) comes from the API for service plus location.
**Wire:** the Budget "Continue" runs the whole-draft validation and opens Review (Module 5). Editing from Review jumps back to the specific step and returns directly to Review.

## MODULE 5: Review and Search (12)
States: default, flexible budget, needs attention (incomplete or invalid fields flagged with jump links), note expanded with keyboard up, searching, search error, offline.
**Wire:** "Find workers" posts the requirement, shows the searching state, then opens Worker results (Module 6) with the query ID. Each row has "Edit", which goes to the matching step and then returns here.

## MODULE 6: Discovery (13 to 15)
**13 Worker results:** worker card component with all variants, loading, loading more (pagination), default, empty, error, offline with saved results, filters sheet and filters applied, sort sheet, saved with a "2 in shortlist" bar. Save heart toggle.
**14 Worker detail:** loading, default, error, offline, saved, new worker with no reviews, verification in progress, long-content stress test (truncation and expand), no longer available. Sticky CTA "Request interview".
**15 Shortlist:** loading, default (Favourites tab), empty, error, offline, filtered to Driver, opened from results, removed with Undo snackbar, unavailable worker (disabled card with a remove option).
**Wire:** result card -> Worker detail. The shortlist store is shared by the heart on cards and detail and by the Shortlist tab. The CTA on detail and on shortlist goes to Request interview (Module 7) with `workerId` plus the draft. An unavailable worker blocks the CTA everywhere.

## MODULE 7: Interview (16 to 17)
**16 Request interview or trial:** default, filled, trial visit selected, note with keyboard up, conflict warning (overlaps another interview), no times left, worker no longer available, sending, send error (retry), request sent.
**17 Interview detail:** loading, error, offline, awaiting confirmation, confirmed (video, with Join enabled only in the join window: "joinable now"), trial visit confirmed (address and arrival info), new time proposed (accept/decline), declined, cancel dialog, cancelled, completed with "decide" (hire -> Module 8, or pass).
**Wire:** Request sent -> Interview detail. Status changes drive notifications (Module 11). "Hire" goes to Confirm & pay with the interview, worker and requirement. Cancel updates Home and Bookings.

## MODULE 8: Payment (18 to 19)
**18 Confirm & pay:** loading the quote, quote error, default with consent unchecked (Pay disabled), ready to pay, policy sheet (cancellation/refund policy), price changed (re-confirm), worker no longer available, offline, opening payment.
**19 Payment status:** processing (auto-moves to success), processing taking longer, pending, success, failed (retry or change method), cancelled by you, offline while verifying, verification error, app reopened mid-payment (resume by pending payment ID).
**Wire:** payment intent is created on Pay. Persist the pending payment ID so Splash/Home can resume Payment status. Success creates the Booking and navigates to Booking detail (Module 9) and fires a notification. Failure returns to Confirm & pay. A receipt for the payment is available in Module 10.

## MODULE 9: Bookings and Service lifecycle (20 to 26)
**20 Bookings list:** Current and Past tabs; loading, default, empty (each), error, offline with saved bookings, pull to refresh, search results, search no match, Past with a Refunded filter.
**21 Booking detail:** loading, error, offline, payment pending, confirmed not started, in progress, completed not rated, completed rated, cancel sheet (reason and refund preview), cancelled with refund, replacement requested.
**22 Active service:** loading, error, offline, before the first day, not arrived yet, default day 2 (attendance calendar), mixed month with rating open, absent filter, report sheet (report an issue).
**23 Service history:** loading, error, offline with saved history, default, empty for a new customer, cook filter, year sheet, search results, search no match.
**24 Rate worker:** default with no rating, 2-star low rating (asks for reason), 5-star excellent (tags), comment with keyboard up, submitting, submit error, discard dialog, thank you, already rated (read-only).
**25 Request replacement:** default, reason chosen, Other with note required, safety concern (escalated path, support contact), from-a-date calendar, not eligible (with reason), confirmation dialog, submitting, submit error, offline, request received.
**26 Replacement status and alternatives:** loading, error, offline, under review, alternatives ready (select one), alternative selected, confirmation dialog, replacement scheduled, couldn't match, cancelled, completed.
**Wire:** Booking detail is the hub. Its actions go to Active service, Rate (when completed and unrated), Replacement (when eligible), Support new ticket (prefilled with the booking), Receipt (Module 10) and Cancel. Cancelling produces a refund transaction (Module 10). A replacement picks from the Module 6 worker detail components. Rating updates the worker's reviews. Service history lists completed bookings and links to Booking detail and Rate.

## MODULE 10: Support and Money (27 to 31)
**27 Support home:** loading, default (FAQs and tickets), FAQ expanded, search results, no search results, no tickets, error, offline.
**28 New ticket:** default plain, opened from a booking (prefilled), booking picker sheet, filled, validation errors, duplicate notice (links to an existing ticket), urgent, uploading and upload failed (retry per file), submitting, submit error, ticket created, offline.
**29 Ticket detail:** loading, error, offline, open new ticket, in progress, waiting for you, composer with keyboard, send failed (retry), resolved, resolved with feedback, closed (read-only).
**30 Transactions:** loading, default, month sheet, empty month, no transactions yet, refunds filter, search results, no search match, error, offline.
**31 Receipt:** loading, success, pending, failed, refund pending, refunded, downloading, saved, link expired (regenerate), error, offline. Download and share a PDF.
**Wire:** tickets are created from Support, Booking detail, Active service reports and Replacement safety paths. Ticket updates raise notifications. Transactions come from Payments and Refunds; each row opens its Receipt. Payment status "View receipt" opens a Receipt.

## MODULE 11: Notifications (32)
States: loading, default, unread tab, all read, empty, error, offline, permission off (banner -> OS settings), row actions (mark read/unread, delete), settings sheet (per-category toggles).
**Wire:** every notification has a `type` and `entityId`, and tapping it routes by type to the matching screen (Interview, Booking, Replacement, Ticket, Receipt). Expo push is registered after login. The Home bell shows the unread count.

## MODULE 12: Account (33)
States: loading, new user, default, offline, error, edit profile (changed/unsaved, email error), language sheet (shared with Module 1), log out dialog, delete account (blocked with an active booking; ready state with confirmation).
**Wire:** edit profile updates the session user. Language change applies app-wide. Logout clears session, caches and push token and returns to Login. Delete account calls the API, clears all data and returns to Splash. Account also links to Service history, Transactions, Support, Notification settings and saved addresses.

---

## Final integration pass (after Module 12)
1. Walk the full journey end to end: sign-up -> build requirement -> results -> interview -> pay -> booking -> active service -> rate -> history -> receipt -> support.
2. Confirm every state in the file names above is reachable via the mock-API toggle (a hidden dev menu).
3. Test deep links, push taps, app-kill-and-resume mid-requirement and mid-payment, and offline cache behaviour.
4. Produce `docs/SCREEN_COVERAGE.md`: one row per PNG file with the route, component and status (done/partial). **The target is 100%.**
5. Run the code-review-graph `detect_changes_tool` and `get_affected_flows_tool`, and fix the high-risk findings.

## How to work
Start with Module 1. After each module, summarise what you built, the screens and states covered, how it is wired to the previous and next module, and the test results. Then continue to the next module without waiting, unless something is ambiguous. If a screenshot is unclear, state your assumption and proceed.
