# Progress (update at the end of every session, then commit)

Last updated: Sat 1:25 PM by Claude

## Works now
- B5–B9 built on design v3: Welcome + Apple sign in, Make your badge, Link your card, People with Scan button → full-screen result, Person, Me. Builds clean; not yet run end to end on the phone
- B0 done: app runs on kingston's iPhone 17 Pro; Supabase schema (B2) is live with Claude's fixes
- B1 scaffold builds for the simulator: Theme, models, service stubs, RootView routing to placeholder views, pack.sh
- B2 `supabase/schema.sql`: profiles/cards/meetings + RLS + `claim_card` / `scan_card` (execute → authenticated). Paste into Supabase SQL Editor to apply.
- B3 `SupabaseService`: real client from Info.plist secrets, auth session via `authStateChanges` (survives restart), all Part 3 methods (Apple sign-in, profile, claim/unlink/scan RPCs, people, note, remove).
- B8 People + Person: counted title, sticker rows, note preview, pull-to-refresh, empty state, Me circle + ScanButton stub; Person has socials, one Where you met (stamp/place/time/editable note), Remove.
- B9 Me sheet: sticker, Edit badge via shared `BadgeFields`, Relink (NFC+claim) / Unlink, Sign out → Welcome. C1 complete.

## In progress
- On-phone test of the demo path (needs Apple sign in + a second account with a linked card)

## Next
- B10 bug bash, then CHECKPOINT

## Known bugs
-
