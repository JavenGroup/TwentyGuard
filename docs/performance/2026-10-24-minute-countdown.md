# Minute countdown and independent deadlines: 2026-10-24

The user selected minute-level work countdowns. This record describes the local **1.7.10 candidate**, performance-measured implementation commit `9365663e73036e8e77372507e3b1ff898110f958` plus the subsequent stale-overlay cleanup fix, based on `839908d` / installed 1.7.9. Coordinator review subsequently approved `fef639e8d06018e07d0acce08d38cba8979eaad5`; the final section records landing and local installation. No public release or DMG upload was performed.

## Result and behavior

Ordinary work countdowns show the ceiling of remaining minutes, switching to seconds for the last 60 seconds. The existing show/hide preference is preserved and there is no new mode selector. Open menus and break overlays retain second updates; postponed breaks, temporary disable and night override retain their existing countdown presentation.

`CountdownTiming` derives the next display change and an independent action deadline from absolute dates. `CountdownScheduler` owns at most one timer for each purpose. Work/rest/postpone/temporary-disable completion, all night tightening stages, screen lock/unlock and override expiry are action deadlines; display callbacks never execute them or replace a pending action. The status icon is loaded and set once, and closed-menu titles are not refreshed.

Both kinds of timer and the unchanged ten-second snapshot heartbeat run in common/event-tracking modes. Clock, time-zone and date notifications recreate the Calendar-dependent night policies, cancel the old timers, recheck current state and reschedule on the main thread. Sleep/lock still save a paused session immediately; waking still starts a fresh work cycle, subject to the original night/temporary-disable policies. No statistics schema, postpone limit, break duration, night override cost or session validity threshold changed.

## Regression evidence

- Initial timing regression: the previous one-second cadence failed the minute boundary, hidden-countdown, fractional-second and due-display assertions. The real event-tracking-mode test also failed until the timer explicitly joined that mode.
- Deterministic simulation: two ordinary work minutes produce **2 display callbacks and 0 deadline polls**; a full 1,500-second work cycle produces **83–84 display callbacks and exactly one work deadline**. Hidden countdowns still complete at the same exact deadline. Open-menu seconds reuse the same action timer.
- Tests cover simultaneous display/action times, stale callback cancellation, restoration without orphan timers, clock rearming, every night tightening stage, lock/unlock, override expiry, a fresh Calendar after a time-zone change, DST, display sleep, and fractional work/rest/postpone/disable boundaries.
- Coordinator pre-review found an actual temporary-disable wake regression: cancelling the old scheduler followed by a handled early return lost the expiry. An isolated **AppDelegate** test reproduced this with two failed assertions after the real `systemWillSleep` / `systemDidWake` methods. Rebuilding schedules on handled returns and related cancellation paths made that same test pass. This verifies the lifecycle bridge, not just the pure plan.
- Final edge regression: an unshown night overlay with an already-normal policy initially retained a later deadline and failed two lifecycle assertions. The plan now schedules immediate cleanup, and the action handler prioritizes removing that stale overlay before a still-active temporary disable. The same event-tracking lifecycle test passes and confirms the disable expiry survives cleanup. No host-clock change or visible lock overlay was used. This cleanup-only follow-up does not change ordinary-work display frequency; the completed performance comparison was retained.
- `make test`: **92 tests, zero failures, one intentional isolation skip**. `make test-lifecycle`: **one lifecycle test passed** under a new temporary home with real preferences/product writes denied. The test refuses to initialize AppDelegate unless home and preference isolation are verified.
- `make build-app`, `make verify-app-bundle` and strict code-signature verification passed. Info.plist, bundled history, development guide and current architecture/requirements sources identify 1.7.10.

Reproduce required checks:

```bash
make test
make test-lifecycle
make build-app
make verify-app-bundle
codesign --verify --deep --strict --verbose=2 build/TwentyGuard.app
```

The native SwiftPM backend remains explicitly selected to preserve this repository's established resource layout. Its toolchain deprecation warning remains a future packaging migration concern.

## Controlled whole-app comparison

