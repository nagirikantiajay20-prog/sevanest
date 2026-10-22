# Store listing notes (draft, needs product/legal review)

**Title:** SevaNest - Trusted Home Help
**Short description (80):** Find and hire verified home workers near you, with interviews and secure payment.
**Long description:** SevaNest helps you find verified home workers (cooks, cleaners, caretakers and more), meet them in an interview or trial, hire, pay securely and track the service. Replace a worker or reach support from the app.

## Data safety / privacy label (derived from the code)
| Data | Collected | Purpose | Shared |
| --- | --- | --- | --- |
| Phone number | Yes | Sign-in (OTP), account | No |
| Name, email | Yes (profile) | Account, bookings | With the assigned worker (name only) |
| Approximate/precise location | Yes, on request | Find workers in your area | No |
| Addresses | Yes | Service location | With the assigned worker |
| Push token (FCM) | Yes | Notifications | Google (FCM) |
| Payment | Via Razorpay | Booking payment; app stores no card data | Razorpay |
| Crash logs, app events | Yes (stg/prod) | Stability, funnel analytics, no PII | Google (Firebase) |
Data is encrypted in transit. Deletion: in-app request once enabled (see DECISIONS 2026-10-15).

## Screenshots checklist
Login, Home, Service discovery, Results, Worker profile, Interview request, Booking confirm, Payment, Active service, Support.

## Content rating
Utility/marketplace, no user-generated public content; expected: everyone/3+ (confirm via questionnaires).
