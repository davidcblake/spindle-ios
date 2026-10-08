# Your checklist, Dave — in order

**Written 2026-10-08.** Everything the app needs that only you can do, because it
happens in your Apple, Vercel or Supabase accounts or on your Mac. Each step says
roughly how long it takes and how you know it worked. Nothing here needs code.

## 1. Switch on the study server (~10 min, any computer)

Full steps are in `SETUP.md` §6 in the **spindle** repository. In short:

1. **Supabase → SQL editor:** paste and run `supabase/migrations/0005_app_attest.sql`.
2. **Make a secret:** on a Mac, Terminal → `openssl rand -base64 48`. Copy it.
3. **Supabase → SQL editor:** run the one `insert` line at the bottom of that same file,
   with your secret pasted in.
4. **Vercel → spindle → Settings → Environment Variables:** add
   - `APP_SERVER_SECRET` = the same secret
   - `APPLE_TEAM_ID` = your 10-character Team ID (developer.apple.com → Account →
     Membership details)

   then **Redeploy**.

**You know it worked when** `https://spindlestudy.vercel.app/api/app/challenge` in a
browser shows `{"challenge":"…"}` instead of "isn't set up on the server yet".

## 2. Check Apple's certificate (~3 min, one time)

The session that wrote the server could not reach apple.com, so it wrote Apple's App
Attest root certificate from memory and proved it intact mathematically. One human look
closes the gap: `SETUP.md` §6 step 5.

## 3. Tick App Attest for the app (~2 min)

developer.apple.com → Certificates, Identifiers & Profiles → Identifiers →
`com.wpv.spindle` → tick **App Attest** → Save.

## 4. Put it on your iPhone (~20 min the first time)

On the Mac:

```
git clone https://github.com/davidcblake/spindle-ios
cd spindle-ios
brew install xcodegen      # once
xcodegen generate
open Spindle.xcodeproj
```

In Xcode: Spindle target → **Signing & Capabilities** → tick *Automatically manage
signing*, choose your team. Plug in the iPhone, pick it at the top, press ▶.

**Expect rough edges.** It is the first time any of this has run on a phone. Try, and tell
me what you see:

- [ ] The welcome screen, then the four tabs
- [ ] Choose Alma 32 → **Prepare Study** → a study appears and is in the Journal
- [ ] A Gospel Library link opens Gospel Library
- [ ] Add a thought; delete one
- [ ] Share → Print / Save PDF
- [ ] Create a plan; tick an item
- [ ] Airplane mode: the journal still opens; Prepare explains why it can't
- [ ] Settings: hide a section, and it disappears from a study

## 5. Give the privacy page an email address (~1 min)

spindle PR #5 adds the privacy policy at `/privacy`. It needs the address people should
write to; it is a placeholder until then, which is why the PR is not merged. Tell me the
address and I will finish it.

## After that

- **iCloud sync** (roadmap Phase 3). I need the CloudKit container's exact name —
  developer.apple.com → Identifiers → iCloud Containers — it probably reads
  `iCloud.com.wpv.spindle`. Getting it wrong is a crash on launch, so it is not guessed.
- **TestFlight** (Phase 4). The App Store Connect answers are drafted in
  `docs/app-store.md`, ready to paste.
