# Progress (update at the end of every session, then commit)

Last updated: Sat 1:13 PM by Cursor

## Works now
- B0 done: app runs on kingston's iPhone 17 Pro; Supabase schema (B2) is live with Claude's fixes
- B1 scaffold builds for the simulator: Theme, models, service stubs, RootView routing to placeholder views, pack.sh
- B2 `supabase/schema.sql`: profiles/cards/meetings + RLS + `claim_card` / `scan_card` (execute → authenticated). Paste into Supabase SQL Editor to apply.
- B3 `SupabaseService`: real client from Info.plist secrets, auth session via `authStateChanges` (survives restart), all Part 3 methods (Apple sign-in, profile, claim/unlink/scan RPCs, people, note, remove).

## In progress
- C1: B3 done; next B8 People/Person, then B9 Me
- B4: NFCService, LocationService and a DEBUG-only Debug scan screen (Welcome → Debug scan) are on the phone; needs the Husky ID two-read test

## Next
- B8 People + Person (Cursor, C1), then B9 Me; B5 Components (Claude)

## Known bugs
-
