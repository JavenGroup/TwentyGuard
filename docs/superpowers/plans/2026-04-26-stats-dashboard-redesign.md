# Health Stats Dashboard Redesign

## Problem
- The current stats window uses absolute frames in a fixed-size window, so content overlaps and the close button covers weekly stats.
- Stats logic is embedded in the UI and still mixes session count, postpone count, break completion, and weekly date windows.
- App restart fragments and stale overnight sessions can pollute daily and weekly totals.

## Direction
- Keep SQLite `sessions` as the canonical stats source.
- Add a pure Swift stats engine that can be tested without AppKit or SQLite.
- Replace `SimpleStatsWindow` usage with a scrollable dashboard window backed by the new snapshot model.

## Stats Rules
- Use the latest seven calendar days including today, not a rolling 168-hour window.
- Ignore completed sessions shorter than 60 seconds.
- Exclude impossible stale sessions from health totals and report them as data-quality issues.
- Count break opportunities separately from completed breaks.
- Count postponed sessions separately from total postpone actions.
- Show data-quality warnings instead of silently hiding suspicious records.

## Verification
- Add unit tests for the stats engine.
- Build with the project Makefile.
- Install through `make install` and launch the `/Applications` version.
