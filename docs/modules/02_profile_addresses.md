# Module 02 — Profile & Addresses

**Goal:** complete customer profile after first login; manage saved addresses.
**Backend (verified against the deployed Swagger, 2026-10-12; supersedes the provisional paths in docs/05):** `GET/POST/PATCH /customers/me`, `GET/POST /customers/me/addresses`, `GET/PATCH/DELETE /customers/me/addresses/{id}`, `PUT /customers/me/addresses/{id}/default`, `GET /service-areas?city=`.
**Routes:** `/profile/setup`, `/profile`, `/addresses`, `/addresses/new`, `/addresses/:id/edit`.

## Screen 2.1 — Profile Setup (`/profile/setup`) — shown once after first login
Elements: title "Tell us about you", Name, Email (optional — TBD), Preferred language dropdown (options from backend/l10n list; V1 default English), mobile (read-only chip), "Continue" button.
| Element | Key | Enabled when | On tap → Action | On success → | On failure |
|---|---|---|---|---|---|
| Name | `profile_name_field` | always | required, 2–60 chars, letters/space | — | "Enter your name" |
| Email | `profile_email_field` | always | if filled must be valid email | — | "Enter a valid email" |
| Language | `profile_language_dropdown` | always | select | — | — |
| Continue | `profile_continue_btn` | name valid & not loading | `PUT /me/profile` | **go `/addresses/new?firstTime=true`** (prompt to add first address; has Skip) | fieldErrors under fields; network → rule 3 |
Back/system back: **disabled** (user cannot skip profile). Android back exits app.

## Screen 2.2 — Add/Edit Address (`/addresses/new`, `/addresses/:id/edit`)
Elements: label chips (Home/Work/Other), Address line 1, line 2, Area (picker from service areas or free text — backend decides), City (prefilled Hyderabad), State, Pincode, "Use current location" link, "Set as default" switch, Save button, (edit mode) Delete button, (firstTime) Skip.
| Element | Key | Enabled when | On tap → Action | On success → | On failure |
|---|---|---|---|---|---|
| Label chips | `address_label_chip_<home|work|other>` | always | select one | — | — |
| Line1 | `address_line1_field` | — | required | — | "Required" |
| Area | `address_area_field` | — | required; picker opens bottom sheet list | — | — |
| Pincode | `address_pincode_field` | — | 6 digits | — | "Enter 6-digit pincode" |
| Use current location | `address_use_location_btn` | always | request location permission **now** (first time) → `LocationService.current()` → reverse-geocode → prefill fields | fields filled | permission denied → snackbar "You can enter the address manually", stay; GPS off → same |
| Default switch | `address_default_switch` | — | toggle | — | — |
| Save | `address_save_btn` | form valid & not loading | `POST` (new) or `PUT` (edit) | firstTime → **go `/home`**; else **pop** to `/addresses` (list refreshed) | fieldErrors; service area unsupported → inline message "We don't serve this area yet" (backend code) stay |
| Skip (firstTime only) | `address_skip_btn` | — | — | **go `/home`** | — |
| Delete (edit only) | `address_delete_btn` | not the only default w/o other address | confirm dialog `address_delete_confirm_btn` → `DELETE` | pop to list | 409 (used by active booking) → dialog "This address is used by an active booking." stay |
Back with edits → discard dialog (rule 2).

## Screen 2.3 — Address List (`/addresses`)
Elements: list of address cards (label, full line, "Default" tag), "+ Add address" FAB, card overflow menu.
| Element | Key | On tap → Action | Result |
|---|---|---|---|
| Add address | `addresses_add_btn` | **push `/addresses/new`** | list refetched on return |
| Address card | `address_card_<id>` | if opened from discovery (`select=true`) → return selected address (**pop with result**); else **push `/addresses/:id/edit`** | — |
| Card menu → Set default | `address_set_default_<id>` | `POST …/default` | list refresh; snackbar "Default address updated" |
| Card menu → Edit | `address_edit_<id>` | push edit | — |
| Card menu → Delete | `address_menu_delete_<id>` | confirm → `DELETE` | list refresh; 409 dialog |
Empty: illustration + "Add your first address" CTA `addresses_empty_add_btn` → push `/addresses/new`.

