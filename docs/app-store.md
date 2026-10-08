# App Store Connect — drafted answers

**Written 2026-10-08, against the code as it is today.** Paste-ready, but read before
pasting: these are claims Apple holds the app to, and only Dave can make them.

## The listing

- **Name:** Spindle — Scripture Study
- **Subtitle (30 characters):** A Christ-centered study companion
- **Category:** Reference (primary), Education (secondary)
- **Age rating:** 4+. No objectionable content; the AI's output is limited to devotional
  study by its system prompt.
- **Privacy policy URL:** `https://spindlestudy.vercel.app/privacy` (live once spindle
  PR #5 is merged)

**Description:**

> Choose any passage in the standard works with a few taps, and Spindle prepares a
> Christ-centered study of it: where it sits, its background, the people, principles and
> patterns in it and where they echo across all four standard works, how it testifies of
> the Savior, teachings from general conference, questions to ponder, and one invitation
> to act.
>
> Every study is saved to your journal, which works without a connection. Add your own
> thoughts — type or dictate — and tap any reference to read it in Gospel Library.
>
> Describe what you want to study over the coming weeks, and Spindle builds a plan you can
> check off as you go.
>
> No account and no ads. Your journal stays on your iPhone.
>
> Spindle is not an official product of The Church of Jesus Christ of Latter-day Saints.
> Studies are prepared with AI; read the passages themselves, and let the scriptures and
> living prophets be the authority.

The last paragraph matters twice over: Apple reviews apps that use a church's name for
implied endorsement, and `AGENTS.md` says the app never presents itself as speaking for
the Church.

## The privacy questionnaire ("App Privacy")

**Does the app collect data?** Yes — two kinds, both declared on the cautious side.

| Apple's data type | Why it is declared | Purpose | Linked to the person? | Used for tracking? |
|---|---|---|---|---|
| **User Content → Other User Content** | Preparing a study or plan sends the passage or request and the profile text to the server and to Anthropic. The server keeps none of it, but Anthropic may hold it briefly under its own terms, which is enough to count | App Functionality | No | No |
| **Identifiers → Device ID** | The App Attest key id, kept with the times it was used, for hourly limits | App Functionality (preventing fraud) | No | No |

**Not declared, and why:**

- *Name, email, contact info:* never asked for.
- *The journal, thoughts, plans, profile at rest:* on the phone, and later in the person's
  own iCloud, which Apple does not count as collection because Spindle cannot read it.
- *Usage data, diagnostics, analytics:* none in the code.

**Tracking:** No. No ads, no third-party SDKs, no cross-app identifiers.

## Export compliance

The app uses only Apple's built-in encryption (HTTPS, App Attest). In App Store Connect
answer **"None of the algorithms mentioned above"** / exempt. Adding
`ITSAppUsesNonExemptEncryption = NO` to `project.yml` will stop the question appearing on
every upload; not done yet because it is a legal statement, which is Dave's to make.

## TestFlight

- **Internal testing** (up to 100 people on your App Store Connect team): no review, no
  privacy URL needed. Fastest way to put it on a second phone.
- **External testing** (the ward): needs the privacy URL, a short "What to Test" note, and
  a one-time beta review by Apple, usually a day.

Draft "What to Test":

> Prepare a study of a passage you are reading this week. Open it again from the Journal
> the next day, with your phone in airplane mode. Add a thought. Try a study plan. Tell
> Dave anything that confused you or that the web version did better.
