# AGENTS.md — SevaNest Customer Mobile Application

> **Project:** SevaNest  
> **Product:** Verified Help. Trusted Homes.  
> **Application:** Customer Mobile Application  
> **Platforms:** Android + iOS  
> **Frontend:** Flutter  
> **Primary Launch Market:** Hyderabad, India  
> **V1 Delivery Target:** 16 weeks / 4 months  
> **Source of Truth:** SevaNest Product Requirements Document (PRD) + approved project decisions  
> **Audience:** Claude Code / coding agents / Flutter developers / reviewers  
> **Document Purpose:** This file is the mandatory development operating manual for the SevaNest Customer App.

---

## READ ORDER & COMPANION DOCS (added after market research)

Before any work, read in this order:

1. `AGENTS.md` (this file) — rules and business invariants
2. `docs/02_TECH_STACK_AND_SETUP.md` — **approved stack** (Riverpod, go_router, dio, freezed, flutter_secure_storage, FCM, Razorpay behind `PaymentService`), flavors, folder structure, core building blocks
3. `docs/03_IMPLEMENTATION_GUIDE.md` — **step-by-step build order with exit criteria and tests per step. Execute in order.**
3a. **`docs/modules/` — module-wise, button-click-level specs (what each button does, where it navigates, failure behaviour, widget keys, test cases). Start with `docs/modules/00_README_HOW_TO_USE.md`; build modules in numeric order; `docs/modules/15_navigation_map_and_functional_flows.md` is the master route map. A module is done only when every interaction-table row is implemented and all its test cases pass.**
4. `docs/04_SCREEN_SPECS.md` — screen inventory, components, copy
5. `docs/05_API_CONTRACT_ASSUMPTIONS.md` — provisional API (superseded by real backend contract when available)
6. `docs/01_MARKET_RESEARCH.md` — reference-app patterns (context only)
7. `OPEN_QUESTIONS.md` — unresolved items; update, never hide in code

Also maintain `docs/PROGRESS.md` (tick each step in doc 03 when its exit criteria pass) and `docs/DECISIONS.md` (any deviation from these docs).

**Decisions resolved by the companion docs** (these supersede "if no solution selected" wording in §8 and §58): state = Riverpod; routing = go_router; HTTP = dio; models = freezed/json_serializable; flavors = dev/stg/prod; app id `com.sevanest.customer` (provisional). **iOS builds require macOS/CI Mac** — plan from Week 1.

**Market-informed UX rules** (from doc 01): few-step requirement builder, pre-selected default address for returning users, trust cues (badge + "what verified means") at decision points, fee transparency before payment, plain-language status timeline, replacement/support always reachable from Active Service. Do not copy competitor branding, assets or copy.

---

## 0. MANDATORY AGENT INSTRUCTION

You are an implementation agent working on the **SevaNest Customer Mobile Application**.

You MUST treat this document and the approved SevaNest PRD as the primary product requirements.

You MUST:

1. Understand the business workflow before modifying code.
2. Preserve existing working functionality.
3. Implement features module-by-module.
4. Follow the backend API contract when one is available.
5. Never invent undocumented business rules and silently encode them.
6. Mark undefined requirements as `TBD` or request clarification through a clear implementation note.
7. Never fake successful backend operations in production flows.
8. Never expose sensitive KYC or payment information.
9. Keep customer-facing state synchronized with backend state.
10. Write tests for every meaningful business workflow.
11. Run formatting, static analysis and tests after meaningful changes.
12. Perform regression checks before declaring a module complete.
13. Prefer reusable components and feature-first architecture.
14. Keep the app ready for future multilingual support and future SevaNest expansion.
15. Do not implement Version 2/future features unless explicitly approved.

### Non-negotiable principle

The Customer App is a **client of the SevaNest backend**, not the source of truth.

The backend is authoritative for:

- authentication/session validity
- customer identity
- worker verification
- worker availability
- matching/search results
- interview/trial status
- booking status
- payment status
- replacement eligibility
- support-ticket state
- rating eligibility
- permissions
- notification state

The Flutter app must render backend-confirmed state.

---

# 1. PRODUCT UNDERSTANDING

SevaNest is a household workforce marketplace connecting customers with verified:

- House Maids
- Drivers
- Cooks
- Babysitters
- Elderly Care Helpers
- Cleaning Helpers

The V1 product consists of:

1. Customer Mobile App
2. Worker Mobile App
3. Web Admin Portal
4. Shared Backend/API and supporting infrastructure

This document covers ONLY the **Customer Mobile Application frontend**, while explicitly documenting its dependencies on Worker App, Admin Portal, backend services and external integrations.

The central product promise is:

> **Verified household staff, simple booking, transparent status and dependable replacement support.**

The customer journey is:

```text
Customer Login
  ↓
Customer Profile
  ↓
Service Requirement
  ↓
Search / Matching
  ↓
Verified Worker Discovery
  ↓
Worker Profile
  ↓
Shortlist / Favourite
  ↓
Interview / Trial
  ↓
Worker Confirmation
  ↓
Booking
  ↓
Payment
  ↓
Booking Confirmation
  ↓
Active Service
  ↓
Status / Attendance Visibility
  ↓
Rating / Service History
  ↓
Support or Replacement when required
```

---

# 2. SOURCE-OF-TRUTH RULES

## 2.1 Requirement priority

When making implementation decisions, use this order:

1. Approved current backend API contract
2. Approved product/business decision recorded by the project team
3. SevaNest PRD
4. This AGENTS.md
5. Existing code conventions that do not conflict with 1–4
6. Agent implementation preference

If two sources conflict:

- Do NOT silently choose.
- Identify the conflict.
- Prefer the newer approved requirement.
- Record the decision.
- Avoid destructive changes until the conflict is resolved if it affects business behavior.

## 2.2 Explicit PRD requirements

The PRD explicitly requires:

- OTP authentication
- Customer profile
- Saved addresses
- Basic customer verification
- Service category selection
- Engagement type selection
- Location
- Preferred timing
- Start date
- Salary/budget where applicable
- Worker discovery
- Worker cards
- Verification badges
- Ratings/reviews
- Shortlist/favourites
- Interview/trial request
- Date/time selection
- Worker confirmation
- Applicable platform/booking fee payment
- Booking status timeline
- Attendance/status visibility
- Service history
- Support request
- Worker rating
- Replacement request
- UPI/cards/net banking through a payment gateway
- Receipts
- Transaction history
- Refund status where applicable
- Push/SMS/optional WhatsApp notifications
- Production-ready Android/iOS application

## 2.3 Requirements that are NOT fully specified

Do not invent final business rules for:

