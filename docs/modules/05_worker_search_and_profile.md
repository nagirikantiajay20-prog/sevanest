# Module 05 — Worker Search Results, Filters & Worker Profile

> **Deployed API (see DECISIONS):** search is `GET /search/workers?category&areaId&engagement&page&limit` (page-numbered, `meta.total`), detail is `GET /search/workers/{id}`; worker cards are anonymous (no name), so the title is the category. Filters = availability window, language, minimum experience (no budget or star filter). Reviews: `/workers/:id/reviews` is mock-only until the backend serves it. The cursor wording below is the original assumption.

**Backend:** `POST /workers/search` (cursor), `GET /workers/{id}`, `GET /workers/{id}/reviews`, `PUT/DELETE /favourites/{id}` (module 06).
**Routes:** `/workers`, `/workers/:id`, `/workers/:id/reviews`.
**Rules:** never show fake workers; verified badge only from backend `verificationStatus`; no KYC data; handle null optional fields; cancel obsolete search requests.

## Screen 5.1 — Results (`/workers`)
Top bar: back, title "{Category} near {area}", requirement summary chip row (tap = edit), Filter button. List of worker cards (infinite scroll).
| Element | Key | On tap → Action | Navigates to / result |
|---|---|---|---|
| Back | `app_back_btn` | pop | Review step (draft intact) |
| Summary chips | `results_summary_chip` | — | **pop to `/discover/review`** (edit) |
| Filter | `results_filter_btn` | open filter bottom sheet | see 5.2 |
| Worker card | `worker_card_<id>` | — | **push `/workers/:id`** |
| Card favourite heart | `worker_card_fav_btn_<id>` | optimistic toggle → API (module 06) | heart toggles; rollback + snackbar on fail |
| Scroll to end | — | if `nextCursor` → load next page (footer loader) | append; end → no loader |
| Pull to refresh | — | reset cursor, re-search | list replaced |
| Footer error | `results_load_more_retry_btn` | retry next page | — |
States: loading (skeleton cards); **empty** → text "No matching workers found. Try changing your area, timing or engagement type." + criteria chips + `results_edit_requirement_btn` (**pop to `/discover/review`**) + `results_retry_btn` (re-search); error → `error_retry_btn`; stale (refresh failed, old list kept) → banner "Showing earlier results" + retry.
If a tapped worker is no longer available (404/410 on detail) → detail shows unavailable state; on back, card removed from list.

## Screen 5.2 — Filter bottom sheet
Filters limited to PRD criteria + backend-supported (availability, budget, language if provided).
| Element | Key | On tap | Result |
|---|---|---|---|
| Availability chips | `filter_availability_<id>` | toggle | — |
| Budget range slider/fields | `filter_budget_field` | edit | — |
| Apply | `filter_apply_btn` | close sheet, re-search with filters (original requirement kept) | results reloaded from page 1 |
| Reset | `filter_reset_btn` | clear filters | re-search on Apply |
| Close | `filter_close_btn` | discard unsaved filter edits | — |
Filter button shows count badge when active.

## Screen 5.3 — Worker Profile (`/workers/:id`)
Sections: photo, name, verification badge, rating (n reviews / "New"), experience, skills, languages, area, availability, about, "How verification works" link, reviews preview. Sticky bottom bar.
| Element | Key | On tap → Action | Result |
|---|---|---|---|
| Back | `app_back_btn` | pop | — |
| Favourite (top-right) | `worker_detail_fav_btn` | optimistic toggle (module 06) | rollback on fail |
| Share | *not V1* | — | — |
| Verification badge / "What does verified mean?" | `worker_verified_info_btn` | open bottom sheet with backend/CMS copy (copy TBD) | sheet `worker_verified_sheet_close_btn` closes |
| See all reviews | `worker_reviews_all_btn` | **push `/workers/:id/reviews`** (paginated) | — |
| Report / Block (⋮ menu) | `worker_menu_report_btn` | **push report sheet** (module 12) | — |
| **Request Interview / Trial** | `worker_request_interview_btn` | require active requirement draft (else prompt "Start a search first" → `/discover/category`) | **push `/interviews/new?workerId=…`** (module 07) |
| Pending badge state | — | if worker not verified → badge reads "Verification in progress"; CTA still allowed only if backend flag `canRequestInterview=true`; otherwise button disabled with reason text |
Unavailable worker (404/410/`unavailable`) → state "This worker is no longer available" + `worker_find_another_btn` → **pop to `/workers`** (list refetched).

## Screen 5.4 — Reviews (`/workers/:id/reviews`)
Paginated list (reviewer first name only, rating, text, date). Empty "No reviews yet". Back pops.

## Test Cases
| ID | Type | Given → When → Then |
|---|---|---|
| SRCH-01 | U | Worker DTO parses with every optional field null; mapper gives safe defaults |
| SRCH-02 | W | Card: long name ellipsis, missing photo → initials, no rating → "New", no overflow at 200% text |
| SRCH-03 | W | Verified badge shown only when status==verified; pending shows "Verification in progress" |
| SRCH-04 | W | First page loads; scroll to end triggers next page once; end of data hides loader |
| SRCH-05 | W | Footer error → retry button loads same cursor |
| SRCH-06 | U | Pagination uses backend cursor, not page numbers |
| SRCH-07 | W | Empty result → message, criteria chips, Edit → `/discover/review`, Retry re-calls search |
| SRCH-08 | W | Apply filter → repo called with original requirement + filters, list reset |
| SRCH-09 | W | Reset filter clears badge count |
| SRCH-10 | U | Re-search cancels previous in-flight request (CancelToken) |
| SRCH-11 | W | Tap card → `/workers/:id` with correct id |
| SRCH-12 | W | Detail: no Aadhaar/KYC fields rendered even if present in raw JSON (DTO excludes) |
| SRCH-13 | W | Request interview with no draft → prompt; with draft → `/interviews/new` |
| SRCH-14 | W | Worker 404/410 → unavailable state; Find another → back to list |
| SRCH-15 | W | Pull-to-refresh shows new list; failed refresh keeps stale + banner |
| SRCH-16 | I | **Flow B (second half)**: Results → Worker Profile |
