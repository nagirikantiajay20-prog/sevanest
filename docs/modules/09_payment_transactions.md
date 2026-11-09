# Module 09 — Payment, Receipts & Transactions

**Backend:** `POST /payments/initiate {bookingId}`, `POST /payments/{id}/verify {sdkPayload}`, `GET /payments/{id}`, `GET /transactions`, `GET /transactions/{id}` (+ `receiptUrl`, refund info).
**Routes:** `/payments/:paymentId`, `/transactions`, `/transactions/:id`.
**Core rule:** the SDK callback is **not** truth. UI shows SUCCESS only when backend payment status is SUCCESS (AGENTS §38, §80.5).
**Abstraction:** `PaymentService.pay(PaymentInit) → PaymentOutcome{success(payload)|cancelled|failed(code,msg)}`. Razorpay adapter default; `FakePaymentService` for tests.

> **Updated 2026-10-14 to the deployed API.** Routes are `POST /payments`, `POST /payments/{id}/verify`,
> `GET /payments` (`status`, `bookingId`, `refunded`), `GET /payments/{id}`, `GET /payments/{id}/receipt`.
> `checkout = { gateway, keyId, orderId, amount, currency }`. `PENDING` with a checkout = can pay;
> `CREATED` = call `POST /payments` again. There is no receipt PDF/URL: the receipt is rendered in the app.
> Failed payments show the gateway's `failureReason` and "If any amount was debited, it will be refunded
> automatically." The sections below keep the original design intent.

## Payment state machine (screen-level)
`initiating → awaitingUser (SDK open) → verifying (backend) → success | failed | pending(timeout)`; plus `cancelledByUser`.

## Screen 9.1 — Payment (`/payments/:paymentId`)
Entered from Confirm (8.1) or Booking detail "Complete payment". Shows amount summary, "Pay securely with UPI / Cards / Net banking" note, `Pay ₹X` button. On entry if `initiate` not yet done: `POST /payments/initiate`.
| Element | Key | Enabled when | On tap → Action | Result |
|---|---|---|---|---|
| Pay now | `payment_pay_btn` | init data ready, state ∈ {ready, failed, cancelled}, not loading | `PaymentService.pay(init)` opens Razorpay sheet; store `pendingPaymentId` (non-sensitive) | → state `verifying` after SDK returns |
| (SDK success) | — | — | `POST /payments/{id}/verify {sdkPayload}` then poll `GET /payments/{id}` (backoff 2s,4s,8s… max ~60s, config consts) until terminal | SUCCESS → **replace `/payments/:id` result view "success"** (9.2) ; FAILED → failed view; still PENDING after max → pending view |
| (SDK cancelled) | — | — | no verify required; GET status once | still ready → stay, snackbar "Payment cancelled. You can try again." |
| (SDK failed) | — | — | GET status once (backend is truth) | failed view with message |
| Back | `app_back_btn` | — | if `verifying` → blocked with toast "Please wait, confirming payment"; else dialog "Leave payment? Your booking stays pending." `payment_leave_confirm_btn` → **go `/bookings/:id`** | — |
Pay button hidden while backend status is PENDING/PROCESSING (prevents double pay).

## Screen 9.2 — Result views (same route, different state)
| State | Content | Buttons |
|---|---|---|
| **Success** | ✓ "Payment received", amount, reference, booking confirmed message from backend | `payment_view_booking_btn` → **go `/bookings/:id`** (stack reset to Home > Booking); `payment_receipt_btn` → **push `/transactions/:id`** |
| **Failed** | "Payment didn't go through" + reason (generic) + "No money deducted unless shown pending/refund" **only if backend says so** | `payment_retry_btn` → back to ready state (re-initiate if backend says order expired; **never creates a second booking**); `payment_support_btn` → **push `/support/new?paymentId=`**; `payment_close_btn` → **go `/bookings/:id`** |
| **Pending** | "We're confirming your payment. This can take a few minutes." | `payment_refresh_btn` → GET status; `payment_view_booking_btn` → `/bookings/:id`; Pay hidden |
| **Refund pending/refunded** (from transactions) | chip + text | — |

## App-kill / resume recovery
On app start & on resume: if `pendingPaymentId` exists → `GET /payments/{id}` → terminal → clear id & push result via notification/snackbar and refresh booking; non-terminal → show pending banner on Home/Booking detail.

## Screen 9.3 — Transactions (`/transactions`) from Account
List (paged): title (service/booking ref), date, amount (`₹`), status chip (Success/Failed/Pending/Refund pending/Refunded). 
| Element | Key | On tap | Result |
|---|---|---|---|
| Transaction row | `txn_row_<id>` | — | **push `/transactions/:id`** |
| Filter chips (All/Success/Refunds) | `txn_filter_<x>` | filter (client or API) | list reload |
Empty: "No transactions yet". 

