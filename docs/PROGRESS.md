# Progress (update at the end of every session, then commit)

Last updated: Sat 3:51 PM by Cursor

## Works now
- Person note card: blue rules now run under every line (ruled index card), instead of one line cutting through the text. Builds clean.
- **A8 QR meet:** Me → **Let them scan** shows a QR + Share for `meet.html?b=<slug>`. `supabase/qr_meet.sql` adds `profiles.slug`, `public_badge`, `meet_via_web`. `web/meet.html` is a design-v3 HELLO sticker page with **Add Me** (anon sign-in). Builds clean. NFC demo path untouched.
- Keyboard: tap outside any text field dismisses it (window-level); Make badge / Edit badge / Person note / Scan note scroll the focused field into view above the keyboard. Builds clean.
- B5–B9 built on design v3: Welcome + Apple sign in, Make your badge, Link your card, People with Scan button → full-screen result, Person, Me. Builds clean; not yet run end to end on the phone
- B0 done: app runs on kingston's iPhone 17 Pro; Supabase schema (B2) is live with Claude's fixes
- B1 scaffold builds for the simulator: Theme, models, service stubs, RootView routing to placeholder views, pack.sh
- B2 `supabase/schema.sql`: profiles/cards/meetings + RLS + `claim_card` / `scan_card` (execute → authenticated). Paste into Supabase SQL Editor to apply.
- B3 `SupabaseService`: real client from Info.plist secrets, auth session via `authStateChanges` (survives restart), all Part 3 methods (Apple sign-in, profile, claim/unlink/scan RPCs, people, note, remove).
- B8 People + Person: counted title, sticker rows, note preview, pull-to-refresh, empty state, Me circle + ScanButton stub; Person has socials, one Where you met (stamp/place/time/editable note), Remove.
- B9 Me sheet: sticker, Edit badge via shared `BadgeFields`, Relink (NFC+claim) / Unlink, Sign out → Welcome. C1 complete.

## In progress
- On-phone test of the demo path (needs Apple sign in + a second account with a linked card)
- **A8 go-live (kingston):** (1) paste `supabase/qr_meet.sql` in SQL Editor, (2) Auth → Providers → enable **Anonymous**, (3) push repo + set Pages source to GitHub Actions, (4) add repo secrets `SUPABASE_URL` + `SUPABASE_ANON_KEY`, (5) confirm `MEET_PAGE_BASE_URL` in Info.plist matches the live Pages URL

## Next
- B10 bug bash, then CHECKPOINT
- End-to-end QR meet: guest phone scans → Add Me → host pull-to-refresh People

## Known bugs
-
