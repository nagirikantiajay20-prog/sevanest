# Module 15 — Master Navigation Map & End-to-End Functional Flows

> Single reference for **where every screen goes** and **how each feature works end to end**. If this file and a module file disagree, fix both and log in `docs/DECISIONS.md`. Navigation verbs: **push** (back returns), **go** (stack reset), **replace** (cannot go back to it), **pop** (return).

## 1. Route-by-route navigation (entry → exits)

| Screen (route) | Reached from | Buttons → destination |
|---|---|---|
| Splash `/splash` | app start | auto → `/login` · `/home` · `/profile/setup` |
| Login `/login` | Splash, logout, 401 | Get OTP → push `/otp` · Terms/Privacy → external |
| OTP `/otp` | Login | Verify → go `/home` or go `/profile/setup` · Change number/back → pop |
| Profile Setup `/profile/setup` | OTP (new user) | Continue → go `/addresses/new?firstTime=true` (back disabled) |
| Add Address `/addresses/new` | Setup, Address list, Discovery step 3, Home banner | Save → (firstTime) go `/home` / else pop · Skip → go `/home` |
| Home `/home` | Splash, OTP, Save/Skip | Find worker → push `/discover/category` · Category tile → push `/discover/engagement` · Bell → push `/notifications` · Active booking → push `/bookings/:id` · Interview card → push `/interviews/:id` · Shortlist worker → push `/workers/:id` · Support → push `/support` |
| Category `/discover/category` | Home, Favourites empty, Bookings empty | Next → push `/discover/engagement` · X → Home |
| Engagement | Category | Next → push `/discover/location` |
| Location | Engagement | Add address → push `/addresses/new` (returns selected) · Next → push `/discover/timing` |
| Timing | Location | Next → push `/discover/start-date` |
| Start date | Timing | Next → push `/discover/budget` (if required) else `/discover/review` |
| Budget | Start date | Next → push `/discover/review` |
| Review | Budget/Start date, Results edit, Confirm edit | Edit row → pop to that step · Search → push `/workers` |
| Results `/workers` | Review | Card → push `/workers/:id` · Heart → toggles favourite (stay) · Filter → sheet · Edit requirement → pop to Review |
| Worker Detail `/workers/:id` | Results, Favourites, Home, Interview, Booking, Replacement | Request interview → push `/interviews/new?workerId=` · Reviews → push `/workers/:id/reviews` · ⋮ Report/Block → sheet · (replacement mode) Choose → pop to `/replacements/:id` · Unavailable → Find another → pop to `/workers` |
| Interview Request `/interviews/new` | Worker detail, Reschedule | Submit → replace `/interviews/:id` |
| Interview Detail `/interviews/:id` | Submit, Home card, list, notification | Worker card → push `/workers/:id` · Confirm worker → push `/bookings/confirm?interviewId=` · Decline → status refresh → Find another → go `/workers` · Support → push `/support/new` |
| Confirm & Pay `/bookings/confirm` | Interview detail | Confirm & pay → push `/payments/:paymentId` · Edit → push `/discover/review` · 409 → Find another → go `/workers` |
| Payment `/payments/:id` | Confirm, Booking detail, notification | SDK → in-place states · Success: View booking → go `/bookings/:id` · Receipt → push `/transactions/:id` · Failed: Retry (stay) / Support → push `/support/new?paymentId=` / Close → go `/bookings/:id` · Back (ready) → go `/bookings/:id` |
| Bookings `/bookings` (tab) | nav tab | Card → push `/bookings/:id` · Pay → push `/payments/:id` · Empty CTA → push `/discover/category` |
| Booking Detail `/bookings/:id` | list, payment success, Home, notification | Pay → push payment · View service → push `/services/current` · Rate → push `/ratings/:id` · Replace → push `/replacements/new` · Cancel → sheet · Receipt → push `/transactions/:id` · Help → push `/support/new?bookingId=` · Worker → push `/workers/:id` |
| Active Service `/services/current` | Booking detail | Worker/Booking links → push · Support/Replace/Rate → push respective · Report → sheet |
| History `/services/history` | Account | Card → push `/bookings/:id` · Rate → push `/ratings/:id` · Rebook → push `/discover/review` |
| Rating `/ratings/:id` | Booking, Service, History | Submit → replace thank-you state → Done → go `/bookings/:id` |
| Replacement Request `/replacements/new` | Booking, Active service | Submit → replace `/replacements/:id` |
| Replacement Status `/replacements/:id` | Submit, notification | Alternative card → push `/workers/:id?replacementId=` · Support → push `/support/new` · View booking → go `/bookings/:newId` |
| Favourites `/favourites` (tab) | nav tab, Account | Card → push `/workers/:id` · Empty CTA → push `/discover/category` |
| Support `/support` | Home, Account | New → push `/support/new` · Card → push `/support/:id` |
| New Ticket `/support/new` | Support, Booking, Payment, Interview, Replacement | Submit → replace `/support/:id` |
| Ticket Detail `/support/:id` | Submit, list, notification | Related link → push entity screen |
| Transactions `/transactions` | Account | Row → push `/transactions/:id` |
| Receipt `/transactions/:id` | list, payment success, Booking | Booking link → push `/bookings/:id` · Receipt → external viewer · Help → push `/support/new?paymentId=` |
| Notifications `/notifications` | Home bell, Account | Row → push target by type (module 13) |
| Account `/account` (tab) | nav tab | rows → module 14 · Logout → go `/login` |

