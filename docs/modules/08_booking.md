# Module 08 — Booking (Confirm, Detail, List, Cancel)

> **Deployed API (see DECISIONS):** there is no `POST /bookings/quote`. Confirm worker = `confirm-worker {startDate}` on the booking, and the fee is set at payment, so the screen shows no fee breakdown or policy text. Cancel reasons are a local list sent as free text. `allowedActions` are derived from the status until the backend sends them. Current / Past is a filter over one paged list.

**Backend:** `POST /bookings/quote`, `POST /bookings`, `GET /bookings?status=`, `GET /bookings/{id}` (with `timeline[]`, `allowedActions[]`, `payment`), `POST /bookings/{id}/cancel`.
**Routes:** `/bookings/confirm`, `/bookings`, `/bookings/:id`.
**Rules:** booking status is backend-owned (customer cannot change it); amounts only from backend; protect from duplicate submission; success message only after backend 2xx.

## Screen 8.1 — Confirm & Pay (`/bookings/confirm?interviewId=` or `?workerId=`)
On open: `POST /bookings/quote` → loading skeleton. Elements: worker mini-card, requirement summary (service, engagement, address, timing, start date), fee breakdown rows + total (from quote), policy text (cancellation/refund/replacement — backend text), consent checkbox (only if legal requires; TBD), "Confirm & pay ₹X".
| Element | Key | Enabled when | On tap → Action | On success → | On failure |
|---|---|---|---|---|---|
| Worker card | `confirm_worker_card` | always | — | **push `/workers/:id`** | — |
| Edit requirement | `confirm_edit_req_btn` | draft exists | — | **push `/discover/review`** | — |
| Policy link | `confirm_policy_link` | always | open bottom sheet with policy | — | — |
| Consent checkbox | `confirm_consent_checkbox` | if required | toggle | — | — |
| **Confirm & pay** | `confirm_pay_btn` | quote loaded, consent ok, not loading | `POST /bookings` (Idempotency-Key generated **once per screen instance**) → returns `bookingId` + `payment` init | **push `/payments/:paymentId`** (module 09) — booking exists in PENDING_PAYMENT | worker unavailable/conflict (409) → dialog "This worker is no longer available" with `confirm_find_another_btn` → **go `/workers`**; quote expired → re-quote, show "Price updated" banner, stay; validation → message; network/unknown → rule 3 + **refetch `/bookings?status=current` to detect created booking** → if found go to payment/detail, else show retry with SAME idempotency key |
| Back | `app_back_btn` | — | pop (if booking already created, back goes to `/bookings/:id` not here) | — | — |
Quote error → `SnErrorState` retry; quote shows `₹` via intl; no client-side totals.

## Screen 8.2 — Booking List (`/bookings`, tab)
Segmented: **Current** | **Past**. Cards: worker photo/name, service, status chip, next date, amount/payment chip.
| Element | Key | On tap | Result |
|---|---|---|---|
| Segment | `bookings_tab_current`, `bookings_tab_past` | switch list | independent paging |
| Booking card | `booking_card_<id>` | — | **push `/bookings/:id`** |
| Pull to refresh | — | refetch | — |
| Empty (current) | `bookings_empty_find_btn` | — | **push `/discover/category`** |
Pending-payment card shows `booking_card_pay_btn_<id>` "Complete payment" → **push `/payments/:paymentId`** (re-initiate if expired).

## Screen 8.3 — Booking Detail (`/bookings/:id`)
Header: status chip (+ plain-language line), worker card, service & schedule, location (area only unless customer's own address), payment summary + payment status chip, `SnTimeline` (backend events), action area.
Actions appear **only if** in `allowedActions`:
| Element | Key | `allowedActions` | On tap → | Result |
|---|---|---|---|---|
| Complete payment | `booking_pay_btn` | `pay` | **push `/payments/:paymentId`** | — |
| View active service | `booking_view_service_btn` | `view_service` | **push `/services/current?bookingId=`** | — |
| Rate worker | `booking_rate_btn` | `rate` | **push `/ratings/:bookingId`** | — |
| Request replacement | `booking_replace_btn` | `replace` | **push `/replacements/new?bookingId=`** | — |
| Cancel booking | `booking_cancel_btn` | `cancel` | **push cancel sheet** (8.4) | — |
| Receipt | `booking_receipt_btn` | `receipt` | **push `/transactions/:id`** | — |
| Get help | `booking_support_btn` | always | **push `/support/new?bookingId=`** | — |
| Worker card | `booking_worker_card` | always | **push `/workers/:id`** | — |
| Replaced-from link | `booking_previous_link` | if replacement | **push `/bookings/:previousId`** | history kept |
Pull-to-refresh and refetch on app resume + on push notification for this booking.

## Screen 8.4 — Cancel sheet (bottom sheet)
Reason list (backend) + notes + refund info text (backend).
| Element | Key | On tap | Result |
|---|---|---|---|
| Reason radio | `cancel_reason_<id>` | select | enables confirm |
| Confirm cancel | `cancel_confirm_btn` | `POST /bookings/{id}/cancel` | close sheet; refetch detail; snackbar "Cancellation requested" (only 2xx); failure → inline error stay |
| Keep booking | `cancel_dismiss_btn` | close | — |

## Test Cases
| ID | Type | Given → When → Then |
|---|---|---|
| BOOK-01 | W | Confirm screen shows quote rows exactly as returned; total not recomputed |
| BOOK-02 | W | Pay disabled while quote loading; enabled after |
| BOOK-03 | W | Tap Pay → repo.createBooking once; route `/payments/:id` |
| BOOK-04 | W | Double tap Pay → one call |
| BOOK-05 | U | Idempotency key stable on retry after network error, new key for a new screen instance |
| BOOK-06 | W | 409 worker unavailable → dialog; Find another → `/workers` |
| BOOK-07 | W | Network error then refetch finds booking → navigates forward, no error shown |
| BOOK-08 | W | Quote expired → banner "Price updated", new total shown |
| BOOK-09 | W | Back from payment returns to booking detail (not confirm) |
| BOOK-10 | W | Detail renders buttons strictly from `allowedActions` (table-driven test over all combos) |
| BOOK-11 | W | Timeline renders done/current/upcoming/failed + unknown event type |
| BOOK-12 | W | Cancel flow: reason required, confirm calls API once, detail refetched |
| BOOK-13 | W | Current/Past tabs page independently; empty state CTA works |
| BOOK-14 | W | Detail refetches on app resume |
| BOOK-15 | U | Status mapper handles unknown enum |
| BOOK-16 | I | **Flow E (to payment start)**: Interview → Confirm worker → Confirm & pay → Payment screen |