## Screen 9.4 — Transaction / Receipt (`/transactions/:id`)
Amount, currency, status, payment method (masked), gateway reference, booking link, date, refund block (if any).
| Element | Key | On tap → Action | Result |
|---|---|---|---|
| View booking | `txn_booking_link` | — | **push `/bookings/:id`** |
| Download / view receipt | `txn_receipt_btn` | `url_launcher` / in-app PDF viewer using short-lived `receiptUrl` (do not cache/log URL) | opens; failure → snackbar "Couldn't open receipt" |
| Need help | `txn_support_btn` | — | **push `/support/new?paymentId=`** |

## Test Cases
| ID | Type | Given → When → Then |
|---|---|---|
| PAY-01 | W | Tap Pay → `PaymentService.pay` called once with init data; double-tap ignored |
| PAY-02 | W | SDK success + backend SUCCESS → success view |
| PAY-03 | W | **SDK success + backend FAILED → failed view (never success)** |
| PAY-04 | W | SDK success + backend stays PENDING past max polls → pending view; Pay hidden |
| PAY-05 | W | SDK cancelled → stay on ready state with snackbar; retry works; no new booking created |
| PAY-06 | W | SDK failed → failed view; Retry returns to ready |
| PAY-07 | U | Duplicate SDK callback handled idempotently (verify called once) |
| PAY-08 | W | Back during verifying is blocked |
| PAY-09 | W | Back from ready → leave dialog → `/bookings/:id` |
| PAY-10 | U | App-kill recovery: pendingPaymentId + backend SUCCESS → cleared and booking refreshed |
| PAY-11 | W | Success view → View booking resets stack (back from booking goes Home, not payment) |
| PAY-12 | U | Polling uses backoff and stops at terminal or max |
| PAY-13 | W | Transactions list paged; status chips for all states incl. unknown |
| PAY-14 | W | Receipt button opens URL via launcher; failure → snackbar |
| PAY-15 | U | No secret key in code (grep test/CI script); only public key used |
| PAY-16 | U | Receipt URL and payment payload absent from logs |
| PAY-17 | I | **Flow E (complete)** with FakePaymentService success; **Flow F** failure → retry → no duplicate booking (repo createBooking call count == 1) |
| PAY-18 | M | Razorpay sandbox on real Android + iOS: UPI intent, card, netbanking, user cancel, kill app mid-payment |

## Payment lifecycle as implemented (2026-11-08 audit)

**Owner:** `PaymentFlow` (`lib/features/payment/presentation/providers/payment_flow.dart`, `paymentFlowProvider`).
`PaymentScreen` only renders its state and forwards taps. `PaymentRecoveryHost` keeps the provider
listened to for the whole app (Riverpod pauses an unlistened provider and with it the connectivity
hook) and still does the app-start / resume snackbar for a payment the customer is not looking at.
Real gateway: `RazorpayPaymentService`; `FakePaymentService` only when the mock API is on.

**Status mapping** (backend values only; nothing is invented in Flutter):

| Backend `status` | `PaymentStatus` | Flow phase |
|---|---|---|
| `CREATED` | created | start again once (`POST /payments`), then pending |
| `PENDING` + `checkout` | pending | `ready` (pay), or `pending` if its checkout was opened before (store holds the id) |
| `PENDING` after the SDK reported | pending | `pending` ("confirming"), polling |
| `SUCCEEDED` | succeeded | `success` (payment) |
| `FAILED` | failed | `failed` (retry allowed) |
| `REFUND_PENDING` / `REFUNDED` / `REFUND_FAILED` | same | paid, shown with refund chip on receipt |
| anything else | unknown | `pending` (never failed, never success) |

`CANCELLED`, `EXPIRED`, `PROCESSING`, `REFUND_PROCESSING` **do not exist in the backend contract**;
they read as unknown. See the backend dependencies below.

**Transitions.** `loading -> ready -> paying (gateway) -> verifying -> success | failed | pending`.
`pending` is left only by a backend answer: `SUCCEEDED -> success`, `FAILED -> failed`, or the customer
choosing Pay again on a payment that is still payable. No timer, timeout, lost connection or SDK
error moves a payment to `failed`.

**Payment vs booking.** `success` means the *payment* is SUCCEEDED. After it the booking is read
separately (`GET /bookings/{id}`); "Your booking is confirmed." shows only when the backend says
CONFIRMED / ACTIVE. Otherwise the screen says "Payment received. We're confirming your booking." and
the booking is looked at again on the poll schedule; an unreadable booking is never "confirmed".