## 2. How each feature works (end-to-end functional flows)

### F1 Login & session
Enter mobile → backend sends SMS OTP → enter OTP → backend returns tokens → tokens go to secure storage → `GET /me` decides Home vs Profile Setup. Every API call carries the bearer token; on 401 the app refreshes once (shared by parallel calls); if refresh fails the session is cleared and the user lands on Login.

### F2 Find a worker (requirement → results)
Seven small steps fill one in-memory draft (category → engagement → address → timing → start date → budget → review). Search sends the draft to the backend, which matches and returns workers page by page (cursor). The app only renders what comes back; filters re-run the search with the same requirement; a new search cancels the previous one. Empty result = guidance, never fake workers.

### F3 Trust display
A worker is shown "Verified" only if the backend says so. Pending shows "Verification in progress". No identity documents or numbers are ever fetched or displayed.

### F4 Shortlist
Heart tap flips instantly, calls API; failure reverts with a message. All hearts for the same worker stay in sync because they read one provider.

### F5 Interview/trial → decision
Customer proposes date/slot → backend creates the request and notifies the worker → worker accepts/schedules (Worker App) → customer sees status changes (push + refresh) → after the interview customer taps Confirm (to booking) or Not a fit (back to search). Buttons shown are exactly those backend allows.

### F6 Booking & payment
Confirm screen fetches a **quote** (fees from admin config). "Confirm & pay" creates the booking once (idempotency key) → backend returns payment order → gateway sheet opens → after the sheet closes the app asks the backend to verify and polls until a final status → only then shows Success. Failure/cancel keeps the same booking so retry cannot duplicate it. If the app is killed mid-payment, the next launch resolves the pending payment.

### F7 Service in progress
Booking detail is the hub: timeline (backend events), payment status, and action buttons driven by `allowedActions`. Active Service shows the attendance/status entries the backend provides (no GPS/face features in V1).

### F8 Rating
Available only when backend marks the booking eligible; one rating per booking; success replaces the form with a thank-you state.

### F9 Replacement
Customer submits reason → Support/Admin reviews in the admin portal → backend moves status → customer sees status/alternatives (push + refresh) → customer picks an alternative → backend confirms new worker/booking; old booking remains in history.

### F10 Support & safety
Ticket created with optional link to a booking/payment/etc.; staff updates appear in ticket detail; customer can reply while open. Report/Block call backend and the effect (hidden worker) comes from refetched results.

### F11 Notifications
Backend events → FCM → app. Foreground = banner; tap = route by `type` and **refetch** the entity. Unread badge from backend count.

### F12 Logout
Server logout (best effort) → unregister device → clear secure storage → reset all providers → Login.

## 3. Navigation test suite (one automated test per row above)
| ID | Type | Description |
|---|---|---|
| NAV-01 | W | Parameterised test: for every row in §1, tap the listed key on a pumped screen with fake repos and assert the resulting route + params (`GoRouter.state.uri`). |
| NAV-02 | W | Every `replace`/`go` transition: after navigation, `pop` is impossible or lands on the documented screen (Profile Setup back disabled, post-submit forms not reachable, post-payment success back → Home). |
| NAV-03 | W | Deep link per notification type reaches the §1 destination; logged-out deep link resumes after login. |
| NAV-04 | W | Android system-back behaviour on each tab and on payment `verifying` state. |
| NAV-05 | U | Route table: every route constant in `routes.dart` appears in §1 and vice-versa (guards against undocumented screens). |
| NAV-06 | I | Flows A–J from AGENTS §68 pass end to end using the key names from the module files. |