- exact pricing
- cancellation/refund policy
- replacement eligibility
- trial pricing
- placement fee rules
- subscription pricing
- matching algorithm
- exact attendance mechanism
- exact verification provider
- exact KYC document list
- exact booking status vocabulary
- exact notification templates
- exact API endpoint names
- exact backend DTOs
- exact legal retention period
- exact map provider implementation
- exact support SLA values

Implement these through configurable/backend-driven behavior or clearly mark them `TBD`.

---

# 3. V1 SCOPE BOUNDARY

## 3.1 In scope for Customer App

- Android
- iOS
- OTP login
- Customer profile
- Addresses
- Service discovery
- Location and availability filtering
- Worker discovery
- Worker profile
- Verification indicators
- Shortlist/favourites
- Interview/trial request
- Booking
- Payment
- Booking status
- Ongoing service visibility
- Service history
- Ratings/reviews
- Replacement requests
- Support/complaints
- Notifications
- Transaction/payment history

## 3.2 Explicitly out of scope for V1 unless approved

Do NOT implement as V1 product requirements:

- automated payroll
- statutory payroll compliance
- worker loans/credit
- insurance marketplace
- facial-recognition attendance
- complex AI recommendation engine
- full apartment-society ERP
- advanced corporate workforce module
- multi-country operations
- GPS/geofenced attendance unless separately approved
- facial verification/attendance unless separately approved
- advanced fraud analytics
- in-app chat/call masking unless separately approved

Future roadmap includes multilingual UI, AI matching, GPS/geofenced attendance, facial verification subject to legal review, worker training/certification, payroll assistance, insurance, apartment dashboard, corporate requests, referrals/loyalty, chat/call masking, advanced fraud analytics and multi-city operations.

---

# 4. CUSTOMER APP ROLE

The Customer App allows a customer to:

1. Authenticate.
2. Create/manage profile.
3. Manage addresses.
4. Define a household workforce requirement.
5. Discover suitable workers.
6. Inspect worker profiles and verification status.
7. Shortlist workers.
8. Request interviews/trials.
9. Confirm a worker.
10. Complete applicable payment.
11. Track booking/service state.
12. View ongoing service status.
13. View service history.
14. Rate eligible workers.
15. Raise support/complaint tickets.
16. Request replacement.
17. View replacement status.
18. View transaction history and receipts.
19. Receive notifications.

---

# 5. SYSTEM CONTEXT

```text
                         SEVANEST
                            |
        +-------------------+-------------------+
        |                   |                   |
        v                   v                   v
 CUSTOMER APP          WORKER APP          ADMIN PORTAL
   Flutter               Flutter               Web
        |                   |                   |
        +-------------------+-------------------+
                            |
                            v
                     BACKEND / API
                            |
      +----------+----------+----------+----------+
      |          |          |          |          |
      v          v          v          v          v
     Auth      Users     Workers    Booking    Payment
                           |
                       Verification
                           |
                     Search/Matching
                           |
                 Notifications / Support
```

The Customer App does not directly communicate with another customer's app or worker app. Shared business entities are synchronized through the backend.

---

# 6. CORE DOMAIN RELATIONSHIPS

The primary customer-side domain relationships are:

```text
Customer
  |
  +---- Addresses
  |
  +---- Favourites ---- Worker
  |
  +---- Service Requirements
              |
              +---- Service Category
              |
              +---- Search/Matching
              |
              +---- Worker
                         |
                         +---- Verification
                         +---- Availability
                         +---- Skills
                         +---- Rating
                         |
                         +---- Interview/Trial
                                  |
                                  +---- Booking
                                         |
                                         +---- Payment
                                         |
                                         +---- Active Service
                                         |
                                         +---- Attendance/Status
                                         |
                                         +---- Rating
                                         |
                                         +---- Replacement
                                         |
                                         +---- Support
```

Core entities defined by the PRD include:

- Customer
- Worker
- Service Category
- Booking
- Interview/Trial
- Verification
- Payment
- Attendance
- Replacement
- Support Ticket
- Notification
- Audit Log

The Customer App primarily consumes/manipulates the customer-facing subset.

---

# 7. RECOMMENDED FLUTTER ARCHITECTURE

Use a **feature-first, layered architecture**.

Recommended:

```text
lib/
├── app/
│   ├── app.dart
│   ├── router/
│   ├── theme/
│   └── bootstrap/
│
├── core/
│   ├── config/
│   ├── constants/
│   ├── errors/
│   ├── extensions/
│   ├── network/
│   ├── storage/
│   ├── security/
│   ├── localization/
│   ├── analytics/
│   └── widgets/
│
├── features/
│   ├── authentication/
│   ├── onboarding/
│   ├── customer_profile/
│   ├── addresses/
│   ├── home/
│   ├── service_discovery/
│   ├── worker_search/
│   ├── worker_profile/
│   ├── favourites/
│   ├── interview_trial/
│   ├── booking/
│   ├── payment/
│   ├── active_service/
│   ├── service_history/
│   ├── ratings/
│   ├── replacement/
│   ├── support/
│   ├── notifications/
│   └── transactions/
│
└── shared/
    ├── models/
    ├── enums/
    └── utils/
```

Each feature should ideally contain:

```text
feature/
├── data/
│   ├── datasources/
│   ├── dto/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── presentation/
    ├── providers_or_notifiers/
    ├── screens/
    ├── widgets/
    └── state/
```

Do not force unnecessary abstractions. The goal is separation of concerns, testability and maintainability.

---

# 8. STATE MANAGEMENT

Use the project's approved state-management solution.

If no state solution is already selected, prefer a predictable reactive architecture such as Riverpod.

Business state must be separated from UI-only state.

Examples:

```text
AuthState
CustomerProfileState
AddressState
ServiceDiscoveryState
WorkerSearchState
WorkerDetailsState
FavouriteState
InterviewState
BookingState
PaymentState
ActiveServiceState
RatingState
ReplacementState
SupportState
NotificationState
TransactionState
```

Every async state should handle:

```text
initial
loading
success
empty
error
```

For mutation flows, also consider:

```text
submitting
success
failure
```

Do not use a global loading spinner for unrelated operations.

---

# 9. AUTHENTICATION FLOW

## 9.1 App launch

```text
Splash
  ↓
Read secure session
  ↓
Session exists?
  ├── No → Login
  └── Yes
        ↓
    Validate/refresh session
        ├── Valid → Home
        └── Invalid → Login
```

Never store access tokens or sensitive session material in plain SharedPreferences.

Use secure storage according to the project's security architecture.

## 9.2 Login

```text
Enter mobile number
  ↓
Validate format
  ↓
Request OTP
  ↓
OTP screen
  ↓
Verify OTP
  ↓
Backend authentication
  ↓
Session/token
  ↓
Customer profile check
```

## 9.3 Existing vs new customer

After authentication:

```text
Authenticated
  ↓
Customer profile exists and complete?
  ├── Yes → Home
  └── No → Profile Setup
```

Do not assume local state means the profile is complete.