**Verification and polling.** The SDK result (`PaymentPaid`) is kept in memory only. It is sent to
`POST /payments/{id}/verify` with one idempotency key; if the answer is lost the same payload is
re-sent with the **same key** on every following check until the backend answers, then the payment is
read with `GET /payments/{id}`. Checks: right after the gateway returns, then after 3, 6, 10, 15, 30,
60, 120 s (`paymentPollDelaysProvider`), one at a time, cancelled on settle/dispose. The schedule
ending does not fail the payment; Check again, the app resuming (`WidgetsBindingObserver`) or the
connection returning (`onlineProvider` false -> true) restarts it. Reachability comes from the real
call result (`NetworkFailure` = offline), not from the radio state alone.

**Offline.** A failed read sets `offline`; the pending screen then says "You're offline. Your payment
status will be checked when your connection returns." with no Pay button. Reconnecting checks the
payment; it never starts another one.

**App restart.** `PendingPaymentStore` (SharedPreferences) keeps the payment id, booking id, first-saved
time and last status seen: identifiers only, never card data, UPI PIN, tokens, secrets or the SDK
signature. It is written when the checkout opens and cleared on SUCCEEDED / FAILED / a cancelled
checkout. On restart the stored id is read from the backend (the backend is the truth; the stored
status is only a hint). If the checkout was opened before, the payment reads "confirming" with Check
again / Pay again instead of the Pay button. If the app was killed before the SDK answer reached the
backend, the verify payload is lost and the backend webhook is what settles it (dependency below).

**UPI return.** Returning from GPay / PhonePe / Paytm without a result (`PaymentSdkFailed`) is treated
as unknown: the payment is read; paid -> success, failed -> failed, still payable -> "confirming" with
Pay again (same Razorpay order, so it cannot be charged twice), unreachable -> offline-pending.
`PaymentCancelled` (customer backed out) with an unpaid payment returns to the Pay button.

**Duplicate prevention (frontend).** Synchronous `_busy` guard (one start / gateway / verify at a time),
`pay()` only from `ready`, one status read at a time, `open()` ignored while a gateway/verify is
running, start key kept while the outcome of a start is unknown (a retry after a lost answer reuses
it) and renewed only after the start was answered or after a confirmed FAILED. Backend idempotency
(`Idempotency-Key` on `POST /payments` and `/verify`) is what makes this safe; see dependencies.

**Retry rules.** Try again is offered only on the `failed` phase (backend FAILED or refused signature)
and starts a new payment with a new key while the booking is PENDING_PAYMENT. Not offered while
pending; changing method happens inside the Razorpay sheet on the same order.

**Refunds.** Read only from `refundStatus` / REFUND_* statuses / `refundedAt` as the backend returns
them (receipt and transaction detail). Nothing is simulated; no REFUND_PROCESSING exists.

**Tests.** `test/features/payment/payment_lifecycle_test.dart` (notifier, fakes, no gateway) and
`payment_flow_test.dart` (screens): success, pending, failed, unknown, cancelled, offline during/after
the gateway, reconnect, timeout, resume, restart, stale local state, UPI return, duplicate taps,
retry rules, start-key reuse, polling stop, timer cancel, payment/booking split, refund mapping.
Live gateway behaviour (UPI intents, kill mid-payment) is device/sandbox testing only (PAY-18).

### Backend dependencies and limitations (frontend cannot fix these)

| # | Capability | Status | Production blocker? |
|---|---|---|---|
| B1 | Webhook settles a payment the app never verified (app killed after paying) | Stated in BACKEND_REQUESTS #20; not verifiable from the app | **Yes** until confirmed in staging |
| B2 | Idempotent `POST /payments` and `/verify` (same key -> same payment) | Contract says so; app relies on it for lost-answer retries | **Yes** until confirmed |
| B3 | Does Razorpay `payment.failed` mark a payment FAILED, or only the order expiring? Until then an SDK error reads "confirming" | Unknown | No (safe, but may show "confirming" longer) |
| B4 | Payment expiry: no `EXPIRED` / `CANCELLED` status, no `expiresAt` | Missing | No; documented as a limitation |
| B5 | `PROCESSING` / `REFUND_PROCESSING` statuses | Missing | No |
| B6 | Booking <-> payment reconciliation if payment SUCCEEDED but booking stays PENDING_PAYMENT; `BookingView` has no `paymentId` | Missing | **Yes** (needs a backend reconciler) |
| B7 | Fee quote before payment | Missing (BACKEND_REQUESTS) | No |