Apple M4 Pro, macOS 26.6.2, CPU percentages use one full core as 100%. Installed 1.7.9 and the candidate were run **serially** from their original app paths. Both used English, visible status countdown, a fresh custom 1,537-second work cycle, a 180-second break duration, night restriction off, closed menus and no overlay. Startup was excluded: after verifying the process had opened its test DB, the harness settled another ten seconds and then measured six consecutive ten-second windows. Native sampling ran afterward, outside the CPU windows.

| Measurement | Installed 1.7.9 | Candidate 1.7.10 |
|---|---:|---:|
| PID | 16336 | 23587 |
| CPU windows (%) | 0.7247, 0.6828, 0.6584, 0.6387, 0.7255, 0.6051 | 0.0302, 0.0422, 0.0858, 0.0204, 0.0201, 0.0373 |
| Mean CPU | **0.672523%** | **0.039343%** |
| Interrupt wakeups / second | **5.4980** | **0.2998** |
| Interrupt wakeups per window | 60, 57, 56, 53, 52, 52 | 3, 2, 6, 3, 2, 2 |
| Package idle wakeups per window | 7, 7, 4, 5, 11, 9 | 0, 0, 0, 1, 0, 0 |
| Resident MiB range | 49.98–50.09 | 45.23–45.34 |
| Snapshot records over launch/settle/measurement | 7, ten seconds apart | 7, ten seconds apart |
| Process-accounted write bytes per window | 8192 each | 8192 each |

The observed CPU reduction in this ordinary-work condition is **94.15%**. Wakeups were independently measured; this is not an assumption that reducing timer frequency saves energy proportionally. No long-duration battery or historical Activity Monitor Energy Impact claim is made. Last-minute, open-menu and overlay states intentionally retain seconds and need not achieve this same resource level.

For callback evidence, baseline source schedules its work callback every second, and the native profile sampled the repeated icon-loading path. Candidate diagnostics recorded **one display callback and zero action callbacks** by its seventh snapshot, with the status changing from `26 min` to `25 min`; action checking was not being polled once per second. The fake-clock tests provide a separately reproducible count across the entire work cycle. These callback counts are distinct from kernel interrupt wakeups.

The candidate's opt-in `TWENTYGUARD_TIMING_PROBE=1` output records the counters on existing snapshots and action callbacks. The flag changes no scheduling or preferences and is off by default. Both test processes received the same environment; 1.7.9 ignores that flag, while the candidate emits an extra diagnostic line every ten seconds. This small extra candidate I/O is part of the measured result; no write-volume improvement is claimed. The sampler converts Mach CPU ticks using the machine's timebase, as independently calibrated in the preceding localization work.

## Real-app scheduling scenarios

The candidate additionally ran three restored synthetic profiles with a two-second break to keep visible test overlays brief. Source rules were unchanged; only fixture durations were shortened.

| Scenario | Observed action callback lateness |
|---|---:|
| Work deadline → break → fresh work | 1.113 ms; 1.542 ms |
| Restored postpone → owed break → fresh work | 2.030 ms; 2.104 ms |
| Restored break → fresh work | 2.233 ms |

All scenarios produced the expected `break_started` / `break_completed` events and ended in a fresh work session with cleared postpone/break state. Callback timestamps were compared to the actual scheduled absolute date. The precision observed in these short runs is evidence for those runs, not a real-time worst-case guarantee under system sleep or a blocked main thread.

Night stages, override/disable deadlines, time-zone/DST and clock changes were exercised deterministically without changing the host clock, time zone or real user settings. Temporary-disable sleep/wake continuity was additionally exercised through the actual AppDelegate lifecycle methods in the isolated XCTest process. Menu tracking was verified using real Foundation timers running in event-tracking mode; an interactive open-menu UI session was not automated.

## Profile isolation and delivery boundary

`CFFIXED_USER_HOME` directed each process to its own temporary app-support tree. Because that variable does not reliably redirect macOS CFPreferences, the measurement profile also denied `cfprefsd` service lookup and all reads/writes to the real preferences directory. Configuration came from volatile `NSArgumentDomain`; a Foundation probe under the same sandbox confirmed the real product preference domain was absent. Each saved session contained the distinctive 1,537-second setting, confirming that configuration was loaded.

