# Launch Readiness

Status labels:

- `Done` - supported by current repo docs or existing assets.
- `Missing` - needed before a broad public launch.
- `Needs verification` - may be true, but must be checked close to posting.
- `Optional` - useful, but not required for the first public pass.

## Product And Distribution

| Item | Status | Notes |
| --- | --- | --- |
| Public brand is `TwentyGuard` | Done | README, version history, and current docs use the name. |
| One-line positioning | Done | `Strict 20-20-20 breaks for macOS.` |
| Direct download artifact | Done | v1.5.0 DMG is documented as signed, notarized, stapled, and Gatekeeper accepted. |
| Checksum surfaced | Done | SHA-256 is present in README and docs. |
| macOS requirement | Done | macOS 12.0+. |
| License | Done | MIT is referenced in README. |
| Local-first privacy claim | Done | README says core behavior does not need network access and data stays local. |

## Public Page

| Item | Status | Notes |
| --- | --- | --- |
| English README | Done | Strong enough for GitHub-first launch. |
| Chinese README | Done | Useful for China/community launch. |
| Screenshot set | Missing | Current screenshots are partial and appear older than v1.5.0 messaging. |
| Demo GIF/video | Missing | Needed to show strict overlay and postpone limit quickly. |
| README app icon | Done | README and README_CN use the stable app icon export, not the status bar glyph. |
| FAQ | Missing | Draft in `copy-bank.md`; should be promoted when stable. |
| Limitations section | Missing | Should explicitly avoid medical claims and explain direct-download expectations. |
| Issue template | Optional | Useful before broader traffic. |

## Assets

| Asset | Status | Notes |
| --- | --- | --- |
| Menu bar screenshot | Needs refresh | Existing `screenshots/menu_bar_interface.png` does not show night screen lock or postpone limit. |
| Break overlay screenshot | Needs refresh | Existing `screenshots/break_reminder.png` shows the old GitHub background context. |
| Health report screenshot | Missing | Important for differentiating from simple timers. |
| Night screen lock screenshot | Missing | Important for the sharper story. |
| DMG/install screenshot | Optional | Useful for direct-download trust. |
| App icon export | Done | Stable export lives at `marketing/icons/twentyguard-app-icon-1024.png`. |
| Status bar glyph | Done | Stronger solid template glyph is installed in app resources. |
| GitHub social preview | Missing | Should use app icon plus name/tagline; no website is planned for now. |

## Market And Naming Risk

| Item | Status | Notes |
| --- | --- | --- |
| App Store Connect availability | Needs verification | Record dated result in `evidence/naming-checks.md`. |
| Domain availability | Needs verification | Record exact domains checked and date. |
| Basic trademark search | Needs verification | Do not infer safety from search results alone. |
| Search collision review | Needs verification | Check exact name and similar spellings before broad launch. |

## Channel Preparation

| Channel | Status | Notes |
| --- | --- | --- |
| GitHub | Drafted | See `channels/github.md`. |
| Hacker News | Drafted | See `channels/hacker-news.md`; verify current Show HN norms before posting. |
| Chinese channels | Drafted | See `channels/china.md`; needs Chinese screenshots. |
| Reddit | Missing | Should be subreddit-specific, not a generic cross-post. |
| Product Hunt | Deferred | No website/landing-page plan for now; revisit only if launch scope expands. |

## Recommended Next Step

Make the first launch pass GitHub-first:

1. Refresh the screenshot set.
2. Finalize GitHub release copy.
3. Add a short FAQ to README or release notes.
4. Verify download link and checksum.
5. Post one focused announcement, then collect feedback before wider channels.
