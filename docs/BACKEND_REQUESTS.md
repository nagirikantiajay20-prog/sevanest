# Requests for the backend team (customer app)

Written 2026-10-13 against `docs/backend_openapi_2026-10-12.json`. Each item says what the app does
today and what unblocks it. Priority: **P1** blocks a shipped screen, **P2** blocks a designed
feature, **P3** polish / confirmation.

---

## Message to send

Hi team,

The SevaNest customer app is now wired to your live API for categories, worker search, worker
profile and the shortlist (`/service-categories`, `/service-areas`, `/search/workers`,
`/search/workers/{id}`, `/shortlist`, `/customers/me/addresses`). Everything below is what is still
missing or unclear. Until then the app shows nothing rather than inventing data.

### P1 - blocks screens that are already built

1. **Worker reviews for customers.** The worker profile has a "Reviews" section and a paged
   `/workers/:id/reviews` screen. No customer-facing endpoint lists a worker's reviews (only
   `GET /ratings` = my own, and worker-side `/workers/me/ratings`). Please add something like
   `GET /search/workers/{workerId}/ratings?page&limit` returning, per review: `score`, `comment`
   (nullable), `createdAt`, `reviewerFirstName` (first name only, no contact data). Also tell us
   what the rating scale is (`RATING_SCALE_MAX`, 1-10 per the Swagger) - ideally expose it in
   `GET /app-config` or `GET /reference-data` as `ratingScaleMax`, because the card's `rating.average`
   is meaningless to display (stars? out of 10?) without it.
2. **Response schemas.** Swagger lists request DTOs but most 200/201 bodies are empty (`{}`),
   including `/service-categories`, `/service-areas`, `/customers/me`, `/customers/me/addresses*`,
   `/shortlist`, `/bookings`. The app parses defensively but has never seen real success bodies
   (no customer test credentials yet). Please publish the response schemas, and confirm:
   - list envelope: `{ data: [...], meta: { page, limit, total } }` everywhere?
   - `GET /shortlist` entry shape: our parser accepts the card inline, or under `card` / `worker`;
     entries for workers who are no longer visible carry only `workerId` and `available: false`.
     Which is it exactly?
   - `GET /service-categories` item fields: we read `code`, `name`, `description`. Is `id` also
     returned? Which one is accepted by `GET /search/workers?category=`? (We send `code`.)
3. **Test credentials for a customer with data.** We can only verify login/refresh/logout live.
   Please provision a static test customer (mobile + OTP) that already has: a completed profile, 1-2
   addresses, a few visible verified workers in two categories/areas, and 1-2 shortlisted workers, so
   we can run the live contract tests (`test/live`).

### P2 - designed features with no endpoint

4. **Price guidance for the Budget step.** The design shows "Typical for a part-time cook in
   Hyderabad ₹6,000-₹10,000 - based on recent bookings". Please add e.g.
   `GET /pricing/guidance?category=&areaId=&engagement=` -> `{ min, max, period, basis }` (404 when
   there is none). Until then the card is hidden and the customer types a range.
5. **Budget in search.** The Budget step collects a min-max range but `GET /search/workers` has no
   budget parameter. Should search filter on budget? If yes: `budgetMin`, `budgetMax`,
   `budgetPeriod` (`HOUR|DAY|MONTH|ONE_TIME` from `/reference-data`). If no, we keep it for the
   booking request only.
6. **Search by requirement.** The requirement also has a start date, days of the week and a time
   window. Search supports only `availableFrom/To` (a time range). Is matching on days and start date
   planned? We currently send engagement + the time range only.
7. **Home aggregate.** The Home screen needs: active booking summary, upcoming interview, unread
   notification count, shortlist preview. There is no `GET /home`. Either add one, or confirm we
   should compose it from `/bookings`, `/notifications/unread-count` and `/shortlist` (then also give
   us the interview endpoints - we found none; see 9).
8. **Customer profile photo.** Design 04 shows "Add a photo". Only `/workers/me/photo` exists. Please
   add an equivalent for customers (`POST /customers/me/photo` -> upload URL, `.../confirm`, `GET`) or
   tell us the photo is out of scope for V1.
