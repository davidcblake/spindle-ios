# Roadmap

**This file is the single source of truth for status**, updated in the same
commit as the work it describes. If it says something is done, it is done on a
device — not "the code is written".

Last updated: 2026-09-07

## Phase 0 — It builds ⏳ in progress

- [x] The Xcode project, generated from `project.yml`
- [x] A journal model that obeys CloudKit's schema rules
- [x] The journal screen, reading from the device, with its empty state
- [ ] **A green build.** Blocked: `project.yml` depends on the foundation at
      `0.1.0`, and that tag does not exist yet. The first CI run will fail to
      resolve the package and say so plainly. It goes green when the tag is
      pushed — nothing else about this repository has to change.

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
| The foundation has no `0.1.0` tag | Phase 0 | Waiting on Dave. This session's git proxy refuses tag pushes (403), so it cannot be done from here |
| Decision `0002` — how the API knows a caller with no account | Preparing a study | Proposed, recommending App Attest. Dave's call |
| CloudKit container + signing | Phase 2 | Container exists; the app has never been signed |
