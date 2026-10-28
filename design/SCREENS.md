# Screen inventory (crawled 2026-10-22 from https://growth-glory-58907994.figma.site/)

Screenshots: `design/screens/NN_*.jpg`, captured at a 325x703 CSS-px viewport (DPR 2, downscaled). The prototype is a Figma Make web app, so widths are slightly narrower than a 390 pt phone; use them for layout and styling, not exact pixel widths. Tokens: `design/tokens.md`.
Dummy data was typed into the prototype (9876543210, "Priya Sharma"); nothing real was sent (the prototype states it is local only).

## Captured

| # | Screens (files) | Prototype content | Existing app screen |
|---|---|---|---|
| 01 | `01_splash` | Logo, wordmark, tagline, "Trusted help for your home", 3 trust icons, room photo, "Getting things ready…" loader | `splash_screen.dart` |
| 02-03 | `02_login`, `03_login_filled` | Photo hero, headline, 3 trust rows, EN chip, "Log in or sign up" sheet, +91 field, Get OTP, **Continue with WhatsApp (dropped)**, privacy note, legal text | `login_screen.dart` |
| 04-05 | `04_otp_empty`, `05_otp_filled` | "Verify your number", masked phone + edit, 6 boxes, resend timer, Verify & continue, "Didn't receive the code?" card (demo autofill chip is prototype-only) | `otp_screen.dart` |
| 06-08 | `06`..`08_profile_setup*` | 4-step progress, avatar + camera, Full name*, Email, language chips (6), address row (-> filled "Home · Madhapur"), Continue, 18+ note | `profile_setup_screen.dart` |
| 09-10 | `09_home`, `10_home_scrolled` | Location header, bell, avatar, greeting, search, Full-time/Part-time toggle, Find help, promo carousel, "Explore services" 8-tile grid, trust strip, bottom nav (Home, Services, Bookings, Favourites, Account) | `home_screen.dart`, `main_shell.dart` |
| 11-21 | `11`..`21_find_*` | "Find a worker" 6 steps: service list, engagement, location (saved addresses + GPS), timing (+ confirm sheet, days chips), start date (quick dates + calendar), budget (range + presets + flexible), review with Edit rows | `service_discovery/*` |
| 22-23 | `22_results`, `23_results_filters_sheet` | Summary header, shortlist heart with count, search field, "6 workers match", Filters (**only "Top rated"**), Sort, worker rows (initials, verified tick, price/month, availability, heart) | `results_screen.dart`, `filter_sheet.dart`, `worker_card.dart` |
| 24-26 | `24`..`26_worker_detail*` | Hero, stats row, About, pricing + match chips, skills, languages, verification list, reviews, sticky Shortlist + Request interview | `worker_detail_screen.dart` |
| 27-29 | `27`..`29_interview_*` | Request interview (video / phone / trial visit, date strip, time chips, note 200), "Request sent" card | `interview_request_screen.dart` |
| 30-33 | `30`..`33_interview_*` | Interview detail (confirmed banner, worker, schedule, progress timeline, Join video call, demo-only completion, "Hire Meena · Confirm and pay") | `interview_detail_screen.dart` |
| 34-36 | `34`..`36_confirm_booking*` | Confirm booking: worker, booking summary + Edit, price details (wage, **service fee ₹500, taxes ₹90**), payment methods (UPI/Cards/Net banking), policy links, T&C checkbox, sticky total + CTA | `confirm_worker_screen.dart`, `payment_screen.dart` |
| 37 | `37_payment_success` | "Booking confirmed" card (amount, booking id, method, reference), View booking / All bookings | `payment_screen.dart` |
| 38, 42 | `38_booking_detail`, `42_booking_detail_completed` | Status banner, worker, details, progress, total paid, CTA | `booking_detail_screen.dart` |
| 39-40 | `39_bookings_current`, `40_bookings_past` | Current/Past tabs with counts, search, cards (status chip, id, worker, dates, price, View details / Rate worker / "You rated 5.0" / Refunded) | `bookings_list_screen.dart` |
| 41 | `41_rating` | Worker card, 5 stars, review (300), Submit, Skip for now | `rating_screen.dart` |
| 43 | `43_shortlist` | Back header, All/Cook/Driver chips, saved cards with Request interview | `favourites_screen.dart` |
| 44-45 | `44_account`, `45_account_bottom` | Profile card + Edit profile, My activity, My details, Help and legal, Log out, Delete account, (Reset Demo = prototype-only) | `account_screen.dart` |
| 46 | `46_service_history` | Totals banner (9 services, 7 workers, ₹53,300), search, category chips, year filter, month groups | `service_history_screen.dart` |
| 47 | `47_transactions` | Month summary (paid / refunds / pending), All/Success/Pending/Failed/Refunds chips, rows with masked method | `transactions_screen.dart` |

