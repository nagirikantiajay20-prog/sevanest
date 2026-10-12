# 01 — Market Research & Reference-App Analysis (Customer App)

> Purpose: ground SevaNest Customer App UX decisions in what public Indian household-help apps already do.
> Confidence: sources are app-store listings, press and design case studies. Facts marked **(unverified)** must be re-checked by installing the app. Do NOT copy proprietary branding/assets/copy — borrow patterns only.
> Date researched: 2026-10-08.

## 1. Reference apps

| App | Model | Patterns worth borrowing | Patterns to avoid / not applicable |
|---|---|---|---|
| **Urban Company** | Scheduled home services marketplace | Address pre-selected for returning users; provider + time slot merged into one step (from a public 3 Sided Coin checkout case study); trust messaging at checkout | Per-visit service-catalogue model; SevaNest is staff-hiring, not per-visit SKU |
| **Snabbit** | 10-minute on-demand house help, hourly | OTP login → location → service pick; hourly bookings up to 4h; reschedule window up to 30 min before start (self-reported); "share OTP to start job" safety pattern; police/ID-verified messaging | Instant dispatch is V2+; SevaNest V1 is interview/trial-first |
| **Pronto** | 10-minute on-demand, recurring schedules | Choose tasks → describe home → instant / scheduled / custom recurring; price shown before booking, no hidden fees | Gig-shift worker model; not V1 |
| **Bookmybai** | Maid-hiring directory/agency | Worker profile card (photo, age, experience, native place); "priority/verified" tag; location radius search (~3 km); video interview for live-in; direct-contact packs; replacement guarantee (2015 press: 6 months — **unverified, historical**) | Pay-to-contact packs; agency hand-off |
| **Housejoy / similar** | Home services | Booking timeline, receipts | — |

## 2. Cross-cutting UX patterns to adopt

1. **Few-step requirement builder.** One question per screen, progress indicator, back preserves state (matches AGENTS §14, §88).
2. **Returning-user shortcut.** Pre-select default address and last category; skip steps the backend already knows.
3. **Trust at point of decision.** Verification badge, "what verified means" bottom sheet, rating count, replacement-support note on worker profile and checkout.
4. **Price/fee transparency before payment.** Fee breakdown screen; amounts come only from backend (AGENTS §40). Fee values are admin-configurable (PRD §10).
5. **Status timeline.** Vertical timeline on booking detail; every state has plain-language copy.
6. **Safety affordances.** Report/Block, Support shortcut on active service, no raw KYC exposure (PRD §9.1).
7. **Reschedule/cancel visible with rules.** Show rule text from backend (cancellation/refund policy is TBD — do not hardcode).
8. **OTP-at-door / start-code (optional, V2 candidate).** Snabbit-style; NOT V1 unless approved.
9. **Notification-driven re-entry.** Tap → entity screen → refetch (AGENTS §50).

## 3. SevaNest differentiators the UI must express

- Hiring (recurring employment) not just visits → *interview/trial* is a first-class step.
- *Replacement support* is a headline promise → always reachable from Active Service.
- *Verified* is earned, never inferred → badge from backend only.

## 4. Market / user context (Hyderabad)

- Target customers: apartment/gated-community households in HITEC City, Madhapur, Kondapur, Gachibowli, Kukatpally (PRD §22).
- Mobile-first, UPI-dominant payments, mixed English/Telugu/Hindi usage → i18n-ready from day 1 (ARB files, no hardcoded strings), V1 ship English unless product approves more.
- Mid-range Android is the majority device class → budget performance (see doc 02 §7), test on low-RAM device.

## 5. Sources
- [Urban Company checkout redesign case study](https://thehardcopy.co/?p=6215)
- [Snabbit App Store listing](https://apps.apple.com/app/id6575381655)
- [Pronto App Store listing](https://apps.apple.com/in/app/pronto-house-help-in-10-mins/id6743402816)
- [Pronto funding coverage](https://techfundingnews.com/pronto-25m-series-b/)
- [Bookmybai on YourStory (2015)](https://yourstory.com/2015/05/bookmybai/)
- [Bookmybai app data](https://mwm.ai/apps/bookmybai/1617961356)