9. **Interviews / trial (module 5 is built and waiting for this).** The Swagger has no interview
   endpoints. The app calls the contract below; please implement it or send the real one:
   - `POST /interviews` (header `Idempotency-Key`) body `{ workerId, type: "interview"|"trial",
     date: "YYYY-MM-DD", slot: "HH:mm", note?, requirement: {serviceId, engagement, address,
     timing, startDate, budget} }` -> the interview. `409` when the slot is taken, `404` when the
     worker is no longer visible.
   - `GET /interviews?page&limit` (+ `meta.total`), `GET /interviews/{id}`.
   - Interview object: `{ id, status: REQUESTED|SCHEDULED|COMPLETED|CANCELLED|DECLINED|CONFIRMED|
     NOT_A_FIT, type, workerId, worker?: <the search card>, date, slot, note, requirement,
     timeline?: [{title, state: done|current|upcoming|failed, at}], allowedActions:
     ["cancel","reschedule","confirm","decline"] }`. The app shows only the actions listed.
   - `POST /interviews/{id}/cancel {reason?}`, `POST /interviews/{id}/decision
     {decision:"decline"}`, `POST /interviews/{id}/reschedule {date, slot}`.
   - `GET /workers/{id}/slots?date=YYYY-MM-DD` -> free start times (`["09:00", ...]`), and the
     booking horizon (we assume 14 days). Is an interview one hour? If V1 has no interview
     step, tell us and we will drop module 5.
10. **Address label, second line, state.** The design shows labels ("Home", "Parents' home"), but
    `CreateAddressDto` has only `line, area, city, pincode, latitude, longitude, isDefault`. Please add
    `label` (nullable string), and optionally `line2`/`state`, or confirm they are not planned.
11. **Reverse-geocoded area.** When the customer taps "Use my current location" we send
    `latitude/longitude` and the geocoder's area name, which may not match a `service-area` name. Is
    there an endpoint to resolve coordinates to a service area (e.g.
    `GET /service-areas/resolve?lat&lng`)? Otherwise we make the customer pick the area.

### P3 - confirmations

12. `GET /search/workers`: `minRating` accepts 1-10. Confirm the scale (see 1) so we can offer a
    rating filter. Also: is `sort` safe to expose (`EXPERIENCE_DESC|EXPERIENCE_ASC|RATING_DESC`)?
13. Error codes we map today: `CATEGORY_NOT_AVAILABLE`, `AREA_NOT_AVAILABLE` (422),
    `WORKER_NOT_FOUND` (404 on card and shortlist PUT), `SHORTLIST_FULL` (422). Please confirm the
    HTTP status for an expired/locked OTP and the exact code (we currently match any `OTP_*` code
    containing LOCK/ATTEMPT/MAX, and HTTP 429), plus the 429 shape (`Retry-After` header vs
    `details[0].retryAfterSeconds`).
14. Default address rules: can a default address be deleted/unset? Does the first address become
    default automatically? Which error code for deleting an address used by an active booking
    (we assume 409)? Which code for an unserviceable area?
15. Support contact (`GET /app-config` -> `support.phone/email`) is `null` today; the Contact support
    button is disabled until it is set. Force-update (`customer.minVersion`) and `maintenance` are
    honoured by the app.
16. Pagination: `GET /shortlist` and `/search/workers` use `page` + `meta.total`. Is `meta.total`
    always present? We stop paging when it is missing.
17. `refresh` endpoint (`POST /auth/token/refresh`): confirm that rotation invalidates the old refresh
    token and the exact request body.

---

## Items that are NOT backend problems (for the team's information)

- Firebase projects / `google-services.json` + `GoogleService-Info.plist` per flavor, the Android
  release keystore, and the iOS schemes need the project owner / a Mac. Android signing is already
  wired to read `android/key.properties`.
- A map provider for the address pin (OPEN_QUESTIONS #15) is a product decision.
