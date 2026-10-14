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
9. **Interviews / trial are booking states (modules 5 and 6 are built on this).** We found that the
   deployed API has no interview resource, so the app drives everything through `/bookings`:
   `POST /bookings {workerId,...}` (MATCHED), `POST /bookings/{id}/schedule {scheduleType,
   scheduledAt}`, `.../interview-complete`, `.../confirm-worker {startDate}`, `.../reopen-matching`,
   `.../cancel {reason}`. Please confirm:
   - that the CUSTOMER may call `schedule`, `interview-complete`, `confirm-worker`,
     `reopen-matching` and `cancel` (the Swagger says "Perform a booking action as the customer" but
     lists admin and worker actions too), and from which states each is allowed;
   - what state `reopen-matching` returns to (we assume NEW_REQUEST) and what happens to `workerId`;
   - whether `schedule` can be repeated to reschedule (we assume yes from MATCHED and
     INTERVIEW_TRIAL_SCHEDULED);
   - the response shape of `GET /bookings` and `GET /bookings/{id}`. We read: `id, status,
     category{code,name}, engagement, workerId, worker (the search card), area{name}, addressId,
     startDate, scheduleType, scheduledAt, budgetMinMinor, budgetMaxMinor, budgetPeriod,
     requirementNote, timeline[{status, at, note}], allowedActions[], paymentId, previousBookingId,
     createdAt`. Please add **`allowedActions`** (so the buttons come from you, not from our copy of
     the state model) and the **status timeline** to the response;
   - slots: there is no slot or availability-window endpoint. We offer hourly starts inside the
     worker's availability window, up to 14 days ahead; the backend only checks "a future time".
     Tell us if it should enforce more.
10. **Address label, second line, state.** The design shows labels ("Home", "Parents' home"), but
    `CreateAddressDto` has only `line, area, city, pincode, latitude, longitude, isDefault`. Please add
    `label` (nullable string), and optionally `line2`/`state`, or confirm they are not planned.
11. **Reverse-geocoded area.** When the customer taps "Use my current location" we send
    `latitude/longitude` and the geocoder's area name, which may not match a `service-area` name. Is
    there an endpoint to resolve coordinates to a service area (e.g.
    `GET /service-areas/resolve?lat&lng`)? Otherwise we make the customer pick the area.

12. **Fee before payment.** `POST /payments` takes the amount from fee configuration, and there is no
    quote endpoint, so the customer cannot see the booking fee before the payment step. Please expose
    it (for example `GET /fees/booking` or the fee on the booking), plus the cancellation / refund /
    replacement policy text, so the Confirm screen can show "Confirm & pay Rs X" and the policy.
13. **Cancellation reasons and refund info.** `cancel` takes a free-text `reason`. If you want fixed
    reasons or to show refund information on the cancel sheet, expose them (e.g. in
    `/reference-data` and on the booking).

### P3 - confirmations

14. `GET /search/workers`: `minRating` accepts 1-10. Confirm the scale (see 1) so we can offer a
    rating filter. Also: is `sort` safe to expose (`EXPERIENCE_DESC|EXPERIENCE_ASC|RATING_DESC`)?
15. Error codes we map today: `CATEGORY_NOT_AVAILABLE`, `AREA_NOT_AVAILABLE` (422),
    `WORKER_NOT_FOUND` (404 on card and shortlist PUT), `SHORTLIST_FULL` (422). Please confirm the
    HTTP status for an expired/locked OTP and the exact code (we currently match any `OTP_*` code
    containing LOCK/ATTEMPT/MAX, and HTTP 429), plus the 429 shape (`Retry-After` header vs
    `details[0].retryAfterSeconds`).
16. Default address rules: can a default address be deleted/unset? Does the first address become
    default automatically? Which error code for deleting an address used by an active booking
    (we assume 409)? Which code for an unserviceable area?
17. Support contact (`GET /app-config` -> `support.phone/email`) is `null` today; the Contact support
    button is disabled until it is set. Force-update (`customer.minVersion`) and `maintenance` are
    honoured by the app.
18. Pagination: `GET /shortlist` and `/search/workers` use `page` + `meta.total`. Is `meta.total`
    always present? We stop paging when it is missing.
19. `refresh` endpoint (`POST /auth/token/refresh`): confirm that rotation invalidates the old refresh
    token and the exact request body.

### Module 7 - payments (2026-10-13, from the typed OpenAPI)

The app runs on `POST /payments`, `POST /payments/{id}/verify`, `GET /payments/{id}` and
`GET /payments` (history). The docs/05 assumptions (`/payments/initiate`, `/transactions`) do not
exist in the backend and are not used.

**Answered by the backend (2026-10-14) and built in the app.** Nothing below has run against real
Razorpay yet (no keys), only against mocks and the documented shapes.

20. **`checkout` shape - answered.** `{ gateway: "razorpay" | "fake", keyId, orderId, amount, currency }`.
    Razorpay SDK gets `key = keyId`, `order_id = orderId`, `amount`, `currency`. `verify` takes
    `providerPaymentId = razorpay_payment_id` and `signature = razorpay_signature`; `razorpay_order_id`
    is not sent. Until Razorpay is configured the gateway is `fake` with `keyId: null`: the app has
    nothing to open and shows "didn't go through" (`CHECKOUT_UNSUPPORTED`). STILL OPEN: what the
    `fake` gateway accepts in `verify`, so staging can be paid without Razorpay keys.
21. **Receipt - answered.** `GET /payments/{id}/receipt` (409 `RECEIPT_NOT_AVAILABLE` before payment,
    404 for another customer). The app renders it; no PDF until an invoice / GST format is approved.
