# Assets Shotlist

The launch story depends on people seeing that TwentyGuard is calm in appearance
but strict in behavior. Current screenshots are useful for orientation, but they
do not yet cover the v1.5.0 launch narrative.

## Current Assets

| Asset | Location | Current Use | Issue |
| --- | --- | --- | --- |
| Break overlay screenshot | `screenshots/break_reminder.png` | Shows full-screen break behavior | Background context appears old and GitHub-specific. |
| Menu bar screenshot | `screenshots/menu_bar_interface.png` | Shows menu structure | Does not show night screen lock, health report, or postpone limit. |
| README menu screenshot | `marketing/assets/menu-main-en-v1.5.2.png` | README and README_CN | Current v1.5.2 menu with postpone limit and night lock entry. |
| README break screenshot | `marketing/assets/break-overlay-en-v1.5.2.png` | README and README_CN | Current v1.5.2 break overlay with capped postpones. |
| README health screenshot | `marketing/assets/health-report-en-v1.5.2.png` | README and README_CN | Current v1.5.2 verdict-first health report. |
| App icon | `marketing/icons/twentyguard-app-icon-1024.png` | README and brand identity | Ready for README; social preview composition still needed. |
| Menu bar glyph | `Sources/TwentyGuard/Resources/statusbar_icon@2x.png` | In-app status item | Use only as functional UI glyph, not as primary logo. |
| Marketing asset folder | `marketing/assets/` | Intended destination for launch visuals | Now contains README screenshot assets; broader channel assets still needed. |

## Required Screenshot Set

Capture fresh screenshots from the current v1.5.2 build.

1. Menu bar main menu
   - Current README asset exists at `marketing/assets/menu-main-en-v1.5.2.png`.
   - Shows current countdown, `20-20-20`, custom mode, postpone limit, and
     night screen lock entry.
   - Use English for GitHub/HN; capture Chinese separately for Chinese channels.

2. Break overlay
   - Current README asset exists at `marketing/assets/break-overlay-en-v1.5.2.png`.
   - Shows countdown, three postpone buttons, and postpone status.
   - A cleaner neutral-background version would still be useful for broader
     channel assets.

3. Eye Health Report
   - Current README asset exists at `marketing/assets/health-report-en-v1.5.2.png`.
   - Shows the verdict-first dashboard.
   - Prefer future sample data that demonstrates completion rate, postpone count, and
     seven-day summary without looking alarming.

4. Night Screen Lock
   - Show the full-screen lock countdown.
   - Show recovery time and schedule line.
   - If the testing exit is visible, decide whether to hide it for public assets.

5. Direct Download / DMG
   - Optional, but useful for trust.
   - Show a clean install flow if publishing outside GitHub.

## Demo GIF Or Video

Target length: 20-35 seconds.

Storyboard:

1. Menu bar countdown is running.
2. Work interval ends.
3. Break overlay appears.
4. User postpones once.
5. Postpone status shows remaining limit.
6. Health report opens with a clear daily verdict.
7. Optional final frame: night lock schedule.

Keep the video quiet and direct. The product is a utility, not a cinematic app.

## Export Sizes

Recommended exports:

- README app icon: 96-128 px rendered from `marketing/icons/twentyguard-app-icon-1024.png`.
- README hero screenshot: 1600 px wide.
- GitHub inline screenshots: 1200-1600 px wide.
- Social preview: 1200 x 630.
- Product Hunt gallery, if used later: 1270 x 760.
- Chinese community post images: 1600 px wide, Chinese UI preferred.

Website assets such as favicon and website Open Graph images are not planned
for now. Keep the current asset work focused on GitHub, release notes, direct
download trust, and community posts.

## Visual Guidelines

- Use the real app UI, not mockups, for trust.
- Use the app icon for brand identity; use the status bar glyph only when the
  asset is specifically about the menu bar.
- Avoid busy or identifiable background content.
- Keep text readable at GitHub README width.
- Do not crop away the menu bar when the menu bar is the feature.
- Show the strict behavior, but keep the composition calm.
- Prefer current version UI over historical screenshots, even if older shots look cleaner.

## Asset Naming

Use predictable names under `marketing/assets/`:

```text
menu-main-en-v1.5.0.png
menu-main-zh-v1.5.0.png
break-overlay-en-v1.5.0.png
break-overlay-postpone-en-v1.5.0.png
health-report-en-v1.5.0.png
night-lock-en-v1.5.0.png
demo-loop-en-v1.5.0.gif
social-preview-en-v1.5.0.png
```
