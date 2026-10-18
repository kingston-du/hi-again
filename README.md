# hi again.

**Remember the people you meet.** Tap someone's student ID (or any NFC card) with your iPhone and their "HELLO my name is" sticker drops in with their socials, stamped with where and when you met. Later, open them in your People list to see their sticker, the place and time, and the note you wrote.

Built solo at **DubHacks 2026** (University of Washington).

## How it works

1. **Sign in** with Apple.
2. **Make your sticker:** first name (that's all you need), sticker color, an optional short bio, and optional contacts: Instagram, Snapchat, LinkedIn, TikTok, phone, Discord, email.
3. **Link your card:** scan your own Husky ID once. The app reads the card's chip ID and stores only a salted SHA-256 hash of it, never the ID itself.
4. **Tap someone's card:** their sticker appears on a full-screen result with a red "met at" rubber stamp. The meeting is saved for both of you with the time and your phone's location. Tapping the same card again within 2 minutes counts as one meeting.
5. **Write a note:** "What do you want to remember?"
6. **People:** everyone you've met, newest first, with pull to refresh. Open a person to see their sticker, socials (tap to open, Discord taps to copy), where you met, and your editable note.
7. **Me:** your sticker, edit it, relink or unlink your card, sign out.

**No app? Use the QR.** On the Me screen, **Let them scan** shows a QR code that opens a web page (`web/meet.html`, hosted on GitHub Pages). The other person sees your sticker and taps **Add Me** to make theirs in Safari, and the meeting is saved for you both.

## Screens

| Screen | File |
|---|---|
| Welcome (Sign in with Apple) | `HiAgain/Views/WelcomeView.swift` |
| Make your sticker | `HiAgain/Views/MakeBadgeView.swift` |
| Link your card | `HiAgain/Views/LinkCardView.swift` |
| People list + Scan button | `HiAgain/Views/PeopleView.swift` |
| Scan result (sticker + stamp + note) | `HiAgain/Views/ScanResultView.swift` |
| Person | `HiAgain/Views/PersonView.swift` |
| Me sheet (edit, card, QR, sign out) | `HiAgain/Views/MeView.swift` |
| Web meet page | `web/meet.html` |

## Tech stack

- **iOS app:** SwiftUI, iOS 17+, async/await. Project generated with [XcodeGen](https://github.com/yonaskolb/XcodeGen) from `project.yml`.
- **NFC:** Core NFC `NFCTagReaderSession` reads the tag identifier (MIFARE, ISO 7816, ISO 15693, FeliCa) in `Services/NFCService.swift`; `Services/CardHasher.swift` salts and hashes it.
- **Location:** Core Location, reverse-geocoded to a place name for the stamp (`Services/LocationService.swift`).
- **Backend:** [Supabase](https://supabase.com) via `supabase-swift`: Sign in with Apple and anonymous auth, Postgres with row-level security, and RPCs `claim_card`, `scan_card`, `unlink_card`, `public_badge`, `meet_via_web`.
- **Web:** a single static page (`web/meet.html`) using `supabase-js`, deployed by `.github/workflows/pages.yml`.
- **Design:** "HELLO my name is" stickers and rubber stamps, Archivo and Caveat Brush fonts, all tokens in `HiAgain/Theme.swift`. Spec in `docs/design/DESIGN-v3.md`.

## Repo layout

```
HiAgain/          SwiftUI app (Views, Components, Models, Services, Theme)
Config/           Info.plist, entitlements, Secrets.xcconfig (git-ignored)
supabase/         SQL to paste into the Supabase SQL Editor
web/              QR meet page for GitHub Pages
docs/             Plan, task board, progress log, decisions, design spec
project.yml       XcodeGen project definition
```

## Running it

You need a Mac with Xcode 16+, an iPhone with NFC (the simulator can't scan cards), and a free Supabase project.

### 1. Supabase

1. Create a project at [supabase.com](https://supabase.com).
2. In **SQL Editor**, run these files in order:
   1. `supabase/schema.sql` (tables, RLS, card and scan functions)
   2. `supabase/qr_meet.sql` (sticker slugs and the web meet functions)
   3. `supabase/profile_bio_contacts.sql` (bio and extra contacts)
3. **Authentication → Providers:** enable **Apple** (with your Services ID and key) and **Anonymous** (used by the web meet page).
4. From **Settings → API**, copy the Project URL and the anon public key.

### 2. Secrets

Create `Config/Secrets.xcconfig` (it is git-ignored, never commit it):

```
// The $() stops xcconfig from reading // as a comment.
SUPABASE_URL = https:/$()/YOUR-PROJECT.supabase.co
SUPABASE_ANON_KEY = YOUR-ANON-KEY
CARD_SALT = ANY-LONG-RANDOM-STRING
```

`CARD_SALT` must stay the same once people have linked cards, or their hashes won't match anymore.

### 3. Build and run

```bash
brew install xcodegen
```

```bash
xcodegen generate
```

```bash
open HiAgain.xcodeproj
```

In Xcode, select the **HiAgain** target, set your own team and bundle ID under **Signing & Capabilities** (the capabilities need Sign in with Apple and NFC Tag Reading), pick your iPhone, and press Run. To check that it builds from the command line:

```bash
xcodebuild -scheme HiAgain -destination 'generic/platform=iOS Simulator' build -quiet
```

### 4. Web meet page (optional)

For local testing, copy `web/config.example.js` to `web/config.js` (git-ignored) and fill in your URL and anon key. To deploy, set **Settings → Pages → Source** to GitHub Actions and add repository secrets `SUPABASE_URL` and `SUPABASE_ANON_KEY`; the workflow writes `config.js` at deploy time. Then point `MEET_PAGE_BASE_URL` in `Config/Info.plist` at your Pages URL.

## Privacy

- Card IDs are hashed on the phone with a secret salt; the database only sees the hash.
- RLS means you can read your own meetings and only the public sticker fields of people you've met. The only thing you can change on a meeting is your own note.

## DubHacks 2026

I'm a freshman at UW, and at the start of the year I meet dozens of people a week and forget most of their names. Swapping Instagrams means passing phones back and forth. hi again turns the card everyone already carries, the Husky ID, into a one-tap way to swap socials and remember where you met. Built over the DubHacks weekend with SwiftUI and Supabase, with Claude Code and Cursor working from a shared plan in `docs/`.

**Next up:** a "hi again" screen for the second time you tap someone, plain-words search over your notes ("career fair", "robotics"), and an App Clip so people without the app can join from a tap.