22. **Method and reference - answered.** `paymentMethod` (`upi`/`card`/`netbanking`/`wallet`/`emi`),
    `paymentMethodDetail` (masked), `gatewayReference`; null until the gateway answers. Shown on the receipt.
23. **Payment of a booking - answered.** `GET /payments?bookingId=`; `BookingView` gets no `paymentId`.
    The booking's Receipt button uses the filter and opens the paid payment.
24. **CREATED vs PENDING - answered.** `CREATED` = no gateway order yet (call `POST /payments` again; the app
    does so once). `PENDING` with a `checkout` = can pay; "confirming" only after the SDK returned.
25. **Retry after FAILED - answered.** A new payment and order, with a fresh Idempotency-Key, while the
    booking is `PENDING_PAYMENT`. Matches the app.
26. **Refund filter - answered.** `GET /payments?refunded=true` (REFUND_PENDING, REFUNDED, REFUND_FAILED).
    The Refunded chip uses it.
27. **Failure reason - answered.** FAILED payments carry `failureCode` (support only, never shown) and
    `failureReason` (shown). "No money deducted" is not claimed; the app says "If any amount was
    debited, it will be refunded automatically."

---

## Items that are NOT backend problems (for the team's information)

- Firebase projects / `google-services.json` + `GoogleService-Info.plist` per flavor, the Android
  release keystore, and the iOS schemes need the project owner / a Mac. Android signing is already
  wired to read `android/key.properties`.
- A map provider for the address pin (OPEN_QUESTIONS #15) is a product decision.

---

## Status of modules 1-5: what is still pending (2026-10-13)

The numbered requests above are the backend asks. This section is the whole picture, so the
backend, product and the app team can see what each pending item blocks and what the app does in
the meantime.

### 1. Backend endpoints or fields still missing

| Request | What is missing | Affects | App behaviour today |
|---|---|---|---|
| 9 | Confirm that interviews are booking states and the customer may drive them; `allowedActions` + timeline in the booking response; slot rules | Modules 5, 6 | Built on the booking API. Buttons follow the state model until `allowedActions` arrives. Unverified live. |
| 1 | Worker reviews for customers | Module 4 | Reviews list is mock-only in dev and empty in live. |
| 1 | Rating scale (`RATING_SCALE_MAX`) exposed to clients | Module 4 | Star rating filter and the "4.6" style display are held back. |
| 4 | Price guidance for the Budget step | Module 4 | Guidance card hidden in live; the customer types a range. |
| 5 | Budget parameter in search | Module 4 | The range is collected but not used for filtering. |
| 6 | Days of week and start date in search | Module 4 | Not used for matching; only the time range is sent. |
| 7 | Home aggregate (active booking, upcoming interview, unread count, shortlist preview) | Module 3 | Live Home shows the new-customer view only. |
| 8 | Customer profile photo endpoint | Module 3 | "Add a photo" is not built. |
| 10 | Address label, line 2, state | Module 3 | Address cards show the area instead of a label. |
| 11 | Coordinates to service-area lookup | Module 3 | After "Use my current location" the customer picks the area when the geocoded name does not match. |
| 2 | Published response schemas (most 200/201 bodies are empty in the Swagger) | All | Parsers are defensive but have never seen real success bodies. |

### 2. Backend confirmations needed (assumptions the app made)

- Whether `meta.total` is always returned (paging stops when it is missing).
- The `GET /shortlist` entry shape (the parser accepts the card inline, under `card`, or under `worker`).
- Whether `GET /search/workers?category=` takes the category `code` (the app sends `code`).
- The exact error code and status for an expired or locked OTP.
- The 429 shape: `Retry-After` header versus `details[0].retryAfterSeconds`.
- Default-address rules (delete or unset the default, first address auto-default).
- The error code for deleting an address that is used by an active booking.
- The error code for an unserviceable area.
- The refresh-token rotation behaviour and request body.
- `support.phone` and `support.email` in `GET /app-config` are `null`, so the Contact support button is disabled until they are set.

### 3. Integrations that need the project owner (not code)

| Item | Needed from | Blocks |
|---|---|---|
| Firebase projects and the per-flavor `google-services.json` / `GoogleService-Info.plist` | Project owner | Push notifications (module 10), step 1.2 |
| iOS schemes and xcconfig files, iOS builds | A Mac or a CI Mac | Step 1.2, release |
| Android release keystore (the build already reads `android/key.properties`) | Project owner | Release builds |
| Map provider for the address pin (OPEN_QUESTIONS #15) | Product decision | Map pin in the address form (current-location fill works without it) |
| A static test customer (mobile + OTP) with a profile, addresses, visible workers and a shortlist | Backend | Live contract tests (`test/live`) |

### 4. App work deliberately deferred to later modules

- Push token register and unregister on logout (FCM, module 10).
- A Bookings-tab segment for interviews (module 6). Interviews are reachable from the Account tab and the Home interview card for now.
- `/bookings/confirm` is a placeholder until module 6; "Confirm this worker" lands there.
- `/support/new` is a placeholder until module 10; "Contact support" lands there.
- The worker profile Report / Block menu (module 10 and the safety endpoints).
- The replacement "Choose" mode on the worker profile (module 9).
- The notification bell (module 10).
- Deep links (module 10).

### 5. Known limitations inside the built code

- Everything that touches the live backend is untested against real success responses (see section 1, response schemas).
- Dev starts on mocks, and stg/prod use the real repositories. Worker search, shortlist, catalogue and addresses have not been exercised live end to end.
- The "What does verified mean?" sheet uses placeholder copy.
- Only English is selectable (`GET /app-config` returns `languages: ["en"]`).
- The Budget step is always shown and every engagement type is offered for every category, because the backend states neither.
- Force-update and maintenance screens are not built (OPEN_QUESTIONS #30).