---

# 10. AUTH SCREEN REQUIREMENTS

## Splash

Responsibilities:

- initialize app
- initialize configuration
- restore secure session
- route based on authentication state

Do not perform long-running business calls unnecessarily.

## Login

Must support:

- mobile number
- OTP request
- validation
- loading
- resend handling
- error handling

## OTP

Must support:

- OTP input
- verification
- resend countdown
- retry
- invalid OTP
- expired OTP
- network failure
- session creation

The actual OTP length and resend timing are backend/product contract details unless already defined elsewhere.

---

# 11. CUSTOMER PROFILE

PRD-required information:

- name
- email
- mobile
- address
- preferred language
- saved addresses
- basic verification

The mobile number is authenticated identity and should not be freely edited unless backend supports a secure change-number flow.

Profile operations:

```text
GET profile
UPDATE profile
GET verification/profile status
```

Do not invent verification requirements.

---

# 12. ADDRESS MANAGEMENT

Customer can maintain saved addresses.

Recommended conceptual model:

```text
Address
├── id
├── label
├── addressLine1
├── addressLine2
├── area
├── city
├── state
├── pincode
├── latitude (if backend supports)
├── longitude (if backend supports)
└── isDefault
```

The exact fields must follow the backend contract.

Operations:

```text
List addresses
Add address
Edit address
Delete address
Set default
Select for requirement
```

Address selection is connected to service discovery and matching.

---

# 13. HOME

The Home screen is a navigation/orchestration surface.

It should allow quick access to:

- Find a worker
- Current/active booking
- Upcoming interview/trial
- Service history
- Shortlist
- Support
- Notifications

Do not create fake dashboard metrics if the backend does not provide them.

---

# 14. SERVICE DISCOVERY FLOW

This is the beginning of the marketplace transaction.

Customer creates a service requirement using:

1. Service category
2. Engagement type
3. Location
4. Preferred timing
5. Start date
6. Salary/budget where applicable

Flow:

```text
Find Worker
  ↓
Select Category
  ↓
Select Engagement Type
  ↓
Select Address/Location
  ↓
Select Timing
  ↓
Select Start Date
  ↓
Enter Budget if applicable
  ↓
Review Requirement
  ↓
Search
```

The PRD explicitly requires these discovery inputs.

---

# 15. SERVICE CATEGORY

V1 categories:

- House Maid
- Driver
- Cook
- Babysitter
- Elderly Care Helper
- Cleaning Helper

Categories should come from backend/admin configuration rather than being permanently hardcoded where practical.

Reason:

The PRD says future categories should be enabled through configurable admin masters without redesigning the app.

Flutter should therefore treat category data as server-driven.

---

# 16. ENGAGEMENT TYPES

Supported PRD options:

- Full-time
- Part-time
- Daily
- Hourly
- Live-in

The UI must not display unsupported combinations without backend/product approval.

Example:

```text
Category = Maid
Engagement = Part-time
```

The valid engagement options may depend on category if the backend provides that relationship.

---

# 17. LOCATION

Location can be selected from saved addresses or entered through the approved location flow.

Do not force GPS permission if it is not necessary.

If maps/location services are integrated:

- request permissions only when needed
- handle denial gracefully
- provide manual address entry
- never block the entire app because location permission is denied

---

# 18. TIMING

Customer selects preferred service timing.

The exact UX may be:

- start/end time
- shift
- day selection
- recurring preference

But do not invent a final recurrence model until product/backend contract defines it.

The requirement is that the customer specifies preferred timings.

---

# 19. START DATE

Customer selects desired start date.

Validate:

- valid date
- backend accepted range
- no impossible past date unless explicitly supported

The backend remains authoritative.

---

# 20. BUDGET

Budget/salary range is applicable where relevant.

Do not assume every category requires the same budget model.

Example:

```text
Min budget
Max budget
Currency = INR
```

Final pricing/fee rules are not fixed by the PRD.

---

# 21. SEARCH / MATCHING

After requirement submission:

```text
Flutter
  ↓
Search API
  ↓
Backend Matching/Search Service
  ↓
Eligible Workers
  ↓
Flutter Worker Results
```

The PRD requires search and matching.

Do not implement an AI matching engine in V1.

The PRD explicitly places a complex AI recommendation engine out of scope.

---

# 22. WORKER RESULT LIST

Worker cards should show PRD-required information:

- profile photo
- experience
- skills
- language
- area
- availability
- verification badge
- rating
- review summary
- favourite control

Each card must be resilient to:

- missing image
- missing optional fields
- long names
- no reviews
- no rating
- loading
- stale data
- worker becoming unavailable

Never crash because an optional backend field is null.

---

# 23. SEARCH PAGINATION

Search results should use backend-supported pagination.

Preferred behavior:

```text
First page
  ↓
Scroll
  ↓
Load next page
  ↓
Append
```

Do not load an unbounded worker list.

If backend uses cursor pagination, follow cursor semantics rather than converting it into page numbers.

---

# 24. SEARCH FILTERS

PRD-supported filters/criteria include:

- category
- engagement
- location
- availability
- budget where applicable

Do not add unsupported filters as mandatory requirements.

Filters must preserve the original service requirement unless the user explicitly changes them.

---

# 25. EMPTY SEARCH STATE

If no suitable worker exists:

Do NOT display fake workers.

Show:

- clear empty state
- current search criteria
- option to modify criteria
- option to retry

Potential guidance:

```text
No matching workers found.
Try changing your area, timing or engagement type.
```

Do not promise availability.

---

# 26. WORKER PROFILE

Worker detail screen should present:

```text
Profile photo
Name/approved display identity
Verification indicator
Experience
Skills
Languages
Area
Availability
Rating/reviews
```

Do not expose:

- Aadhaar number
- full KYC document
- private verification documents
- internal admin remarks
- sensitive worker data

The PRD explicitly prohibits public exposure of full identity documents.

---

# 27. VERIFICATION BADGE

The badge must reflect backend verification status.

Never derive:

```text
documentUploaded == true
```

as:

```text
verified == true
```

Verification requires configured checks and authorized approval.

Use backend status.

---

# 28. FAVOURITES / SHORTLIST

Operations:

```text
Add favourite
Remove favourite
List favourites
```

Optimistic UI may be used only if rollback is implemented.

If the API fails:

```text
Favourite icon
  ↓
rollback
  ↓
error feedback
```

Do not leave the UI claiming a favourite exists when the server rejected it.

---

# 29. INTERVIEW / TRIAL

Customer can request an interview/trial.

Flow:

```text
Worker Profile
  ↓
Request Interview/Trial
  ↓
Select preferred date/time
  ↓
Submit
  ↓
Backend
  ↓
Interview/Trial record
  ↓
Status returned
```

The PRD explicitly requires preferred date/time and interview/trial scheduling.

