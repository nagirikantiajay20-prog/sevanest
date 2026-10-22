# Module 06 — Favourites / Shortlist

> **Deployed API (see DECISIONS):** shortlist is `GET /shortlist` (paged), `PUT/DELETE /shortlist/{workerId}`, not `/favourites`. One `favouriteProvider` holds every heart.

**Backend:** `GET /favourites`, `PUT /favourites/{workerId}`, `DELETE /favourites/{workerId}`.
**Route:** `/favourites` (bottom-nav tab). Heart control also appears on worker card (05) and worker detail (05).

## Heart toggle behaviour (shared component `FavouriteButton`)
| Step | Behaviour |
|---|---|
| Tap (`…fav_btn_<id>`) | Flip icon immediately (optimistic), disable further taps until response |
| Success | Keep state; invalidate: favourites list, that worker's detail; update flag in results list item |
| Failure | **Rollback** icon; snackbar "Couldn't update shortlist. Try again."; re-enable |
| 401 | login redirect (global) |
Must be idempotent: PUT twice is safe.

## Screen 6.1 — Shortlist (`/favourites`)
List of worker cards (same card widget; heart filled).
| Element | Key | On tap | Result |
|---|---|---|---|
| Worker card | `worker_card_<id>` | — | **push `/workers/:id`** |
| Heart | `worker_card_fav_btn_<id>` | remove (optimistic) | card animates out; snackbar "Removed" with `fav_undo_btn` (re-PUT) |
| Undo | `fav_undo_btn` | `PUT /favourites/{id}` | card returns |
| "Find a worker" (empty state) | `favs_empty_find_btn` | — | **push `/discover/category`** |
| Pull to refresh | — | refetch | — |
States: loading skeleton; empty "Your shortlist is empty. Tap the heart on a worker to save them."; error retry; paginated if backend paginates. Unavailable workers remain with "Unavailable" tag (no actions except remove).

## Test Cases
| ID | Type | Given → When → Then |
|---|---|---|
| FAV-01 | W | Tap heart on card → icon filled immediately; repo.add called once |
| FAV-02 | W | Repo throws → icon rolls back, snackbar shown, tap re-enabled |
| FAV-03 | W | Rapid double tap → one request |
| FAV-04 | W | After add, Favourites tab (refetched) lists worker |
| FAV-05 | W | Remove from Favourites → card disappears; Undo restores and calls PUT |
| FAV-06 | W | Detail heart state matches list heart state after toggling elsewhere (invalidation) |
| FAV-07 | W | Empty state CTA → `/discover/category` |
| FAV-08 | W | Unavailable worker shows tag, tap opens unavailable detail |
| FAV-09 | I | **Flow C**: Worker Profile → Favourite → Favourites shows worker → Unfavourite → gone |
