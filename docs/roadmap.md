# Roadmap

**This file is the single source of truth for status**, updated in the same
commit as the work it describes. If it says something is done, it is done on a
device — not "the code is written".

Last updated: 2026-10-06

## Phase 0 — It builds ✅ done (2026-09-07)

- [x] The Xcode project, generated from `project.yml`
- [x] A journal model that obeys CloudKit's schema rules
- [x] The journal screen, reading from the device, with its empty state
- [x] **A green build**, against the foundation at `0.1.0` —
      [run 34166265470](https://github.com/davidcblake/spindle-ios/actions/runs/34166265470).
      The first attempt failed exactly as predicted, on resolving a tag that did
      not exist yet; the tag was pushed and nothing else had to change.

**Done means:** CI builds the app against a tagged foundation.

## The goal: everything the web app does, then evolve it

**Decided 2026-10-06 by Dave:** the first version of Spindle for iPhone does
*everything the web app at `davidcblake/spindle` does today*, and nothing new.
Changes to the product wait until that copy is finished.

The list below was taken from the web app's **code**, not from its spec.
`docs/spindle-prd.md` is out of date: the live app also has a General
Conference section, My Thoughts, Settings, a welcome screen and Plans, and
none of those are in the spec.

There is no sign-in on purpose (`0001`): iCloud does the job the website's
accounts do.

## Phase 1 — Everything that does not need the server ⬜

None of this waits on decision `0002`.

- [x] **Scripture data:** five volumes, every book's chapter count, the
      single-chapter books, and D&C's two Official Declarations, copied from
      `src/lib/scripture.ts` together with its tests (`Sources/Scripture.swift`,
      `Tests/ScriptureTests.swift`). This is the repository's first test
      target, and CI now runs the tests as well as building: 14 tests in 2 suites
      green, [run 37549047583](https://github.com/davidcblake/spindle-ios/actions/runs/37549047583).
      One deliberate
      difference: declarations are written in their own order, not the order
      they were tapped
- [ ] **Choosing a passage:** volume, then book, then chapter tiles; pick
      several; the reference is written out as you go ("Alma 5–7, 32"); changing
      volume or book clears the chapters; 20 chapters at most, which is the
      server's limit
- [ ] **The study as types:** the eleven sections, including *From General
      Conference*. The contract is `src/lib/study.ts`; §6.2 of the spec is
      missing the conference section
- [ ] **The study screen:** all eleven sections in order; the ones a person
      has hidden are left out; scripture references and conference talks open in
      Gospel Library (copied from `src/lib/links.ts`)
- [ ] **Journal:** newest first, showing the reference, the date and the
      anchor line; opens with no connection; delete asks first
- [ ] **My Thoughts:** a person's own dated notes on a study; add and delete
- [ ] **Welcome:** on first launch, an invitation to fill in the profile.
      Every field is optional and can be skipped
- [ ] **Settings:** the profile (first name, calling, family, study focus,
      spiritual season); show or hide each study section; how widely to draw on
      general conference
- [ ] **Print or save as PDF** from any study
- [ ] **Offline:** "Offline — journal available"; Prepare explains why it
      cannot run; everything already saved still works
- [ ] **The details:** the header's "Feast upon the words of Christ" and the
      2 Nephi 25:26 footer

## Phase 2 — The two features that call the server ⬜

**Decision `0002` is made: App Attest** (Dave, 2026-10-06). What blocks this
phase now is server work in `davidcblake/spindle`, not a decision. Both endpoints of the web app's server (the
addresses the app calls) assume a signed-in website user. They turn away
anyone else, they read the profile from the website's database, and their
limits on how often someone can use them count rows that a phone saving to
iCloud never writes.

- [x] `0002` decided: App Attest (Dave, 2026-10-06)
- [ ] `/api/study` accepts the app: knows the caller is genuine, has its own
      usage limit per device, and takes the profile in the request, checking it
      and cutting it to a safe length on the server
- [ ] `/api/plan` the same
- [ ] **Preparing a study:** a loading state; the study saved before it is
      shown; errors that say what went wrong (no connection, the service
      refused, the study was cut off)
- [ ] **Plans:** describe what you want, get a plan back, open it, tick items
      off ("3 of 8 complete"), delete with a confirmation

## Phase 3 — iCloud on ⬜

- [ ] The store switched to `.synced`, once the CloudKit container is entitled
      and signed. **This is the first time the foundation's CloudKit code will
      ever have run.**
- [ ] The same journal, thoughts, plans and settings on a second device

## Phase 4 — TestFlight ⬜

- [ ] Signing, an App Store Connect record, a build uploaded
- [ ] A privacy policy and accurate privacy labels
- [ ] Somebody who is not Dave using it for a week

**Done means:** a person in the ward opens it on their own phone and studies.

## After the copy is finished — not before

Ideas that are not in the web app, so they wait:

- Dictation for My Thoughts through `PPInput`. The keyboard's own microphone
  already works on day one, as it does on the web.
- A daily reminder (`PPNotify`)
- Anything from the spec's v2 list, and the open question in
  `plug-and-play-ios/docs/where-we-are.md`: a study generator, or a
  conversational companion

## Known blockers

| Blocker | Blocks | Status |
|---|---|---|
| Server support for App Attest (`0002`, decided 2026-10-06) | Phase 2 (preparing a study and Plans) | Not started. Work in `davidcblake/spindle` |
| CloudKit container + signing | Phase 3 | Container exists; the app has never been signed |