Writes to the real product app-support directory were denied. `lsof` verified every opened test DB/WAL/SHM path was under the corresponding temporary home. SHA-256 checks of **146 real preference, statistics, log and session files** were identical after both performance runs and all three functional runs, before restoring the real app. Normal stopping/restoring of the real process is outside that immutable interval. The installed executable's hash remained unchanged, and the restored PID **34511** runs `/Applications/TwentyGuard.app/Contents/MacOS/TwentyGuard`, version **1.7.9**, with no `CFFIXED_USER_HOME` test override.

Final measurement homes:

- Baseline: `/var/folders/ds/z4wlpr957r109vjdvjrxjwpc0000gp/T/twentyguard-minute-baseline-2yx39scf`
- Candidate: `/var/folders/ds/z4wlpr957r109vjdvjrxjwpc0000gp/T/twentyguard-minute-candidate-v85l2ppo`

Performance-measured executable SHA-256: `4809e23176067b564cc69a04f2fa3917919be62fd26d0e2f8025c0eb0b580795`.

The orchestration source (`compare.py`), Foundation preference probe, raw CPU/wakeup JSON, callback traces, state/event fixtures, red/green/lifecycle test logs, build log, native profiles and the integrity manifest are preserved in `build/performance/2026-10-24-minute-countdown/` in this worktree. They are ignored machine-local artifacts. `summary.json`, `comparison.json`, `functional.json` and `real-data-integrity.json` provide the compact review entry points.

The final rebuilt candidate is separately identified in `final-verification.json`; only the stale-overlay cleanup branch and its tests changed after performance measurement. The implementation passed independent coordinator review and was subsequently landed and locally installed as recorded below. No public release was performed.


## Reviewed landing and installed verification

The coordinator independently reviewed the complete change and both lifecycle edge fixes, ran the Countdown group (25 tests, one designed skip, zero failures), and ran the isolated AppDelegate lifecycle test including unshown-overlay cleanup (one test, zero failures). The verified primary checkout fast-forwarded `main` from `839908d` to **`fef639e8d06018e07d0acce08d38cba8979eaad5`**, pushed normally, and read back that exact remote revision. No unrelated local or remote work was overwritten.

`make install` rebuilt from the primary checkout and `make launch` started **1.7.10**, PID **64186**, from `/Applications/TwentyGuard.app/Contents/MacOS/TwentyGuard`. Installed bundle metadata and version history match; bundle structure and strict signature checks passed. The installed executable exactly matches the primary build, SHA-256 **`7e63541b3a58bf1ef737d8fca724a5927cf9bc161eef67e3bef2a5e5177d07e9`**. Its environment has neither `CFFIXED_USER_HOME` nor the timing-probe override.

All **15 preference keys/values** are identical, including the show/hide setting. All **3,942 preexisting session rows** and **66 preexisting stats-event rows** remain value-for-value identical, and SQLite `quick_check` returns `ok`. The initial post-install validation confirmed that all **141 existing JSONL file prefixes** remained intact; new lifecycle records append normally.

The pre-install session was already marked system-paused and had no active work start. Launch correctly started a fresh cycle under the existing recovery rule. Later display-wake, screensaver-stop and screen-unlock events produced the existing fresh-cycle behavior; new lifecycle rows are expected, while all preexisting rows were retained. The work/break durations, custom mode and ten-second snapshots remained intact.

A separate real-profile post-install observation measured three consecutive five-second CPU windows of **0.0518%, 0.0000%, and 0.0276%**, mean **0.02646%**. Interrupt wakeups were 1, 0 and 1, and normal snapshot writes remained present. The coordinator independently observed 0.000% / 0.031% in two further five-second windows. A zero-valued short window is not a claim of permanently zero CPU usage.

Native binding of this menu-bar app timed out, so its installed on-screen label was not directly captured. Minute text had already been verified from the actual isolated app's status-button title (`26 min` → `25 min`). Installed process/version, code identity, real profile, session snapshots and low runtime overhead were verified; this is not a claim of manual UI acceptance.

Installation logs, pre-install SQLite/preferences/session backups, post-install row comparison, process/environment evidence and CPU samples are in `build/performance/2026-10-24-minute-countdown/install/`. Machine-local evidence is retained in both the primary checkout and the managed worktree. Only this verification record changed after the installed code revision; the task branch can be safely retired while retaining the worktree.
