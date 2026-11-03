You are taking over the SevaNest Customer mobile app (Flutter, Android + iOS) from a previous Claude Code account. Nothing from the old chat carries over, so rebuild context from the files before you change any code.

STEP 1 - Read, in this order:
1. docs/HANDOFF.md  (summary of the project, timeline, conventions, open items)
2. AGENTS.md  (mandatory rules and business invariants)
3. docs/02_TECH_STACK_AND_SETUP.md, docs/03_IMPLEMENTATION_GUIDE.md
4. docs/modules/00_README_HOW_TO_USE.md, then docs/modules/01..09
5. docs/PROGRESS.md, docs/DECISIONS.md (newest first), OPEN_QUESTIONS.md, docs/BACKEND_REQUESTS.md
6. design/tokens.md, design/SCREENS.md, design/screens/ (reference screenshots)
7. Run `git log --oneline -30` and `git status`.

STEP 2 - Verify the environment:
flutter pub get
dart run build_runner build -d
flutter gen-l10n
flutter analyze
flutter test
Report what passes and what fails. Don't fix anything yet.

STEP 3 - Reply with a short summary (under 20 lines):
- what the app does and how the code is organised
- the current state, including the uncommitted work (booking and payment widget refactor, transaction_detail_screen.dart, glass_success_overlay.dart)
- the open questions and gaps you found
Then ask me what to work on next.

RULES (always):
- Commit and push only as GitHub user nagirikantiajay20-prog (set repo-local git user.name/email first). Never use Ajay-prog.
- Use Conventional Commits (feat(scope):, fix(scope):, refactor(scope):, chore:).
- Build only the dev APK: flutter build apk --release --flavor dev -t lib/main_dev.dart. Let it overwrite build/app/outputs/flutter-apk/app-dev-release.apk. Don't build stg or prod, and don't create renamed copies, unless I ask.
- The server is the source of truth. Payment success is only what the backend confirms. Never invent data the API doesn't provide.
- Log deviations in docs/DECISIONS.md, tick docs/PROGRESS.md only when analyze is clean and tests pass, and put unresolved items in OPEN_QUESTIONS.md.
- Match the reference designs in design/screens/ closely. Keep widgets split into *_parts.dart files like the existing code.
- Raw history of the 31 earlier sessions is in sessions.zip (about 315 MB unpacked). Don't load it whole. Grep it only when HANDOFF.md and the docs can't answer a question.
