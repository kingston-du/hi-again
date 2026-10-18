# hi again. Design v3: HELLO stickers and rubber stamps

Replaces Part 2 "Design" tokens and fonts in MEGA-PLAN.md (screens and flow are unchanged).
Mockups: App Screens canvas https://claude.ai/artifact/2Wkoeu6zGcJ32uSu6WGJDi

## The idea in one line
Every person is a real "HELLO my name is" sticker in their color, with their name in marker. Every meeting is a red rubber stamp. Everything else is plain, quiet iOS.

## What changed from v2 and why
| v2 | v3 | Why |
|---|---|---|
| Lilac paper `#F3F0FA`, violet `#5A3FF0` | Neutral paper `#F2F2EE`, ink `#141414`, stamp red `#D23B24` | Purple/indigo on lavender is the #1 tell of AI-made UI. Red is the color of real HELLO stickers and stamp pads |
| Scan screen floods violet | Scan screen floods stamp red | Same moment, new color |
| Bricolage Grotesque + Instrument Serif Italic accent words + Geist / Geist Mono labels | Archivo (variable width) + Caveat Brush (names only) + system SF Pro | Geist, italic-serif accent words and mono eyebrow labels are all on public "AI slop" lists |
| Portrait pastel badge with lanyard slot | Landscape HELLO sticker (real proportions) | It's an object everyone recognizes |
| Pastel badge colors (peach, lilac, mint, butter, sky, rose) | Sticker colors (red, blue, green, yellow, pink, black) | Pastels can't carry white "HELLO" text |
| Grain overlay, tilted cards everywhere, pill buttons with colored glow, big "42 people" number | No grain, tilt only on stickers and stamps, 14 pt-radius flat buttons, small count next to the title | Each was decoration without meaning |
| Floating Tap button | Large round red Scan button floating bottom center, labeled "Scan a card" | kingston asked for a big centered circle; the label says what it does |

## Tokens (`Theme.swift`)
| Token | Hex | Use |
|---|---|---|
| `paper` | `#F2F2EE` | Every screen background |
| `surface` | `#FFFFFF` | Grouped rows, inputs, the note card |
| `ink` | `#141414` | Text, primary buttons |
| `muted` | `#66665F` | Secondary text (5:1 on paper) |
| `faint` | `#9A9A92` | Placeholders, chevrons |
| `rule` | `#DDDDD6` | Borders, section rules |
| `ruleSoft` | `#ECECE6` | Dividers inside a group |
| `stamp` | `#D23B24` | Stamps, scan screen, wordmark period. Nothing else |
| `danger` | `#B8301C` | Unlink, Remove |
| `unknown` | `#F2C230` | "Not on the app yet" screen |
| `noteLine` | `#C7D4EC` | Blue rules on the note index card |

Badge colors (`BadgeColor` enum, text color on the band in brackets):
`red #D23B24 (white)`, `blue #2556C4 (white)`, `green #1D7A4F (white)`, `yellow #F2C230 (ink)`, `pink #C83C78 (white)`, `black #1E1E1E (white)`.
Change the enum to `red, blue, green, yellow, pink, black` and the `profiles.badge_color` default to `'red'`.

## Type
| Role | Font | Spec |
|---|---|---|
| Screen titles, headlines | Archivo ExtraBold (800), width 87.5 | 30 to 38 pt, tracking -0.3, line height 1.0 |
| Wordmark `hi again.` | Archivo Black (900), width 112 | 22 pt, period in `stamp` |
| "HELLO" on stickers | Archivo Black (900), width 125 | ~12% of sticker width, tracking +2 |
| "my name is" | Archivo SemiBold 600 | ~4.3% of sticker width |
| Names on stickers, Me initial | Caveat Brush | ~24% of sticker width, never anywhere else |
| Stamp text | Archivo Bold/Black, width 75 | Caps |
| Everything else (UI, body, buttons, notes) | System SF Pro | 13 to 17 pt |

Fonts: Google Fonts "Archivo" (variable, includes wdth axis) and "Caveat Brush". Drop Bricolage, Instrument Serif, Geist, Geist Mono. In SwiftUI set width with `.fontWidth(...)` only on system fonts; for Archivo register the static instances you need (Archivo-ExtraBold SemiCondensed, Archivo-Black Expanded) or use the variable font with a `wdth` variation.

