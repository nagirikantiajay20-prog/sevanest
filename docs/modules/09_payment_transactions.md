# Module 09 — Payment, Receipts & Transactions

**Backend:** `POST /payments/initiate {bookingId}`, `POST /payments/{id}/verify {sdkPayload}`, `GET /payments/{id}`, `GET /transactions`, `GET /transactions/{id}` (+ `receiptUrl`, refund info).
**Routes:** `/payments/:paymentId`, `/transactions`, `/transactions/:id`.
**Core rule:** the SDK callback is **not** truth. UI shows SUCCESS only when backend payment status is SUCCESS (AGENTS §38, §80.5).
**Abstraction:** `PaymentService.pay(PaymentInit) → PaymentOutcome{success(payload)|cancelled|failed(code,msg)}`. Razorpay adapter default; `FakePaymentService` for tests.

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
