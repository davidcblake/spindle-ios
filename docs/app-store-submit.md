# Submitting Spindle to the App Store: every field, ready to paste

**For Dave. Written 2026-11-28 against build 7 and later.** Go top to bottom in
App Store Connect › Apps › Spindle. Each field shows what to paste. The claims
in it (privacy, age rating, export compliance) are yours to make. They're written
to match the code, and `docs/app-store.md` explains why each answer is what it is.

Before submitting: make sure iCloud sync has been seen working on two devices with
build 7 or later, and that a few people have used it for a week through TestFlight.

---

## 1. Screenshots

Actions tab of `davidcblake/spindle-ios` › **App Store screenshots** › **Run workflow**
› wait about 15 minutes › open the finished run › download **app-store-screenshots**.

Inside: `1-today`, `2-study`, `3-journal`, `4-plans` (light) and the same four in
dark mode. All are 1320 × 2868, the **6.9-inch** size. In App Store Connect ›
**App Store** tab › **iPhone 6.9" Display**, drag in the four light ones in order.
Apple scales them for smaller iPhones on its own.

They show sample content written for the purpose (a study of Alma 32, a thought,
a plan on faith), not anyone's real journal.

## 2. App Information (left sidebar)

| Field | Paste |
|---|---|
| Name | `Spindle — Scripture Study` |
| Subtitle | `Christ-centered daily study` |
| Category | Primary **Reference**, secondary **Education** |
| Content rights | Apple asks whether the app contains, shows or accesses third-party content. Spindle quotes short scripture verses and names conference talks, then links to Gospel Library for the rest. The honest answer is **Yes**, and Apple then asks you to confirm you have the rights. Short quotation for personal study is ordinary practice, but this is the question the Church permission letter (`docs/permission-letters.md`) settles for good. Your call. |
| Age rating | Answer **None** / **No** to every question → **4+** |

## 3. Pricing and Availability

- Price: **Free** (USD 0.00)
- Availability: all countries, or just the United States to start

## 4. App Privacy

- Privacy Policy URL: `https://spindlestudy.vercel.app/privacy`
- **Get Started** › "Do you or your third-party partners collect data from this app?" › **Yes**
- Tick exactly two data types:
  1. **User Content › Other User Content**
     - Used for: **App Functionality**
     - Linked to the user's identity? **No**
     - Used for tracking? **No**
  2. **Identifiers › Device ID**
     - Used for: **App Functionality**
     - Linked to the user's identity? **No**
     - Used for tracking? **No**
- Nothing else. Not audio (Speak is recognized on the phone), not contact info, not
  usage data. The journal in the person's own iCloud isn't "collected", because
  Spindle can't read it.
- **Publish**.

## 5. The version page (App Store tab › 1.0 Prepare for Submission)

**Promotional text** (170 characters max, can change any time without review):

> Choose a passage and receive a Christ-centered study of it: its people, principles and patterns across the standard works, with questions to ponder and an invitation.

**Description:**

> Choose any passage in the standard works with a few taps, and Spindle prepares a Christ-centered study of it: where it sits, its background, the people, principles and patterns in it and where they echo across all four standard works, how it testifies of the Savior, teachings from general conference, questions to ponder, and one invitation to act.
>
> Every study is saved to your journal, which works without a connection. Add your own thoughts, typed or spoken, and tap any reference or talk to read it in Gospel Library.
>
> Describe what you want to study over the coming weeks, and Spindle builds a plan you can check off as you go. A gentle daily reminder can help you keep the habit.
>
> No account and no ads. Your journal stays on your iPhone and in your own private iCloud, so it is there on a new phone too.
>
> Spindle is not an official product of The Church of Jesus Christ of Latter-day Saints. Studies are prepared with AI; read the passages themselves, and let the scriptures and living prophets be the authority.

**Keywords** (100 characters max, commas, no spaces needed):

```
scriptures,Book of Mormon,Bible,gospel,Jesus Christ,general conference,journal,study plan,faith
```

| Field | Paste |
|---|---|
| Support URL | `https://spindlestudy.vercel.app/support` |
| Marketing URL | leave empty |
| Version | `1.0` |
| Copyright | `2026 David Blake` |

**Build:** click **+** next to Build and choose the newest (1.0 (7) or later).

## 6. App Review Information

- Sign-in required: **No** (untick). Spindle has no accounts.
- Contact: your name, phone and email (Apple only uses them to reach you about review).
- **Notes** (paste):

> Spindle has no sign-in; open it and tap "Skip for now" or fill in the optional profile. To try it: tap the round + button, choose a book and a chapter (for example Alma 32), and tap Prepare Study. A study is prepared by our server in about 20–40 seconds using an AI model with a system prompt limited to faithful, devotional scripture study. Every conference talk it names is checked against the list of real talks before it is shown. The journal is stored on the device and in the user's private iCloud (CloudKit); our server keeps no studies. Speak (dictating a thought) uses on-device speech recognition only. Spindle is an independent app and says so in the app and the listing; it is not affiliated with or endorsed by The Church of Jesus Christ of Latter-day Saints.

## 7. Release and submit

- Version release: **Manually release this version** (so you choose the day), or
  automatically after approval.
- **Add for Review** › **Submit to App Review**.

Review usually takes one to two days. If Apple writes back with a question, paste it
into a Claude session and the reply can be drafted from the code.
