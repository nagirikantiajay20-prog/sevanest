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
    is not sent. CLOSED (2026-10-14): the `fake` gateway is removed (it only worked in backend tests);
    staging runs Razorpay test mode (`PAYMENT_PROVIDER=razorpay`, test key). The backend paid a booking
    end to end with it: order -> Razorpay checkout -> verify 200 SUCCEEDED -> booking CONFIRMED. A
    checkout that is not `razorpay` with a `keyId` still ends in "didn't go through" (`CHECKOUT_UNSUPPORTED`).
    Live test customers: +919999900001 / +919999900002, OTP 123456 (set `SEVANEST_LIVE`).
21. **Receipt - answered.** `GET /payments/{id}/receipt` (409 `RECEIPT_NOT_AVAILABLE` before payment,
    404 for another customer). The app renders it. UPDATE 2026-10-14: `GET /payments/{id}/receipt/pdf`
    is added (same 404/409 errors; a payment receipt, NOT a GST tax invoice, which waits on the client).
    It needs a backend deploy before it is live on staging, so the app does not use it yet.
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

### Module 8 - active service, history, rating (2026-10-14, from the typed OpenAPI)

The app runs on `GET /attendance/bookings/{id}` (+ `/summary`), `GET /bookings`, `POST /ratings`,
`GET /ratings`, `GET /ratings/bookings/{id}`. The module-doc routes (`/services/history`,
`/bookings/{id}/attendance`, `POST /bookings/{id}/rating`, `rating-eligibility`) do not exist and are not used.

28. **Customer attendance access.** The Swagger lists `/attendance/bookings/{id}` for a customer, but the
    spec does not say whether the customer token is accepted today. CONFIRM with a live customer who has an
    ACTIVE booking. The app shows "No updates yet" for an empty list and a retry for 403.
29. **Attendance statuses.** The Swagger enum is `PRESENT | ABSENT | EXCEPTION`. The design shows Late and
    Leave, and "Checked in 8:02 AM / Scheduled 8 AM - 12 PM". None are in `AttendanceView` (`date`, `status`,
    `note`, `recordedBy`, `updatedAt`), so the app shows only the three statuses plus the note. Any other
    value reads "Updated". Add check-in / out times and a scheduled window if they should appear.
30. **Customer "raise exception".** `POST /attendance/bookings/{id}/exceptions` exists (a day the worker did not
    record, note required). The designs have no screen for it, so it is NOT built. Decide whether the active
    service screen should offer "Report a missing day".
31. **Service history route.** There is none. History is `GET /bookings` grouped by `status` in the app
    (Current / Completed / Cancelled / Replaced), paged 20 at a time. The designs also show "9 services,
    7 workers, total spent" and a year / category filter and search: none of those are served. Ask whether a
    `GET /bookings/summary` (counts, total spent) or a `search` / `year` filter is planned.
32. **Rating eligibility.** There is no eligibility endpoint and no `allowedActions` on bookings. The app treats
    a booking as rateable when it is `COMPLETED` (derived) and `GET /ratings/bookings/{id}` answers 404; the
    server stays the judge (`422 RATING_NOT_ELIGIBLE` and `409 RATING_ALREADY_EXISTS` switch the screen to the
    reason / "already rated" states). Confirm that `COMPLETED` is the only rateable state, and whether a
    booking that ended early (`REPLACED`, designs say "Ended early") can be rated.