## Screen 2.4 — Profile (`/profile`) from Account
Elements: name, email, mobile (read-only, lock icon), language, verification status chip (read-only), "Edit" → inline edit mode, "Save".
| Element | Key | On tap | Result |
|---|---|---|---|
| Edit | `profile_edit_btn` | switch fields editable (mobile stays locked) | — |
| Save | `profile_save_btn` | `PUT /me/profile` | success → snackbar "Profile updated", read mode; failure → field errors |
| Cancel | `profile_cancel_btn` | revert, read mode (discard dialog if changed) | — |

## Test Cases
| ID | Type | Given → When → Then |
|---|---|---|
| PROF-01 | U | name/email/pincode validators |
| PROF-02 | W | Setup: Continue disabled until name valid |
| PROF-03 | W | Continue success → route `/addresses/new?firstTime=true`; system back does nothing |
| PROF-04 | W | Backend fieldErrors on email → shown under email field |
| PROF-05 | W | Mobile field is read-only everywhere |
| ADDR-01 | W | Save success firstTime → `/home`; non-first → pops to list showing new item |
| ADDR-02 | W | Skip → `/home` |
| ADDR-03 | W | Use current location: permission denied → manual-entry message, no crash, fields editable |
| ADDR-04 | W | Unsupported area error → inline message, Save re-enabled |
| ADDR-05 | W | Delete → confirm dialog → repo.delete called once → list refresh; 409 → dialog |
| ADDR-06 | W | Set default moves "Default" tag |
| ADDR-07 | W | `select=true` tap returns address to caller |
| ADDR-08 | W | Empty list shows CTA; loading skeleton; error retry |
| ADDR-09 | W | Edit form with unsaved changes → back shows discard dialog |
| ADDR-10 | U | Address DTO parse with null optional fields (lat/lng, line2) |
| ADDR-11 | M | Location permission flow on Android & iOS (denied, denied-forever, granted) |


## Implementation status & backend mapping (2026-10-12)

Built from the approved screens (`SevaNest_screens` 04 Profile setup, 08 Location > address sheet) + this spec.

| Spec element | Status | Notes |
|---|---|---|
| 2.1 Profile setup | DONE | `POST /customers/me {name,email,preferredLanguage}`. Email is **required** by the backend (spec/design say optional) - the field is validated as required. Language shown as design chips; only `en` selectable (`/app-config` languages). Photo (design) NOT built: no customer-photo endpoint exists (only `/workers/me/photo`). |
| 2.2 Address form | DONE except GPS | Fields = backend `line, area, city, pincode, isDefault`. House/flat + building/street are joined into `line` (", ") and split on the first ", " when editing. No **label chips, line 2 or state** (backend has none). Area = picker over `GET /service-areas?city=Hyderabad`, free text if that call fails. "Use current location" + map pin NOT built: no location/geocoding dependency approved (OPEN_QUESTIONS #15); lat/lng are never sent (optional in the API). |
| 2.3 Address list | DONE | Default first (backend order), Set default = `PUT .../default`, delete = `DELETE` (soft), `select=true` returns the address. Card title = area (no label field). |
| 2.4 Profile | DONE | `GET` + `PATCH /customers/me`. Mobile shown read-only only if the profile body contains `mobile`; verification chip only if it contains `verificationStatus` (response schema unpublished - UNVERIFIED). |
| Default switch on edit | Turning ON = `PATCH` then `PUT .../default`. Turning OFF is impossible (API has no unset); the switch is disabled for the current default. |
| Error codes | Not observed live: the "unsupported area" code, the 409 body for addresses used by a booking. Both are handled generically (field error under the field / `ConflictFailure` dialog). |