## Not captured (prototype crawl stopped; need your export or another pass)
Home: bell/notifications, location sheet, search overlay, "See all" services, promo target. Account: Edit profile, Saved addresses list/form, Language, Notifications, Loading skeleton preview, Help and support, Terms / Privacy / About, Log out and Delete dialogs. Payment Failed / Pending outcomes. Active service, replacement, support screens, transaction detail, cancel sheet, empty/error/offline states.

## Design vs existing app/backend: conflicts to resolve before building
1. **Fee/tax breakdown on Confirm booking** (₹500 + ₹90): the app has no quote endpoint; the fee is set at payment (docs/PROGRESS 6.1). Show only when the backend supplies it.
2. **Filters sheet** shows only "Top rated"; the app filters by availability, language, experience (backend params). Rating filter is OPEN_QUESTIONS #40.
3. **Join video call**: no video calling in V1 (no provider). Design has it.
4. **Service history totals, filter chips, search**: backend has none (BACKEND_REQUESTS 29-34).
5. **Bookings search**, **Transactions search and month picker**, **profile avatar/photo** (photo is out of V1).
6. **Budget step** and "Typical for a part-time cook" guidance: mock only until backend guidance exists.
7. **Interview "Request sent" then immediate "confirmed" by worker** is prototype choreography, not a flow.
8. **WhatsApp login**: dropped by decision.
9. **Fonts**: Sitka Heading (headings) is a Windows font; Inter for body. Decision pending (bundle free serif + Inter, `google_fonts`, or system).
10. Prototype shows a 6-language chooser; V1 is English only (existing handling kept).

## Decisions (2026-10-22, owner)
- **No mock data in the UI.** Only backend data. A design element the backend cannot serve is hidden and logged in `docs/BACKEND_REQUESTS.md` ("Figma design integration").
- **Every button and card must have a working action.** An element with no real action is not shown (so no disabled "Coming soon" video button; video join is a V2 item).
- Confirm booking fee/tax rows: shown only when the backend supplies them (no `BookingQuote` mock).
- Filters use the app's real filters (availability, language, experience); "Top rated" left out (backend rating filter pending #40).
- Service history totals/filters hidden (backend gap).
- Fonts: system fonts; family defined only in `lib/app/theme/typography.dart`.
- Screenshots are 325 px wide: layout reference only.

