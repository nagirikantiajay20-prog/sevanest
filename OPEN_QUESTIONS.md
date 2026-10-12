# OPEN_QUESTIONS.md (AGENTS §79)

Status: `OPEN` | `ANSWERED` | `ASSUMED(temporary)`. Update here; never bury in code.

| # | Question | Owner | Status | Temporary assumption / impact |
|---|---|---|---|---|
| 1 | Backend API contract (OpenAPI) | Backend | PARTIAL | Auth + customer-profile calls verified live (docs/05); Swagger has no success-response schemas - ask the backend team to publish them |
| 2 | Backend status enums (interview, booking, payment, replacement, ticket) | Backend | OPEN | mappers w/ unknown fallback |
| 3 | Payment provider | Product | ASSUMED | Razorpay adapter behind `PaymentService` |
| 4 | Booking/platform fee & trial pricing | Product | OPEN | from backend quote only |
| 5 | Refund & cancellation rules | Product/Legal | OPEN | text from backend; no hardcoding |
| 6 | Replacement eligibility | Product | OPEN | `allowedActions` from backend |
| 7 | Trial rules (paid? duration?) | Product | OPEN | |
| 8 | Matching algorithm / sort order | Backend | OPEN | render backend order |
| 9 | Attendance mechanism | Product | OPEN | render backend statuses only |
| 10 | Verification provider & what "verified" means to customers | Ops | OPEN | badge from backend; copy TBD |
| 11 | KYC info visible to customers | Legal | OPEN | none beyond badge |
| 12 | Rating scale & review constraints | Product | ASSUMED | 1–5 + optional text |
| 13 | Support SLA / categories | Ops | OPEN | backend-driven |
| 14 | Notification event catalog | Backend | OPEN | type+entityId payload assumed |
| 15 | Map provider | Product | OPEN | `LocationService` abstraction |
| 16 | V1 languages | Product | ASSUMED | English; i18n-ready |
| 17 | Consent/terms UX | Legal | OPEN | `GET /legal/current` returns null terms/privacy; the links say "not available yet" (`termsUrl` / `privacyUrl` in app_config.dart) |
| 18 | Data retention/deletion UX (account delete?) | Legal | OPEN | not in V1 until defined |
| 19 | Brand/design assets, colours, fonts | Design | OPEN | placeholder tokens `TBD-BRAND` |
| 20 | App name/ID availability (trademark, domain, bundle id) | Business | OPEN | `in.sevanest.customer` provisional |
| 21 | Bottom-nav tab set | Design | OPEN | Home/Bookings/Favourites/Account |
| 22 | OTP length, resend seconds, max attempts | Backend | PARTIAL | resend/expiry seconds come from the response; 5 attempts per code observed; OTP length is NOT in any response, so the app uses 6 (design) |
| 23 | Email required at profile setup? | Product | ANSWERED (by backend) | `POST /customers/me` requires `email`; the app enforces it (design shows Optional) |
| 24 | Draft requirement persistence | Product | OPEN | in-memory only |
| 25 | Idempotency-Key support | Backend | OPEN | header sent; harmless if ignored |
| 26 | iOS build infrastructure (Mac/CI) | DevOps | OPEN | needed by Week 1 |
| 27 | DLT / SMS provider registration | Ops/Backend | OPEN | Ordinary numbers get 503 `SMS_NOT_CONFIGURED`; only backend-provisioned static test numbers can log in. Needed before any real user can sign in |
| 28 | Error code when OTP attempts are exhausted | Backend | OPEN | Not observed live; the app maps any `OTP_*` code containing LOCK/ATTEMPT/MAX, and HTTP 429, to the "Too many attempts" state |
| 29 | 429 shape (`Retry-After` header vs `details[0].retryAfterSeconds`) | Backend | OPEN | Both are honoured; verified by mocked tests only |
| 30 | Force-update / maintenance (`GET /app-config` minVersion, maintenance) | Product | OPEN | Not implemented in the auth module |
| 31 | Support phone/email | Ops | OPEN | `GET /app-config` -> `support` is null today; the button explains support isn't available |
| 32 | Brand assets (logo, arch artwork, Inter font) for the auth screens | Design | OPEN | Placeholder house icon + painted arches; colours sampled from the mockups |
| 33 | Customer password / dev-login path | Backend | ANSWERED | Backend added static test numbers + OTP instead; there is no password login for customers |
| 34 | Success-response schemas for `/customers/me`, `/customers/me/addresses*`, `/service-areas` | Backend | OPEN | Swagger lists request DTOs only; parsers are defensive (extra/missing fields tolerated) and unverified live until test credentials are used |
| 35 | Customer profile photo upload endpoint | Backend | OPEN | Design 04 shows "Add a photo"; only `/workers/me/photo` exists. Not built |
| 36 | Address label (Home/Office/...), line 2, state | Backend/Design | OPEN | Designs show labels ("Home", "Parents' home"); API has none. Cards show area instead |
| 37 | Error codes: unsupported service area; address used by an active booking; whether the area must match `/service-areas` | Backend | OPEN | Handled generically (field error / 409 dialog) |
| 38 | Can a default address be deleted / unset? Does the first address auto-default? | Backend | OPEN | UI pre-selects "default" for the first address; switch is disabled on the current default |
| 39 | GPS "use current location", reverse geocoding and map pin | Product | OPEN | Needs a location + geocoding provider (#15). Not built |
