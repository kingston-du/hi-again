# Progress (update at the end of every session, then commit)

Last updated: Sat 1:18 PM by Cursor

## Works now
- B0 done: app runs on kingston's iPhone 17 Pro; Supabase schema (B2) is live with Claude's fixes
- B1 scaffold builds for the simulator: Theme, models, service stubs, RootView routing to placeholder views, pack.sh
- B2 `supabase/schema.sql`: profiles/cards/meetings + RLS + `claim_card` / `scan_card` (execute → authenticated). Paste into Supabase SQL Editor to apply.
- B3 `SupabaseService`: real client from Info.plist secrets, auth session via `authStateChanges` (survives restart), all Part 3 methods (Apple sign-in, profile, claim/unlink/scan RPCs, people, note, remove).
- B8 People + Person: counted title, sticker rows, note preview, pull-to-refresh, empty state, Me circle + ScanButton stub; Person has socials, one Where you met (stamp/place/time/editable note), Remove.

## In progress
- C1: B3 and B8 done; next B9 Me
- B4: NFCService, LocationService and a DEBUG-only Debug scan screen (Welcome → Debug scan) are on the phone; needs the Husky ID two-read test

## Next
- B9 Me (Cursor, C1); B5 Components (Claude — already in tree, used by B8)

## Known bugs
-
