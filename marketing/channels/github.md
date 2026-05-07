# GitHub Channel

GitHub should be the first public launch surface because it already carries the
source, README, release artifact, checksum, and issue feedback loop.

## Goal

Make the repository understandable within one minute:

- what it is,
- who it is for,
- why it is stricter than normal break reminders,
- how to download or build it,
- what data stays local.

## Release Title

```text
TwentyGuard v1.5.0 - Strict 20-20-20 breaks for macOS
```

## Release Body Draft

TwentyGuard v1.5.0 is ready as a direct-download macOS release.

TwentyGuard is a native menu bar app for people who keep working through their
eye breaks. It follows the 20-20-20 rule, supports custom work rhythms, limits
repeated postpones, shows eye-health rhythm statistics, and can enforce an
optional night screen lock.

Why it is different from a normal reminder:

- full-screen break overlays instead of disposable notifications,
- cumulative postpone limits so breaks cannot be delayed forever,
- a verdict-first health report that shows completion and postpone patterns,
- optional evening wind-down and night lock,
- local-first storage for settings, logs, and statistics.

The v1.5.0 DMG is Developer ID signed, Apple-notarized, stapled, and accepted by
Gatekeeper.

Download:

```text
TwentyGuard-v1.5.0.dmg
```

SHA-256:

```text
8824ab01248c4534f2ea2c19d758ebff2da68d186b5023022f11274ca2ed0e88
```

Note: TwentyGuard is not medical software and does not make clinical claims. It
is a small utility for building firmer screen-break habits.

## Pinned Repository Description

```text
Strict 20-20-20 breaks for macOS. Native menu bar app with postpone limits,
health rhythm stats, and optional night screen lock.
```

## README Improvement Notes

Before pushing a broader launch:

- Add fresh screenshots from v1.5.0.
- Add the short demo GIF if available.
- Add a short limitations/medical-claims note.
- Add a link to the latest signed DMG release.
- Keep the privacy language factual: core behavior does not need network access;
  settings, logs, and statistics stay local.

## First GitHub Announcement Comment

```text
TwentyGuard v1.5.0 is out as a signed and notarized macOS DMG.

It is a native menu bar app for people who keep working through 20-20-20 eye
breaks. The main difference from a normal reminder is that breaks are harder to
ignore: full-screen overlay, capped postpones, a health rhythm report, and an
optional night screen lock.

Feedback on the strictness, install flow, and health report wording would be
especially useful.
```
