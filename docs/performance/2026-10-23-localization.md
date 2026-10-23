# Countdown localization CPU regression: 2026-10-23

This record supports review of the local 1.7.9 candidate against installed 1.7.8 (source baseline `3fb6fb7`). It is a local performance verification, pending coordinator review and installation. No push, merge, public release, or replacement of `/Applications/TwentyGuard.app` was performed.

## Cause and change

The one-second countdown calls `AppLocalization.localized`. Previously every call eagerly computed the development search list, recursively enumerated the checkout's `.build` directory even when the packaged resource existed, and reread the language's strings file. Missing keys repeated that work for fallback languages.

The default localization store now resolves its resource location once and loads each requested language table once. `NSLock` covers both initial loading and subsequent access, including cached missing bundles and empty tables. Runtime switching selects another cached language; fallback remains selected language → Simplified Chinese → English → key. Explicit `resourceBundleURL` reads are deliberately uncached and never populate the default store. Each test store owns its resolver and tables without global reset hooks.

Packaged bundle paths are checked before evaluating development discovery. SwiftPM development discovery remains available once per process when needed. No timer cadence, break/postpone/night policy, statistics, or session restoration logic changed.

## Regression and build verification

- The new cache tests first ran against an equivalent uncached store and eager resolver: 7 assertions failed across 5 tests. Repeated lookups resolved/loaded 100 times; concurrent cold lookups 1,000 times; missing resources resolved 300 times; packaged lookup evaluated development discovery once. The two existing-behavior tests passed.
- After the fix, all 7 new tests pass, covering those cases, missing-language table caching, language switching/fallback, SwiftPM search, and multiple explicit fixtures including rewriting the same fixture path.
- Final `make test`: **67 tests, 0 failures**.
- `make build-app`, `make verify-app-bundle`, and `codesign --verify --deep --strict --verbose=2 build/TwentyGuard.app`: passed.
- All version sources now identify **1.7.9**; installed app remains **1.7.8**.

Apple Swift 6.4 on this machine defaults to `swiftbuild`, whose generated resource bundles place strings under `Contents/Resources`. The existing loader and verifier use the native SwiftPM flat bundle layout. Makefile now explicitly selects `--build-system native`, retaining that established packaging contract; this resolved the full-suite resource lookup failures and the resulting app passed bundle verification. Native is deprecated in this toolchain. A future move to `swiftbuild` needs a coordinated loader/packager/verifier layout update.

## Translation microbenchmark

`make benchmark-localization` compiles the same real `AppLocalization.swift` with `swiftc -O` through Makefile. All paths query `screenUsage` in English and return identical text (11 UTF-8 bytes); the harness checks equality. Times are per call.

| Lookup | Before, wall / CPU ms, n=30 | Candidate, wall / CPU ms, n=30 |
|---|---:|---:|
| Default `localized` after first lookup | 32.656507 / 32.172667 | 0.000082 / 0.000100 |
| Explicit packaged resource URL | 0.158465 / 0.157800 | 0.162706 / 0.162567 |
| Already loaded dictionary | 0.000060 / 0.000167 | 0.000039 / 0.000067 |

A longer candidate run (`LOCALIZATION_BENCHMARK_ITERATIONS=10000`) measured default cached queries at **0.000074 wall / 0.000075 CPU ms** per call, versus explicit uncached loading at 0.172752 / 0.164305 ms. Nanosecond-scale figures include harness overhead and should be read as sub-microsecond lookup cost, not a precise speedup factor.

The standalone harness does not run inside an app bundle, so its first default query still discovers SwiftPM resources once (candidate 42.08 ms wall / 28.14 ms CPU in the 30-query run). That is separate from stable cache hits; packaged app discovery is protected by the lazy-search regression test. The initial old-app samples before rebuilding were 6.79%, 7.19%, and 6.79% CPU, but rebuilding cleaned the development directory from the previously reported ~3,998 entries to 282 during the controlled comparison. Those earlier readings are not used as the comparison denominator.

Reproduce query measurements:

```bash
make benchmark-localization LOCALIZATION_BENCHMARK_BUNDLE=/Applications/TwentyGuard.app/Contents/Resources/TwentyGuard_TwentyGuardCore.bundle
make benchmark-localization LOCALIZATION_BENCHMARK_ITERATIONS=10000
```

## Whole-app comparison and data protection

Machine: Apple M4 Pro, macOS 26.6.2 (25G83), Apple Swift 6.4. CPU percentages use one complete core as 100%.

Installed and candidate binaries ran **serially**, with the normal instance first quitting and returning after each comparison. Their settings matched: English, custom work duration **1537 seconds**, break duration 180 seconds, visible countdown, night restriction off, no menus or overlays open. Each run used a new `CFFIXED_USER_HOME` and persisted an active fresh work session with that distinctive duration. After a first 5-second observation window and another 5 seconds settling, three consecutive 5-second stable windows were measured. Profiling ran afterward, outside those windows.

