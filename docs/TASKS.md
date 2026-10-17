# Task board

One card per job. Claude adds cards; any tool flips its own card's Status (todo → doing → done).
Full spec: docs/PLAN.md. Rules: AGENTS.md.

### Chunks (bigger hand-offs)

**C1 · Data + People + Me** · Owner: Cursor · Does B3, then B8, then B9 in one session, committing after each card (`B3: …`, `B8: …`, `B9: …`). Files: `Services/SupabaseService.swift`, `Views/PeopleView.swift`, `Views/PersonView.swift`, `Views/MeView.swift`. Views: build the layout and behavior with plain SwiftUI and Theme tokens only (no custom shapes); Claude swaps in the Sticker/Stamp components and final styling afterwards, so keep each row and header in a small private subview that's easy to replace. PeopleView keeps a `@State var scanning` hook and a bottom "Tap a card" button that calls an empty `startScan()` (Claude fills it in B7). Person shows one "Where you met" section (see PLAN Part 2, screen 6). Don't touch Components/, Theme.swift, or the onboarding/scan views. *Done when:* B3, B8 and B9 are each done per their cards.

Status: todo

### Base MVP

**B0 · Setup** · Owner: kingston (Claude guides) · Part 5, minus Xcode steps 1, 3 and 4 (Claude generated the project with XcodeGen) · *Done when:* the empty app runs on your iPhone, Supabase keys are in `Secrets.xcconfig`, and the fonts are in the folder.

Status: done

**B1 · Scaffold** · Owner: Claude · Files: everything in the repo layout except Views' bodies and service internals · *Done when:* `Theme.swift` has every token and font from Part 2 (fonts registered via `UIAppFonts` in Info), Models and `ScanOutcome`/`ClaimResult`/`Place` exist exactly as in Part 3, services exist as stubs with the exact signatures, `RootView` routes to placeholder views, Info has `NFCReaderUsageDescription`, `NSLocationWhenInUseUsageDescription` and `com.apple.developer.nfc.readersession.iso7816.select-identifiers` (include `A0000002471001` so ISO 7816 cards are detected), `scripts/pack.sh` works, and it builds.

Status: done (font files arrive with B0; names already listed in UIAppFonts)

**B2 · Database** · Owner: DeepSeek (Claude reviews) · Files: `supabase/schema.sql` · *Done when:* one script creates the 3 tables, RLS policies and 2 functions exactly per Part 3 and grants execute to `authenticated`. kingston pastes it into Supabase → SQL Editor and it runs clean.

Status: done

**B3 · Supabase service** · Owner: Codex · Files: `Services/SupabaseService.swift` · *Done when:* every function in the contract works against the real database. Client created from the `Secrets` values (read via Info.plist keys `SUPABASE_URL`, `SUPABASE_ANON_KEY`), dates decode, and the session survives an app restart.

Status: done

**B4 · NFC, hashing and location** · Owner: Claude · Files: `NFCService`, `CardHasher`, `LocationService` · *Done when:* on your iPhone, a debug button reads your Husky ID twice and shows the same short code both times, and `currentPlace()` returns a name within 2 seconds or nil. **Do this early: it's the riskiest card.** Record which cards give stable IDs in DECISIONS.md.

Status: doing (built and installed; waiting on the two-scan test with a real card)

**B5 · Components** · Owner: Claude · Files: `Components/*` · *Done when:* Badge (both sizes, all 6 colors), Stamp, buttons and TapButton look right in Xcode Previews on a paper background, using Theme only.

Status: todo (Cursor, as part of chunk C1)

**B6 · Onboarding** · Owner: Claude · Files: `WelcomeView`, `MakeBadgeView`, `LinkCardView`, `RootView` · *Done when:* a new user signs in with Apple, makes a badge (live preview, Next rules), and links a card (`taken` shows "This card is already linked to someone else."), then lands on People. A returning user goes straight to People.

Status: todo

**B7 · Scan** · Owner: Claude · Files: `ScanResultView`, the scan action in `PeopleView` · *Done when:* Tap → NFC sheet → `scanCard` with the place → the full-screen result with the drop-in badge, stamp and haptic for met and already met, and the unknown, own-card and couldn't-read states. The note saves on Done. Scan to badge in under 3 seconds.

Status: todo

