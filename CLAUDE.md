# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## 🤖 AI Coding Assistant Principles

1. **AI Coding First** - Leverage AI assistance throughout the development lifecycle
2. **CLAUDE.md Persists English Version** - Maintain documentation in English for broader accessibility
3. **Architecture Design Principle: KISS** - Keep It Simple, Stupid


---

## Project Overview

**20-20-20 Mac App** - A native macOS menu bar application implementing the 20-20-20 rule (every 20 minutes, look at something 20 meters away for at least 20 seconds) to protect eye health.

**Implementation Status**: ✅ **COMPLETE** - Fully implemented and ready for production use.

**Key Features**: Work/break cycles, postpone functionality, health statistics, multi-language support, smart system event response

📖 **Detailed Features**: See [docs/REQUIREMENTS.md](docs/REQUIREMENTS.md)

## 🎯 Core Design Decisions

**These are key design principles that have been clearly established and should not be repeatedly questioned:**

### 1. Behavior After System Wake ⭐ (v1.1.0)
> **Regardless of previous state, always start a fresh work cycle after any system wake event**

**Rationale**:
- Screensaver/sleep/lid close already provides eye rest
- Users should start fresh to avoid "just opened, already need break" experience

**Trigger Events**: System sleep, screen lock, screensaver, display sleep, lid close

### 2. Postpone Mechanism ⭐ (v1.2.0)
> **Default mode limits cumulative postpones to 5 minutes; custom mode can choose 5 or 10 minutes**

**Rationale**: Prevent users from bypassing break reminders through repeated postpones

**Implementation**: Dynamic button disabling + real-time status display

### 3. Time Calculation
> **Use absolute time instead of relative counting**

**Rationale**: Avoid cumulative errors, support system sleep recovery

