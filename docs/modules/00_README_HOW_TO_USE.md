# docs/modules/ — Module-wise Build & Test Specs (Button-Click Level)

> Claude Code: for each module, implement **exactly** what its file says, then run its **Test Cases** section. A module is done only when every row in its "Interaction Table" is implemented and every test case passes (AGENTS §77, §96).
> Order of modules = build order (matches `docs/03_IMPLEMENTATION_GUIDE.md`). Routes follow `docs/04_SCREEN_SPECS.md`. APIs follow `docs/05_API_CONTRACT_ASSUMPTIONS.md` (provisional → real contract overrides).

## Module index
| File | Module | Phase |
|---|---|---|
| 01_authentication.md | Splash, Login, OTP, Logout | 2 |
| 02_profile_addresses.md | Profile setup/edit, Addresses | 3 |
| 03_home_and_navigation.md | Main shell, Home | 3 |
| 04_service_discovery.md | Requirement builder (7 steps) | 4 |
| 05_worker_search_and_profile.md | Results, filters, worker detail | 4 |
| 06_favourites.md | Shortlist | 4 |
| 07_interview_trial.md | Request, detail, decision | 5 |
| 08_booking.md | Confirm, detail, list, cancel | 6 |
| 09_payment_transactions.md | Pay, result, receipts, transactions | 7 |
| 10_active_service_history_rating.md | Active service, history, rating | 8 |
| 11_replacement.md | Request, status, alternatives | 9 |
| 12_support_safety.md | Tickets, report/block | 10 |
| 13_notifications.md | Push, centre, deep links | 10 |
| 14_account_settings.md | Account, logout, legal | 3/11 |
| 15_navigation_map_and_functional_flows.md | Master route map, end-to-end feature flows, navigation tests | all |

## How to read an Interaction Table
Columns: **Element** (what the user taps/does) · **Key** (`Key('…')` you MUST set on the widget so tests can find it) · **Enabled when** · **On tap → Action** (validation / API call) · **On success → Navigates to** · **On failure** (what the user sees; where they stay).
- "push" = `context.push` (back returns here). "go" = `context.go` (replaces stack). "replace" = `context.pushReplacement` (back cannot return — used after irreversible mutations).
- "stay" = remains on same screen.
- Anything not in a table is NOT to be built (AGENTS §3.2, §80.13).

## Global rules that apply to EVERY button (do not repeat per row)
1. **Submit buttons** (anything that calls a mutation): disabled + inline spinner while `isLoading`; re-enabled on failure; double-tap ignored.
2. **Back button / system back**: pops one level unless row says otherwise; on screens with unsaved input show "Discard changes?" dialog (`Key('discard_dialog_confirm')`, `Key('discard_dialog_cancel')`).
3. **Network failure on mutation**: show `SnErrorState`/snackbar "Couldn't reach SevaNest. Check your connection and try again." Never say "failed" when outcome unknown — for booking/payment say "We're checking the status" and refetch.
4. **401 anywhere**: session cleared → `go('/login')` with message "Please sign in again."
5. **403**: snackbar "You don't have access to this." stay.
6. **Validation error from backend** (`fieldErrors`): show under matching field; stay.
7. **Pull-to-refresh** on list/detail screens refetches; **Retry** button on error state refetches same request.
8. **Every list** has loading skeleton, empty state, error+retry, pagination footer loader.
9. **Strings** from `AppLocalizations`; the English text in tables is draft copy.

## Test conventions
- Test IDs: `<MODULE>-<NN>` e.g. `AUTH-03`. Types: **U** unit, **W** widget, **I** integration (`integration_test`), **M** manual (device).
- Widget tests use fake repositories (mocktail); integration tests use mock-repo flavor or a local mock server.
- Each test case lists: Given → When (button key tapped) → Then (screen/route/state/API call assertion).
- After finishing a module: `dart format . && flutter analyze && flutter test` then tick `docs/PROGRESS.md`.

## Key naming convention
`<screen>_<element>_<type>` snake_case, e.g. `login_mobile_field`, `otp_verify_btn`, `worker_card_fav_btn_<id>`.

## Shared UI elements referenced by modules
- **Top app bar back arrow** `Key('app_back_btn')` → pop.
- **Snackbar** for transient errors (4 s).
- **Error state** `Key('error_retry_btn')` → refetch.
- **Empty state** CTA key per module.
- **Bottom nav** keys: `nav_home`, `nav_bookings`, `nav_favourites`, `nav_account`.
