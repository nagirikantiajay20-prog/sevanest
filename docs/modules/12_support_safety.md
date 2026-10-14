# Module 12 — Support Tickets & Safety (Report/Block)

> **Built on the real contract (docs/backend_openapi_2026-10-13.json), which overrides the routes assumed below.**
> Backend: `GET /support/categories`, `POST /support/tickets` (Idempotency-Key; body `categoryId`, `description` max 4000, optional `bookingId`), `GET /support/tickets` (paged), `GET /support/tickets/{id}` (status `OPEN | IN_PROGRESS | ESCALATED | CLOSED`, `resolution`, `history`), `GET` / `POST /support/tickets/{id}/messages` (body max 2000; 409 `TICKET_CLOSED`), `POST /safety/reports` (`reasonCode` enum, `note` max 1000, `alsoBlock`), `POST /safety/blocks`, `GET /safety/blocks`, `DELETE /safety/blocks/{id}`.
> Not in the backend, so not built: subject, photos, urgent priority, FAQ and help search, "Waiting for you" / resolved feedback, ticket overflow menu, listing or lifting blocks (no design entry). A payment, replacement or interview is linked through its booking. `ESCALATED` is shown as "In progress". See BACKEND_REQUESTS 45-50.
> Design: screens 27, 28, 29 and 22 "Report sheet open". Routes: `/support`, `/support/new?bookingId=|paymentId=|replacementId=|interviewId=|categoryId=|safety=true`, `/support/:id`.

**Original draft backend (assumed, superseded):** `GET /catalog/ticket-categories`, `POST /tickets`, `GET /tickets`, `GET /tickets/{id}`, `POST /tickets/{id}/reply`, `POST /workers/{id}/report`, `POST /workers/{id}/block`.
**Routes:** `/support`, `/support/new`, `/support/:id`.
**Rules:** customer cannot see/edit internal owner/priority/escalation fields; categories server-driven.

## Screen 12.1 — Support Home (`/support`)
Elements: "Raise a ticket" button, optional FAQ/contact (only if provided by backend config), ticket list (subject, category, status chip, last update).
| Element | Key | On tap | Result |
|---|---|---|---|
| New ticket | `support_new_btn` | — | **push `/support/new`** |
| Ticket card | `ticket_card_<id>` | — | **push `/support/:id`** |
| Filter chips Open/Closed | `support_filter_<open|closed>` | filter | list reload |
| Empty | `support_empty_new_btn` | — | **push `/support/new`** |
Pull-to-refresh; paged.

## Screen 12.2 — New Ticket (`/support/new`)
Elements: category dropdown (backend), related item chip (auto when launched from booking/payment/etc.; removable), subject (optional), description (required, min 10, max from backend), Submit. Attachments **not V1**.
| Element | Key | Enabled when | On tap → Action | On success → | On failure |
|---|---|---|---|---|---|
| Category | `ticket_category_dropdown` | — | select | — | — |
| Related item chip ✕ | `ticket_related_remove_btn` | prefilled | clear link | — | — |
| Description | `ticket_description_field` | — | validate length | — | inline error |
| Submit | `ticket_submit_btn` | category + description valid, not loading | `POST /tickets` + Idempotency-Key | **replace → `/support/:id`**; snackbar "Ticket raised" after 2xx | fieldErrors inline; network → rule 3 + refetch `/tickets` to avoid duplicate |
Back with text → discard dialog.

## Screen 12.3 — Ticket Detail (`/support/:id`)
Shows: ticket id, category, status chip, created date, related item link, conversation/updates (customer message + staff updates), resolution block (when closed).
| Element | Key | Visible when | On tap | Result |
|---|---|---|---|---|
| Related item link | `ticket_related_link` | has link | — | **push** corresponding booking/payment/replacement screen |
| Reply field + Send | `ticket_reply_field`, `ticket_reply_btn` | status open & backend allows reply | `POST …/reply` | message appended after 2xx; failure → keep text, snackbar |
| Reopen | `ticket_reopen_btn` | `allowedActions: reopen` | confirm → API | status refetch |
| Pull to refresh | — | — | refetch | — |
Status labels from mapper; internal fields never shown.

## Report / Block worker (bottom sheet from worker detail, active service)
| Element | Key | On tap → Action | Result |
|---|---|---|---|
| Report | `report_open_btn` | sheet: reason list `report_reason_<id>` + details + `report_submit_btn` | `POST /workers/{id}/report`; success → sheet closes, snackbar "Thanks, our team will review this" (2xx only); creates/links ticket if backend returns ticketId → option `report_view_ticket_btn` → **push `/support/:id`** |
| Block | `block_open_btn` | confirm dialog `block_confirm_btn` ("You won't be matched with this worker") → `POST …/block` | worker hidden from results; pop to previous list; failure → snackbar |
| Cancel | `report_cancel_btn` | close | — |
Block/report availability depends on backend flag; do not fake effects locally.

## Test Cases
| ID | Type | Given → When → Then |
|---|---|---|
| SUP-01 | W | Categories loaded from repo; error → retry |
| SUP-02 | W | Submit disabled until category + description ≥ min length |
| SUP-03 | W | Launched from booking → related chip prefilled with that booking; remove clears it |
| SUP-04 | W | Submit success → route replaced to detail; back doesn't return to form |
| SUP-05 | W | Network error on submit → refetch avoids duplicate ticket |
| SUP-06 | W | Detail never renders owner/priority/escalation fields even if in JSON |
| SUP-07 | W | Reply appears only after API success; failure keeps text |
| SUP-08 | W | Closed ticket shows resolution; reply hidden |
| SUP-09 | W | List filter Open/Closed; empty-state CTA works |
| SUP-10 | W | Report sheet submit → API once → confirmation; failure keeps sheet open |
| SUP-11 | W | Block confirm → API → worker no longer in results (list refetched) |
| SUP-12 | I | **Flow J**: Support → New ticket → Submit → Detail → status update visible after refresh |
