# Assets Shotlist

The launch story depends on people seeing that TwentyGuard is calm in appearance
but strict in behavior. Current screenshots are useful for orientation, but they
do not yet cover the v1.5.0 launch narrative.

## Current Assets

| Asset | Location | Current Use | Issue |
| --- | --- | --- | --- |
| Break overlay screenshot | `screenshots/break_reminder.png` | Shows full-screen break behavior | Background context appears old and GitHub-specific. |
| Menu bar screenshot | `screenshots/menu_bar_interface.png` | Shows menu structure | Does not show night screen lock, health report, or postpone limit. |
| App icon | `marketing/icons/twentyguard-app-icon-1024.png` | README and brand identity | Ready for README; social preview composition still needed. |
| Menu bar glyph | `Sources/TwentyGuard/Resources/statusbar_icon@2x.png` | In-app status item | Use only as functional UI glyph, not as primary logo. |
| Marketing asset folder | `marketing/assets/` | Intended destination for launch visuals | Currently empty except `.gitkeep`. |

## Required Screenshot Set

Capture fresh screenshots from the current v1.5.0 build.

1. Menu bar main menu
   - Show current countdown.
   - Show `20-20-20`, custom mode, postpone limit, and night screen lock.
   - Use English for GitHub/HN; capture Chinese separately for Chinese channels.

2. Break overlay
   - Use a neutral desktop or app background.
   - Show the countdown and three postpone buttons.
   - Capture a second state where postpone status is visible.

3. Eye Health Report
   - Show the verdict-first dashboard.
   - Prefer sample data that demonstrates completion rate, postpone count, and
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
