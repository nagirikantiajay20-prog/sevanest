# Module 04 — Service Discovery (Requirement Builder)

**Goal:** collect a service requirement in 7 short steps, preserving values on back, then search.
**State:** `requirementDraftProvider` (in-memory; created on entry, disposed on exit/search-complete-reset). Fields: `categoryId, engagement, addressId, timing, startDate, budgetMin, budgetMax`.
**Backend:** `GET /catalog/categories` (incl. `engagementTypes[]`, `requiresBudget`), `GET /catalog/time-slots`, addresses (module 02). Search call is in module 05.
**Shared chrome on every step:** back arrow `app_back_btn`, close (X) `discover_close_btn`, progress bar "Step n of N" (N=7, or 6 if budget not required), sticky bottom button `discover_next_btn`.

**Global behaviours**
- Back arrow → previous step (values kept). On step 1 back → exits flow (discard dialog only if any value set).
- Close X → dialog "Discard this request?" [`discover_discard_confirm_btn` → clear draft, **pop to Home**] [`discover_discard_cancel_btn` → stay].
- Next is disabled until the step is valid.
- Steps skipped when preset (e.g., category from Home tile): progress shows them as done; back from step 2 goes to step 1.

## Step 1 — Category (`/discover/category`)
Grid of categories (server-driven; icon + name). Loading skeleton grid; error → retry; empty → "No services available right now".
| Element | Key | On tap | Result |
|---|---|---|---|
| Category tile | `discover_category_tile_<id>` | select (highlight); selecting a different category **clears** engagement & budget | enables Next |
| Next | `discover_next_btn` | — | **push `/discover/engagement`** |

## Step 2 — Engagement (`/discover/engagement`)
Radio cards from `category.engagementTypes` only (Full-time, Part-time, Daily, Hourly, Live-in as allowed). Never show unsupported combos.
| Element | Key | On tap | Result |
|---|---|---|---|
| Engagement card | `discover_engagement_<type>` | select | enables Next |
| Next | `discover_next_btn` | — | **push `/discover/location`** |
Only one allowed type → preselect.

## Step 3 — Location (`/discover/location`)
Shows saved addresses (radio list), default preselected; buttons below.
| Element | Key | On tap | Result |
|---|---|---|---|
| Address row | `discover_address_<id>` | select | enables Next |
| Add new address | `discover_add_address_btn` | **push `/addresses/new`**; on return with new address it is auto-selected | — |
| Use current location | `discover_use_location_btn` | permission → reverse geocode → opens prefilled `/addresses/new` to confirm/save | denied → snackbar manual message |
| Next | `discover_next_btn` | validate area is serviceable (backend flag on address) | **push `/discover/timing`**; unserviceable → inline "We don't serve this area yet", Next disabled |
No addresses → empty state with `discover_empty_add_address_btn` → push `/addresses/new`.

## Step 4 — Timing (`/discover/timing`)
Slot chips from backend `time-slots` (multi-select if engagement allows, else single) OR start/end time pickers per backend config. **No recurrence model beyond what backend provides.**
| Element | Key | On tap | Result |
|---|---|---|---|
| Time slot chip | `discover_slot_<id>` | toggle | enables Next when ≥1 |
| Custom start / end | `discover_time_start_btn`, `discover_time_end_btn` | `showTimePicker` | validate end > start |
| Next | `discover_next_btn` | — | **push `/discover/start-date`** |

## Step 5 — Start date (`/discover/start-date`)
Calendar; `firstDate=today(+minLeadDays from backend)`, `lastDate` per backend or +90 days (config const).
| Element | Key | On tap | Result |
|---|---|---|---|
| Date cell | `discover_date_<yyyymmdd>` | select | enables Next |
| Next | `discover_next_btn` | — | if `requiresBudget` → **push `/discover/budget`** else **push `/discover/review`** |

## Step 6 — Budget (`/discover/budget`) *(only if required)*
| Element | Key | Rules | Result |
|---|---|---|---|
| Min ₹ field | `discover_budget_min_field` | numeric ≥ backend min | — |
| Max ₹ field | `discover_budget_max_field` | ≥ min, ≤ backend max | error "Max must be at least min" |
| Next | `discover_next_btn` | valid | **push `/discover/review`** |

## Step 7 — Review (`/discover/review`)
Summary card with rows: Service, Engagement, Address, Timing, Start date, Budget. Each row has Edit.
| Element | Key | On tap | Result |
|---|---|---|---|
| Edit row | `discover_review_edit_<field>` | **pop back to that step** (later values preserved) | — |
| Search | `discover_search_btn` | validate full draft → build search request | **push `/workers`** (module 05) carrying the draft; back from Results returns to this Review screen with the draft intact |
Results' "Edit requirement" and summary chips pop back to Review.

## Test Cases
| ID | Type | Given → When → Then |
|---|---|---|
| DISC-01 | W | Category screen loading → skeleton; error → retry refetches; empty → message |
| DISC-02 | W | Next disabled until category chosen; tap → `/discover/engagement` |
| DISC-03 | W | Changing category clears engagement & budget in draft |
| DISC-04 | W | Engagement shows only types provided by selected category |
| DISC-05 | W | Single engagement type is preselected |
| DISC-06 | W | Back from step N preserves values entered in step N and N-1 |
| DISC-07 | W | Close X → dialog; confirm clears draft and lands on Home; cancel stays |
| DISC-08 | W | Location: default address preselected; add new → returns & auto-selected |
| DISC-09 | W | Unserviceable area → inline message; Next disabled |
| DISC-10 | W | Location permission denied → manual message, flow continues |
| DISC-11 | U | Date rules: past date rejected; min lead days respected |
| DISC-12 | U | Budget validation: min>max rejected; non-numeric rejected |
| DISC-13 | W | requiresBudget=false → budget step skipped; progress "Step n of 6" |
| DISC-14 | W | Review Edit on Address → pops to step 3; Next returns without losing other fields |
| DISC-15 | W | Review Search tap → search repo called with exact draft; route `/workers` |
| DISC-16 | W | Double tap Search → one request |
| DISC-17 | I | **Flow B (first half)**: Home → … → Review → Search → Results |
