# Module 03 — Main Shell & Home

> **Deployed API (2026-10-13/15, see DECISIONS):** Home = `GET /customers/me/home` (aggregate); unread count from `GET /notifications/unread-count`. The routes in the Backend line below are the original assumption. Live Home shows the new-customer view until bookings exist for the customer.

**Goal:** persistent bottom navigation + Home as launch surface. No fake metrics (AGENTS §13).
**Backend:** `GET /home` (aggregate, assumed) else compose: `GET /bookings?status=current&limit=1`, `GET /interviews?upcoming=true&limit=1`, `GET /catalog/categories`, `GET /notifications/unread-count`.
**Routes:** `/home` (inside shell). Shell tabs: Home `/home`, Bookings `/bookings`, Favourites `/favourites`, Account `/account` (final tab set TBD with design).

## Bottom navigation
| Element | Key | On tap | Result |
|---|---|---|---|
| Home tab | `nav_home` | switch branch (state preserved) | shows Home |
| Bookings tab | `nav_bookings` | switch | Booking list (module 08) |
| Favourites tab | `nav_favourites` | switch | Shortlist (module 06) |
| Account tab | `nav_account` | switch | Account (module 14) |
Re-tapping active tab scrolls to top / pops to tab root. Android back on a non-Home tab → go to Home tab; back on Home → exit app (confirm not required).

## Screen 3.1 — Home (`/home`)
Layout top→bottom (a section is **hidden** if backend returns nothing for it):
1. Header: greeting "Hi, {name}", default address chip, notification bell with unread badge.
2. Primary CTA card "Find a worker".
3. Category quick row (from catalog).
4. Active booking card (if any).
5. Upcoming interview/trial card (if any).
6. Shortlist preview (if any favourites).
7. Support shortcut.

| Element | Key | On tap → Action | Navigates to |
|---|---|---|---|
| Address chip | `home_address_chip` | open address picker bottom sheet (list from module 02; selecting changes **default for discovery draft only**, not server default unless user taps "Set default") | stays; chip updates |
| Notification bell | `home_bell_btn` | — | **push `/notifications`** |
| Find a worker card | `home_find_worker_btn` | reset requirement draft, start flow | **push `/discover/category`** |
| Category tile | `home_category_tile_<id>` | reset draft, preset category | **push `/discover/engagement`** (category step skipped; back goes to category screen) |
| Active booking card | `home_active_booking_card` | — | **push `/bookings/:id`** |
| "View all" (bookings) | `home_view_bookings_btn` | — | switch to Bookings tab |
| Upcoming interview card | `home_interview_card` | — | **push `/interviews/:id`** |
| Shortlist preview card | `home_fav_worker_<id>` | — | **push `/workers/:id`** |
| "View shortlist" | `home_view_favs_btn` | — | switch to Favourites tab |
| Support shortcut | `home_support_btn` | — | **push `/support`** |
Pull-to-refresh refetches all sections independently (one section failing shows a small inline retry, not a full-screen error).
No addresses saved → show banner "Add an address to find workers" `home_add_address_btn` → push `/addresses/new`.

## Test Cases
| ID | Type | Given → When → Then |
|---|---|---|
| HOME-01 | W | No active booking/interview → those sections absent, no placeholder numbers |
| HOME-02 | W | Tap `home_find_worker_btn` → route `/discover/category` and draft is empty |
| HOME-03 | W | Tap category tile → `/discover/engagement` with category preset in draft |
| HOME-04 | W | Active booking present → card shows; tap → `/bookings/:id` correct id |
| HOME-05 | W | Bell shows unread count; tap → `/notifications` |
| HOME-06 | W | One section API fails → other sections still render, inline retry on failed one |
| HOME-07 | W | No address → banner CTA → `/addresses/new` |
| HOME-08 | W | Bottom nav keeps each tab's scroll/state when switching |
| HOME-09 | W | Android back on Bookings tab → Home tab; back on Home → app exits |
| HOME-10 | W | Pull-to-refresh calls repos again |
