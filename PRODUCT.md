# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

Flutter app shipping to Android and iOS with one shared design language (confirmed). Recorded as `android` because iOS deliberately follows the same language rather than adapting per OS; revisit if iOS-native conventions are wanted.

## Stack
Existing Flutter codebase (Riverpod, go_router, dio, freezed, FCM, Razorpay behind `PaymentService`); see `docs/02_TECH_STACK_AND_SETUP.md`.

## Users
Urban households in Hyderabad (launch market) hiring domestic help: first-time and repeat hirers who are time-pressed and cautious about trusting a stranger into their home.

## Product Purpose
SevaNest ("Verified Help. Trusted Homes.") is a marketplace connecting customers with verified household workers: cooks, maids, drivers, elder-care helpers and similar. The customer builds a requirement, discovers workers, requests an interview/trial, pays, books, and gets support or replacement when needed. Success: a customer reaches a trusted hire in few steps and feels covered afterwards.

## Positioning
Verified workers, an interview/trial before commitment, dependable replacement support, and fees shown before payment.

## Operating Context
Mobile-first, used in short sessions. Flow: Splash, Login/OTP, profile setup, Home, requirement builder (service, engagement, location, timing, start date, budget), worker results and detail, shortlist or interview request, pay, booking and active service, replacement/support. Backend supplies statuses, fees, refund text and replacement eligibility; the app renders them rather than hardcoding rules.

## Capabilities and Constraints
- Android + iOS, Flutter; phone format +91, currency in rupees.
- English plus Hindi/Telugu localisation (l10n in repo).
- Backend-driven statuses, quotes and allowed actions; many product rules still open (see `OPEN_QUESTIONS.md`: fees, refunds, trial rules, what "verified" means).
- Do not copy competitor branding, assets or copy.

## Brand Commitments
Visual tokens in `design/tokens.md` (teal action `#0F766E`, navy ink `#1E3A5F`, slate neutrals, extracted from the Figma prototype) are binding. Tagline: "Verified Help. Trusted Homes."

## Evidence on Hand
Design screens in `design/screens`, `design/SCREENS.md`, market research in `docs/01_MARKET_RESEARCH.md`, module specs in `docs/modules/`. No real testimonials or verified-count statistics are on hand; do not fabricate them.

## Product Principles
1. Trust cues (verification badge, what "verified" means) appear at every decision point.
2. Few steps to a shortlist; pre-fill what returning users already told us.
3. Show fees and status in plain language before and after payment.
4. Replacement and support are always reachable from an active service.
5. Render backend truth; never invent rules in the client.

## Accessibility & Inclusion
Multilingual users (English, Hindi, Telugu); 44pt touch targets, labels, dynamic type and sufficient contrast.
