# Progress (update at the end of every session, then commit)

Last updated: Sat 1:20 PM by Cursor

## Works now
- B0 done: app runs on kingston's iPhone 17 Pro; Supabase schema (B2) is live with Claude's fixes
- B1 scaffold builds for the simulator: Theme, models, service stubs, RootView routing to placeholder views, pack.sh
- B2 `supabase/schema.sql`: profiles/cards/meetings + RLS + `claim_card` / `scan_card` (execute → authenticated). Paste into Supabase SQL Editor to apply.
- B3 `SupabaseService`: real client from Info.plist secrets, auth session via `authStateChanges` (survives restart), all Part 3 methods (Apple sign-in, profile, claim/unlink/scan RPCs, people, note, remove).
- B8 People + Person: counted title, sticker rows, note preview, pull-to-refresh, empty state, Me circle + ScanButton stub; Person has socials, one Where you met (stamp/place/time/editable note), Remove.
- B9 Me sheet: sticker, Edit badge via shared `BadgeFields`, Relink (NFC+claim) / Unlink, Sign out → Welcome. C1 complete.

## In progress
- B4: NFCService, LocationService and a DEBUG-only Debug scan screen (Welcome → Debug scan) are on the phone; needs the Husky ID two-read test

## Next
- B6 Onboarding / B7 Scan (Claude); B5 Components already in tree and used by B8/B9
- Card short code on Me only appears after Relink from Me (LinkCardView doesn't persist the hash yet — B6 can write the same `linkedCardHash.<userId>` key)

## Known bugs
-
