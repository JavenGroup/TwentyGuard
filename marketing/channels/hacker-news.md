# Hacker News Channel

Use only after the README, screenshots, and download flow are polished. Check
current Show HN norms before posting.

## Best Angle

Transparent maker post:

- built a small native Mac app,
- problem is not knowledge of the 20-20-20 rule but avoidance,
- stricter than notification reminders,
- local-first and open source,
- asking for feedback on strictness and Mac UX.

## Title Options

```text
Show HN: TwentyGuard - strict 20-20-20 breaks for macOS
```

```text
Show HN: A native Mac app that makes 20-20-20 breaks harder to ignore
```

```text
Show HN: TwentyGuard, a local-first Mac break timer with capped postpones
```

## Body Draft

I built TwentyGuard, a small native macOS menu bar app for people who keep
working through their eye breaks.

The idea is simple: most break reminders are easy to dismiss. That is fine for
people who already have good habits, but it did not solve my actual problem,
which was always negotiating for one more compile, one more message, or one more
video.

TwentyGuard follows the 20-20-20 rule, but tries to be firmer than a normal
notification:

- full-screen break overlays across monitors,
- 1/2/5 minute postpones with a cumulative limit,
- custom work/rest rhythms,
- a health report that shows completion and postpone patterns,
- optional night screen lock for an evening cutoff.

It is local-first. Core behavior does not need network access, and settings,
logs, and statistics are stored on the Mac. The current v1.5.0 DMG is Developer
ID signed and notarized.

This is not medical software and does not claim to cure eye strain. It is a
small utility for people who already know they should rest and want a stricter
tool to make that happen.

I would especially appreciate feedback on:

- whether the strictness feels useful or too aggressive,
- the direct-download install flow,
- the health report wording,
- what you would expect from a native Mac utility like this.

## Posting Checklist

- Fresh screenshots are in README.
- Download link points to the latest release.
- Checksum is visible.
- No medical claims.
- The first comment is ready with technical details if people ask.

## First Comment Notes

Useful details to have ready:

- macOS 12.0+.
- Swift/AppKit native app.
- MIT license.
- Local data path and privacy behavior.
- Why direct download is used.
- How strict mode and postpone limits work.
