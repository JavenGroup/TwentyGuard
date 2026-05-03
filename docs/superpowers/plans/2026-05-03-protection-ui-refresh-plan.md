# Protection UI Refresh Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refresh the night lock menu, full-screen night overlay, and health statistics window according to the approved restrained-but-mandatory UI design.

**Architecture:** Keep the existing AppKit app structure. Add one small core presentation evaluator for the statistics verdict so the most important new behavior is unit-tested, then update the AppKit windows and menu builders in place.

**Tech Stack:** Swift 5.9, SwiftPM, AppKit, XCTest, existing Makefile app packaging.

---

### Task 1: Add Tested Statistics Verdict Model

**Files:**
- Create: `Sources/TwentyTwentyTwentyCore/StatsHealthVerdict.swift`
- Create: `Tests/TwentyTwentyTwentyCoreTests/StatsHealthVerdictTests.swift`

- [ ] **Step 1: Write failing verdict tests**

Create tests for these behaviors:

```swift
func testLongWorkTakesPriority() {
    let day = makeDay(longestWorkSeconds: 96 * 60, breakCompletionRate: 0.95, postponeSessionRate: 0.1)
    let verdict = StatsHealthVerdictEvaluator().verdict(for: day)
    XCTAssertEqual(verdict.title, "工作过长")
    XCTAssertEqual(verdict.severity, .warning)
}

func testLowBreakCompletionIsRestProblem() {
    let day = makeDay(longestWorkSeconds: 30 * 60, breakCompletionRate: 0.5, postponeSessionRate: 0.1)
    let verdict = StatsHealthVerdictEvaluator().verdict(for: day)
    XCTAssertEqual(verdict.title, "休息不足")
    XCTAssertEqual(verdict.severity, .warning)
}

func testHealthyDayIsNormalRhythm() {
    let day = makeDay(longestWorkSeconds: 35 * 60, breakCompletionRate: 0.9, postponeSessionRate: 0.1)
    let verdict = StatsHealthVerdictEvaluator().verdict(for: day)
    XCTAssertEqual(verdict.title, "节奏正常")
    XCTAssertEqual(verdict.severity, .good)
}
```

- [ ] **Step 2: Run the failing tests**

Run: `swift test --filter StatsHealthVerdictTests`

Expected: FAIL because `StatsHealthVerdictEvaluator` does not exist.

- [ ] **Step 3: Implement verdict model**

Add:

```swift
public enum StatsHealthVerdictSeverity: Equatable, Sendable {
    case good
    case warning
    case neutral
}

public struct StatsHealthVerdict: Equatable, Sendable {
    public let title: String
    public let reason: String
    public let severity: StatsHealthVerdictSeverity
}

public struct StatsHealthVerdictEvaluator: Sendable {
    public func verdict(for day: StatsDaySnapshot) -> StatsHealthVerdict
}
```

Priority order: no data, overlong work, low break completion, high postpones, healthy rhythm, data warning.

- [ ] **Step 4: Verify verdict tests pass**

Run: `swift test --filter StatsHealthVerdictTests`

Expected: PASS.

### Task 2: Refine Night Lock Menu

**Files:**
- Modify: `Sources/TwentyTwentyTwenty/AppDelegate.swift`

- [ ] **Step 1: Update menu copy and structure**

Change `buildNightRestrictionSubmenu()` so the submenu uses:

```swift
Enable
Wind-down Starts: 20:00
Full Lock Starts: 21:00
Unlocks: 07:00
Tonight: 35 -> 25 -> 15 -> 5 -> Locked
Testing Escape: Shown >
```

For Chinese localization, use:

```swift
启用
收紧开始: 20:00
完全禁用: 21:00
恢复可用: 07:00
今晚: 35 分钟 -> 25 分钟 -> 15 分钟 -> 5 分钟 -> 禁用
测试出口: 显示 >
```

- [ ] **Step 2: Move testing escape into submenu**

Replace the direct `显示测试退出` toggle with a submenu containing two actions:

```swift
显示
隐藏
```

Both actions update `nightRestrictionSettings.testingExitEnabled`, save settings, rebuild the menu, and refresh visible night overlays.

- [ ] **Step 3: Build and inspect menu**

Run: `swift test`

Expected: PASS. Later desktop inspection must show the reorganized menu.

### Task 3: Replace Night Lock Overlay With Full-Screen Status Page

**Files:**
- Modify: `Sources/TwentyTwentyTwenty/NightRestrictionOverlayWindow.swift`

- [ ] **Step 1: Remove centered container dependency**

Keep the black full-screen window, but place labels directly on `contentView`.

Required labels:

```swift
夜间禁用
屏幕已禁用
08:42:18
07:00 恢复使用
20:00 收紧 - 21:00 禁用
```

- [ ] **Step 2: De-emphasize testing escape**

Move testing escape to the bottom-right corner, use small text, and keep the existing second-click confirmation behavior.

- [ ] **Step 3: Build and inspect overlay**

Run: `swift test`

Expected: PASS. Later desktop inspection must show no centered card.

### Task 4: Redesign Stats Dashboard Around Today's Verdict

**Files:**
- Modify: `Sources/TwentyTwentyTwenty/StatsDashboardWindow.swift`

- [ ] **Step 1: Render verdict first**

Change `render(_:)` to show:

```swift
header
verdict panel
key metrics row
seven-day table
quality warnings only when needed
```

- [ ] **Step 2: Add key metrics**

Show three cards:

```swift
完成率
推迟
夜间
```

Read night status from `UserDefaults.standard.bool(forKey: "nightRestrictionEnabled")`.

- [ ] **Step 3: Align seven-day table**

Use fixed-width columns:

```swift
日期 | 工作 | 完成 | 推迟
```

Each day row uses `day.totalPostpones` for the postpone column.

- [ ] **Step 4: Hide clean data quality panel**

Only show data quality section when `quality.hasIssues == true`.

- [ ] **Step 5: Build and inspect stats window**

Run: `swift test`

Expected: PASS. Later desktop inspection must show verdict-first layout and aligned daily rows.

### Task 5: Version, Install, Verify, Commit

**Files:**
- Modify: `Info.plist`
- Modify: `Sources/TwentyTwentyTwenty/Resources/version-history.json`

- [ ] **Step 1: Bump patch version**

Set version to `1.3.1` and add a version history entry for the UI refresh.

- [ ] **Step 2: Run full verification**

Run:

```bash
swift test
make install
make launch
```

Expected: tests pass, app installs to `/Applications/20-20-20.app`, and launches.

- [ ] **Step 3: Desktop inspection**

Use macOS accessibility or Computer Use to inspect:

```text
Night menu structure
Full-screen night overlay
Health statistics window
```

- [ ] **Step 4: Commit and push**

Commit with message:

```bash
git commit -m "Refresh protection UI"
```

Push `main` to origin.