**B8 · People and Person** · Owner: Codex (or Claude if it has room) · Files: `PeopleView`, `PersonView` · *Done when:* the list matches Part 2 (title count, row badges, note preview, pull to refresh, empty state), Person shows socials that open the right app and one "Where you met" section (stamp, place, time, editable note), and Remove works.

Status: todo (Cursor, as part of chunk C1)

**B9 · Me** · Owner: Cursor · Files: `MeView` · *Done when:* the sheet matches Part 2: edit badge reuses `MakeBadgeView`'s fields, relink/unlink works, sign out returns to Welcome.

Status: todo (Cursor, as part of chunk C1)

**B10 · Bug bash** · Owner: Codex, with Grok for a second opinion · *Done when:* the full demo path works 5 times in a row on the phone with 3 different cards, there are no crashes, and every bug found is fixed or listed under Known bugs.

Status: todo

> **CHECKPOINT (target 9pm Saturday):** the demo path works on your phone: sign in → make badge → link card → scan another card → badge appears → saved with time and place → shows in People → note visible on Person. **If it doesn't, start no add-on.** Fix and polish what exists.

### Add-ons (in this order; each one is independent, so stop wherever time runs out)

**A1 · Search** · Owners: Cursor (keyword), Grok (edge function), Claude (screen) · A search field at the top of People filters instantly on name, place and note. On submit, the edge function `search` receives the question plus a compact list (`id, name, place, date, note, tags`), asks Grok for the best 5 ids as JSON, and the app shows those as badges under "Best matches". If the call fails, the keyword results stay up.

Status: todo

**A2 · AI tags** · Owners: Grok (edge function + prompt), Codex (`TagService` + `tags text[]` column on meetings), Claude (chips UI) · After Done on a note, the edge function `tags` returns 3 to 5 short tags. They show as dashed chips on Person; tap × to remove. A failure saves the note without tags. Both edge functions call `https://api.x.ai/v1/chat/completions` with `XAI_API_KEY` and a model set in one constant. Create them in the Supabase dashboard (Edge Functions → New) to skip installing the CLI.

Status: todo

**A3 · Pending cards and web join page** · Owners: DeepSeek (SQL), Cursor (`web/join.html`), Claude (QR screen) · `scan_card` on an unknown card saves a pending meeting (`other_id null`, `pending_card_hash`). The butter screen gets **Help them join**, which shows a QR code (Core Image `CIQRCodeGenerator`) for `https://<github-pages-url>/join.html?code=XXXX`. A `claim_codes` table plus `create_claim_code(p_hash)` and `claim_with_code(p_code)` link the card to the new person's account. The page uses anonymous sign-in, asks for first name, one social and a badge color, and is styled with the same tokens. Claiming fills in every pending meeting and creates the mirror rows. Host it with GitHub Pages from the public repo.

Status: todo

**A4 · Photos** · Owners: Codex (Storage upload, `photo_url`), Claude (round photo slot on Badge) · Optional photo in Make your badge; badges without one stay as they are.

Status: todo

**A5 · Events** · Owners: DeepSeek (clustering function), Claude (screen) · Group meetings within 500 m and 12 hours into events, named from place and date ("HUB · OCT 17"), with a segmented control on People: People | Events.

Status: todo

**A6 · Privacy** · Owners: DeepSeek (SQL), Cursor (toggles in Me) · Pause scanning (`scan_card` returns unknown while paused), hide individual socials, block a person.

Status: todo

**A7 · Polish** · Owner: Claude · Curved place text around the stamp, faint paper grain, a soft sound on tap, and a "You met your first person!" moment.

Status: todo

---

**A8 · Public badge page** · Owners: DeepSeek (SQL), Cursor (`web/u.html`), Claude (QR on Me) · Files: `supabase/public_badge.sql`, `web/u.html`, `Views/MeView.swift` · Anyone without the app sees your badge: Me shows a QR (and Share link) for `https://<github-pages-url>/u.html?b=<slug>`. A `slug text unique` column on profiles (8 random chars) and `public_badge(p_slug text) returns jsonb` (security definer, executable by `anon`, returns only first name, last name, badge color and socials). The page is styled with the same tokens and has social buttons plus a "Get hi again" line. Shares the GitHub Pages setup with A3. *Done when:* scanning the QR with a phone that doesn't have the app opens the badge in Safari.

Status: todo
