# Progress (update at the end of every session, then commit)

Last updated: Sat 12:55 PM by Cursor

## Works now
- B1 scaffold builds for the simulator: Theme, models, service stubs, RootView routing to placeholder views, pack.sh
- B2 `supabase/schema.sql`: profiles/cards/meetings + RLS + `claim_card` / `scan_card` (execute → authenticated). Paste into Supabase SQL Editor to apply.

## In progress
- B2 schema reviewed and hardened by Claude; waiting for kingston to run it in the Supabase SQL Editor (CLI can't reach Postgres on this network)

## Next
- B0 Setup (kingston: signing on the phone, Supabase, Secrets.xcconfig, fonts)
- B4 NFC (Claude) and B3 Supabase service (Codex) once schema is applied

## Known bugs
-