## Status
| Item | Status |
|---|---|
| Theme tokens, text styles, shared components (Step A) | Done, approved 2026-10-22 |
| Splash | Done (room photo photo added 2026-10-23; see below) |
| Login | Done (hero photo photo added 2026-10-23; WhatsApp Trimmed) |
| OTP | Done (hero photo + phone illustration photo added 2026-10-23; demo autofill chip Trimmed) |
| Profile setup | Done (avatar, back button, address row, 6-language choice Trimmed; hero photo photo added 2026-10-23) |
| Home + shell | Done (promo carousel, search, Full/Part-time toggle, avatar, tile/hero photos Trimmed or photo added 2026-10-23) |
| Find a worker: shared chrome + step 1 Service | Done (header, step bar, headline and error card restyled for all steps) |
| Find a worker step 2 Engagement (+ "Service · Change" pill shared by steps 2-6) | Done |
| Find a worker step 3 Location | Done |
| Find a worker step 4 Timing (window cards, time fields, day tiles, "Selected: n days"; shared pills and chips) | Done ("Confirm preferred time" sheet Trimmed: not in module 04) |
| Find a worker step 5 Start date (shortcut cards, schedule chip on steps 5-6) | Done ("Need someone urgently?" tip Trimmed: no backing feature) |
| Find a worker step 6 Budget (guidance card, readout, fields) | Done (guidance still hidden when the backend has none; summary stays above Review, not beside it) |
| Find a worker Review (shared header with "All steps done", divided rows with Edit pills) | Done |
| Results + Filters (header, summary chips, Filters pill, worker card, filter sheet) | Done (search field, Sort chip, "n workers match", price per month and distance Trimmed: no backend data) |
| Worker detail + reviews list (hero, stats, skills, languages, availability, reviews quote cards, sticky Shortlist + Request interview, pending badge, disabled-with-reason) | Done (name, distance, About, pricing/match chips, jobs done, repeat customers, verification checklist, Share Trimmed or Blocked: no backend data) |
| Shortlist (header + subtitle, category chips with counts, cards with Request interview, unavailable badge, undo, empty) | Done (price, distance, "Saved today" Trimmed: no backend data) |
| Interview request (header, worker card, type cards, date, slot chips, note, sticky submit with hint) | Done (video/phone types, auto-confirm Trimmed; date strip kept as the existing date picker) |
| Interview detail + list (header, status card, worker card, details card, progress card, actions from allowedActions, list cards) | Done (Join video call Trimmed; Complete shown only if backend allows it) |
| Confirm booking (header, worker card, summary card with Edit, price card from BookingQuote, policy link, sticky total + CTA) | Done (payment-method chips, T&C checkbox Trimmed: payment happens in the next step; fee/tax rows use the approved BookingQuote mock, Blocked by backend) |
| Payment (header, ring-icon result states for success/failed/pending/verifying/not-payable, amount cards, sticky Pay bar, leave dialog, recovery banner) | Done (payment method and reference rows Trimmed: not served) |
| Bookings list, Booking detail, Cancel sheet (header, Current/Past chips, status-chip cards with reference and Complete payment, status card, details card, timeline card, actions from allowedActions, sheet) | Done (search, tab counts, price per card Trimmed: no backend data) |
| Active service (header with report/block, worker card, status, today card, month summary, attendance card, actions; now refetches on notification) | Done (no design; shared components only) |
| Rating (header, worker card, stars, tag chips, review, thank-you / already rated / not eligible cards) | Done |
| Replacement request + status (shared header, canvas, deep CTAs; cards already match the theme; all statuses, alternatives and withdraw unchanged) | Done (no design) |
| Support (home was already on-design; new ticket and ticket detail moved to the shared header; report/block sheets unchanged) | Done (no design) |
| Notifications (centre and deep-link screen on the shared header; push pre-prompt dialog restyle pending the global dialog pass) | Done (no design) |
| Account (header, profile card with Edit profile, grouped My activity / My details / Help and legal, logout and delete rows), Profile, Addresses list and form, Deletion status on the shared header | Done (Reset Demo, Language row Trimmed; row counts like "9 services" Trimmed: not served; dialogs in the global pass) |
| Service history (header, totals card, search, filters, grouped sections, cards with rating and rebook) | Done (totals, search and filters KEPT: the backend now serves them, so the earlier hide decision no longer applies) |
| Transactions + Receipt (header, All/Paid/Refunded chips, row cards with status chips, receipt card with refund note) | Done (search, month picker, month summary, per-row method Trimmed: not served) |
| Global pass (dialogs and sheets already follow the theme: 24 radius, serif titles, 32-radius sheets; confirm dialogs use a filled confirm button; no-connection lists show the offline state with retry; 401/403 messages already mapped) | Done (offline banner added with connectivity_plus, approved) |
| Photos (splash, login, OTP, profile setup, Home header and service tiles) taken from the prototype /images, resized to ~100 KB, in assets/images | Done (Home promo banner Trimmed; profile avatar photo not used: no customer-photo endpoint) |
| PRD audit of Splash, Login, OTP, Profile setup, Addresses against modules 01 and 02 | Done (all keys and test cases present; login terms/privacy links now keyed; label chips, line 2, state, language dropdown differ by backend/design decision, already documented in module 02) |
| (old row) Payment success, Bookings, Booking detail, Rating | Not started (Confirm booking partly Blocked by backend: quote) |
| Account, Service history, Transactions | Not started (history totals/filters Blocked by backend) |

