# Spindle for iPhone — rules

**The foundation's rulebook applies here.** Read
[`plug-and-play-ios/AGENTS.md`](https://github.com/davidcblake/plug-and-play-ios/blob/main/AGENTS.md)
first. Everything it says about native SwiftUI, strict concurrency, no
singletons, local-first, and what "done" means is true in this repository too.
This file records only what is different because this is an app rather than the
foundation.

## What this is

Spindle: a daily scripture study companion for members of The Church of Jesus
Christ of Latter-day Saints, rebuilt native on the Plug and Play foundation.
The product spec is `docs/spindle-prd.md` in
[`davidcblake/spindle`](https://github.com/davidcblake/spindle), which is also
where the web app and the study API live.

**This app exists to build faith.** Its content is devotional, drawn from the
standard works and the teachings of living prophets, and it never surfaces
controversy or criticism. That is a product rule, not a style note, and it
outranks anything that would make the app more impressive.

## What is different here

- **The foundation test does not apply.** That rule decides what belongs in
  `plug-and-play-ios`. Here the question is the opposite one: *is this
  Spindle-specific, or should it be in the foundation so the other three apps
  get it too?* If the answer is the latter, it goes there, in a pull request,
  with the foundation test answered.
- **This app depends on a tagged version of the foundation**, never `main`.
  Taking a newer tag is a decision somebody makes on purpose.
- **There is no sign-in.** iCloud is the account. If a screen ever needs to know
  who somebody is, that is a decision record, not a login form.
- **Nothing generated is authoritative.** A study says what it drew on so a
  person can go and read the passage themselves, and the app never presents
  itself as speaking for the Church.

## Decision records

The architecture decisions for this rebuild live in
[`davidcblake/spindle/docs/decisions`](https://github.com/davidcblake/spindle/tree/main/docs/decisions),
because the first of them is about the web app and the API as much as the phone:

- `0001` — rebuilding natively on Plug and Play, and where the journal lives
- `0002` — who may call the study API when nobody has an account
