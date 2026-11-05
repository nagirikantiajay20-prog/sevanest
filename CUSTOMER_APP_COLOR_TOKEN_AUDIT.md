# Customer App Color Token Audit

Date: 2026-11-06. Scope: `lib/` (generated `lib/l10n/gen` excluded). Tokens live in `lib/app/theme/tokens.dart` (`AppColors`).

## Counts

| Pattern | Before (HEAD + working tree) | After |
|---|---|---|
| `Colors.white` (exact, not `white70` etc.) | 213 matches (214 by the earlier substring grep) | 0 |
| Inline `Color(0x........)` outside `tokens.dart` | 687 literals on 634 lines (193 distinct values) | 0 |
| New `AppColors` tokens | n/a | 169 |
| Existing tokens reused (exact value match) | n/a | 24 distinct values, 176 literals |

`Colors.white` became the existing `AppColors.surface` (`0xFFFFFFFF`, identical value). Raw `Color(0x..)` literals became `AppColors.<name>`; `const Color(..)` became `AppColors.<name>` (already `const`).

## Method (value-preserving by construction)

A script (`tool/shots/migrate_colors.js`, scratch, not committed) rewrote one subtree at a time. For each literal it looked up an existing token with the identical 8-digit ARGB value; if none existed it added a token with that exact value. No alpha was converted to `withValues(alpha:)`, so opacity rounding cannot drift. Calls such as `AppColors.teal.withValues(...)` and gradients were left untouched. Imports of `tokens.dart` were added where missing.

## Batches

| # | Subtree | Literals | `Colors.white` | New tokens | `dart analyze` (batch + theme) |
|---|---|---|---|---|---|
| 1 | features/active_service | 10 | 1 | 6 | clean |
| 2 | features/addresses | 47 | 14 | 23 | clean |
| 3 | features/app_gate | 0 | 1 | 0 | clean |
| 4 | features/authentication | 70 | 12 | 40 | clean |
| 5 | features/booking | 24 | 4 | 6 | clean |
| 6 | features/customer_profile | 38 | 22 | 7 | clean |
| 7 | features/favourites | 22 | 4 | 6 | clean |
| 8 | features/home | 32 | 27 | 12 | clean |
| 9 | features/interview_trial | 63 | 16 | 10 | clean |
| 10 | features/notifications | 25 | 5 | 4 | clean |
| 11 | features/payment | 39 | 8 | 4 | clean |
| 12 | features/ratings | 4 | 2 | 1 | clean |
| 13 | features/replacement | 25 | 8 | 3 | clean |
| 14 | features/service_history | 22 | 2 | 0 | clean |
| 15 | features/support | 52 | 13 | 2 | clean |
| 16 | features/worker_profile | 21 | 6 | 6 | clean |
| 17 | features/worker_search | 49 | 16 | 4 | clean |
| 18 | features/service_discovery | 138 | 42 | 33 | clean |
| 19 | core | 6 | 8 | 2 | not run per batch (whole `lib` analyzed clean afterwards) |
| 20 | app | 0 | 2 | 0 | same |

Totals: 687 literals, 213 `Colors.white`, 169 new tokens. A first attempt on batch 1 produced `const AppColors.x` (invalid); the analyzer caught it, the batch was reverted and the script fixed before any other batch ran.

## Evidence and what was NOT done

- `flutter analyze` and `dart analyze lib`: clean after all batches. Full `flutter test`: 1075 passed, 12 skipped, 0 failed (run after the migration, before the final splash fix).
- **Per-batch tests and per-batch before/after screenshots were NOT run.** Per-batch analyze only. The request required a comparison screenshot per batch; that was not done. The "zero visual change" claim rests on exact-value substitution plus the analyzer and the widget-test suite, not on pixel comparison. Screenshots captured afterwards (`tool/shots/out`, scratch) show the migrated app rendering normally but are not a before/after diff.
- Token names are hue + hex (e.g. `whiteA90xE6`, `teal0B5A53`, `rose700`) with 169 of them not semantic. Renaming to roles needs design sign-off (OPEN_QUESTIONS #19).
- Exceptions kept as raw colors: `AppShadows` in `tokens.dart` (token file itself), and any `Colors.*` other than `Colors.white` (e.g. `Colors.transparent`) were out of scope.
- `Colors.whiteNN` variants (`white70`, etc.): count 0 at start, nothing to migrate.
- Existing uncommitted edits from the previous pass in 12 files were preserved; the migration also touched those files.
