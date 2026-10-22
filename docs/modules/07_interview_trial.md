# Module 07 — Interview / Trial

> **Deployed API (see DECISIONS):** the Swagger has no `/interviews`. An interview or trial is a booking state: request = `POST /bookings {workerId}` + `schedule`; done = `interview-complete` (needs `outcomeNote`); Not a fit = `reopen-matching`; cancel = `cancel {reason}`; slot length from `GET /search/workers/{id}/slots` (`slotMinutes`). Routes and keys below are unchanged.

**Backend:** `POST /interviews`, `GET /interviews`, `GET /interviews/{id}`, `POST /interviews/{id}/cancel`, `POST /interviews/{id}/decision`, slots from `GET /catalog/time-slots` or `/workers/{id}/slots` (TBD).
**Routes:** `/interviews/new`, `/interviews` (list, from Bookings tab segment or Home), `/interviews/:id`.
**Rules:** statuses are backend-owned; use `InterviewStatusMapper` with `unknown` fallback; action buttons appear only if present in `allowedActions[]`.

## Screen 7.1 — Request Interview/Trial (`/interviews/new?workerId=`)
Elements: worker mini-card, type selector (Interview | Trial — only if backend offers both), date picker, time slot chips, note (optional, max 300), "Submit request".
| Element | Key | Enabled when | On tap → Action | On success → | On failure |
|---|---|---|---|---|---|
| Type segment | `interview_type_<interview|trial>` | backend offers | select | — | — |
| Date | `interview_date_btn` | — | `showDatePicker` (today..+N days config) | — | past date blocked |
| Time slot chip | `interview_slot_<id>` | date chosen | select (one) | — | — |
| Note | `interview_note_field` | — | ≤300 chars | — | counter |
| Submit | `interview_submit_btn` | date+slot chosen, not loading | `POST /interviews {workerId, type, date, slot, note, requirementDraft}` + Idempotency-Key | **replace → `/interviews/:id`** (cannot return to form) ; snackbar "Request sent" only after 2xx | slot taken (409) → message "That slot is no longer available" + slots refreshed; worker unavailable → dialog with `interview_find_another_btn` → **go `/workers`**; network → rule 3 and **refetch `/interviews`** to see if created before showing error |
Back with chosen values → discard dialog.

## Screen 7.2 — Interview Detail (`/interviews/:id`)
Elements: status chip, worker card (tap → worker profile), date/time, type, requirement summary, timeline (requested → scheduled → completed…) from backend, action buttons.
| Element | Key | Visible when (`allowedActions`) | On tap → Action | Result |
|---|---|---|---|---|
| Worker card | `interview_worker_card` | always | — | **push `/workers/:id`** |
| Cancel request | `interview_cancel_btn` | `cancel` | confirm dialog `interview_cancel_confirm_btn` → `POST …/cancel {reason?}` | status refetched; snackbar "Request cancelled" |
| Reschedule | `interview_reschedule_btn` | `reschedule` | **push `/interviews/new`** in reschedule mode (prefilled) | on success replace to detail |
| **Confirm this worker** | `interview_confirm_worker_btn` | `confirm` (after outcome) | **push `/bookings/confirm?interviewId=`** (module 08) | — |
| Not a fit | `interview_reject_worker_btn` | `decline` | confirm → `POST …/decision {decision:'decline'}` | status refetch; CTA `interview_find_another_btn` → **go `/workers`** |
| Contact support | `interview_support_btn` | always | **push `/support/new?bookingOrInterviewId=`** | — |
| Pull to refresh | — | — | refetch | — |
Status copy examples: Requested "Waiting for the worker to respond"; Scheduled "Interview on {date}, {time}"; Completed "Decide whether to confirm this worker". Unknown → "Status updated" (neutral).

## Screen 7.3 — Interview List (`/interviews`)
Cards: worker, date, status chip. Tap → **push `/interviews/:id`**. Empty: "No interviews yet" + `interviews_empty_find_btn` → push `/discover/category`.

## Test Cases
| ID | Type | Given → When → Then |
|---|---|---|
| INT-01 | U | StatusMapper maps each known enum + unknown → neutral |
| INT-02 | W | Submit disabled until date+slot chosen |
| INT-03 | W | Submit success → route replaced with detail; back does not return to form |
| INT-04 | W | Double tap Submit → one request; same Idempotency-Key |
| INT-05 | W | 409 slot taken → message, slots reloaded, still on form |
| INT-06 | W | Network error on submit → app refetches list; if created → goes to detail instead of showing failure |
| INT-07 | W | Detail shows only actions in `allowedActions` |
| INT-08 | W | Cancel → dialog → repo.cancel once → status refetched |
| INT-09 | W | Confirm worker → `/bookings/confirm?interviewId=` |
| INT-10 | W | Decline → status updates → Find another → `/workers` |
| INT-11 | W | Past date impossible to pick |
| INT-12 | W | Unknown status renders without crash |
| INT-13 | I | **Flow D**: Worker → Request → Date/Time → Submit → Detail status |
