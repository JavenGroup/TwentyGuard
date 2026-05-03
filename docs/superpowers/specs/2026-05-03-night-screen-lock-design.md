# Night Screen Lock Design

Date: 2026-05-03

## Goal

Add an optional night restriction mode that gradually tightens screen-use cycles in the evening, then blocks the screen completely overnight.

## User-facing Behavior

- The feature is off by default.
- Defaults when enabled:
  - Wind-down starts at 20:00.
  - Full lock starts at 21:00.
  - Screen unlocks at 07:00 the next morning.
- During wind-down, the configured work duration is reduced in three equal time stages:
  - 75% of the base work duration.
  - 50% of the base work duration.
  - 25% of the base work duration.
- Stage limits are rounded down to 5-minute increments, with a minimum of 5 minutes.
- During full lock, all screens are covered by a night lock overlay.
- The night lock overlay shows the recovery time, countdown, and schedule.
- During early testing, the overlay includes a small testing escape that dismisses the lock for the current night only.

## UI

- Menu section under Settings:
  - Night Screen Lock submenu.
  - Enable Night Screen Lock toggle.
  - Wind-down start time selector.
  - Full lock time selector.
  - Morning unlock time selector.
  - Today rhythm summary.
  - Testing escape toggle.
- Break overlays display a night wind-down hint when the app is in a wind-down stage.
- Full night lock overlay has no normal app quit control.

## Policy

The core policy is independent from AppKit so it can be tested with deterministic dates.
