# Module 14 — Account & Settings

**Route:** `/account` (tab). Sub-routes link to other modules. No new backend except logout (module 01) and optional app-config/legal links.

## Screen 14.1 — Account (`/account`)
Header: avatar initials, name, mobile (masked partially), verification status chip (read-only).
| Element | Key | On tap → Action | Navigates to |
|---|---|---|---|
| Profile header / Edit | `account_profile_btn` | — | **push `/profile`** (module 02) |
| My addresses | `account_addresses_btn` | — | **push `/addresses`** |
| Shortlist | `account_favourites_btn` | — | switch to Favourites tab |
| My bookings | `account_bookings_btn` | — | switch to Bookings tab |
| Interviews & trials | `account_interviews_btn` | — | **push `/interviews`** |
| Service history | `account_history_btn` | — | **push `/services/history`** |
| Transactions & receipts | `account_transactions_btn` | — | **push `/transactions`** |
| Support | `account_support_btn` | — | **push `/support`** |
| Notifications | `account_notifications_btn` | — | **push `/notifications`** |
| Notification permission row | `notif_open_settings_btn` | visible if OS-denied | open OS app settings |
| Language | `account_language_btn` | visible only if >1 language enabled (V1 English only → hidden) | language sheet |
| Terms of Service | `account_terms_btn` | open URL (legal TBD) | in-app browser |
| Privacy Policy | `account_privacy_btn` | open URL | in-app browser |
| About / version | `account_about_btn` | show app version/build (from package info) | bottom sheet |
| **Log out** | `account_logout_btn` | confirm dialog "Log out of SevaNest?" → `account_logout_confirm_btn` | runs logout use case (module 01) → **go `/login`**; `account_logout_cancel_btn` closes |
| Delete account | *hidden until legal/retention policy defined (OPEN_QUESTIONS #18)* | — | — |
Logout failure of server call is ignored; local session always cleared.

## Test Cases
| ID | Type | Given → When → Then |
|---|---|---|
| ACC-01 | W | Each row tap pushes the exact route listed (parameterised test over the table) |
| ACC-02 | W | Language row hidden when only English enabled |
| ACC-03 | W | Logout: confirm → session cleared → `/login`; cancel → stays |
| ACC-04 | W | After logout, back press cannot return to account/home |
| ACC-05 | W | Mobile shown masked; verification chip read-only |
| ACC-06 | W | Notification-off row appears only when OS permission denied |
| ACC-07 | U | After logout all providers reset (no previous user's data visible after new login) |
| ACC-08 | M | Legal links open on both platforms |