## Pending design (keep existing screens, restyle with shared components only)
Edit profile, Saved addresses, Language, Notifications, Help, legal pages, Log out and Delete dialogs, Home overlays (bell, location sheet, search), payment Failed/Pending, active service, replacement, support, empty/error/offline states.

---

# Step 0: Coverage matrix (2026-10-22)

**Input gap:** `design/screens-v2/` does not exist and no Figma frame links were given, so the "new" column is `n/a`. Old = `design/screens/NN`. Re-check every "old" row when V2 arrives (V2 wins on visuals).
Req: M01..M15 = docs/modules file; AGENTS = PRD. Actions: KEEP / BUILD (in design style) / TRIM / BLOCKED (typed marked mock + backend dependency).

| Screen / State | Req? | Design old / new | App today? | Action |
|---|---|---|---|---|
| Splash (auto-route, timeout retry, sign in again) | M01 | 01 / n/a | yes | KEEP; BUILD timeout retry state |
| Login (validation, 429, terms/privacy) | M01 | 02-03 / n/a | yes | KEEP; TRIM WhatsApp |
| OTP (wrong / expired / locked / resend timer) | M01 | 04-05 / n/a | yes | KEEP; BUILD wrong/expired/locked; TRIM demo autofill chip |
| Profile setup | M02 | 06-08 / n/a | yes | KEEP; TRIM avatar photo, 6-language chips |
| Add/Edit address, Address list, empty, delete-409 dialog | M02 | 08 partial / n/a | yes | BUILD |
| Profile view/edit | M02.4 | none / n/a | yes | BUILD |
| Discard-changes dialog | M00 | none | yes | BUILD |
| Shell + bottom nav (Home, Bookings, Favourites, Account) | M03 | 09 shows 5 tabs / n/a | yes | KEEP; TRIM "Services" tab |
| Home (greeting, address chip, bell badge, Find CTA, categories, active booking, interview, shortlist, support, no-address banner, per-section retry) | M03 | 09-10 / n/a | yes | KEEP; BUILD active booking / interview / shortlist / support cards + section retry; TRIM promo carousel, trust strip |
| Home address-picker sheet | M03 | none | yes | BUILD |
| Home search, "See all" | no | 09 | no | TRIM |
| Find a worker steps 1-6 + Review (+ close/discard, unserviceable, empty/error) | M04 | 11-21 / n/a | yes | KEEP; BUILD dialogs and states |
| Budget guidance text | no endpoint | 20 | mock | BLOCKED (hide on 404) |
| Results (loading / empty / error / stale / footer retry) | M05 | 22 / n/a | yes | KEEP; BUILD empty, stale, error |
| Filters sheet | M05 | 23 / n/a | yes | KEEP with real filters (availability, language, experience); TRIM "Top rated" |
| Worker detail (+ unavailable, verified sheet, report/block) | M05, M12 | 24-26 / n/a | yes | KEEP; BUILD unavailable, verified sheet |
| Worker reviews list | M05.4 | none | yes | BUILD; data BLOCKED (mock until served) |
| Shortlist (+ empty, undo, unavailable tag) | M06 | 43 / n/a | yes | KEEP; BUILD empty/unavailable |
| Interview request | M07 | 27-29 / n/a | yes | KEEP; TRIM video type, auto-confirm choreography; BUILD 409 slot-taken |
| Interview detail: requested, scheduled, reschedule proposed, completed, cancelled, declined, not a fit, unknown | M07 | 30-33 (3 states) / n/a | yes | KEEP; BUILD other statuses; TRIM Join video call, demo completion |
| Interview list + empty | M07.3 | none | yes | BUILD |
| Confirm booking | M08 | 34-36 / n/a | yes | KEEP |
| Fee / tax rows | M08 quote | 35 | no | BLOCKED: typed BookingQuote mock (approved) |
| Payment: ready, verifying, success, failed, pending, cancelled, leave dialog, recovery banner | M09 | 37 (success only) / n/a | yes | KEEP success; BUILD rest |
| Bookings list Current/Past (+ pay CTA, empty) | M08.2 | 39-40 / n/a | yes | KEEP; BUILD every status chip; TRIM search |
| Booking detail (every status, timeline, allowedActions) | M08.3 | 38, 42 / n/a | yes | KEEP; BUILD cancelled, replaced, replacement requested, pending payment, unknown |
| Cancel sheet | M08.4 | none | yes | BUILD |
| Active service (attendance, report missing day, empty) | M10.1 | none | yes | BUILD |
| Rating (+ thank-you, already rated, not eligible) | M10.3 | 41 / n/a | yes | KEEP; BUILD other states |
| Service history list | M10.2 | 46 / n/a | yes | KEEP; TRIM totals banner, category/year chips, search |
| Replacement request + status (requested, approved, rejected, cancelled, completed, unknown) | M11 | none | yes | BUILD |
| Support home / new ticket / ticket detail / report-block sheet | M12 | none | yes | BUILD |
| Notification centre, push pre-prompt, "item isn't available" screen | M13 | none | yes | BUILD |
| Account | M14 | 44-45 / n/a | yes | KEEP; TRIM Reset Demo; Language hidden (EN only) |
| Logout confirm dialog | M14 | none | yes | BUILD |
| Delete account | OPEN_QUESTIONS #18 | 44-45 | yes | KEEP (approved), restyle |
| Transactions list (statuses, chips, empty) | M09.3 | 47 / n/a | yes | KEEP; TRIM search, month picker, month summary |
| Receipt / transaction detail | M09.4 | none | yes | BUILD |
| Terms / Privacy / About | M14 | none | yes | BUILD |
| Global loading skeleton, empty, error+retry, offline banner | M00 | none | partial | BUILD |

