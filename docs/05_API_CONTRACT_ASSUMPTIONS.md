# 05 — Provisional API Contract (ASSUMPTIONS — REPLACE WITH REAL CONTRACT)

> **Status: PROVISIONAL.** No backend contract exists yet. Everything here is a *proposal to unblock the mock repositories* (AGENTS §78). When the backend publishes OpenAPI/Swagger, **replace this file**, update DTOs, and record diffs in `docs/DECISIONS.md`. Never ship against these paths without confirmation.
> Base: `{apiBaseUrl}` (= `{host}/api/v1`), JSON, `Authorization: Bearer <access>`. Errors: `{ "code": "STRING", "message": "...", "fieldErrors": {"field":"msg"} }`. Pagination: `?cursor=&limit=` → `{ "items":[], "nextCursor": null|"..." }`. Mutations accept `Idempotency-Key`.

## VERIFIED AUTH CONTRACT (supersedes the provisional auth rows below)

Source: deployed backend `https://sevanest-backend.onrender.com` - Swagger at `/docs` (spec embedded in `/docs/swagger-ui-init.js`; there is no `/openapi.json`) **plus controlled live calls** (2026-10-12) with the backend's provisioned test customer account. Base URL: `{host}/api/v1`. Swagger documents request bodies and status codes but **no success-response schemas**; response shapes below were observed live.

| Call | Request | Observed result |
|---|---|---|
| `POST /auth/otp/request` | `{mobile, appType:"CUSTOMER"}` - mobile = 10 digits (`+91`/`91`/`0` accepted) | 200 `{expiresInSeconds:300, resendAfterSeconds:30}`. 400 `VALIDATION_FAILED` with `details:[{field,messages[]}]`. 409 `ACCOUNT_TYPE_MISMATCH` (number registered as a worker). 503 `SMS_NOT_CONFIGURED` for ordinary numbers while DLT/SMS is not set up. Swagger: 429 carries `details[0].retryAfterSeconds`. |
| `POST /auth/otp/verify` | `{mobile, appType, otp, deviceId(UUID v4), deviceName?}` | 200 `{accessToken, refreshToken, tokenType:"Bearer", expiresIn:900, user:{id,type,isNewUser}}`. 400 `OTP_INVALID` ("N attempt(s) remaining", 5 per code), 400 `OTP_EXPIRED` (also when no OTP was requested). `deviceId` must be UUID-shaped (`"probe"` -> 400). |
| `POST /auth/token/refresh` | `{refreshToken}` (min length 20) | 200 same shape as verify; the refresh token is **single-use and rotated**. Re-using an old one -> 401 `REFRESH_TOKEN_INVALID` and the session is revoked. |
| `POST /auth/logout` | bearer | 204; the token is inactive afterwards (401 `UNAUTHENTICATED` "Session is not active"). |
| `GET /customers/me` | bearer | 200 = profile exists; 404 `CUSTOMER_PROFILE_NOT_FOUND` for a new user -> the app treats it as "profile incomplete". Profile creation needs `name,email,preferredLanguage` (module 02). |
| `GET /users/me` | bearer | 200 identity (`id,type,status,mobile,email,roles,permissions`). Not used by the app yet. |
| `GET /app-config` | none | `{customer:{minVersion},worker:{minVersion},maintenance,support:{phone,email},legal:{acceptanceRequired,terms,privacy},languages:["en"]}` - `support` feeds "Contact support". |
| Errors | all | `{code, message, details?, requestId}`. 401 `UNAUTHENTICATED`. |
| Rate limiting | all | Every response carries `x-ratelimit-limit: 120`, `x-ratelimit-remaining`, `x-ratelimit-reset: 60` (global, per minute). OTP endpoints are additionally rate-limited per mobile and per IP (Swagger text). The 429 body / `Retry-After` and the OTP lock-out error code were **not** triggered live (that would burn the shared test account), so they are covered by mocked tests only. |

Not available / not supported by the backend: password login for customers (`/auth/admin/login` is for admins only) and `otpLength` in any response (the app uses 6, as in the approved design).

---

| Area | Method & path | Notes |
|---|---|---|
| Auth (old, superseded by the verified contract above) | `POST /auth/otp/request {mobile}` -> `{otpLength,resendAfterSeconds}` | superseded |
| | `POST /auth/otp/verify {mobile,otp}` → `{accessToken,refreshToken,isNewUser}` | |
| | `POST /auth/refresh`, `POST /auth/logout` | |
| Profile | `GET /me` → profile + `profileComplete` + verification status | |
| | `PUT /me/profile {name,email,preferredLanguage}` | mobile immutable |
| Addresses | `GET/POST /me/addresses`, `PUT/DELETE /me/addresses/{id}`, `POST /me/addresses/{id}/default` | |
| Config | `GET /catalog/categories` → `[{id,name,iconUrl,engagementTypes[],requiresBudget}]` | server-driven |
| | `GET /catalog/service-areas`, `GET /catalog/time-slots`, `GET /catalog/replacement-reasons`, `GET /catalog/ticket-categories` | |
| Search | `POST /workers/search {categoryId,engagement,addressId,timing,startDate,budgetMin,budgetMax,filters}` + cursor | |
| Worker | `GET /workers/{id}`, `GET /workers/{id}/reviews` | no KYC fields ever |
| Favourites | `GET /favourites`, `PUT/DELETE /favourites/{workerId}` | |
| Interview | `POST /interviews`, `GET /interviews`, `GET /interviews/{id}`, `POST /interviews/{id}/cancel`, `POST /interviews/{id}/decision` | `allowedActions[]` in response |
| Booking | `POST /bookings/quote`, `POST /bookings`, `GET /bookings`, `GET /bookings/{id}` (+`timeline[]`,`allowedActions[]`), `POST /bookings/{id}/cancel` | |
| Payment | `POST /payments/initiate {bookingId}` → `{paymentId,orderId,amount,currency,publicKey}`; `POST /payments/{id}/verify {sdkPayload}`; `GET /payments/{id}` | backend verifies with gateway |
| Transactions | `GET /transactions`, `GET /transactions/{id}` (+`receiptUrl`, refund status) | |
| Service | `GET /bookings/{id}/attendance`, `GET /services/history` | |
| Rating | `POST /bookings/{id}/rating {score,comment}` | |
| Replacement | `POST /bookings/{id}/replacement {reasonId,notes}`, `GET /replacements/{id}`, `GET /replacements/{id}/alternatives`, `POST /replacements/{id}/select {workerId}` | |
| Support | `POST/GET /tickets`, `GET /tickets/{id}` | |
| Safety | `POST /workers/{id}/report`, `POST /workers/{id}/block` | PRD §9.1 |
| Notifications | `POST/DELETE /devices {fcmToken,platform}`, `GET /notifications`, `POST /notifications/{id}/read` | |
| Home | `GET /home` (optional aggregate) | fallback: compose |

**Enums:** all status enums are **backend-owned**. Client maps via `*StatusMapper` with an `unknown` fallback (AGENTS §30, §34, §39, §46). Never `switch` exhaustively without a default.

**Questions for the backend team** are tracked in `OPEN_QUESTIONS.md`.