---

# 30. INTERVIEW STATE

The exact backend statuses are TBD unless API contract defines them.

The UI should be state-driven.

Conceptual states:

```text
Requested
Pending
Scheduled
Completed
Cancelled
Rejected
```

Do not hardcode these names if the backend provides different enum values.

Create a mapper from backend status → presentation state if necessary.

---

# 31. TRIAL FLOW

Where applicable:

```text
Interview
  ↓
Trial
  ↓
Outcome
  ↓
Customer decision
```

The trial must be represented as a business state, not merely a static screen.

---

# 32. WORKER CONFIRMATION

After customer selects a worker:

```text
Review worker
  ↓
Confirm
  ↓
Backend validates
  ↓
Booking/payment flow
```

Backend may reject confirmation because:

- worker unavailable
- booking conflict
- requirement invalid
- worker status changed
- payment requirement
- business rule failure

Flutter must display backend error gracefully.

Never assume the worker remains available because they were available five minutes ago.

---

# 33. BOOKING

Booking is the central transaction.

Conceptually:

```text
Booking
├── id
├── customer
├── worker
├── requirement
├── service category
├── engagement
├── date(s)
├── status
└── payment relation
```

Actual DTO fields must follow backend contract.

---

# 34. BOOKING STATE MACHINE

The PRD defines the business sequence:

```text
New Request
  ↓
Match
  ↓
Interview
  ↓
Trial
  ↓
Confirm
```

and also supports:

```text
Cancel
Replace
```

A logical customer-facing lifecycle can be:

```text
REQUESTED
  ↓
MATCHED
  ↓
INTERVIEW_SCHEDULED
  ↓
TRIAL
  ↓
CONFIRMED
  ↓
ACTIVE
  ↓
COMPLETED
```

Potential alternate states:

```text
CANCELLED
REJECTED
REPLACEMENT_REQUESTED
```

These are conceptual mappings only. Use backend enums as the source of truth.

---

# 35. BOOKING DETAILS

Customer should be able to see:

- worker
- service
- location
- date/time
- engagement type
- status
- payment status where applicable
- timeline
- support action
- replacement action when eligible
- rating action when eligible

Do not show actions merely because the screen exists. Action visibility must depend on backend eligibility/state.

---

# 36. BOOKING TIMELINE

The PRD explicitly requires a booking status timeline.

Use a reusable timeline component.

Example:

```text
✓ Request Created
│
✓ Worker Matched
│
✓ Interview Scheduled
│
✓ Worker Confirmed
│
○ Service Started
│
○ Service Completed
```

The actual timeline events must come from backend when possible.

---

# 37. PAYMENT

Supported methods:

- UPI
- Cards
- Net banking

Possible providers:

- Razorpay
- Cashfree
- PayU

Provider selection is a project configuration decision.

Flutter should use an abstraction such as:

```text
PaymentService
```

rather than scattering provider-specific logic throughout screens.

---

# 38. PAYMENT FLOW

Correct conceptual flow:

```text
Customer confirms booking
  ↓
Backend creates payment/order
  ↓
Flutter receives payment initiation data
  ↓
Payment SDK/UI
  ↓
Customer completes payment
  ↓
Gateway result
  ↓
Backend verifies payment
  ↓
Booking/payment state updated
  ↓
Flutter fetches/receives final state
```

Never treat a local SDK success callback as the final authoritative payment state.

---

# 39. PAYMENT STATES

UI should support backend states such as:

```text
PENDING
PROCESSING
SUCCESS
FAILED
REFUND_PENDING
REFUNDED
```

Actual enum values must come from backend.

Handle:

- user cancellation
- payment timeout
- gateway error
- network loss
- duplicate callback
- app termination during payment
- backend verification delay

Payment callbacks must be idempotently handled.

---

# 40. RECEIPTS AND TRANSACTIONS

Customer needs:

- payment receipt
- transaction history
- refund status where applicable

Transaction screen should not fabricate amounts.

Always display backend-provided amount/currency/status.

---

# 41. ACTIVE SERVICE

After booking becomes active:

```text
Booking
  ↓
Active Service
```

Customer can access:

- current worker
- service details
- status/attendance visibility
- support
- rating when eligible
- replacement when eligible
- service history

---

# 42. ATTENDANCE / STATUS

V1 requires attendance/status visibility.

V1 does NOT require facial-recognition attendance.

Do not build face recognition.

GPS/geofenced attendance is a future roadmap feature unless separately approved.

The Customer App should display whatever status the backend actually provides.

---

# 43. SERVICE HISTORY

Service history should include previous eligible engagements.

Conceptual:

```text
Current
  └── Active Service

Past
  ├── Completed
  ├── Cancelled
  └── Replaced
```

Do not create client-side history from cached screens only. Use backend history as source of truth.

---

# 44. RATING / REVIEW

Ratings are tied to completed/eligible engagements.

Flow:

```text
Completed booking
  ↓
Backend says rating eligible
  ↓
Show rating action
  ↓
Customer submits rating/review
  ↓
Backend validates
  ↓
Success
```

Never allow duplicate ratings if backend prohibits them.

The app should support:

- loading
- submit
- success
- failure
- already rated

Exact rating scale and review constraints must follow backend/product definition.

---

# 45. REPLACEMENT

Replacement is a first-class workflow.

Customer action:

```text
Active Service
  ↓
Request Replacement
  ↓
Reason
  ↓
Supporting notes
  ↓
Submit
```

Backend then handles:

```text
Admin/Support review
  ↓
Eligibility
  ↓
Current engagement update
  ↓
Alternative matching
  ↓
Customer selects replacement
  ↓
New worker confirmed
```

Customer App MUST NOT directly force a replacement.

---

# 46. REPLACEMENT UI STATES

Conceptual:

```text
No replacement request
Replacement requested
Under review
Approved
Alternatives available
Replacement selected
Replacement confirmed
Rejected
Closed
```

Use backend state mapping.

The customer must retain historical visibility of the previous engagement.

---

# 47. SUPPORT / COMPLAINTS

Customer can create support requests.

Possible categories should be backend/configuration driven.

A ticket conceptually contains:

```text
Ticket
├── id
├── category
├── priority
├── status
├── owner/assignment
├── description
├── related booking
└── resolution
```

The PRD defines category, priority, owner and resolution.

---

# 48. SUPPORT FLOW

```text
Customer
  ↓
Create Ticket
  ↓
Backend
  ↓
Support Executive
  ↓
Investigation
  ↓
Resolution
  ↓
Ticket Closed
  ↓
Customer sees updated status
```

Customer should not be able to change internal owner/escalation fields.

---

# 49. NOTIFICATIONS

Supported notification channels:

- Push
- SMS
- optional WhatsApp

Flutter primarily consumes push notifications.

Notification examples may include:

- OTP
- interview update
- booking update
- payment update
- replacement update
- support ticket update

The final event/template list must be agreed with backend/product.

---

# 50. DEEP LINKING / NOTIFICATION ROUTING

When a push notification is tapped:

```text
Notification
  ↓
Determine event/type
  ↓
Open relevant entity
  ↓
Fetch latest backend state
  ↓
Render current state
```

Never trust notification payload as the complete source of truth.

Example:

```text
bookingId = 123
```

The app should open booking details and fetch booking 123.

---

# 51. ERROR HANDLING

Every API-driven screen must handle:

### Loading

Use skeleton/progress appropriate to context.

### Empty

Explain what is empty and what action can be taken.

### Error

Provide understandable message and retry.

### Unauthorized

Clear session and route to login if token/session is invalid.

### Forbidden

Show access restriction.

### Validation

Show field-level errors when possible.

### Network failure

Do not display "booking failed" when only connectivity is uncertain unless backend confirms failure.

---

# 52. OFFLINE / POOR NETWORK

The primary launch market includes mobile users and the PRD requires usability under normal mobile network conditions.

The app should:

- avoid unnecessary payloads
- cache safe read-only data where appropriate
- preserve form state during transient errors where safe
- show retry
- avoid duplicate submissions
- use idempotency for sensitive mutation flows when backend supports it

Never cache sensitive KYC/payment secrets insecurely.

---

# 53. SECURITY REQUIREMENTS

Must support:

- HTTPS
- secure token/session storage
- role-aware backend authorization
- no public KYC document access
- sensitive data masking
- safe logging
- rate-limited OTP/API interaction on backend
- secure secret handling
- production monitoring
- backup/recovery handled by backend/cloud

Flutter must never contain:

- payment secret keys
- backend private credentials
- database credentials
- admin credentials
- API provider secret keys

Public client keys may be present only when designed for client-side use.

---

# 54. PRIVACY

The Customer App may process:

- phone number
- name
- email
- address
- location
- booking history
- payment references
- support information
- ratings/reviews

Use minimum necessary access.

Do not expose another customer's data.

Do not expose worker private KYC data.

Terms, privacy policy, consent and retention/deletion requirements must be legally reviewed before production.

---

# 55. ACCESSIBILITY / USABILITY

Customer App should:

- use readable typography
- provide sufficient touch targets
- support dynamic content lengths
- avoid text overflow
- provide semantic labels where useful
- handle localization-ready strings
- avoid hardcoded user-facing strings
- provide clear errors
- avoid overly complex flows

Worker App has an explicit large-button/local-language requirement; Customer App should still be accessible but must not copy worker UX blindly.

---

# 56. LOCALIZATION READINESS

Even if V1 launches primarily in English:

Do:

```text
AppLocalizations
```

or project-approved localization architecture.

Do NOT scatter:

```dart
Text("Find Worker")
```

throughout business screens if the project has localization support.

Use keys such as:

```text
find_worker
request_interview
confirm_booking
payment_success
replacement_request
```

Future roadmap includes Telugu, Hindi and other languages.

---

# 57. DESIGN SYSTEM

The Customer App must use one consistent design system.

Centralize:

- colors
- typography
- spacing
- radii
- shadows
- buttons
- input fields
- cards
- chips
- badges
- dialogs
- bottom sheets
- loading states
- empty states
- error states

Do not create a new button/card style for every screen.

Brand-specific visual values should be taken from approved SevaNest design assets when available.

---

# 58. NAVIGATION

Use a typed/centralized routing solution approved by the project.

Do not scatter navigation strings everywhere.

Conceptual route groups:

```text
/auth
/home
/profile
/addresses
/discover
/workers
/workers/:id
/favourites
/interviews
/bookings
/bookings/:id
/payments
/services/current
/services/history
/ratings
/replacements
/support
/notifications
/transactions
```

These route names are implementation suggestions and may be changed to match the existing project.

---

# 59. BACK NAVIGATION RULES

Important:

- Do not lose partially completed service requirements accidentally.
- Do not leave payment flow with stale state.
- Do not allow back navigation to create duplicate booking operations.
- After successful irreversible actions, route to the correct state rather than replaying mutation.
- Refresh backend state when returning to sensitive transactional screens.

---

# 60. DATA MODEL RULE

Use separate concepts for:

- UI model
- API DTO
- domain entity

Where the project complexity justifies it.

Never let raw JSON maps spread across the entire presentation layer.

Example:

```text
API JSON
  ↓
DTO
  ↓
Mapper
  ↓
Domain Entity
  ↓
State
  ↓
UI
```

For small simple payloads, avoid unnecessary boilerplate, but preserve type safety.

---

# 61. API CLIENT RULES

Centralize:

- base URL
- headers
- authentication
- timeout
- serialization
- error mapping
- refresh/session handling
- logging controls

Every API request must have:

- typed request model where appropriate
- typed response model where appropriate
- predictable error mapping
- cancellation strategy where appropriate

Do not directly call HTTP clients from widgets.

Preferred:

```text
Screen
 ↓
Controller/Notifier
 ↓
Use Case
 ↓
Repository
 ↓
Remote Data Source
 ↓
API Client
```

---

# 62. API CONTRACT DISCIPLINE

When backend API documentation is provided:

1. Read it before implementing the feature.
2. Use exact endpoint.
3. Use exact HTTP method.
4. Use exact request field names.
5. Use exact response field names.
6. Use exact enums.
7. Respect pagination.
8. Respect authentication.
9. Respect error formats.
10. Do not create fake endpoints.

If backend contract differs from this document, backend contract plus approved product decision wins.

---

# 63. MOCK DATA RULE

Mock data may be used only for:

- initial UI development
- Storybook/demo-like development
- tests
- explicit development fallback

Mock data must NOT silently replace production API calls.

Use an explicit abstraction:

```text
Repository
 ├── Remote implementation
 └── Mock implementation
```

Production configuration must point to the real implementation.

---

# 64. NO FAKE SUCCESS

Never implement:

```text
onTap:
  showSuccess()
```

without completing the actual operation.

For example:

```text
Confirm Booking
```

must not show:

> Booking confirmed!

until the backend confirms the booking.

The same rule applies to:

- payments
- favourites
- interviews
- replacement
- ratings
- support tickets
- profile updates

---

# 65. IDEMPOTENCY / DUPLICATE ACTIONS

For mutations:

- disable submit button while request is in progress
- protect against double taps
- restore button on failure
- refresh authoritative state after success

For payment/booking operations, use backend-supported idempotency mechanisms where available.

---

# 66. ANALYTICS

If analytics is approved:

Track business events without sensitive personal data.

Possible events:

```text
login_started
login_success
profile_completed
service_search_started
worker_viewed
worker_favourited
interview_requested
trial_requested
booking_confirmed
payment_started
payment_success
payment_failed
service_viewed
rating_submitted
replacement_requested
support_ticket_created
```

