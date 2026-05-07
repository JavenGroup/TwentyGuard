# Launch Plan

## Goal

Run a credible public launch for a small native macOS utility that is useful
enough for daily use, easy to understand in one minute, and honest about what it
does and does not claim.

## Launch Thesis

```text
Most break reminders are easy to ignore. TwentyGuard is for people who need the
break to actually happen.
```

The product is not another wellness dashboard. It is a quiet macOS utility with
firm guardrails: full-screen breaks, capped postpones, rhythm feedback, and an
optional night cutoff.

## Current State As Of 2026-05-05

- Brand: `TwentyGuard`.
- Public subtitle: `Strict 20-20-20 breaks for macOS.`
- Repository: `https://github.com/JavenGroup/TwentyGuard`.
- Version: `1.5.0`.
- Distribution: direct-download DMG is documented as Developer ID signed,
  Apple-notarized, stapled, and Gatekeeper accepted.
- Website: not planned for the current launch scope.
- Marketing workspace: created, but channel drafts and launch assets are still
  incomplete.

## Phase 1: Make The Page Trustworthy

- Refresh the README opening with the final launch story if needed.
- Use the app icon as the README brand mark; keep the status bar glyph limited
  to menu bar UI.
- Add current screenshots for the actual v1.5.0 UI.
- Add a short demo GIF or video showing the complete loop:
  - menu bar countdown,
  - break overlay,
  - postpone limit,
  - health report,
  - night screen lock.
- Add a concise limitations section:
  - not medical advice,
  - direct-download Mac app,
  - local-only data storage,
  - requires macOS 12.0+.
- Confirm the release download link, checksum, and Gatekeeper note on the public
  page.

## Phase 2: Prepare Copy Once

Use `copy-bank.md` as the source for:

- one-sentence description,
- GitHub release note,
- short social post,
- longer founder-style story,
- FAQ,
- Chinese announcement copy,
- channel-specific variants.

Keep the message practical and modest. Do not promise to cure eye strain,
headaches, sleep issues, or vision problems.

## Phase 3: Verify Launch Risk

Record dated results in `evidence/naming-checks.md` before broad launch:

- App Store Connect name availability.
- Domain availability.
- Basic trademark search in key markets.
- Search-result review for `TwentyGuard` and similar spellings.
- Competitor/collision notes for nearby names.

Until those checks are done, keep the launch narrower and GitHub-centered.

## Phase 4: Channel Order

Recommended order:

1. GitHub release and pinned repository.
2. Personal blog or maker note explaining the problem and design choices.
3. Chinese community post if a Chinese screenshot set is ready.
4. Hacker News `Show HN` after the README, screenshots, and direct download flow
   feel polished.
5. Defer Product Hunt while there is no website or landing-page plan.

Avoid copying the same post across communities. Each channel should answer:
why this exists, who it is for, and what is different.

## Phase 5: Feedback Loop

Track:

- GitHub stars and forks.
- Release downloads.
- Issues opened.
- Common setup failures.
- Repeated feature requests.
- Which copy makes people understand the night screen lock feature.
- Whether people object to strictness or ask for softer modes.

## Launch Principle

Lead with the behavior change, not the feature list. The feature list supports
the story; it should not replace it.
