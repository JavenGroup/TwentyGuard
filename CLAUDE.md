# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**20-20-20 Mac App** - A complete eye protection utility implementing the 20-20-20 rule (every 20 minutes, look at something 20 meters away for at least 20 seconds). This is a native macOS menu bar application with full-screen break notifications.

## ✅ Implementation Status: **COMPLETE**

The app is fully implemented and ready for production use. All planned features have been developed and tested.

## Architecture

**Native macOS Application** built with Swift and AppKit:
- **Menu Bar Application**: Lives in the status bar with comprehensive menu system
- **Full-Screen Overlay**: Modal break window that prevents interaction with other apps
- **Local Storage**: UserDefaults-based settings persistence
- **Multi-Language Support**: Localized for 5 languages
- **High-DPI Support**: Retina-ready custom icons

## ✅ Implemented Features

### Core Functionality
- ✅ **Default 20-20-20 mode** (20 min work, 20 sec break)
- ✅ **Custom mode support** (10-60 min work, 10-600 sec break)  
- ✅ **Postpone options** (1, 2, 5 minutes with keyboard shortcuts)
- ✅ **"Break Now" testing** (immediate break trigger)

### User Interface
- ✅ **Custom status bar icon** (high-resolution 20 logo with template rendering)
- ✅ **Comprehensive menu system** with mode switching and settings
- ✅ **Full-screen break overlay** with modern design and proper text alignment
- ✅ **Keyboard shortcuts** (⌘1, ⌘2, ⌘5 for postpone actions)
- ✅ **Optional countdown display** in menu bar

### Internationalization
- ✅ **Multi-language support**: Chinese (Simplified), English, Spanish, Japanese, Korean
- ✅ **Auto-detection** of system language with manual override
- ✅ **Dynamic menu updates** when language changes

### System Integration
- ✅ **Login item support** (start at system login)
- ✅ **Settings persistence** (all preferences saved automatically)
- ✅ **Dark/Light mode adaptation** (template-based icon rendering)

## 🏗️ Project Structure

### Source Project (Swift Package Manager)
- **Location**: `/Users/javenfang/Coding/20-20-20/`
- **Purpose**: Main development and maintenance
- **Build**: `make build && make run`
- **Files**:
  - `Sources/TwentyTwentyTwenty/AppDelegate.swift` - Main application logic
  - `Sources/TwentyTwentyTwenty/BreakOverlayWindow.swift` - Break window implementation
  - `Sources/TwentyTwentyTwenty/Resources/` - Status bar icon assets

### Release Project (Xcode)
- **Location**: `/Users/javenfang/Coding/TwentyTwentyApp/`
- **Purpose**: App Store packaging and distribution
- **Build**: `xcodebuild -project TwentyTwentyApp.xcodeproj -scheme TwentyTwentyApp -configuration Release build`

## 🚀 Build Instructions

### Development Build (Swift Package Manager)
```bash
cd /Users/javenfang/Coding/20-20-20/
make build
make run
```

### Release Build (Xcode)
```bash
cd /Users/javenfang/Coding/TwentyTwentyApp/
xcodebuild -project TwentyTwentyApp.xcodeproj -scheme TwentyTwentyApp -configuration Release build
```

**Release App Location**: 
`/Users/javenfang/Library/Developer/Xcode/DerivedData/TwentyTwentyApp-*/Build/Products/Release/20-20-20.app`

## 🎯 Technical Implementation Notes

### Status Bar Icon
- Custom PNG assets (16x16 and 32x32) with template rendering for dark/light mode
- Swift Package Manager: Bundle resource loading via `Bundle.main.path(forResource:ofType:inDirectory:)`
- Xcode Project: Standard Assets.xcassets integration

### Break Overlay Window
- Full-screen borderless window with `.screenSaver` level
- Global keyboard monitoring for shortcuts (works even without window focus)
- Proper text alignment using grid layout for colon-separated content
- Auto-sizing buttons for multi-language support

### Localization System
- Runtime language switching without app restart
- Fallback chain: Selected → System → Chinese → English
- All UI strings localized including button shortcuts

### Settings Persistence
- UserDefaults-based with immediate saving
- Keys: `showCountdownInStatusBar`, `isCustomMode`, `customWorkDuration`, `customBreakDuration`, `currentLanguage`

## 🔧 Maintenance Notes

- **Source of Truth**: Swift Package Manager project (`/Users/javenfang/Coding/20-20-20/`)
- **Release Packaging**: Xcode project (`/Users/javenfang/Coding/TwentyTwentyApp/`)
- **Sync Strategy**: Manual code synchronization between projects when needed
- **Asset Management**: Status bar icons stored in both projects with different bundle structures

## 📱 App Store Readiness

- ✅ **Bundle ID**: `com.example.twentytwentytwenty`
- ✅ **App Name**: "20-20-20"
- ✅ **Version**: 1.0
- ✅ **Minimum macOS**: 12.0
- ✅ **Code Signing**: Configured
- ✅ **Size**: ~952KB (extremely lightweight)

The app is ready for App Store submission or direct distribution.