Analytics implementation must not leak:

- Aadhaar
- payment credentials
- private addresses unnecessarily
- OTP
- tokens
- secrets

---

# 67. TESTING STRATEGY

Every feature must have tests at appropriate levels.

## Unit tests

Test:

- validators
- mappers
- state transitions
- use cases
- business display logic
- error mapping

## Repository/API tests

Test:

- request creation
- response parsing
- errors
- pagination
- auth failure
- null/optional fields

## Widget tests

Test:

- rendering
- validation
- button behavior
- loading
- empty
- error
- success

## Integration/E2E

Test the critical customer journeys.

---

# 68. MANDATORY END-TO-END TEST FLOWS

At minimum:

### Flow A — New customer

```text
Launch
→ Login
→ OTP
→ Profile Setup
→ Home
```

### Flow B — Search

```text
Home
→ Find Worker
→ Category
→ Engagement
→ Location
→ Timing
→ Start Date
→ Budget
→ Search
→ Results
→ Worker Profile
```

### Flow C — Favourite

```text
Worker Profile
→ Favourite
→ Favourites
→ Worker visible
→ Unfavourite
```

### Flow D — Interview

```text
Worker Profile
→ Request Interview
→ Select Date/Time
→ Submit
→ Verify status
```

### Flow E — Booking

```text
Interview/Trial
→ Confirm Worker
→ Booking
→ Payment
→ Backend confirmation
→ Booking Details
```

### Flow F — Payment failure

```text
Booking
→ Payment
→ Failure
→ Retry
→ No duplicate booking
```

### Flow G — Active service

```text
Confirmed Booking
→ Active Service
→ Status/Attendance
→ Service History
```

### Flow H — Rating

```text
Completed Eligible Booking
→ Rating
→ Submit
→ Success
```

### Flow I — Replacement

```text
Active Service
→ Replacement
→ Reason
→ Submit
→ Status
→ Alternatives
→ Select Replacement
```

### Flow J — Support

```text
Support
→ Create Ticket
→ Submit
→ Ticket Details
→ Status Update
```

---

# 69. ACCESSIBILITY AND RESPONSIVENESS TEST MATRIX

Test at minimum across:

- small Android phone
- standard Android phone
- large Android phone
- small iPhone
- standard iPhone
- large iPhone

Test:

- long worker names
- long addresses
- long service names
- missing profile image
- no reviews
- large text
- keyboard open
- network slow
- network disconnected
- orientation behavior according to product decision

---

# 70. PERFORMANCE

Customer App should:

- paginate worker results
- avoid unnecessary rebuilds
- cache safe images
- optimize image sizes
- avoid huge JSON payloads
- avoid repeated identical API calls
- debounce search where appropriate
- cancel obsolete requests
- avoid loading all history at once
- use lazy lists

Do not optimize prematurely at the cost of correctness.

---

# 71. IMAGE HANDLING

Worker images and profile media must:

- show placeholders
- handle failed loading
- use appropriate cache strategy
- avoid leaking private document URLs
- not expose KYC documents

KYC files must remain private.

---

# 72. LOGGING

Development logs may include:

- endpoint
- request ID
- status code
- timing

Never log:

- OTP
- access token
- refresh token
- payment credentials
- Aadhaar number
- full private address unnecessarily
- private document URLs

Production logging must be appropriately reduced/redacted.

---

# 73. ENVIRONMENT CONFIGURATION

Separate:

```text
development
staging
production
```

Configuration should include only non-secret client-safe values.

Secrets belong in secure backend/infrastructure configuration.

Never commit:

```text
.env
private keys
API secrets
payment secret keys
service account credentials
```

unless the project explicitly uses a safe secret-management mechanism.

---

# 74. CI/CD EXPECTATIONS

Before merging:

```text
flutter pub get
flutter format/check
flutter analyze
flutter test
```

plus project-specific checks.

For release:

- debug build
- staging build
- release build
- Android verification
- iOS verification
- signing configuration
- crash monitoring
- environment verification

---

# 75. RELEASE CHECKLIST

Before Customer App release:

## Authentication

- [ ] OTP works
- [ ] invalid OTP handled
- [ ] expired OTP handled
- [ ] session persistence works
- [ ] logout works
- [ ] expired session redirects correctly

## Profile

- [ ] profile creation
- [ ] profile update
- [ ] address management
- [ ] validation

## Discovery

- [ ] categories load from backend
- [ ] engagement options correct
- [ ] search works
- [ ] pagination works
- [ ] filters work
- [ ] empty state works

## Worker

- [ ] profile works
- [ ] verification badge correct
- [ ] rating/reviews correct
- [ ] favourite works

## Interview

- [ ] request
- [ ] date/time
- [ ] status
- [ ] cancellation behavior if supported

## Booking

- [ ] confirmation
- [ ] state timeline
- [ ] cancellation if supported
- [ ] active state
- [ ] history

## Payment

- [ ] payment initiation
- [ ] success
- [ ] failure
- [ ] retry
- [ ] refund status
- [ ] receipt
- [ ] transaction history

## Service

- [ ] status
- [ ] attendance visibility
- [ ] history
- [ ] rating eligibility

## Replacement

- [ ] request
- [ ] reason
- [ ] status
- [ ] alternatives
- [ ] selection

## Support

- [ ] create ticket
- [ ] ticket list
- [ ] ticket details
- [ ] status

## Notifications

- [ ] device registration
- [ ] foreground
- [ ] background
- [ ] tap/deep link
- [ ] latest state refresh

---

# 76. DEVELOPMENT ORDER

Do NOT randomly build screens.

Recommended implementation order:

## Phase 1 — Foundation

1. Flutter project structure
2. Environment configuration
3. Theme/design system
4. Routing
5. API client
6. Secure storage
7. Error system
8. Shared components
9. App bootstrap

## Phase 2 — Authentication

10. Splash
11. Login
12. OTP
13. Session management
14. Logout
15. Profile completion routing

## Phase 3 — Customer

16. Profile
17. Addresses
18. Home

## Phase 4 — Discovery

19. Categories
20. Engagement type
21. Location
22. Timing
23. Start date
24. Budget
25. Search
26. Filters
27. Worker cards
28. Worker details
29. Favourites

## Phase 5 — Interview/Trial

30. Interview request
31. Scheduling
32. Interview details
33. Trial state

## Phase 6 — Booking

34. Confirmation
35. Booking details
36. Booking timeline
37. Booking list
38. Cancellation where supported

## Phase 7 — Payment

39. Payment abstraction
40. Payment initiation
41. Gateway
42. Verification state
43. Receipts
44. Transactions
45. Refund status

## Phase 8 — Active Service

46. Current service
47. Status/attendance visibility
48. Service history
49. Rating