## TRIM list (reason)
1. WhatsApp login: dropped by decision; not in M01.
2. Demo autofill chip, Reset Demo, demo-only completion: prototype scaffolding.
3. Join video call + "video" interview type: no video in V1 (AGENTS 3.2); AGENTS/modules do not mention a disabled "Coming soon", so hidden.
4. Interview auto-"confirmed": prototype choreography; status is backend-owned.
5. Home promo carousel, trust strip, search, "See all": not in M03.
6. "Services" tab: M03 tabs are Home, Bookings, Favourites, Account.
7. "Top rated" filter: no backend filter (OPEN_QUESTIONS #40).
8. Bookings search; Transactions search, month picker, summary; History totals, chips, search: no backend (BACKEND_REQUESTS 29-34).
9. Profile avatar photo: no customer-photo endpoint.
10. Six-language chooser: V1 English only.

## BLOCKED BY BACKEND (typed, marked mock + logged in docs/BACKEND_REQUESTS.md)
1. BookingQuote (fee, tax, total): no quote endpoint.
2. Budget guidance: no endpoint.
3. Worker reviews: mock until served.
4. Interview slot/schedule rules: client-side ScheduleRepository.

## Decisions (2026-10-22, owner, Step 0 replies)
- **Fee/tax: typed `BookingQuote` mock for now** (one service function, clearly marked, logged in BACKEND_REQUESTS). This supersedes the earlier "no BookingQuote mock" line for this one case.
- **Delete account: keep** the existing screen, restyled. (Overrides M14 "hidden until #18"; log the policy dependency.)
- The Figma URL given (growth-glory-58907994.figma.site) is the prototype already crawled; no separate V2 found. Awaiting owner: same design, re-crawl, or another source.

## Proposed integration order
Step A (tokens + shared components, built, awaiting review) -> Splash, Login, OTP -> Profile setup + Addresses -> Home + shell -> Find a worker 1-6 + Review -> Results + Filters -> Worker detail + reviews -> Shortlist -> Interview request, detail, list -> Confirm booking -> Payment states -> Bookings list, Booking detail, Cancel sheet -> Active service -> Rating -> Replacement -> Support -> Notifications -> Account + sub-screens, Transactions, History -> global empty/error/offline + dialogs.