33. **Rating tags and comment limit.** No tags endpoint (the module doc's `rating_tag_<id>` is not built).
    `review` is max 2000 in the Swagger; the design says 300 and `/reference-data` has no review limit. The
    app reads the limit from `ratingReviewMaxProvider` (default 2000). Add `ratingReviewMax` to
    `/reference-data`, or confirm 2000.
34. **Rebook.** No `rebook` action is sent, so there is no "Hire again" button (the design has one). Add it to
    the booking `allowedActions` if wanted.
35. **Response bodies.** Success bodies of `/attendance` and `/ratings` are typed in the Swagger and parsed
    defensively (a row without a date is skipped; unknown status = "Updated"). Not yet seen from a live
    customer with data: the test customer has no ACTIVE / COMPLETED booking.
36. **Worker name and photo.** Neither the booking nor the attendance carries the worker's name; the card is the
    anonymous search card (category, experience, languages), as on the other screens.

### Module 10 - active service, history, rating (answered by the backend on 2026-10-14)

Items 28-36 above are answered. Built in the app:

- **28 customer attendance:** works for the customer's own bookings (others 404).
- **29 statuses:** `LATE` and `LEAVE` exist; every row has `checkInAt` / `checkOutAt` (null until the worker taps).
  The summary adds `late`, `leave`, `scheduledWindow {from,to}` and `worker`. Shown as badges, "In 8:25 AM · Out
  12:05 PM", "Scheduled 8 AM - 12 PM". Unknown statuses still read "Updated". **Q-101:** LATE / LEAVE / the times
  await client sign-off.
- **30 customer exception:** built as "Report a missing day" on the active service screen (ACTIVE booking only, day
  from the start date to today, note 1-500; 409 = day already has an entry).
- **31 history:** `GET /customers/me/booking-history` (`year`, `category`, `search`, `status`) and `/summary`
  (`totalServices`, `distinctWorkers`, `totalSpentMinor`, `currency`). **Q-104:** "total spent" includes money still
  held; the app shows the server's number as "total spent".
- **32 rating eligibility:** every customer booking carries `allowedActions` and `rating`; the app trusts the list
  even when empty (so a rated or REPLACED booking never shows Rate). `/ratings/bookings/{id}/eligibility` is NOT
  called (no response schema was given; `allowedActions` carries the same answer). **Q-102:** REPLACED ("Ended
  early") is not rateable until the client decides. Repeat rating = 409 (shown as "already rated").
- **33 review limit / tags:** `ratingReviewMax` from `/reference-data` (default 300, the app falls back to 300). No
  tags: **Q-103**, no chips.
- **34 rebook:** "Hire again" only when `allowedActions` has `rebook`; `POST /bookings/rebook {bookingId}` (no
  `startDate` is sent, the server picks it), then opens the new booking.
- **36 worker identity:** `worker {displayName, initials, photo {url, largeUrl, expiresAt, cacheKey}}` shown on
  booking detail, active service and history; photo cached by `cacheKey`.

Not verified against a live customer yet (no shared test account with ACTIVE / COMPLETED bookings).

Backend follow-up answers (2026-10-14, from their code, no live run):
- **Rebook default start:** omitted `startDate` leaves the new booking's `startDate` and `requestedStartDate` null; it
  is set later at the schedule/start step (today or later). Send `startDate` ("YYYY-MM-DD") for "start today". Returns
  201 (200 on a replayed `Idempotency-Key`); 409 `REBOOK_NOT_ALLOWED` if not COMPLETED, plus the normal creation
  errors (`WORKER_NOT_ELIGIBLE`, `WORKER_UNAVAILABLE`, `DUPLICATE_BOOKING`). `allowedActions` is only a hint.
- **`rating` object:** `{rated, eligible, code}`, code = `ELIGIBLE | ALREADY_RATED | NOT_COMPLETED |
  ENDED_EARLY_NOT_RATEABLE | NO_WORKER`. Same logic as `/ratings/.../eligibility`
  (`{bookingId, eligible, code, reason, reviewMaxLength, scaleMax}`), so `allowedActions` agrees.
- **`scheduledWindow`:** `{from:"08:00", to:"12:00"}`, plain 24h strings, no date or timezone.
- **Q-101..Q-104** still have no client sign-off; backend defaults are what the app already follows. Review length
  300 is Q-105: read `reviewMaxLength`, don't hard-code.

### Module 9 - replacement (answered by the backend on 2026-10-14, commit `ad37f66`)

The app runs on `POST/GET /replacement-requests`, `GET /replacement-requests?bookingId=`, `GET .../{id}`,
`GET .../{id}/alternatives`, `POST .../cancel`, `POST .../select` and `GET /bookings/{id}/replacement-chain`.
Backend verified 23/23 on a throwaway local database; nothing has run on staging, so the app is not yet
verified against a live customer with an ACTIVE booking (no shared test account, nothing seeded).

Done and used by the app:
- Alternatives: `GET /replacement-requests/{id}/alternatives?page&limit`, customer-safe cards (no name), owner of
  an APPROVED request only, never the replaced worker; other status = 409 `INVALID_TRANSITION` (the app reads that
  as "no alternatives"), someone else's request = 404.
- Booking link: `GET /replacement-requests?bookingId=` (mine only) replaces the old scan of the whole list.
- Timeline: `timeline[]` (`status`, `at`, `actor` CUSTOMER / STAFF / SYSTEM, `remarks` on APPROVED / REJECTED only)
  gives the Progress timestamps; the date fields are the fallback.
- Statuses: APPROVED = alternatives may be listed and one selected. REJECTED is final (alternatives, select, cancel,
  approve = 409); the booking goes back to ACTIVE, so the rejected screen offers "Request a new replacement".
  `decisionRemarks` is shown verbatim.
- Error codes: create 409 `REPLACEMENT_ALREADY_OPEN` (opens the open request), 404 `BOOKING_NOT_FOUND` and
  422 `REPLACEMENT_NOT_ELIGIBLE` (lock the form); select 409 `WORKER_UNAVAILABLE`, 422 `WORKER_NOT_ELIGIBLE`
  ("choose another"), 422 `SAME_WORKER`, 409 `INVALID_TRANSITION` ("this request has changed", status re-read);
  cancel 409 `INVALID_TRANSITION` the same.
- After select: a new MATCHED booking (`replacementBookingId`), old one REPLACED. The copy no longer says the new
  worker "is now with you" or that the old booking "ends": it says a new booking was created and the usual steps
  follow.

Still needs a client decision (the app does NOT assume any of these):
37. **Reasons.** No fixed reason list is approved. `reason` stays free text (1-1000): the app sends the English text of
    the chosen reason and the customer's words as `notes`. Notes limit is 2000 (the design shows 500; the app uses 2000
    via `replacementNotesMaxProvider`, change it there if the client picks 500).
38. **"Needed from" date.** Not accepted or stored; the question is not shown. The replacement starts from today.
41. **Replacement booking rules.** Does a replacement skip the interview or the booking fee, or keep the old price?
    Today it follows the normal flow with no price or payment copied. The app claims none of it (the design's
    "No change in price" is not shown).
44. **Review ETA.** No ETA field and no review-time rule, so none is shown.

### Module 10 - support, safety, notifications (2026-10-14, from the typed OpenAPI)

The app runs on `/support/*`, `/safety/*`, `/notifications*` and `PUT /auth/device-token`. The module-doc routes (`/tickets`, `/devices`, `/workers/{id}/report`) do not exist. Nothing below has run against a live customer with tickets or notifications.

45. **FAQ, help search, contact content.** The design shows "Popular questions", a help search and "Call / Email support". No FAQ endpoint exists, so FAQ and search are NOT built. Contact comes from `GET /app-config` `support.phone` / `support.email`, both `null` today, so the buttons are disabled. Is FAQ content planned (an endpoint, or `/reference-data`)? Please set the support contact.
46. **Ticket fields the design has and the schema lacks.** `CreateTicketDto` is `categoryId`, `description` (max 4000), `bookingId` only. Not built: subject (80), photo attachments (3 images, 5 MB; no upload route), "Urgent" priority (`priority` is staff-only), a payment / replacement / interview link (only `bookingId`; the app resolves those to their booking), resolved feedback and rating. Questions: is there a minimum description length (the app uses 10 from the module doc)? Will `subject` and attachments be added? Should a safety-category ticket tell the customer it is prioritised?
47. **Ticket statuses.** `OPEN | IN_PROGRESS | ESCALATED | CLOSED`. The design's "Waiting for you" and "Resolved" do not exist. The app shows ESCALATED as "In progress" (internal) and CLOSED with the `resolution` text. Confirm that is right, and whether `history[].type` has a stable list (the app reads only `fromStatus` / `toStatus`).
48. **Conversation.** `GET .../messages` is paged but the order is not stated (the app sorts by `createdAt`). Is the ticket `description` also returned as the first message? (The app adds it when no customer message equals it.) Can a customer reopen a closed ticket (the design offers "No, I still need help")? Today the app offers "Create a new ticket".
49. **Report reasons and block.** `reasonCode` is `HARASSMENT | THEFT | SAFETY_CONCERN | MISCONDUCT | FRAUD | NO_SHOW | OTHER`; the design's "Arrived late / Left early / Attendance is wrong / Work quality" are not in it and are not offered. `reason` (500) and `note` (1000) are both free text: the app sends only `note`. `POST /safety/reports` has no Idempotency-Key and returns no ticket id. Is there a customer-visible "Blocked workers" list planned (the app shows none: the design has no entry)?
50. **Naming the worker.** The app sends `workerId` from a worker profile and `bookingId` from a booking or the active service. Confirm `bookingId` is accepted from a customer for both report and block ("Customers may use it instead of workerId").
51. **Device token.** `PUT /auth/device-token` binds the token to the session. There is no unbind route. On logout the app deletes the FCM token on the device (best effort) and calls `POST /auth/logout`. Does logout (session revocation) also drop the bound token? Is a token stored per session or per user? What does the server do with a token FCM reports invalid?
52. **Push payload.** Not published. The app reads `route` as `{type, id}` (or `"type:id"`) or flat `type` + `entityId` / `id`. Please publish the data keys and every `InboxItemView.route.type` the backend can send (the app handles `booking`, `interview`, `payment`, `replacement`, `ticket`; the module doc has `*_update`), and whether a rating prompt has a type.
53. **Notification centre extras.** No preferences (the design's settings sheet), no mark-unread, no delete. The unread count body is empty in the Swagger: the app reads a bare number or `count` / `unread` / `unreadCount`. Please document it.
54. **Push permission re-ask.** The app asks once after the first interview request and again after 3 days if the customer chose "Not now". Is that interval a product decision (config)?

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


## Module 14: Account & Settings (2026-10-14)

55. **Legal URLs** - `GET /app-config` -> `legal.terms.url` / `legal.privacy.url` are null today. The Account screen opens them in the in-app browser when set; please publish both (OPEN_QUESTIONS #17).
56. **Delete account** - no endpoint or retention policy is defined (OPEN_QUESTIONS #18). The row is hidden; tell us the route and what happens to bookings / payments before we build it.
