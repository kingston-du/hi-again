# AGENTS.md (every tool reads this first, every session)

App: "hi again." An iPhone app (SwiftUI, iOS 17+, Supabase). Scan someone's NFC card, their
name badge appears, and the meeting is saved for both people with time, place and a private note.

- Spec, design and contracts: docs/PLAN.md (Part 2 design, Part 3 contracts)
- Work board: docs/TASKS.md · Handoff log: docs/PROGRESS.md · Decisions: docs/DECISIONS.md

## Rules
1. Do ONE card from docs/TASKS.md: the one you were given. Touch only the files it lists.
2. Code against docs/PLAN.md Part 3 exactly. Don't rename or change a contract. If one is wrong,
   stop and say so; only Claude (the architect) changes contracts.
3. Every color, font, spacing and radius comes from Theme. No hex values or font sizes in Views.
   Views/, Components/ and Theme.swift are design-critical: Claude writes them (Codex only if asked).
4. No new packages. async/await. Small, plain files. No architecture changes without asking.
5. Build before saying done:
   xcodebuild -scheme HiAgain -destination 'generic/platform=iOS Simulator' build -quiet
   Fix every error.
6. Finish: set the card's Status to done in TASKS.md, add 1 to 3 lines to PROGRESS.md
   (what works now, anything broken), then commit "<ID>: <what works now>".
7. Files inside HiAgain/ appear in Xcode by themselves (synced folder). Never edit HiAgain.xcodeproj
   by hand; change project.yml and run `xcodegen generate`. Info.plist and entitlements are in Config/.
8. Never commit Config/Secrets.xcconfig and never print keys.

## Demo path (never break it)
Sign in → make badge → link card → scan another card → badge appears → saved with time and
place → shows in People → note visible on Person.