📖 **Complete Design Decisions**: See [docs/architecture.md](docs/architecture.md#9-key-technical-decisions)

## Architecture

**Native macOS Application** built with Swift and AppKit:
- Menu Bar Application with comprehensive menu system
- Full-Screen Break Overlay (multi-monitor support)
- SQLite + JSON dual-layer data persistence
- 5 languages support with runtime switching
- Smart session recovery after sleep/screensaver

📖 **Detailed Technical Architecture**: See [docs/architecture.md](docs/architecture.md)
- Component relationship diagrams, data flow, timing mechanism details
- Event handling system, persistence solutions
- Complete maintenance guide and troubleshooting

## 🏗️ Project Structure

**Single Project Architecture** (Swift Package Manager):
- Location: `/Users/javenfang/Projects/20-20-20/`
- No Xcode project files needed, everything managed via Makefile
- Core Files: AppDelegate.swift, BreakOverlayWindow.swift, EventRecorder.swift, StatsDatabase.swift

📖 **Complete File Documentation**: See [docs/architecture.md](docs/architecture.md#13-project-structure)

---

## 📚 Documentation Navigation

**This Document**: Quick development guide with **build process and critical development notes**.

**Current Implementation Docs (v1.2.0)**:
- **[docs/REQUIREMENTS.md](docs/REQUIREMENTS.md)** - Functional requirements: complete feature list and user scenarios
- **[docs/architecture.md](docs/architecture.md)** - Technical architecture: in-depth implementation details and maintenance guide
- **[docs/bugfix-history.md](docs/bugfix-history.md)** - Bug fix history: root cause analysis and fix records

**Archived Historical Docs**:
- **[docs/prd-statistics-requirements.md](docs/prd-statistics-requirements.md)** - Statistics requirements changes (implemented in v1.1.0)
- **[docs/design-statistics-system.md](docs/design-statistics-system.md)** - Statistics system design (implemented in v1.1.0)

## 🚀 Standardized Build Process

### ⚠️ Important Notice
**This project has ONE standard build process managed via Makefile. Do not use other build methods to avoid version confusion.**

### Standard Build Commands

#### 1. Development & Debugging
```bash
cd /Users/javenfang/Projects/20-20-20/
make run        # Run development version directly (swift run)
```

#### 2. Build App Bundle
```bash
make build-app  # Build .app bundle to build/20-20-20.app
                # This is the ONLY standard build output location
```

#### 3. Install to Applications
```bash
make install    # Auto-execute: Build → Kill old process → Install to /Applications/
make launch     # Launch version in /Applications/
```

### 🚫 Forbidden Operations
- **DO NOT** create .app files in project root directory
- **DO NOT** build directly with Xcode (project has no .xcodeproj file)
- **DO NOT** manually copy .app to other locations
- **DO NOT** run multiple versions of the app simultaneously

### 📁 Standard Directory Structure
```
20-20-20/
├── build/              # ONLY build output directory
│   └── 20-20-20.app   # make build-app output
├── .build/            # Swift build intermediate files (auto-generated)
└── Sources/           # Source code
```

### 🔄 Complete Workflow
```bash
# Standard process after code modification
make build-app  # Step 1: Build new version
make install    # Step 2: Install to Applications
make launch     # Step 3: Launch new version
```

**⚠️ Important Notes:**
- **build/ directory** is the ONLY build output location
- **All builds MUST go through Makefile** to ensure consistency
- **Avoid version confusion**: Always use `make install` to update Applications version

## 🔧 Maintenance Notes

### Development Workflow
- **Source of Truth**: Swift Package Manager project (`/Users/javenfang/Projects/20-20-20/`)
- **Build Management**: All builds unified through Makefile
- **Asset Management**: Resource files centrally managed in Sources/ directory

### 📦 Release Checklist

**⚠️ MUST check before every new release:**

1. **Update Version History File**: [Sources/TwentyTwentyTwenty/Resources/version-history.json](Sources/TwentyTwentyTwenty/Resources/version-history.json)
   - Update `current_version` field (e.g., "1.2.0")
   - Add new version record at **beginning** of `versions` array
   - Include: version number, date (YYYY-MM-DD), major changes list
   - Keep versions in reverse chronological order (newest first)

2. **Verify About Page**:
   ```bash
   make install && make launch
   # Click menu bar → About → Confirm version info is correct
   ```

3. **Example Version Record**:
   ```json
   {
     "version": "1.2.0",
     "date": "2025-01-20",
     "changes": [
       "Added new feature X",
       "Fixed bug Y",
       "Improved performance Z"
     ]
   }
   ```

**Why Important**: version-history.json is the ONLY data source for the About page. Forgetting to update will show outdated version info to users.

### 🚨 Critical Update Process
**Required steps after every code modification:**

1. **Development & Testing**:
   ```bash
   make build && make run  # Test development version
   ```

2. **Update Applications Version** (REQUIRED):
   ```bash
   make install  # One-command replace Applications version
   make launch   # Launch new version
   ```

### 📊 Statistics Debugging Checklist

**⚠️ Important: When debugging statistics issues, ALWAYS check JSONL log files first!**

JSONL is the source of truth for event records; database is the query optimization layer. Any statistics issues should start investigation from JSONL.

**When statistics window shows no data, check in this order:**

1. **First Check JSONL Files** (are events recorded):
   ```bash
   cat ~/Library/Application\ Support/com.twentytwentytwenty/logs/$(date +%Y-%m-%d).jsonl | jq -r '.eventType' | sort | uniq -c
   ```
   Should see: `work_started`, `break_started`, `work_completed`, `break_completed` events

2. **Check sessions Table** (is data written to database):
   ```bash
   sqlite3 ~/Library/Application\ Support/com.twentytwentytwenty/20_20_20_stats.db \
     "SELECT COUNT(*) FROM sessions WHERE date(start_time, 'unixepoch') = date('now');"
   ```
   Should return today's session count (> 0)

3. **Check Table Schema** (confirm field names are correct):
   ```bash
   sqlite3 ~/Library/Application\ Support/com.twentytwentytwenty/20_20_20_stats.db \
     "PRAGMA table_info(sessions);"
   ```
   Confirm existence of fields: `postpones` (JSON), `break_info` (JSON), `actual_work_duration`

**Key Points**:
- New version uses JSON fields (`postpones`, `break_info`), not separate `postpone_1min` columns
- StatsDatabase query methods MUST parse JSON instead of direct column queries
- `type` field only has value `'work'`, break info is in JSON

### 🐛 Quick Troubleshooting

**Symptom: Countdown inaccurate or version confusion**
- **Solution**: `make install` to reinstall latest version

**Symptom: Postpone functionality abnormal**
- **Check**: Postpone logic should NOT modify `currentWorkDuration`

📖 **Complete Troubleshooting**: See [docs/architecture.md](docs/architecture.md#101-common-issues)
- Detailed symptom analysis and solutions
- Log viewing methods and database check commands
- Performance monitoring metrics

## 📱 App Store Readiness

- ✅ **Bundle ID**: `com.example.twentytwentytwenty`
- ✅ **App Name**: "20-20-20"
- ✅ **Version**: 1.2.0
- ✅ **Minimum macOS**: 12.0
- ✅ **Code Signing**: Configured
- ✅ **Size**: ~952KB (extremely lightweight)

The app is ready for App Store submission or direct distribution.