## Components
- **Sticker** (`.row` 46x31, `.medium` 260x170, `.large` 300x196; ratio ~1.53). Radius 12 (large) / 5 (row). Color band fills the whole sticker; "HELLO" + "my name is" centered on top; a white panel (radius 5, inset 8 left/right, 12 bottom) with the first name in Caveat Brush. Shadow: `0 1 2` ink 18% plus `0 8 18` ink 8%. `.row` shows only the band and the panel with the first initial. Tilt: -2° to -5° on `.large`, 0 on forms and rows.
- **Stamp** (`.large` 116 pt on Welcome/Scan, 92 pt on Person). Two circles (outer stroke 2.6, inner 1.2 at r 31/47 of 100). Place only around the ring in caps (fallback `HI AGAIN`); "MET", date `OCT 17`, time `2:14 PM` in the middle — date appears once. Color `stamp` (white on the scan screen). Rotate -12° to +14°, slight ink roughness (displacement), 92% opacity. On the large badge it overlaps the bottom-right corner.
- **Scan button**: 92 pt circle in `stamp`, floating bottom center (62 pt above the bottom edge), thin white inner ring at 6 pt inset (like a stamp), white ID-card-with-waves icon 38 pt, shadow `0 2 4` ink 18% + `0 14 28` ink 16%. Caption "Scan a card" (SF Semibold 13, ink) centered under it. VoiceOver label "Scan someone's card".
- **Primary button**: 54 pt tall, radius 14, `ink` fill, white SF Semibold 17. On the red scan screen it inverts to white with ink text. No shadows, no pills.
- **Grouped rows**: iOS inset-grouped style, white, 1 pt `rule` border, radius 12, rows 50 pt, `ruleSoft` dividers.
- **People row**: `.row` sticker, name (SF Semibold 17) with time on the right (13 `muted`), place (14 `muted`), first line of the note (14 `ink`, one line). Hairline under each row. Grouped by day with a small `muted` day header.
- **Note card** (scan screen): white index card, radius 6, the question label underlined in `stamp`, then blue `noteLine` rules.

## Screens (see canvas)
Welcome · Make your badge · Link your card · People · Scan result · Person · Me sheet, plus People empty and Unknown card. Layout notes:
- Welcome: wordmark top left, tilted Maya sticker with stamp, left-aligned headline and line of body, black Sign in with Apple at the bottom.
- Make your badge: live sticker preview, six square swatches (selected = 2 pt ink ring with a paper gap), first/last name, socials in one grouped box (`@` prefix for Instagram/Snapchat, `in/` for LinkedIn), "At least one" hint, Next.
- People: "People" title with the count in `muted` next to it, your initial in a circle of your badge color top right (opens Me), day-grouped rows, the round Scan button floating at the bottom center.
- Scan result: full `stamp` red. Large sticker drops in, white stamp thunks onto its corner (stamp owns when), "You met Maya." + place (+ "You've met before" / bio if any), social buttons (white 1.5 pt outline, label + handle), note index card, white Done. No separate date line.
- Person: back "People", `…` menu, large sticker, centered full name in ink SF Semibold 17 (when last name exists; sticker already owns first name), bio in `muted` centered under it, socials as grouped rows with ↗, then "Where you met": one stamp beside the place name (no sidecar date — stamp has it), and below it your note on the index card (tap to edit; empty shows "Add a note" in `faint`). You tap a card once, so there is one meeting per person, not a list.
- Me: sheet with "You" and Done, your sticker, "This is what people see when they tap your card.", Edit badge, Your card (Linked · 4F2A, Relink, Unlink in `danger`), Sign out.

## Rules that keep it from looking AI-made
No gradients, glows, glass, grain or colored shadows. No mono "eyebrow" labels, no italic-serif accent words, no emoji. Red appears only on stamps, the Scan button, the scan screen and the wordmark period. Text is left-aligned except inside stickers and stamps, and the Person identity block (full name + bio under the sticker). Motion: the sticker drop (spring, response 0.45, damping 0.75) and a stamp thunk (scale 1.15 → 1.0 in 0.12 s with a rigid haptic); everything else uses default iOS transitions. Respect Reduce Motion.
