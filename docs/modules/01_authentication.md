# Module 01 — Authentication (Splash, Login, OTP, Logout)

**Goal:** customer signs in with mobile OTP; session persists securely; expired sessions route to login.
**Depends on:** core network, secure session store, router. **Backend:** `POST /auth/otp/request`, `/auth/otp/verify`, `/auth/refresh`, `/auth/logout`, `GET /me`.
**Routes:** `/splash`, `/login`, `/otp`.

## Screen 1.1 — Splash (`/splash`)
No buttons. Automatic flow:
| Step | Action | Result |
|---|---|---|
| 1 | Init config, Firebase, read secure session | — |
| 2 | No tokens | `go('/login')` |
| 3 | Tokens exist → `GET /me` (refresh once on 401) | 200 & `profileComplete=true` → `go('/home')`; 200 & false → `go('/profile/setup')`; auth failure → clear session, `go('/login')` |
| 4 | Network error/timeout (>8 s config const) | Show `SnErrorState` with `Key('splash_retry_btn')` "Retry" → repeat step 3. Also show `Key('splash_login_btn')` "Sign in again" → clear session `go('/login')` |
Never leave user on a blank splash.

## Screen 1.2 — Login (`/login`)
Elements: logo, title "Verified Help. Trusted Homes.", mobile field with fixed "+91" prefix, "Get OTP" button, terms/privacy links.
| Element | Key | Enabled when | On tap → Action | On success → | On failure |
|---|---|---|---|---|---|
| Mobile field | `login_mobile_field` | always | digits only, max 10; inline validate `^[6-9]\d{9}$` on change after first blur | — | error text "Enter a valid 10-digit mobile number" |
| Get OTP | `login_get_otp_btn` | valid number & not loading | `POST /auth/otp/request {mobile}` | **push `/otp`** passing `mobile`, `otpLength`, `resendAfterSeconds` | 429 → snackbar backend message, stay; network → rule 3; 400 → field error |
| Terms link | `login_terms_link` | always | open Terms URL (in-app browser/`url_launcher`) | external | snackbar if cannot open |
| Privacy link | `login_privacy_link` | always | open Privacy URL | external | same |
Keyboard: "Done" on keyboard triggers Get OTP if enabled.

## Screen 1.3 — OTP (`/otp`)
Elements: back arrow, title "Verify your number", subtitle "Code sent to +91 XXXXX 12345" (masked), OTP input (N boxes), "Verify" button, resend countdown / "Resend OTP", "Change number".
| Element | Key | Enabled when | On tap → Action | On success → | On failure |
|---|---|---|---|---|---|
| OTP input | `otp_input_field` | always | autofill (`oneTimeCode`); when N digits entered auto-submit **or** enable Verify (pick auto-submit = false for V1 → enable button) | — | — |
| Verify | `otp_verify_btn` | N digits & not loading | `POST /auth/otp/verify {mobile,otp}` → save tokens in secure store → `GET /me` | profileComplete → **go `/home`**; else **go `/profile/setup`** (stack cleared; back cannot return to OTP) | invalid OTP → inline "Incorrect code. Try again." clear field, stay; expired → "Code expired. Request a new one." show Resend enabled; too many attempts → message from backend + disable Verify; network → rule 3 (keep OTP typed) |
| Resend | `otp_resend_btn` | countdown == 0 | `POST /auth/otp/request` | restart countdown, snackbar "OTP sent again" | 429 snackbar; stay |
| Countdown text | `otp_countdown_text` | — | shows "Resend in 00:xx" | — | — |
| Change number | `otp_change_number_btn` | always | pop to `/login` (field keeps number) | — | — |
| Back arrow | `app_back_btn` | always | same as Change number | — | — |

## Logout (triggered from Account — module 14, logic here)
`logout()` use case: `POST /auth/logout` (ignore failure) → `DELETE /devices` (FCM) best-effort → clear secure store → invalidate all providers → **go `/login`**.

## State machine (OTP notifier)
`idle → requesting → sent → verifying → (success | invalidOtp | expired | locked | networkError) → sent` (retry). Test every transition.

## Test Cases
| ID | Type | Given → When → Then |
|---|---|---|
| AUTH-01 | U | validator: `9876543210` ok; `1234567890`, `98765`, `abc` rejected |
| AUTH-02 | W | Login: Get OTP disabled on empty/invalid; enabled on valid |
| AUTH-03 | W | Tap `login_get_otp_btn` with fake repo success → router at `/otp` with mobile |
| AUTH-04 | W | Tap Get OTP, repo throws 429 → snackbar shown, still on `/login`, button re-enabled |
| AUTH-05 | W | Tap Get OTP twice rapidly → repo called once |
| AUTH-06 | W | OTP wrong → inline error, field cleared, still on `/otp` |
| AUTH-07 | W | OTP expired → Resend becomes enabled and message shown |
| AUTH-08 | U | resend countdown uses fake async; at 0 resend enabled; after resend restarts |
| AUTH-09 | W | Verify success + profileComplete=false → route `/profile/setup`; back press does NOT return to `/otp` |
| AUTH-10 | W | Verify success + profileComplete=true → `/home` |
| AUTH-11 | U | tokens saved only via SecureSessionStore (not shared_preferences) |
| AUTH-12 | W | Splash: no session → `/login`; valid session → `/home`; 401 w/ refresh fail → `/login`; timeout → retry button visible |
| AUTH-13 | U | 401 interceptor: 3 parallel requests trigger exactly 1 refresh |
| AUTH-14 | U | logout clears store and calls device-unregister even if `/auth/logout` fails |
| AUTH-15 | U | OTP and token never appear in log output (redaction test) |
| AUTH-16 | M | SMS autofill works on Android & iOS; airplane mode during verify keeps typed OTP |
| AUTH-17 | I | **Flow A**: launch → login → OTP → profile setup |