On this macOS, `CFFIXED_USER_HOME` redirected AppDataPaths but **did not reliably redirect CFPreferences**. The accepted comparison therefore used equivalent process isolation for preferences: all relevant app settings were supplied through volatile `NSArgumentDomain`, the sandbox denied `cfprefsd` service lookup and all reads/writes under the real `~/Library/Preferences`, and a Foundation probe under exactly that profile confirmed the real app persistent domain returned `nil`. The app's persisted 1537-second work duration confirmed it loaded the test configuration rather than the real 1500-second setting. No temporary preference value was written into the real product domain. No production preference framework change was introduced.

The sandbox additionally denied writes to the real app-support directory. `lsof` verified every SQLite DB/WAL/SHM path was under the appropriate temporary home. SHA-256 snapshots of **145 real preference/statistics/log/session files** were identical after both test processes exited, before restoring the installed app. Normal quitting/restoring of the real instance was outside that immutable measurement interval.

| Evidence | Installed 1.7.8 | Candidate 1.7.9 |
|---|---:|---:|
| Test PID | 97148 | 98094 |
| Stable CPU windows | 1.538564%, 1.542890%, 1.718795% | 0.318775%, 0.346552%, 0.326180% |
| Mean stable CPU | **1.600083%** | **0.330503%** |
| Interrupt wakeups per 5-second window | 30, 32, 28 | 30, 31, 29 |
| Package idle wakeups | 0, 0, 0 | 0, 0, 0 |
| Read bytes per window | 4096, 0, 0 | 0, 4096, 0 |
| Write bytes per window | 8192, 0, 8192 | 0, 8192, 0 |
| Resident MiB per window | 85.72, 85.67, 85.67 | 47.38, 42.67, 42.69 |

The measured stable CPU reduction is **79.3%** in this controlled condition. Wakeup cadence is essentially unchanged, consistent with preserving the one-second timer and ten-second snapshots. Small window I/O differences are not evidence of an I/O improvement. The first observation window, approximately 0.3–5.3 seconds after launching, was 13.65% versus 0.35%; it is excluded from stable results and does not measure complete cold-start CPU.

The baseline 5-second native profile again sampled `localized → localizationTable → defaultAdditionalSearchURLs → localSwiftPMBuildResourceBundleURLs`. The candidate profile sampled no localization discovery/table-loading frames. The regression tests establish the stronger deterministic guarantee of no repeated discovery/loading; absence from one sampled profile alone does not prove that guarantee.

Temporary homes used by the final comparison:

- Baseline: `/var/folders/ds/z4wlpr957r109vjdvjrxjwpc0000gp/T/twentyguard-baseline-o5rkf50o`
- Candidate: `/var/folders/ds/z4wlpr957r109vjdvjrxjwpc0000gp/T/twentyguard-candidate-7j_hf2nu`

The process sampler uses macOS `proc_pid_rusage` and converts CPU Mach ticks through `mach_timebase_info` (125/3 on this machine). This conversion was checked against a CPU-bound self-process and `getrusage`: 23,909,110 ticks matched 0.996215 seconds. It also records disk counters, interrupt/package wakeups, and resident bytes.

```bash
python3 scripts/measure-idle-cpu.py <pid> --interval 5 --windows 3
sample <pid> 5 1 -file <profile-output.txt>
```

The final sandbox profile was:

```scheme
(version 1)
(allow default)
(deny mach-lookup (global-name-regex ".*cfprefsd.*"))
(deny file-read* (subpath "/Users/javenfang/Library/Preferences"))
(deny file-write* (subpath "/Users/javenfang/Library/Preferences"))
(deny file-write* (subpath "/Users/javenfang/Library/Application Support/com.javengroup.twentyguard"))
```

Run arguments under the temporary `CFFIXED_USER_HOME` were:

```text
-currentLanguage en -isCustomMode YES -customWorkDuration 1537 -customBreakDuration 180 -showCountdownInStatusBar YES -nightRestrictionEnabled NO
```

## Local review evidence and remaining boundary

The complete measurement orchestration, Foundation isolation probe, raw JSON, per-file integrity snapshots, profiles, benchmark output, red/green/final test logs, build log and executable hashes are preserved under `build/performance/2026-10-23-localization/` in this checkout. These machine-specific artifacts are ignored by Git; this report and reusable benchmark/sampler are versioned.

Review commands:

```bash
make test
make build-app
make verify-app-bundle
codesign --verify --deep --strict --verbose=2 build/TwentyGuard.app
git diff --check
```

Stable-query and whole-app CPU acceptance passed for the measured countdown state. This does not establish long-duration battery consumption or every break/night/overlay state. Activity Monitor's historical 12-hour Energy Impact was not used for acceptance. Default caches intentionally live for the app process; replacing bundled resources in a running process requires restart. Explicit fixture reads remain live and independent.

Coordinator review is still required before installing, pushing, merging, or publishing the candidate.
