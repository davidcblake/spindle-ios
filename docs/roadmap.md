# Roadmap

**This file is the single source of truth for status**, updated in the same
commit as the work it describes. If it says something is done, it is done on a
device — not "the code is written".

Last updated: 2026-09-07

## Phase 0 — It builds ✅ done (2026-09-07)

- [x] The Xcode project, generated from `project.yml`
- [x] A journal model that obeys CloudKit's schema rules
- [x] The journal screen, reading from the device, with its empty state
- [x] **A green build**, against the foundation at `0.1.0` —
      [run 34166265470](https://github.com/davidcblake/spindle-ios/actions/runs/34166265470).
      The first attempt failed exactly as predicted, on resolving a tag that did
      not exist yet; the tag was pushed and nothing else had to change.

**Done means:** CI builds the app against a tagged foundation.

## Phase 1 — A study on the phone ⬜

- [ ] The study JSON decoded into types (the contract is `docs/spindle-prd.md`
      §6.2 in the web repository)
- [ ] Passage selection across the standard works
- [ ] The ten-section study view
- [ ] Preparing a study — needs the API to accept a caller with no account,
      which is decision `0002` and is server work, not app work

## Phase 2 — Sync and the rest ⬜

- [ ] The store switched to `.synced`, once the CloudKit container is entitled
      and signed. **This is the first time the foundation's CloudKit code will
      ever have run.**
- [ ] Thoughts on an entry, with dictation (`PPInput`)
- [ ] A daily reminder (`PPNotify`)
- [ ] Gospel Library deep links
- [ ] Study plans

## Phase 3 — TestFlight ⬜

- [ ] Signing, an App Store Connect record, a build uploaded
- [ ] A privacy policy and accurate privacy labels
- [ ] Somebody who is not Dave using it for a week

**Done means:** a person in the ward opens it on their own phone and studies.

## Known blockers

| Blocker | Blocks | Status |
|---|---|---|
| Decision `0002` — how the API knows a caller with no account | Preparing a study | Proposed, recommending App Attest. Dave's call |
| CloudKit container + signing | Phase 2 | Container exists; the app has never been signed |
