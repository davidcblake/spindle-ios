# Spindle for iPhone

A daily scripture study companion, native on the
[Plug and Play](https://github.com/davidcblake/plug-and-play-ios) foundation.

**Nothing here works yet.** This is the scaffold: an app that builds against the
foundation and shows an empty journal. See [docs/roadmap.md](docs/roadmap.md)
for what is true today, which is very little.

## Build it

The Xcode project is generated rather than committed:

```bash
brew install xcodegen
xcodegen generate
open Spindle.xcodeproj
```

Signing is off in `project.yml` so CI can build without certificates. **Turn it
on in Xcode** (Signing & Capabilities → your team) before running on a device,
and add the iCloud/CloudKit capability before switching the store to `.synced`.

## Where the rest of Spindle lives

[`davidcblake/spindle`](https://github.com/davidcblake/spindle) — the web app,
the study API, the product spec, and the decision records for this rebuild.
