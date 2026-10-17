# Decisions (one line each, newest last)

- Track: Chef's Choice (re-check sponsor prizes at opening).
- Base MVP = sign in, badge, link card, scan, note, People, Person, Me. Everything else is an add-on after the 9pm checkpoint.
- Card key = SHA-256(salt + NFC tag UID). Only cards that read the same twice can be linked.
- A meeting is stored as two rows, one per person, so notes stay private and RLS stays simple.
- Look: badges and stamps, violet on lilac paper, light only. Fonts: Bricolage Grotesque, Instrument Serif Italic, Geist Mono, system UI.
- In-app AI (add-ons) = Grok via Supabase Edge Functions; the key lives only in Supabase secrets.
- Web join page (A3) uses anonymous sign-in, since Apple sign-in on the web needs extra setup.
- Cut: map, voice notes, photo at scan, 5-tab dock, notifications.
