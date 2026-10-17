# MEGA PLAN: build day (DubHacks 2026, Sat Oct 17 to Sun Oct 18)

> **Claude Code: if you are reading this, you are the architect.** Go to [Part 1, Kickoff](#part-1-kickoff-claude-code-does-this-first) and do it now. Everything you need is in this file.
>
> **kingston: you do three things.** (1) Make a folder for the app, (2) put this file in it, (3) open Claude Code in that folder and send:
> `Read MEGA-PLAN.md. You're the architect. Do the Kickoff.`

**App name:** `hi again.` (working name; Xcode project `HiAgain`). To change it, edit this line before kickoff. The name on the home screen is one setting, so it can change any time.

---

## Part 0. What we're building (the simple version)

**One line:** scan someone's student ID (or any NFC card) and their name badge pops up on your phone, stamped with where and when you met. Later, open their badge to see their socials and the note you wrote.

**Pitch:** "Remember the *people* you meet."

**Track:** Chef's Choice (open-ended). Re-check at the opening ceremony in case a sponsor prize fits better (xAI is a sponsor, so using Grok for the AI add-ons may count).

### The base MVP (this is the whole demo; build only this first)

1. **Sign in** with Apple.
2. **Make your badge:** first name, last name, a badge color, and up to three socials (Instagram, Snapchat, LinkedIn). At least one social.
3. **Link your card:** scan your own card once.
4. **Tap:** scan someone else's card. Their badge drops in on a violet screen, a "met at" stamp lands on it, and the meeting is saved for both of you with time and place.
5. **Note:** one optional line on the result screen: "What do you want to remember?"
6. **People:** everyone you've met, newest first. Tap one to see their badge, socials, and every time you met with your notes.
7. **Me:** your badge, edit it, your card (relink or unlink), sign out.

That's it: **6 screens** (Welcome, Make your badge, Link your card, People, Scan result, Person) plus a small Me sheet.

### Add-ons (only after the base works end to end on your phone)

| # | Add-on | Why it's worth it |
|---|---|---|
| A1 | **Plain-words search** (keyword first, then AI ranking with Grok) | The demo payoff: "the robotics person from DubHacks" finds them |
| A2 | **AI tags** from your note (Grok) | Makes notes searchable and looks smart; uses a sponsor's API |
| A3 | **Pending cards + web join page** (unclaimed card saves a pending meeting; QR opens a Safari page to make a badge) | Lets a judge's own card work |
| A4 | **Profile photos** on badges | Faces help memory |
| A5 | **Events** (meetings grouped by place and day) | "Everyone I met at DubHacks" |
| A6 | **Privacy** (pause scanning, hide a social, block someone) | Good answer to "isn't this creepy?" |
| A7 | **Polish** (curved text on stamps, paper grain, a sound on tap) | Pure delight |

**Cut entirely (don't build, don't discuss):** map, voice notes, photo at scan, the 5-tab dock, notifications, Android, messaging.

---

## Part 1. Kickoff (Claude Code does this first)

Claude, do these in order. Keep kingston's steps short and one at a time, since they have light Xcode experience.

1. **Create the shared context files** in this folder, exactly as written in [Appendix A](#appendix-a-files-to-create-verbatim). Copy this file to `docs/PLAN.md` (keep `MEGA-PLAN.md` too). Create `docs/TASKS.md` from [Part 6](#part-6-the-task-board) with every status set to `todo`.
2. **`git init`**, add `.gitignore` from Appendix A, and commit `"kickoff: context files"`. If `gh` is installed and signed in, offer `gh repo create hi-again --public --source . --push`; otherwise tell kingston to create the repo on github.com.
3. **Walk kingston through B0** (setup they must click through themselves, in [Part 5](#part-5-setup-steps-only-kingston-can-do-b0)). Ask for confirmation after each group.
4. **Do B1** (scaffold) yourself, build-check it, then tell kingston which builder takes which card next ([Part 6](#part-6-the-task-board)) and give them the exact prompt to paste ([Part 4](#part-4-how-each-builder-works)).
5. From then on, you are the architect: you own `docs/PLAN.md` contracts, review other tools' work when kingston asks, and build the cards marked Claude.

**Hackathon rule:** all code is written during the event. This plan is specs only, so write the code fresh; never copy from kingston's older app Du Vide.

---

## Part 2. Design (simple, clean, still ours)

**The idea: name badges and passport stamps.** Every person is a "HELLO, I'M" conference badge in their own pastel color. Every meeting is a round stamp. Light lilac paper, deep plum ink, one strong violet. No dark mode.

### Tokens (put these in `Theme.swift`; nothing else defines a color or font)

| Token | Value | Use |
|---|---|---|
| `paper` | `#F3F0FA` | Every screen background |
| `card` | `#FFFFFF` | Rows, inputs, sheets |
| `ink` | `#1C1530` | Text (deep plum, never pure black) |
| `inkSoft` | `#6E6488` | Secondary text, mono lines |
| `line` | `#E2DCF0` | Hairlines, input borders |
| `violet` | `#5A3FF0` | Primary buttons, Tap button, stamps, the scan screen |
| `butter` | `#FFEDB0` | "Not on the app yet" screen |
| Badge colors | peach `#FFD6C2`, lilac `#D9CFFF`, mint `#C9F0DE`, butter `#FFEDB0`, sky `#CDE4FF`, rose `#FFD3E2` | One per person, picked at setup |

| Role | Font | Notes |
|---|---|---|
| Display (titles, names) | **Bricolage Grotesque** 800, tight tracking | Names on badges, screen titles |
| Accent (one word per headline, notes) | **Instrument Serif Italic** | "Remember the *people* you meet." Notes are written in this, like handwriting |
| Mono (places, times, labels) | **Geist Mono** 500, ALL CAPS, wide tracking | `HUB · SAT 2:14 PM` |
| UI (buttons, fields) | System font (SF Pro) | Fewer fonts to bundle |

Spacing scale: 4, 8, 12, 16, 24, 32. Radius: rows and badges 24, buttons fully round (pill, 56 pt tall). Shadow: ink at 12% opacity, y 8, blur 20. Motion: springs (response 0.45, damping 0.7), nothing over 0.6 s except the tap moment. Respect Reduce Motion.

### Components (build once in `Components/`, reuse everywhere)

- **Badge** (`size: .row | .large`, `tilt: Double`). A pastel rounded rectangle with a small capsule "lanyard slot" cut out at the top center, a mono label `HELLO, I'M`, the first name huge in Bricolage, the last name smaller, and a mono detail line. `.large` is tilted 3 to 6 degrees with the shadow; `.row` is flat with no tilt.
- **Stamp.** An 84 pt circle with a 2 pt violet stroke and a dashed inner ring. The place name sits in mono caps (two lines max) with the date below, rotated −12°, at 90% opacity. (Curved text around the edge is add-on A7.)
- **PrimaryButton** (violet pill, white text, soft violet glow) and **SecondaryButton** (white pill, ink text, `line` border).
- **SocialButton.** A white pill with the network's name and handle that opens the app, falling back to the website.
- **TapButton.** A 76 pt violet circle with `wave.3.right` and the word "Tap", floating bottom center.

### The screens

1. **Welcome.** The wordmark `hi again` with a violet period. Headline: "Remember the *people* you meet." One tilted sample badge ("Maya") with a stamp on its corner. The **Sign in with Apple** button (black style).
2. **Make your badge.** A live badge preview at the top that updates as you type. Fields for first name and last name, a row of six color dots, and Instagram, Snapchat and LinkedIn fields with "@" already shown. **Next** stays disabled until there's a first name and one social.
3. **Link your card.** A simple drawing of a card held at the top of an iPhone. "Hold your student ID to the top of your phone." **Scan my card**, then the card's short code appears on your badge in mono (`CARD 4F2A`). Below: **Skip for now**.
4. **People (home).** Title: "**12** people you've met" with the number in violet. A list of `.row` badges, newest first, each showing the first name, a mono line `HUB · SAT 2:14 PM`, and the note's first line in serif italic. A small circle in your badge color with your initial sits top right and opens Me; the TapButton floats at the bottom. Empty state: "Nobody yet. Tap a card to meet someone." with a hand-drawn arrow toward the Tap button.
5. **Scan result** (full screen, the signature moment). The screen floods violet, the person's `.large` badge drops in on a spring, then the stamp thunks onto its corner with a success haptic. Then "You met *Maya*." in white, their social buttons, and a white index card: "What do you want to remember?" (one text field). **Done**.
   - Met again: same, with mono "MET AGAIN · 3RD TIME".
   - Unknown card: butter background, a dashed empty badge with "?", "Not on the app yet." (Add-on A3 turns this into a pending meeting plus "Help them join".)
   - Your own card: "That's *you*."
   - Couldn't read: stay on People and show "Couldn't read that. Hold it near the top of your phone."
6. **Person.** Their `.large` badge, their social buttons, then a list of meetings, newest first: a small stamp on the left and your note in serif italic on the right (tap to edit). A **…** menu with **Remove Maya**.
7. **Me** (sheet). Your badge exactly as others see it, **Edit badge** (same fields as setup), "Your card: linked · 4F2A" with **Relink** and **Unlink**, and **Sign out**.

### Copy voice

Short and warm, like a friend who's good with names. First names everywhere. No exclamation marks, except "You met your first person!" on someone's first ever scan.

| Instead of | Write |
|---|---|
| Connection successfully created | You met Maya |
| User not registered | Not on the app yet |
| NFC read error | Couldn't read that. Hold it near the top of your phone. |
| Add a note (optional) | What do you want to remember? |
| Delete connection | Remove Maya |

---

## Part 3. Architecture (the contracts every builder codes against)

Only Claude changes this section. If a builder thinks a contract is wrong, it stops and says so.

### Repo layout

```
HiAgain/                      ← Xcode project folder (repo root)
  AGENTS.md  CLAUDE.md  MEGA-PLAN.md  .gitignore
  docs/      PLAN.md  TASKS.md  PROGRESS.md  DECISIONS.md
  scripts/   pack.sh                     ← copies a task's context to the clipboard for chat-only tools
  supabase/  schema.sql   functions/     ← SQL run in the Supabase SQL editor; edge functions (add-ons)
  web/       join.html                   ← add-on A3 only
  HiAgain/                               ← the app target
    HiAgainApp.swift   RootView.swift
    Theme.swift
    Models/      Profile.swift  Meeting.swift  Person.swift  ScanOutcome.swift
    Services/    SupabaseService.swift  NFCService.swift  CardHasher.swift  LocationService.swift
    Components/  Badge.swift  Stamp.swift  Buttons.swift  TapButton.swift
    Views/       WelcomeView  MakeBadgeView  LinkCardView  PeopleView  ScanResultView  PersonView  MeView
    Resources/Fonts/
  Config/Secrets.xcconfig                ← git-ignored
```

Ownership: `Views/`, `Components/` and `Theme.swift` are design-critical. Claude writes them; Codex only when Claude is out of usage. DeepSeek never writes a View.

### Database (Supabase Postgres)

Three tables. A meeting is stored **twice, once per person**, so each person owns their own row and their own private note. That keeps security rules dead simple.

| Table | Columns | Rules (RLS) |
|---|---|---|
| `profiles` | `id uuid` PK = auth user id · `first_name text not null` · `last_name text` · `badge_color text not null default 'lilac'` · `instagram text` · `snapchat text` · `linkedin text` · `created_at timestamptz default now()` | Read: your own, or anyone you have a meeting row with. Insert/update: your own only |
| `cards` | `card_hash text` PK · `user_id uuid unique` → profiles · `claimed_at timestamptz default now()` | No direct access at all. Only the two functions below touch it |
| `meetings` | `id uuid` PK default `gen_random_uuid()` · `owner_id uuid` → profiles · `other_id uuid` → profiles · `met_at timestamptz default now()` · `lat float8` · `lng float8` · `place_name text` · `note text` | Read, update and delete: only where `owner_id = auth.uid()`. Only the `note` column is updatable. No direct inserts (only `scan_card` inserts) |

Handles are stored without "@". `card_hash` = SHA-256 hex of (`CARD_SALT` + the card UID as hex). The raw UID never leaves the phone.

**Three database functions** (`security definer`, `set search_path = public`, executable by `authenticated`):

- `claim_card(p_hash text) returns text`. Returns `'linked'` (deletes any old card for this user, then links this one), `'already_yours'`, or `'taken'` (another user has it; change nothing).
- `unlink_card() returns void`. Deletes the caller's card row. `SupabaseService.unlinkCard()` calls it.
- `scan_card(p_hash text, p_lat float8, p_lng float8, p_place text) returns jsonb`:
  - No card row: `{"status":"unknown"}`, saves nothing.
  - Card belongs to the caller: `{"status":"self"}`.
  - Otherwise it inserts **two** meeting rows (caller → them, them → caller) with the same time and place, and returns `{"status":"met","meeting_id":<caller's row id>,"times_met":<count of caller's rows with them>,"profile":<their profiles row as json>}`.

### Swift contracts

```swift
enum BadgeColor: String, Codable, CaseIterable { case peach, lilac, mint, butter, sky, rose }

struct Profile: Codable, Identifiable, Hashable {
    let id: UUID; var firstName: String; var lastName: String?
    var badgeColor: BadgeColor; var instagram: String?; var snapchat: String?; var linkedin: String?
}   // CodingKeys map to snake_case columns

struct Meeting: Codable, Identifiable, Hashable {
    let id: UUID; let ownerId: UUID; let otherId: UUID; let metAt: Date
    var lat: Double?; var lng: Double?; var placeName: String?; var note: String?
}

struct Person: Identifiable, Hashable {          // built on the client: one per other_id
    let profile: Profile; let meetings: [Meeting] // newest first
    var id: UUID { profile.id }; var lastMet: Date { meetings[0].metAt }
}

enum ScanOutcome { case met(Profile, meetingId: UUID, timesMet: Int), unknown, ownCard }

enum ClaimResult: String { case linked, alreadyYours = "already_yours", taken }

struct Place { let name: String?; let lat: Double; let lng: Double }
```

| Service | Functions (all `async throws` unless noted) |
|---|---|
| `SupabaseService` (singleton `shared`, `@MainActor ObservableObject` with `@Published var session`) | `signInWithApple(idToken: String, nonce: String)` · `signOut()` · `myProfile() -> Profile?` · `saveProfile(_:)` · `claimCard(hash:) -> ClaimResult` · `unlinkCard()` · `scanCard(hash:place:) -> ScanOutcome` · `people() -> [Person]` (one query for my meetings, one `in` query for those profiles, grouped client-side) · `updateNote(meetingId:text:)` · `removePerson(id:)` (deletes my rows with them) |
| `NFCService` | `readCardUID() -> Data`. Uses `NFCTagReaderSession` polling `.iso14443` and `.iso15693`, takes the first tag's identifier (MIFARE, ISO 7816, ISO 15693, or FeliCa), and sets `alertMessage = "Hold a card near the top of your phone."` |
| `CardHasher` (no async) | `static func hash(_ uid: Data) -> String` (CryptoKit SHA-256 of salt + hex) · `static func shortCode(_ hash: String) -> String` (first 4 characters, uppercased) |
| `LocationService` | `currentPlace() -> Place?`. Asks "when in use" permission, takes one fix, reverse-geocodes (prefer a point-of-interest name such as "HUB"), and **gives up after 2 seconds** with whatever it has. A scan never waits on location |

App flow (`RootView`): no session → Welcome. Session but no profile → Make your badge → Link your card. Otherwise → People.

---

## Part 4. How each builder works (the shared context system)

**One rule makes it work: every tool reads the same files, and every session ends by writing to them.**

| File | What it is | Who writes it |
|---|---|---|
| `AGENTS.md` | Short rules every tool reads first. Codex and Cursor read it automatically; Claude Code reads it through `CLAUDE.md` | Claude only |
| `docs/PLAN.md` | This file: spec, design, contracts | Claude only |
| `docs/TASKS.md` | The task board: one card per job, with owner, files and "done when" | Claude adds cards; any tool flips its own card's status |
| `docs/PROGRESS.md` | The handoff log: what works, what's broken, what's next | Every tool, at the end of every session |
| `docs/DECISIONS.md` | One line per decision so no tool re-argues it | Whoever makes the decision |

**The loop, for every tool:** read → do one card → build → update TASKS + PROGRESS → commit. Switching tools then costs one sentence, since git and the docs carry everything. **Only one tool edits the repo at a time** (no merge conflicts); chat-only tools can draft in parallel.

### The roles

| Builder | Where it runs | Gets | Never |
|---|---|---|---|
| **Claude** (architect) | Claude Code in the repo | Kickoff, contracts, NFC, Theme and Components, every screen, reviews | Burn usage on plumbing |
| **Codex** (ChatGPT) | Codex CLI or app in the repo | Supabase service, People and Person screens if Claude is busy, bug hunts, reviews. Takes over Claude's cards when Claude's window runs out | Change contracts |
| **Cursor** | Your editor, open on the repo | Small cards (Me sheet, keyword search, web join page), quick edits, Tab autocomplete, "explain this error" | Big refactors |
| **DeepSeek** | Web chat (can't see the repo) | SQL schema and functions, model code, the Devpost write-up | Any View or design work |
| **Grok** | Web chat for building; **its API is the app's AI** | The add-on edge functions and their prompts (tags, search), second opinion on bugs | Views |

Usage tips: send Claude one tiny message around 8:30am so its 5-hour window resets about 1:30pm, just after hacking starts. In Codex, use the bigger model only for hard bugs and the light one for routine cards. More detail: `dubhacks/ai-tools-plan.md` in the project.

### Prompts to paste

**Start a card (Claude Code, Codex, Cursor agent):**
```
Read AGENTS.md, docs/PROGRESS.md and card <ID> in docs/TASKS.md. Plan it in 3 lines, then build it. Build-check, then finish per AGENTS.md rule 6.
```

**Chat-only tools (DeepSeek, Grok).** In Terminal run `scripts/pack.sh <ID>` (it copies AGENTS.md, the contracts section, the card and the files it lists to your clipboard), paste into the chat, and add:
```
Write the complete files this card lists. Output each one as a code block whose first line is a comment with its path. No explanations.
```
Then paste the answer into Cursor's agent: `Create or replace these files exactly, then build-check and finish per AGENTS.md rule 6.`

**Review (Claude or Codex, whoever didn't write it):**
```
Review the last commit against AGENTS.md and the contracts in docs/PLAN.md Part 3. List real bugs only, worst first. No style nits.
```

**Stuck on a bug for 20 minutes:** paste the error into a *different* tool than the one that wrote the code:
```
Read AGENTS.md. This fails: <error>. Here is the file. Find the cause before changing anything.
```

**Before a tool's usage runs out:** `Stop. Update docs/PROGRESS.md and the card status, then commit.`

---

## Part 5. Setup steps only kingston can do (B0)

Claude walks you through these one group at a time. About 30 minutes.

**Xcode project**
1. Xcode → File → New → Project → iOS → App. Name `HiAgain`, Interface SwiftUI, Language Swift, no tests. Save it **into this folder** (uncheck "Create Git repository", since Claude already made one).
2. Target → General → Minimum Deployments: iOS 17.0. Under Signing & Capabilities, pick your team (a paid Apple Developer account is required for NFC and Sign in with Apple on a real phone).
3. **+ Capability**: *Near Field Communication Tag Reading* and *Sign in with Apple*.
4. File → Add Package Dependencies → `https://github.com/supabase/supabase-swift` → add the `Supabase` product.
5. Plug in your iPhone and run the empty app once, so you know signing works.

Newer Xcode versions use synced folders, so files Claude creates in the `HiAgain/` folder appear in Xcode by themselves. If one doesn't, drag it in.

**Supabase**
6. Make a new project at supabase.com. From Settings → API, copy the **Project URL** and the **anon public key**.
7. Authentication → Providers → **Apple**: turn it on and add your app's bundle ID (for example `com.kingston.HiAgain`) under Client IDs. That's all native sign-in needs.
8. Also turn on **Anonymous sign-ins** (Authentication → Settings). It's the backup if Apple sign-in fights you, and add-on A3 uses it.

**Keys and fonts**
9. Claude creates `Config/Secrets.xcconfig` from Appendix A; you paste in the URL, the anon key, and any random 32 characters as `CARD_SALT`. Then in the project's Info tab, set the target's configuration file to `Secrets` (Claude will point to the exact spot).
10. Download **Bricolage Grotesque**, **Instrument Serif** and **Geist Mono** from Google Fonts and unzip them into `HiAgain/Resources/Fonts/`. Claude registers them.
11. Later (add-ons A1/A2): put your xAI key in Supabase → Edge Functions → Secrets as `XAI_API_KEY`. It never goes in the app.

**Cards:** have your Husky ID plus 2 or 3 spare NFC cards (ORCA, hotel key, gym fob). The first real test of B4 tells us which ones give the same ID every scan. Contactless credit cards and phone wallets change their ID on purpose, so they won't work.

---

## Part 6. The task board

Claude copies this into `docs/TASKS.md` with a `Status:` line under each card. Do them roughly in order; cards that share a row in the timeline can run side by side if one of them is a chat-only tool.

### Base MVP

**B0 · Setup** · Owner: kingston (Claude guides) · Part 5 · *Done when:* the empty app runs on your iPhone, Supabase keys are in `Secrets.xcconfig`, and the fonts are in the folder.

**B1 · Scaffold** · Owner: Claude · Files: everything in the repo layout except Views' bodies and service internals · *Done when:* `Theme.swift` has every token and font from Part 2 (fonts registered via `UIAppFonts` in Info), Models and `ScanOutcome`/`ClaimResult`/`Place` exist exactly as in Part 3, services exist as stubs with the exact signatures, `RootView` routes to placeholder views, Info has `NFCReaderUsageDescription`, `NSLocationWhenInUseUsageDescription` and `com.apple.developer.nfc.readersession.iso7816.select-identifiers` (include `A0000002471001` so ISO 7816 cards are detected), `scripts/pack.sh` works, and it builds.

**B2 · Database** · Owner: DeepSeek (Claude reviews) · Files: `supabase/schema.sql` · *Done when:* one script creates the 3 tables, RLS policies and 2 functions exactly per Part 3 and grants execute to `authenticated`. kingston pastes it into Supabase → SQL Editor and it runs clean.

**B3 · Supabase service** · Owner: Codex · Files: `Services/SupabaseService.swift` · *Done when:* every function in the contract works against the real database. Client created from the `Secrets` values (read via Info.plist keys `SUPABASE_URL`, `SUPABASE_ANON_KEY`), dates decode, and the session survives an app restart.

**B4 · NFC, hashing and location** · Owner: Claude · Files: `NFCService`, `CardHasher`, `LocationService` · *Done when:* on your iPhone, a debug button reads your Husky ID twice and shows the same short code both times, and `currentPlace()` returns a name within 2 seconds or nil. **Do this early: it's the riskiest card.** Record which cards give stable IDs in DECISIONS.md.

**B5 · Components** · Owner: Claude · Files: `Components/*` · *Done when:* Badge (both sizes, all 6 colors), Stamp, buttons and TapButton look right in Xcode Previews on a paper background, using Theme only.

**B6 · Onboarding** · Owner: Claude · Files: `WelcomeView`, `MakeBadgeView`, `LinkCardView`, `RootView` · *Done when:* a new user signs in with Apple, makes a badge (live preview, Next rules), and links a card (`taken` shows "This card is already linked to someone else."), then lands on People. A returning user goes straight to People.

**B7 · Scan** · Owner: Claude · Files: `ScanResultView`, the scan action in `PeopleView` · *Done when:* Tap → NFC sheet → `scanCard` with the place → the full-screen result with the drop-in badge, stamp and haptic for met and met again, and the unknown, own-card and couldn't-read states. The note saves on Done. Scan to badge in under 3 seconds.

**B8 · People and Person** · Owner: Codex (or Claude if it has room) · Files: `PeopleView`, `PersonView` · *Done when:* the list matches Part 2 (title count, row badges, note preview, pull to refresh, empty state), Person shows socials that open the right app and meetings with editable notes, and Remove works.

**B9 · Me** · Owner: Cursor · Files: `MeView` · *Done when:* the sheet matches Part 2: edit badge reuses `MakeBadgeView`'s fields, relink/unlink works, sign out returns to Welcome.

**B10 · Bug bash** · Owner: Codex, with Grok for a second opinion · *Done when:* the full demo path works 5 times in a row on the phone with 3 different cards, there are no crashes, and every bug found is fixed or listed under Known bugs.

> **CHECKPOINT (target 9pm Saturday):** the demo path works on your phone: sign in → make badge → link card → scan another card → badge appears → saved with time and place → shows in People → note visible on Person. **If it doesn't, start no add-on.** Fix and polish what exists.

### Add-ons (in this order; each one is independent, so stop wherever time runs out)

**A1 · Search** · Owners: Cursor (keyword), Grok (edge function), Claude (screen) · A search field at the top of People filters instantly on name, place and note. On submit, the edge function `search` receives the question plus a compact list (`id, name, place, date, note, tags`), asks Grok for the best 5 ids as JSON, and the app shows those as badges under "Best matches". If the call fails, the keyword results stay up.

**A2 · AI tags** · Owners: Grok (edge function + prompt), Codex (`TagService` + `tags text[]` column on meetings), Claude (chips UI) · After Done on a note, the edge function `tags` returns 3 to 5 short tags. They show as dashed chips on Person; tap × to remove. A failure saves the note without tags. Both edge functions call `https://api.x.ai/v1/chat/completions` with `XAI_API_KEY` and a model set in one constant. Create them in the Supabase dashboard (Edge Functions → New) to skip installing the CLI.

**A3 · Pending cards and web join page** · Owners: DeepSeek (SQL), Cursor (`web/join.html`), Claude (QR screen) · `scan_card` on an unknown card saves a pending meeting (`other_id null`, `pending_card_hash`). The butter screen gets **Help them join**, which shows a QR code (Core Image `CIQRCodeGenerator`) for `https://<github-pages-url>/join.html?code=XXXX`. A `claim_codes` table plus `create_claim_code(p_hash)` and `claim_with_code(p_code)` link the card to the new person's account. The page uses anonymous sign-in, asks for first name, one social and a badge color, and is styled with the same tokens. Claiming fills in every pending meeting and creates the mirror rows. Host it with GitHub Pages from the public repo.

**A4 · Photos** · Owners: Codex (Storage upload, `photo_url`), Claude (round photo slot on Badge) · Optional photo in Make your badge; badges without one stay as they are.

**A5 · Events** · Owners: DeepSeek (clustering function), Claude (screen) · Group meetings within 500 m and 12 hours into events, named from place and date ("HUB · OCT 17"), with a segmented control on People: People | Events.

**A6 · Privacy** · Owners: DeepSeek (SQL), Cursor (toggles in Me) · Pause scanning (`scan_card` returns unknown while paused), hide individual socials, block a person.

**A7 · Polish** · Owner: Claude · Curved place text around the stamp, faint paper grain, a soft sound on tap, and a "You met your first person!" moment.

---

## Part 7. Timeline (Seattle time)

| When | What | Who |
|---|---|---|
| Sat 8:30am | One tiny message to Claude to start its window early | you |
| 9:30–11 | Check-in | |
| 11–12:30 | Opening. Listen for sponsor prizes (xAI?), the Devpost link and the Saturday-night stub deadline | |
| 12:30 | **Kickoff**, B0, B1 | Claude + you |
| 1:30 | B4 (NFC on the phone ASAP) · B2 in parallel | Claude · DeepSeek |
| 3:00 | B3 · B5 | Codex · Claude |
| 5:00 | B6, B7 | Claude |
| 7:30 | B8 · B9 · then B10 | Codex · Cursor · Codex + Grok |
| **9:00** | **Checkpoint.** Make the Devpost stub now (it was due Saturday night in past years) | you |
| 9pm–4am | Add-ons in order: A1, A2, A3, then the rest | as listed |
| 4–7am | **Sleep.** Claude's window resets while you sleep | |
| 7–9am | Polish pass (Claude), bug fixes (Codex), screenshots, record the ~2 min video | |
| 9am | **Feature freeze.** README; Devpost write-up (DeepSeek drafts, you edit); repo public | DeepSeek, you |
| 10:30am | **Submit** (no edits after) | you |
| 11:30–2 | Judging at your table | you |

Before the demo: have your phone charged, 3 spare cards already linked to demo profiles (make them with friends or test accounts), and a backup screen recording of the demo path in case the Wi-Fi dies.

---

## Part 8. Demo and submission

**Demo (about 2 minutes):**
1. *Hook:* "How many people did you meet this weekend? How many of their names do you actually remember?"
2. *Tap:* scan a spare card linked to a demo friend. The screen floods violet, their badge drops in, and the stamp lands with "HUB · SUN 11:42 AM".
3. *Remember:* type "does robotics, from Portland" and tap Done. Open People, then their badge: socials, stamp, note.
4. *Payoff (with A1):* search "robotics person from DubHacks" and it finds them.
5. *Judge's card (with A3):* scan their card, show "Help them join", and let them make a badge on their own phone.
6. *Close:* "Every student already carries the card. It's the fastest way to connect, and the only way to remember."

**Likely questions:**
- *Why not NameDrop or an Instagram QR?* It works with a card anyone hands you (no unlocking, no menus), it shares socials rather than a phone number, and it remembers where and when you met.
- *Isn't it creepy?* Someone has to hand you their card, a scan only shows what they put on their badge, the raw card number never leaves the phone (only a salted hash is stored), and notes are private to whoever wrote them.
- *What about cards that change their ID?* The app only links cards that read the same twice; student IDs and transit cards do.

**Submission checklist:** Devpost page (Inspiration · What it does · How we built it · Challenges · Accomplishments · What we learned · What's next), screenshots of every screen, the ~2 min video, a public GitHub link with a README, the track(s) selected, "Built with" tags: SwiftUI, Core NFC, Supabase, Grok/xAI.

---

## Appendix A. Files to create (verbatim)

### `AGENTS.md`

~~~markdown
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
7. Never commit Config/Secrets.xcconfig and never print keys.

## Demo path (never break it)
Sign in → make badge → link card → scan another card → badge appears → saved with time and
place → shows in People → note visible on Person.
~~~

### `CLAUDE.md`

~~~markdown
@AGENTS.md

You are the architect. You own docs/PLAN.md and docs/TASKS.md. When kingston asks "what next?",
read PROGRESS.md and TASKS.md and answer with the next card, its owner, and the exact prompt to paste.
~~~

### `docs/PROGRESS.md`

~~~markdown
# Progress (update at the end of every session, then commit)

Last updated: <time> by <tool>

## Works now
- nothing yet

## In progress
-

## Next
- B0 Setup (kingston), then B1 Scaffold (Claude)

## Known bugs
-
~~~

### `docs/DECISIONS.md`

~~~markdown
# Decisions (one line each, newest last)

- Track: Chef's Choice (re-check sponsor prizes at opening).
- Base MVP = sign in, badge, link card, scan, note, People, Person, Me. Everything else is an add-on after the 9pm checkpoint.
- Card key = SHA-256(salt + NFC tag UID). Only cards that read the same twice can be linked.
- A meeting is stored as two rows, one per person, so notes stay private and RLS stays simple.
- Look: badges and stamps, violet on lilac paper, light only. Fonts: Bricolage Grotesque, Instrument Serif Italic, Geist Mono, system UI.
- In-app AI (add-ons) = Grok via Supabase Edge Functions; the key lives only in Supabase secrets.
- Web join page (A3) uses anonymous sign-in, since Apple sign-in on the web needs extra setup.
- Cut: map, voice notes, photo at scan, 5-tab dock, notifications.
~~~

### `.gitignore`

~~~
Config/Secrets.xcconfig
xcuserdata/
DerivedData/
.DS_Store
*.xcuserstate
.env
~~~

### `Config/Secrets.xcconfig` (git-ignored; kingston fills it)

~~~
// The $() stops xcconfig from reading // as a comment.
SUPABASE_URL = https:/$()/YOUR-PROJECT.supabase.co
SUPABASE_ANON_KEY = paste-anon-key
CARD_SALT = paste-32-random-characters
~~~
Expose each as an Info key with the same name (value `$(SUPABASE_URL)` and so on), and read them with `Bundle.main.object(forInfoDictionaryKey:)`.

### `scripts/pack.sh` (Claude writes this in B1)

Takes a card ID, finds that card in `docs/TASKS.md`, and copies to the clipboard (`pbcopy`): `AGENTS.md`, Part 3 of `docs/PLAN.md`, the card's text, and the current contents of every file the card lists (noting any file that doesn't exist yet). It prints how many characters were copied.

---

*Sources this plan is built from (in the DubHacks 2026 project): the PRD, Design Theme, App Flow and Plan docs from the brainstorm, the App Screens mockups, `dubhacks/ai-tools-plan.md`, and `dubhacks/dubhacks-2026-research.md`. Where this file and those disagree, this file wins: it is the simplified version kingston asked for on Oct 17.*
