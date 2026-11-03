# SevaNest customer app: integrated screens and what each still needs from the backend

As of 2026-11-03. API: `https://sevanest-backend.onrender.com/api/v1`. Full history and numbered
requests: `docs/BACKEND_REQUESTS.md`. The app never invents data: anything not served stays hidden.

## Screens integrated (design + live API)

| # | Screen | Endpoints used | Still needed from backend |
|---|---|---|---|
| 1 | Splash / app gate | `GET /customers/me`, `GET /app-config` | Set env values: `customer.storeUrl`, `support.phone/email`, `legal.terms/privacy.url` (all null today) |
| 2 | Login | `POST /auth/otp/request` | Real SMS (DLT); OTP length; error code for expired/locked OTP; 429 shape (`Retry-After` vs `details[0].retryAfterSeconds`) |
| 3 | OTP | `POST /auth/otp/verify`, `POST /auth/token/refresh` | Confirm refresh rotation invalidates the old token |
| 4 | Profile setup | `POST/PATCH /customers/me`, customer photo upload | Confirm the customer photo contract (app mirrors `/workers/me/photo`: upload URL, PUT, confirm) |
| 5 | Add address sheet (+ home photo) | `/customers/me/addresses*`, `/service-areas`, `/locations/service-area` | **Address home photo is not in the API.** App assumes `POST /customers/me/addresses/{id}/photo {contentType,sizeBytes}` -> `{photoId,url,method}`, PUT bytes, `POST .../photo/{photoId}/confirm`, `DELETE .../photo`, `photoUrl` on `AddressResponse`. Serviceability flag per address |
| 6 | Home | `GET /customers/me/home` (ETag), `/notifications/unread-count` | Promo carousel, "Explore services" tile images, worker price on shortlist cards |
| 7 | Find a worker: service, engagement, location, timing, start date, budget, review | `/service-categories` (`allowedEngagements`), `/reference-data`, `/pricing/guidance` | Budget filter in search (needs pricing rules); ONE_TIME budget period design; schedule config (timing/start-date rules are client-side) |
| 8 | Results | `GET /search/workers`, `GET /search/workers/count` | Price and distance on cards; confirm `minRating` scale (1-5 vs 1-10) and `meta.total` always present |
| 9 | Worker detail + reviews | `GET /search/workers/{id}`, worker reviews, `/shortlist` | Not served yet: About text, price/month, hours/day, distance, jobs done, repeat-customer %, per-check verification list ("in progress"), `canRequestInterview`, `verification: PENDING` |
| 10 | Shortlist | `GET/PUT/DELETE /shortlist` | Confirm entry shape (card inline vs `card`/`worker`) |
| 11 | Interview request / list / detail | `/interviews`, `/interviews/.../slots`, booking actions | `horizonDays` in `/app-config` (today only with slots); video interview join (V2) |
| 12 | Confirm booking | `POST /bookings`, `confirm-worker` | **Quote endpoint**: `POST /bookings/quote` -> `{wageMinor, feeMinor, taxMinor, totalMinor, currency, expiresAt}`. App shows a marked mock (fee Rs 500, 18% tax) until it exists |
| 13 | Payment + success | `POST /payments`, `/verify`, `GET /payments/{id}` | Razorpay verified on staging; nothing pending |
| 14 | Bookings list / detail / cancel | `GET /bookings`, `/bookings/{id}`, `/cancel`, `POST /bookings/rebook` | Search on bookings; fixed cancel reasons + refund info (optional) |
| 15 | Transactions / transaction detail / receipt | `GET /payments`, `/payments/{id}/receipt` | Month summary (paid / refunds / pending), search; deploy `/receipt/pdf` to staging |
| 16 | Active service | `/attendance/bookings/{id}` (+ `/summary`, `/exceptions`) | Nothing pending (verify with live data) |
| 17 | Service history | `/customers/me/booking-history` (+ `/summary`) | Nothing pending (verify with live data) |
| 18 | Rating | `POST /ratings`, `/ratings/bookings/{id}` | Rating tags field (app appends `Tags: ...` to the review today) |
| 19 | Replacement request / status | `/replacement-requests*`, `/bookings/{id}/replacement-chain` | Client decisions: fixed reasons, notes 500 vs 2000, "needed from" date, price/fee/interview rules |
| 20 | Support home / new ticket / ticket | `/support/*`, `/safety/*` | FAQ + help search content, ticket subject, photo attachments, "waiting for you"/"resolved" statuses, reopen |
| 21 | Notifications | `/notifications*`, `PUT/DELETE /auth/device-token` | Push payload keys and every `route.type`; preferences, delete, mark-unread; unread-count body shape |
| 22 | Account | `/customers/me`, `/app-config` | Account deletion retention rules + remote flag to show the row |

## Cross-cutting asks

1. Fresh OpenAPI with **success response schemas** (current spec has `{}` for most 200/201 bodies; `/openapi.json` is 404 on the host).
2. A staging test customer that has ACTIVE and COMPLETED bookings, tickets and notifications, so the live tests can run.
3. A production host separate from staging.
