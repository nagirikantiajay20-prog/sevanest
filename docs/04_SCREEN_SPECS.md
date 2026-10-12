# 04 — Screen Inventory & Specs (Customer App)

> Wireframe-level specs until design sign-off (M2). Each screen must implement all states from AGENTS §86: initial, loading, success, empty, error+retry, offline, unauthorized, forbidden, stale. Copy keys live in `app_en.arb`; the English text below is the *draft* copy.

## Navigation map
```
Splash → Login → OTP → [Profile Setup] → MainShell
MainShell tabs (TBD with design): Home | Bookings | Favourites | Account
Home → Find Worker flow → Results → Worker Detail → Interview → Confirm → Payment → Booking Detail
Booking Detail → Active Service / Rating / Replacement / Support
Account → Profile | Addresses | Transactions | Support | Notifications | Settings(logout, legal)
```

## Screen list

| # | Route | Screen | Key elements | Primary API |
|---|---|---|---|---|
| 1 | `/splash` | Splash | logo, loader | session + `GET /me` |
| 2 | `/login` | Login | +91 field, "Get OTP" | otp/request |
| 3 | `/otp` | OTP | code field, timer, resend, change number | otp/verify |
| 4 | `/profile/setup` | Profile setup | name, email, language, first address CTA | PUT profile |
| 5 | `/home` | Home | active booking card, "Find a worker" CTA, categories row, upcoming interview, shortlist | home/catalog |
| 6 | `/discover/category` | Category | grid of categories (server-driven) | categories |
| 7 | `/discover/engagement` | Engagement | radio cards (full-time, part-time, daily, hourly, live-in as allowed) | — |
| 8 | `/discover/location` | Location | saved addresses list, add new, use current location | addresses |
| 9 | `/discover/timing` | Timing | slot chips / time pickers | — |
| 10 | `/discover/start-date` | Start date | calendar | — |
| 11 | `/discover/budget` | Budget | min/max INR | — |
| 12 | `/discover/review` | Review requirement | summary, edit links, "Search" | — |
| 13 | `/workers` | Results | worker cards, filter button, sort(TBD), paginate | search |
| 14 | `/workers/:id` | Worker detail | photo, badge, stats, skills, languages, reviews, CTA bar | worker |
| 15 | `/favourites` | Shortlist | cards, remove | favourites |
| 16 | `/interviews/new` | Request interview/trial | date, time, note | interviews |
| 17 | `/interviews/:id` | Interview detail | status, schedule, actions, decision | interviews |
| 18 | `/bookings/confirm` | Confirm & pay | worker, fee breakdown, policy, Pay | quote/bookings |
| 19 | `/payments/:id` | Payment status | processing/success/failed/pending | payments |
| 20 | `/bookings` | Booking list | tabs Current/Past | bookings |
| 21 | `/bookings/:id` | Booking detail | timeline, actions | booking |
| 22 | `/services/current` | Active service | worker, attendance list, actions | attendance |
| 23 | `/services/history` | Service history | grouped list | history |
| 24 | `/ratings/:bookingId` | Rate worker | stars, comment | rating |
| 25 | `/replacements/new` | Request replacement | reason, notes | replacement |
| 26 | `/replacements/:id` | Replacement status / alternatives | status, alt cards | replacement |
| 27 | `/support` | Support home/list | tickets, "New ticket" | tickets |
| 28 | `/support/new` | New ticket | category, booking, description | tickets |
| 29 | `/support/:id` | Ticket detail | status, updates, resolution | tickets |
| 30 | `/transactions` | Transactions | list, refund chips | transactions |
| 31 | `/transactions/:id` | Receipt | amount, ref, status, download | transactions |
| 32 | `/notifications` | Notification centre | list, read state | notifications |
| 33 | `/account` | Account | profile, addresses, logout, legal links | — |

## Key component behaviours

**Worker card**
```
[photo] Name (1 line, ellipsis)       ♡
        ✔ Verified   ★ 4.6 (23)   | "New" if no reviews
        Maid · 5 yrs · Telugu, Hindi
        Madhapur · Available mornings
```
Missing photo → initials avatar; missing optional fields → row hidden; long name → ellipsis; Verified badge only when `verificationStatus == verified` from backend; "Verification in progress" for pending (copy TBD — do not show as verified).

**Booking timeline (`SnTimeline`)**: items `{title, subtitle?, timestamp?, state: done|current|upcoming|failed}` from backend; fallback template only when backend omits.

**Fee breakdown**: rows `{label, amount}` from quote; total bold; currency `₹` via intl; never compute totals client-side other than display formatting.

**Primary CTA rules**: single primary action per screen, sticky bottom, 48dp+, loading state disables, label changes ("Processing…").

**Status chips**: colour+icon+text (not colour alone). Unknown status → neutral grey "Updated".

## Copy tone
Simple, reassuring, no jargon. Examples: "No matching workers found. Try changing your area, timing or engagement type." / "We're confirming your payment. This usually takes a moment." / "This worker is no longer available. Let's find another."

## Accessibility per screen
Semantics labels for icon buttons (favourite, back, filter); error messages announced; tap targets ≥ 48dp; support text scale to 200% without clipping (use `Flexible`/`Wrap`).
