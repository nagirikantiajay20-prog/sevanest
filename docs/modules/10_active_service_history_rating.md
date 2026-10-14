# Module 10 — Active Service, Service History & Rating

**Backend (REAL, docs/backend_openapi_2026-10-13.json - overrides the assumed routes below):**
`GET /bookings/{id}` + `GET /bookings` (history; no `/services/history`), `GET /attendance/bookings/{id}` and `/summary?month=YYYY-MM`
(status `PRESENT | ABSENT | EXCEPTION`, `note`), `POST /ratings {bookingId, score >= 1, review <= 2000}` (Idempotency-Key; 409 `RATING_ALREADY_EXISTS`,
422 `RATING_NOT_ELIGIBLE`, 400 `RATING_SCORE_OUT_OF_SCALE`), `GET /ratings`, `GET /ratings/bookings/{id}` (404 = not rated), `ratingScaleMax` from `/reference-data`.
No eligibility endpoint, no tags, no `rebook`. See BACKEND_REQUESTS 28-36.
~~Assumed (not deployed): `/bookings/{id}/attendance`, `GET /services/history`, `POST /bookings/{id}/rating`, `rating-eligibility`.~~
**Routes:** `/services/current?bookingId=`, `/services/history`, `/ratings/:bookingId`.
**Rules:** no face-recognition/GPS attendance (V2). Show **only** statuses backend provides. Rating only when `allowedActions` has `rate`.

## Screen 10.1 — Active Service (`/services/current`)
Entry points: Home active card (via booking detail), Booking detail "View active service". If no `bookingId` and exactly one active booking → use it; if several → picker list.
Elements: worker card, service/engagement, schedule, location, "Today" status block, attendance list (date, status label, remark if any), action row.
| Element | Key | Visible when | On tap | Result |
|---|---|---|---|---|
| Worker card | `service_worker_card` | always | — | **push `/workers/:id`** |
| Booking details | `service_booking_link` | always | — | **push `/bookings/:id`** |
| Attendance row | `attendance_row_<date>` | has data | expand/collapse remark | — |
| Load more | `attendance_load_more_btn` | `nextCursor` | page | append |
| Report an issue | `service_support_btn` | always | — | **push `/support/new?bookingId=`** |
| Request replacement | `service_replace_btn` | `replace` | — | **push `/replacements/new?bookingId=`** |
| Rate worker | `service_rate_btn` | `rate` | — | **push `/ratings/:bookingId`** |
| Report/Block worker | `service_report_btn` | always | — | report sheet (module 12) |
Empty attendance: "No updates yet. You'll see your worker's status here." Error → retry. Refetch on resume + on notification.

## Screen 10.2 — Service History (`/services/history`)
Grouped sections: **Current**, **Past → Completed / Cancelled / Replaced**. Cards: worker, service, dates, outcome chip, rating given (stars) if any.
| Element | Key | On tap | Result |
|---|---|---|---|
| History card | `history_card_<id>` | — | **push `/bookings/:id`** |
| Rate (if eligible, on card) | `history_rate_btn_<id>` | — | **push `/ratings/:id`** |
| Rebook same worker | `history_rebook_btn_<id>` *(only if backend `rebook` action)* | prefill draft | **push `/discover/review`** |
Paginated; empty "No past services yet".
Entry: Account → "Service history".

## Screen 10.3 — Rating (`/ratings/:bookingId`)
On open: check eligibility (`GET /bookings/{id}` allowedActions or `GET …/rating-eligibility`). Elements: worker card, star selector (scale from backend; default 1–5 TBD), optional tags (backend), comment (max from backend, default 500), Submit.
| Element | Key | Enabled when | On tap → Action | On success → | On failure |
|---|---|---|---|---|---|
| Star n | `rating_star_<n>` | eligible | select score | — | — |
| Tag chip | `rating_tag_<id>` | eligible | toggle | — | — |
| Comment | `rating_comment_field` | eligible | text | — | length error |
| Submit | `rating_submit_btn` | score chosen, not loading | `POST /bookings/{id}/rating` | **replace** with thank-you state "Thanks for your feedback" + `rating_done_btn` → **go `/bookings/:id`** | `already_rated` → state "You've already rated this service" + button to booking; not eligible → message, hide form; validation → field error; network → rule 3 (keep input) |
Not eligible on open → screen shows reason, no form.

## Test Cases
| ID | Type | Given → When → Then |
|---|---|---|
| SVC-01 | W | Active service renders attendance statuses incl. unknown label without crash |
| SVC-02 | W | Empty attendance → friendly message; error → retry |
| SVC-03 | W | Buttons Replace/Rate shown only if `allowedActions` contain them |
| SVC-04 | W | Multiple active bookings → picker; single → direct |
| SVC-05 | W | Each button navigates: worker, booking, support, replacement, rating (route + params asserted) |
| SVC-06 | W | History groups Completed/Cancelled/Replaced; pagination loads more; empty state |
| SVC-07 | W | Rating: Submit disabled until star chosen |
| SVC-08 | W | Submit success → thank-you; back/done returns to booking; duplicate submit blocked |
| SVC-09 | W | already_rated → no form |
| SVC-10 | W | Not eligible (no `rate` action) → reason message, no form |
| SVC-11 | W | Network failure keeps stars/comment |
| SVC-12 | U | Rating scale and comment max read from config (not literals) |
| SVC-13 | I | **Flow G**: Confirmed booking → Active service → Attendance → History |
| SVC-14 | I | **Flow H**: Completed eligible booking → Rating → Submit → Success |
