# Module 13 — Notifications (Push, Centre, Deep Links)

> **Built on the real contract (docs/backend_openapi_2026-10-13.json), which overrides the routes assumed below.**
> Backend: `GET /notifications` (`unreadOnly`, paged; item `{id, event, title, body, route:{type,id}, readAt, createdAt}`), `POST /notifications/{id}/read`, `POST /notifications/read-all`, `GET /notifications/unread-count`, `PUT /auth/device-token {token, platform: ANDROID|IOS}` (binds the token to the session; `DELETE /auth/device-token` unbinds the current session only; logout calls it, then deletes the token on the device).
> Deep links: ONE mapper (`routeForNotification` / `routeForPushData`); entities open through `/open?to=<route>`, which reads the entity fresh. Push is behind `PushService` (Firebase when configured, no-op otherwise). Not built, no backend support: settings sheet, per-row mark-unread / delete. See BACKEND_REQUESTS 51-54.

**Original draft backend (assumed, superseded):** `POST /devices {fcmToken, platform}`, `DELETE /devices/{token}`, `GET /notifications`, `POST /notifications/{id}/read`, `POST /notifications/read-all`, `GET /notifications/unread-count`.
**Routes:** `/notifications`, `/open?to=`.
**Payload contract (assumed, unconfirmed):** `{ type, entityId, notificationId, title, body }` or `route:{type,id}`. Payload is a *hint* — always fetch fresh entity (AGENTS §50).

## Push lifecycle (no buttons, but must be implemented)
| Event | Behaviour |
|---|---|
| Permission | Ask **after first meaningful action** (e.g., after first interview request) via pre-prompt screen: `notif_prompt_allow_btn` (→ OS dialog) / `notif_prompt_later_btn` (dismiss, ask again after N days/config). Never at launch. iOS: provisional not used. Denied → app works; Account shows "Notifications off" with `notif_open_settings_btn` → app settings. |
| Token | After login & permission: register `POST /devices`. On `onTokenRefresh` → re-register. On logout → unregister. |
| Foreground message | Show local notification/in-app banner (`notif_banner_<id>`) with tap action; refresh unread count + the entity if screen open. |
| Background/terminated tap | `onMessageOpenedApp` / `getInitialMessage` → deep link routing below. |
| Background handler | top-level function, `@pragma('vm:entry-point')`, initialises Firebase, no UI work. |

## Deep-link routing table (type → route; always refetch entity)
| `type` | Route | Notes |
|---|---|---|
| `interview_update` | `/interviews/:entityId` | |
| `booking_update` | `/bookings/:entityId` | |
| `payment_update` | `/payments/:entityId` if non-terminal else `/transactions/:entityId` | |
| `replacement_update` | `/replacements/:entityId` | |
| `ticket_update` | `/support/:entityId` | |
| unknown / missing id | `/notifications` | never crash |
Auth gate: if logged out → login first, then continue to target (stash target in memory). Validate `entityId` format; if API returns 404/403 → "This item isn't available" screen with `Go to Home` button. Back from a deep-linked screen goes to Home (not exit) when stack was empty.

## Screen 13.1 — Notification Centre (`/notifications`)
Paginated list: icon by type, title, body, time, unread dot.
| Element | Key | On tap → Action | Result |
|---|---|---|---|
| Back | `app_back_btn` | pop | — |
| Notification row | `notification_row_<id>` | mark read (`POST …/read`, optimistic; rollback silently on fail) | **push** target per routing table |
| Mark all read | `notif_mark_all_btn` | `POST /notifications/read-all` | dots cleared, bell badge 0 |
| Pull to refresh | — | refetch | — |
Empty: "You're all caught up". Error retry. Bell badge on Home updates from unread-count (refetch on resume & push).

## Test Cases
| ID | Type | Given → When → Then |
|---|---|---|
| NOT-01 | U | payload→route table for each type, unknown type, missing id |
| NOT-02 | W | Tap row → marked read, navigates to correct route with id |
| NOT-03 | W | Mark all read → dots cleared, badge 0, API once |
| NOT-04 | W | Empty and error states |
| NOT-05 | U | Token registration on login, on refresh; unregistration on logout |
| NOT-06 | W | Permission pre-prompt: Allow → OS request called; Later → no request, re-ask rule honored |
| NOT-07 | W | Denied permission → Account shows off state; app functions |
| NOT-08 | U | Deep link when logged out → login → then target |
| NOT-09 | W | Deep link target 404 → unavailable screen with Home button |
| NOT-10 | W | Entity screen refetches latest state after deep link (not payload data) |
| NOT-11 | M | Real device: foreground banner, background tap, terminated tap (Android + iOS), booking id opens correct booking |
