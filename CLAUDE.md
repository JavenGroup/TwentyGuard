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

### 单一项目架构 (Swift Package Manager)
- **Location**: `/Users/javenfang/Coding/20-20-20/`
- **Purpose**: 所有开发、维护和发布
- **架构说明**: 本项目采用单一 Swift Package Manager 架构，无需 Xcode 项目文件
- **Files**:
  - `Sources/TwentyTwentyTwenty/AppDelegate.swift` - Main application logic
  - `Sources/TwentyTwentyTwenty/BreakOverlayWindow.swift` - Break window implementation
  - `Sources/TwentyTwentyTwenty/Resources/` - Status bar icon assets
  - `Makefile` - 标准化构建流程定义

## 🚀 标准化构建流程

### ⚠️ 重要说明
**本项目只有一个标准构建流程，通过 Makefile 管理。请勿使用其他方式构建，以避免版本混乱。**

### 标准构建命令

#### 1. 开发调试
```bash
cd /Users/javenfang/Coding/20-20-20/
make run        # 直接运行开发版本（swift run）
```

#### 2. 构建应用包
```bash
make build-app  # 构建 .app 包到 build/20-20-20.app
                # 这是唯一的标准构建输出位置
```

#### 3. 安装到 Applications
```bash
make install    # 自动执行：构建 → 杀掉旧进程 → 安装到 /Applications/
make launch     # 启动 /Applications/ 中的版本
```

### 🚫 禁止的操作
- **不要**在项目根目录创建 .app 文件
- **不要**使用 Xcode 直接构建（项目无 .xcodeproj 文件）
- **不要**手动复制 .app 到其他位置
- **不要**同时运行多个版本的应用

### 📁 标准目录结构
```
20-20-20/
├── build/              # 唯一的构建输出目录
│   └── 20-20-20.app   # make build-app 的输出
├── .build/            # Swift build 的中间文件（自动生成）
└── Sources/           # 源代码
```

### 🔄 完整工作流程
```bash
# 修改代码后的标准流程
make build-app  # 步骤1: 构建新版本
make install    # 步骤2: 安装到 Applications
make launch     # 步骤3: 启动新版本
```

**⚠️ 重要注意事项：**
- **build/ 目录**是唯一的构建输出位置
- **所有构建必须通过 Makefile**，确保一致性
- **避免版本混乱**：始终使用 `make install` 更新 Applications 版本

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

### Development Workflow
- **Source of Truth**: Swift Package Manager project (`/Users/javenfang/Coding/20-20-20/`)
- **构建管理**: 所有构建通过 Makefile 统一管理
- **Asset Management**: 资源文件在 Sources/ 目录中集中管理

### 🚨 Critical Update Process
**每次修改代码后的必要步骤：**

1. **开发和测试**：
   ```bash
   make build && make run  # 开发版本测试
   ```

2. **更新Applications版本**（必须步骤）：
   ```bash
   make install  # 一键替换Applications中的版本
   make launch   # 启动新版本
   ```

3. **验证修复**：
   - 检查会话状态文件：`currentWorkDuration` 应该是 1800（30分钟）
   - 检查时间格式：应该是 `+0800`（本地时间）而不是 `Z`（UTC）
   - 测试屏保/睡眠恢复：应该重置为新的30分钟工作周期

### 🐛 常见问题排查

**症状：倒计时不是从30分钟开始**
- **原因**：Applications中的旧版本仍在运行
- **解决**：`make install` 重新安装最新版本

**症状：时间格式显示UTC（Z结尾）而不是本地时间（+0800）**
- **原因**：旧版本的时间处理逻辑
- **解决**：确保运行最新版本，检查 LogManager.swift 中的 DateFormatter 设置

**症状：推迟功能影响正常工作周期**
- **原因**：推迟逻辑错误地修改了持久化的工作时长
- **解决**：确保推迟逻辑只使用临时状态变量，不修改 `currentWorkDuration`

### 构建一致性保证
- **唯一构建方式**: 通过 Makefile 命令
- **输出位置固定**: build/20-20-20.app
- **版本管理**: 避免多版本共存导致的混乱

## 📱 App Store Readiness

- ✅ **Bundle ID**: `com.example.twentytwentytwenty`
- ✅ **App Name**: "20-20-20"
- ✅ **Version**: 1.0
- ✅ **Minimum macOS**: 12.0
- ✅ **Code Signing**: Configured
- ✅ **Size**: ~952KB (extremely lightweight)

The app is ready for App Store submission or direct distribution.