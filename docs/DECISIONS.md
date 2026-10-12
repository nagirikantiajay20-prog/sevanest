# DECISIONS (log deviations/choices; newest first)

| Date | Decision | Reason | Approved by |
|---|---|---|---|
| 2026-10-12 | Modules without a published backend contract (Home onward) use mock repositories behind the repository interfaces, switched by `mockApiProvider` (dev menu: long-press the Home greeting, non-prod). Auth/profile/address stay on the real backend | Build prompt asks for a mock API with loading/error/offline toggles; backend only publishes auth/profile/address | Build prompt |
| 2026-10-12 | `ProviderScope(retry: null)`: no hidden Riverpod auto-retries | Riverpod 3 retries failed providers by default, which hid error states and Retry | AGENTS §65 |
| 2026-10-12 | Profile/address calls use the Swagger paths (`/customers/me`, `PATCH` for edits, `PUT .../default`, `/service-areas`), not the module doc's provisional `/me/*` | AGENTS §2.1: deployed backend contract wins | Backend contract |
| 2026-10-12 | Email is required in profile setup (design says Optional) | `CreateCustomerProfileDto.required = [name, email, preferredLanguage]` | Backend contract |
| 2026-10-12 | No address label chips, line 2 or state; one `line` built from "House / flat" + "Building or street" | Backend `CreateAddressDto` has only line/area/city/pincode/lat/lng/isDefault | Backend contract |
| 2026-10-12 | No profile photo, "Use current location" or map pin in this module | No customer photo endpoint; no location/geocoding dependency or map provider approved (#15) | Pending product |
| 2026-10-12 | Account tab now shows two entry tiles (Profile, Saved addresses) instead of a placeholder | Module-02 screens must be reachable; module 14 will extend the screen | Pending module 14 |
| 2026-10-12 | Name validator also allows `. ' -` and combining marks (Indic scripts) | Real names (D'Souza, Devanagari) fail a letters-and-space rule | Pending product |
| 2026-10-12 | Auth has NO mock path: dev/stg/prod all call the deployed backend (`/api/v1`). Test data comes from backend-provisioned test numbers via env vars in `test/live` only | Task brief: no fake auth; the backend contract now exists | Product owner |
| 2026-10-12 | Get OTP is enabled at 10 digits and validates on tap/blur (design "Login - Error" shows an enabled button with an inline error); module doc AUTH-02 said "disabled when invalid" | Approved design is newer | Follows design |
| 2026-10-12 | After a wrong/expired code the digits stay (red) and Verify stays disabled until the code is edited; module doc said "clear the field" | Matches design "OTP - Wrong code" | Follows design |
| 2026-10-12 | OTP footer minutes, resend cooldown and expiry come from the request response (5 min / 30 s today), not the design's "10 minutes" copy | Backend is authoritative (AGENTS 0) | Backend contract |
| 2026-10-12 | Language sheet lists the design's 6 languages but only English is selectable | `GET /app-config` -> `languages:["en"]`; no translations yet (OPEN_QUESTIONS #16) | Pending product |
| 2026-10-12 | Added "Sign in again" on the failed splash card (module 01 requires `splash_login_btn`; the design shows only Try again + Contact support) | Never strand a user with an unusable stored session | Pending design review |
| 2026-10-12 | Primary colour token changed to `#0F766E` (sampled from the approved auth screens) | Buttons must match the design | Pending brand sign-off (#19) |
| 2026-10-08 | Stack: Riverpod, go_router, dio, freezed, secure storage, FCM, Razorpay behind PaymentService | PRD recommends Flutter; community-standard stack; provider-swappable payments | Pending team confirmation |