## Phase 9 — Replacement

50. Replacement request
51. Replacement status
52. Alternative workers
53. Replacement selection

## Phase 10 — Support/Notifications

54. Support tickets
55. Ticket details
56. Notifications
57. Deep links

## Phase 11 — Hardening

58. Unit tests
59. Widget tests
60. Integration tests
61. Regression
62. Performance
63. Security
64. Device testing
65. Release build

---

# 77. MODULE COMPLETION CRITERIA

A module is NOT complete just because the screen looks correct.

A module is complete only when:

```text
UI
+
State management
+
API integration
+
Validation
+
Loading
+
Empty
+
Error
+
Success
+
Navigation
+
Security
+
Tests
+
Regression
```

are complete.

Example:

A Worker Search module is not complete if only the worker cards exist.

It must also have:

- search request
- pagination
- loading
- empty
- errors
- filters
- retry
- worker detail navigation
- favourite integration
- stale-state handling
- tests

---

# 78. BACKEND DEPENDENCY TRACKER

Maintain a live list of dependencies.

Example:

| Customer Feature | Backend Dependency |
|---|---|
| OTP | Auth/OTP API |
| Profile | Customer API |
| Addresses | Address API |
| Categories | Category master API |
| Search | Matching/Search API |
| Worker details | Worker API |
| Verification badge | Worker verification state |
| Favourite | Favourite API |
| Interview | Interview API |
| Trial | Trial API |
| Booking | Booking API |
| Payment | Payment gateway + payment API |
| Status | Booking/service API |
| Rating | Rating API |
| Replacement | Replacement API |
| Support | Ticket API |
| Notifications | Notification API |
| Transactions | Payment/transaction API |

Do not block frontend progress unnecessarily. If an API is unavailable, use a clearly isolated mock repository for development and replace it when the contract is available.

---

# 79. OPEN QUESTIONS TO TRACK

Create a project-level `OPEN_QUESTIONS.md` if one does not already exist.

Track at minimum:

1. Exact API contract.
2. Exact backend status enums.
3. Payment provider.
4. Exact booking fee.
5. Refund rules.
6. Cancellation rules.
7. Replacement eligibility.
8. Trial rules.
9. Matching algorithm.
10. Attendance implementation.
11. Verification provider.
12. Exact KYC fields visible to customer.
13. Exact rating scale.
14. Support SLA.
15. Notification event catalog.
16. Map provider.
17. Localization languages for V1.
18. Legal consent/terms UX.
19. Data retention/deletion UX.
20. Final design system/assets.

Never hide unresolved questions inside implementation assumptions.

---

# 80. BUSINESS RULES THAT MUST NOT BE BROKEN

1. Only backend-confirmed verified workers should be represented as verified.
2. Customer cannot directly approve worker KYC.
3. Customer cannot directly alter booking status.
4. Customer cannot directly force replacement.
5. Payment success must be backend verified.
6. Rating must respect eligibility.
7. Sensitive KYC documents must never be exposed.
8. Customer must not see another customer's private information.
9. Worker availability must be revalidated by backend.
10. Booking must be protected from duplicate submission.
11. Failed operations must not appear successful.
12. Admin-only functions must never be implemented as customer controls.
13. Future V2 features must not silently become V1 scope.

---

# 81. CUSTOMER APP / WORKER APP INTERCONNECTION

The two apps share backend entities.

Example:

```text
CUSTOMER
  |
  | Service Requirement
  v
BACKEND
  |
  | Matching
  v
WORKER
  |
  | Accepts Opportunity
  v
BACKEND
  |
  | Interview
  v
CUSTOMER
  |
  | Confirms
  v
BOOKING
  |
  v
PAYMENT
  |
  v
ACTIVE SERVICE
```

Do not implement direct device-to-device business communication.

---

# 82. CUSTOMER APP / ADMIN INTERCONNECTION

Admin actions can change what Customer sees.

Example:

```text
Customer submits support ticket
        ↓
Backend
        ↓
Support Executive
        ↓
Admin updates ticket
        ↓
Backend
        ↓
Customer sees status
```

Another example:

```text
Worker verification
        ↓
Verification Executive
        ↓
Approved
        ↓
Backend
        ↓
Customer worker profile displays verified status
```

Another:

```text
Admin changes booking state
        ↓
Backend
        ↓
Customer booking timeline changes
```

Flutter must refresh or receive state updates accordingly.

---

# 83. CUSTOMER APP / PAYMENT INTERCONNECTION

```text
Customer App
    ↓
Backend Payment Order
    ↓
Payment Provider
    ↓
Payment Result
    ↓
Backend Verification
    ↓
Booking/Payment State
    ↓
Customer App
```

Never skip backend verification.

---

# 84. CUSTOMER APP / NOTIFICATION INTERCONNECTION

```text
Business Event
   ↓
Backend
   ↓
Notification Service
   ↓
FCM/SMS/WhatsApp
   ↓
Customer
```

When a notification is opened:

```text
Notification
  ↓
Route to entity
  ↓
Fetch latest backend state
  ↓
Render current state
```

---

# 85. CUSTOMER APP / MAPS INTERCONNECTION

Maps are used conceptually for location/search/service area.

Possible uses:

- address selection
- location search
- distance/service-area context

Exact map provider is not fixed; PRD recommends Google Maps or another provider.

Do not couple the entire domain layer directly to Google Maps SDK.

Use a location abstraction.

---

# 86. IMPORTANT UI STATES FOR EVERY SCREEN

Every API-backed screen should consider:

### Initial
Nothing loaded.

### Loading
Request running.

### Success
Data displayed.

### Empty
Request succeeded but no data.

### Error
Request failed.

### Retry
User can retry.

### Offline
No connection.

### Unauthorized
Session invalid.

### Forbidden
Operation not allowed.

### Stale
Previously loaded data exists but refresh failed.

Use these states consistently.

---

# 87. FORM VALIDATION

Validation should exist at:

1. UI level for immediate feedback.
2. Backend level for authoritative validation.

Never assume client-side validation is security.

Example:

```text
Customer enters start date
 ↓
Flutter validates basic format
 ↓
Backend validates business rule
```

---

# 88. DRAFT SERVICE REQUIREMENT

For a multi-step discovery flow, preserve temporary form state while navigating between steps.

Example:

```text
Category
 ↓
Engagement
 ↓
Location
 ↓
Timing
 ↓
Date
 ↓
Budget
```

Back navigation should preserve entered values.

If the customer exits, decide whether to discard or persist the draft based on product decision. Do not silently persist sensitive information indefinitely.

---

# 89. PAGINATION AND REFRESH

Use:

- pull-to-refresh where useful
- pagination for long lists
- refresh after mutation
- invalidate relevant cached state

Example:

```text
Favourite worker
  ↓
Invalidate Worker Details
Invalidate Favourite List
Potentially invalidate Search Result
```

