# Module 11 — Replacement

**Backend (REAL, docs/backend_openapi_2026-10-13.json - overrides the assumed routes below):**
`POST /replacement-requests {bookingId, reason <=1000, notes <=2000}` (Idempotency-Key; 404 not mine, 422 `REPLACEMENT_NOT_ELIGIBLE`, 409 while one is open),
`GET /replacement-requests` (mine, newest first, paged), `GET /replacement-requests/{id}`, `POST .../{id}/cancel` (withdraw an open request; booking ACTIVE again),
`POST .../{id}/select {workerId}` (once APPROVED; creates the MATCHED replacement booking, closes the old one as REPLACED), `GET /bookings/{id}/replacement-chain` (oldest first).
Status `REQUESTED | APPROVED | REJECTED | CANCELLED | COMPLETED`. No reason list, no needed-from date, no customer alternatives route, no events. See BACKEND_REQUESTS 37-44.
~~Assumed (not deployed): `POST /bookings/{id}/replacement`, `GET /replacements/{id}`, `/alternatives`, `/replacements/{id}/select`, `GET /catalog/replacement-reasons`.~~
**UI (design 25 / 26 wins):** Request received screen after submit (Track request replaces the form with the status); choose a card on the status screen, then "Confirm replacement" (dialog); worker detail "Choose" mode is NOT built.
**Routes:** `/replacements/new?bookingId=`, `/replacements/:id`.
**Stage rule (audit 2026-11-08):** replacement is for ACTIVE bookings only. After an interview (`INTERVIEW_TRIAL_COMPLETED`) the booking detail offers Confirm worker / Find another worker (`booking_reopen_matching_btn` → confirm → `reopen-matching` → `/workers`) / Cancel, never Request Replacement; `Booking.fromJson` removes `replace` for any non-ACTIVE status. Pre-service change: unsupported, see BACKEND_REQUESTS "Worker change by stage".
**Rules:** customer only *requests*; Support/Admin decides (AGENTS §45, §80.4). Eligibility = backend (`allowedActions.replace`). Previous engagement stays visible. Status enum is backend-owned (`ReplacementStatusMapper` + unknown fallback).

Conceptual UI states: `requested → under_review → approved → alternatives_available → replacement_selected → replacement_confirmed`; terminal `rejected`, `closed`.

## Screen 11.1 — Request Replacement (`/replacements/new`)
Elements: info banner (backend text about how replacement works), booking/worker mini-card, reason radio list, notes field (required if reason = Other; max from backend), Submit.
| Element | Key | Enabled when | On tap → Action | On success → | On failure |
|---|---|---|---|---|---|
| Reason | `replacement_reason_<id>` | — | select | — | — |
| Notes | `replacement_notes_field` | — | text | — | "Please add a note" if Other |
| Submit | `replacement_submit_btn` | reason chosen (+notes if needed), not loading | confirm dialog "Request a replacement? Our team will review it." `replacement_confirm_btn` → `POST /bookings/{id}/replacement` | **replace → `/replacements/:id`**; snackbar "Request sent" after 2xx | not eligible (422/403) → message from backend, form locked; already requested (409) → **replace → existing `/replacements/:id`**; network → rule 3 + refetch booking to detect request |
| Cancel dialog | `replacement_cancel_btn` | — | dismiss | — | — |
Back with input → discard dialog.

## Screen 11.2 — Replacement Status (`/replacements/:id`)
Top: status banner (colour+icon+text), summary: previous worker card (greyed "Current engagement" tag), reason/notes, timeline (backend events), contextual section by state:
| State | Section | Buttons |
|---|---|---|
| requested / under_review | "We're reviewing your request" + expected time (backend) | `replacement_support_btn` → **push `/support/new?replacementId=`**; (if allowed) `replacement_withdraw_btn` → confirm → withdraw API (only if backend `withdraw`) |
| approved (no alternatives yet) | "Finding alternatives for you" | refresh |
| alternatives_available | list of alternative worker cards (reuse WorkerCard) | card → **push `/workers/:id?replacementId=`** ; select CTA there (see below) |
| replacement_selected | "Waiting for confirmation" + chosen worker | — |
| replacement_confirmed | success text + new worker card | `replacement_view_booking_btn` → **go `/bookings/:newBookingId`**; `replacement_view_old_btn` → **push `/bookings/:oldBookingId`** |
| rejected | reason (backend) | `replacement_support_btn`; `replacement_back_booking_btn` → **go `/bookings/:id`** |
| closed | summary | — |
Pull-to-refresh; refetch on resume/notification.

## Selecting a replacement
In worker detail opened with `replacementId`, the bottom bar shows `worker_select_replacement_btn` "Choose as replacement" instead of Request Interview (unless backend requires interview first — TBD).
| Element | Key | On tap → Action | Result |
|---|---|---|---|
| Choose as replacement | `worker_select_replacement_btn` | confirm dialog `replacement_select_confirm_btn` → `POST /replacements/{id}/select {workerId}` | **pop to `/replacements/:id`**, state → replacement_selected (refetch); 409 worker unavailable → dialog, list refetched; network → rule 3 |

## Test Cases
| ID | Type | Given → When → Then |
|---|---|---|
| REP-01 | W | Replace button hidden/disabled if not eligible; reason message shown |
| REP-02 | W | Submit disabled until reason; Other requires notes |
| REP-03 | W | Submit → confirm dialog → API once → route replaced to status; back doesn't return to form |
| REP-04 | W | 409 already requested → goes to existing status |
| REP-05 | W | Not eligible 422 → form locked with message |
| REP-06 | U | StatusMapper: all states + unknown |
| REP-07 | W | Each state renders correct section and only its buttons (table-driven) |
| REP-08 | W | Alternatives list uses WorkerCard; tap → detail with replacementId |
| REP-09 | W | Select replacement → confirm → API → status refetched; unavailable worker handled |
| REP-10 | W | Confirmed state: both new and old booking links navigate correctly; old engagement remains viewable |
| REP-11 | W | Withdraw visible only when backend allows |
| REP-12 | I | **Flow I**: Active service → Replacement → Reason → Submit → Status → Alternatives → Select |