Do not blindly refresh the entire application after every action.

---

# 90. CACHING

Safe candidates:

- service categories
- non-sensitive configuration
- recently viewed public worker data where approved

Do not cache sensitive:

- OTP
- tokens outside secure storage
- payment secrets
- private KYC documents
- sensitive personal data without a clear policy

---

# 91. CODE QUALITY RULES

- Strong typing.
- Null safety.
- No giant widgets.
- No business logic inside UI widgets.
- No duplicated API logic.
- No magic strings for statuses.
- No magic numbers for business rules.
- No hardcoded production URLs.
- No ignored analyzer errors.
- No commented-out dead code.
- No unnecessary dependencies.
- No debug prints in production.
- No secrets in source control.

---

# 92. FLUTTER PERFORMANCE RULES

- Prefer `const` where appropriate.
- Use lazy lists.
- Avoid unnecessary rebuilds.
- Keep images optimized.
- Dispose controllers/listeners.
- Cancel requests where appropriate.
- Avoid nested expensive layouts.
- Avoid loading huge lists into memory.
- Profile before making speculative optimizations.

---

# 93. AGENT WORKING METHOD

Before changing code:

### Step 1
Inspect repository structure.

### Step 2
Read existing architecture.

### Step 3
Find existing navigation/state/API conventions.

### Step 4
Identify related feature implementation.

### Step 5
Read backend API contract if available.

### Step 6
Map requirement → screen → state → API → entity.

### Step 7
Implement smallest coherent change.

### Step 8
Run formatter/analyzer/tests.

### Step 9
Review edge cases.

### Step 10
Run regression.

### Step 11
Document unresolved questions.

### Step 12
Only then mark feature complete.

---

# 94. DO NOT OVERWRITE EXISTING WORK

Before modifying an existing module:

1. Understand why it exists.
2. Check its consumers.
3. Check tests.
4. Check navigation.
5. Check API dependencies.
6. Check whether another feature depends on its state.
7. Make the smallest safe change.

If a redesign is needed, preserve behavior unless the requirement explicitly changes it.

---

# 95. CHANGE MANAGEMENT

For every requirement change:

```text
Requirement
 ↓
Impact analysis
 ↓
Affected screens
 ↓
Affected API
 ↓
Affected state
 ↓
Affected tests
 ↓
Implementation
 ↓
Regression
```

Record significant changes.

Do not silently expand scope.

---

# 96. DEFINITION OF DONE — FEATURE

A feature is DONE only if:

- [ ] Requirement understood
- [ ] API contract confirmed
- [ ] Domain model created/updated
- [ ] Repository integrated
- [ ] State management implemented
- [ ] UI implemented
- [ ] Navigation implemented
- [ ] Loading handled
- [ ] Empty handled
- [ ] Error handled
- [ ] Validation handled
- [ ] Security checked
- [ ] Tests added
- [ ] Regression run
- [ ] Analyzer clean
- [ ] Formatting clean
- [ ] No mock production dependency
- [ ] Open questions documented

---

# 97. DEFINITION OF DONE — RELEASE

Release is DONE only if:

- [ ] All V1 customer requirements implemented
- [ ] Backend integrations verified
- [ ] Critical E2E journeys pass
- [ ] Payment tested in approved environment
- [ ] Notifications tested
- [ ] Android tested
- [ ] iOS tested
- [ ] Security review completed
- [ ] Sensitive information verified as protected
- [ ] Production configuration verified
- [ ] Crash/error monitoring active
- [ ] Regression passed
- [ ] UAT passed
- [ ] Release build generated
- [ ] Store assets ready
- [ ] Known issues documented
- [ ] Handover documentation completed

---

# 98. FINAL CUSTOMER APP WORKFLOW

The implementation must ultimately support this complete lifecycle:

```text
                         CUSTOMER APP
                              |
                              v
                        AUTHENTICATION
                              |
                              v
                       PROFILE / ADDRESS
                              |
                              v
                      SERVICE DISCOVERY
                              |
             +----------------+----------------+
             |                |                |
          CATEGORY       ENGAGEMENT         LOCATION
             |                |                |
             +----------------+----------------+
                              |
                           TIMING
                              |
                         START DATE
                              |
                           BUDGET
                              |
                              v
                       SEARCH / MATCHING
                              |
                              v
                       WORKER RESULTS
                              |
                     +--------+--------+
                     |                 |
                     v                 v
                 FAVOURITE        WORKER PROFILE
                                       |
                                       v
                              INTERVIEW / TRIAL
                                       |
                                       v
                                CONFIRM WORKER
                                       |
                                       v
                                   BOOKING
                                       |
                                       v
                                   PAYMENT
                                       |
                                       v
                               CONFIRMED BOOKING
                                       |
                                       v
                                ACTIVE SERVICE
                                       |
                      +----------------+----------------+
                      |                |                |
                      v                v                v
                   STATUS          SUPPORT           RATING
                      |                |                |
                      |                |                |
                      +----------------+----------------+
                                       |
                                  IF PROBLEM
                                       |
                                       v
                                  REPLACEMENT
                                       |
                                       v
                               ALTERNATIVE WORKERS
                                       |
                                       v
                              NEW WORKER CONFIRMED
```

---

# 99. FINAL AGENT DIRECTIVE

You are not merely building Flutter screens.

You are implementing a **transactional marketplace client**.

Every customer action has a business meaning.

Therefore always ask:

```text
What is the customer trying to accomplish?
        ↓
What backend entity represents it?
        ↓
What API performs the operation?
        ↓
What state does it create/change?
        ↓
What other modules depend on that state?
        ↓
What should the customer see?
        ↓
What happens if it fails?
        ↓
What happens if the network disappears?
        ↓
Can the action be duplicated?
        ↓
What security/privacy implications exist?
        ↓
What test proves the workflow works?
```

The goal is not:

> "Make the screen look correct."

The goal is:

> **"Implement the complete customer business workflow correctly, securely, testably and consistently with the SevaNest product requirements."**

---

# 100. REFERENCE REQUIREMENT SUMMARY

SevaNest V1 is a Hyderabad-first household workforce marketplace with Android/iOS customer and worker applications and a web admin portal.

Customer V1 capabilities include:

- OTP authentication
- profile
- saved addresses
- service selection
- engagement selection
- location/timing/start date/budget
- worker search/matching
- verified worker discovery
- worker profile
- favourites
- interview/trial
- booking
- payment
- booking status
- ongoing service
- attendance/status visibility
- service history
- rating/review
- replacement
- support/complaints
- notifications
- transaction history

The product must prioritize:

> **Trust + simplicity + transparent status + dependable replacement support.**

The V1 implementation must remain within approved scope and must not silently introduce future roadmap functionality.

---

## END OF AGENTS.MD
