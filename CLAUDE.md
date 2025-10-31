# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## 📚 文档导航

**本文档**: 开发快速入口，提供**构建流程和关键开发注意事项**。

**完整文档**:
- **[docs/REQUIREMENTS.md](docs/REQUIREMENTS.md)** - 功能需求文档：完整的功能列表和用户场景
- **[docs/architecture.md](docs/architecture.md)** - 技术架构文档：深入的实现细节和维护指南
- **[docs/bugfix-history.md](docs/bugfix-history.md)** - Bug 修复历史：问题根因分析和修复记录

---

## Project Overview

**20-20-20 Mac App** - A native macOS menu bar application implementing the 20-20-20 rule (every 20 minutes, look at something 20 meters away for at least 20 seconds) to protect eye health.

**Implementation Status**: ✅ **COMPLETE** - Fully implemented and ready for production use.

**Key Features**: 工作/休息循环、推迟功能、健康统计、多语言支持、系统事件智能响应

📖 **详细功能说明**: 参见 [docs/REQUIREMENTS.md](docs/REQUIREMENTS.md)

## 🎯 核心设计决策

**这些是关键的设计原则，已经明确确定，不应反复讨论：**

### 1. 系统唤醒后的行为 ⭐ (v1.1.0)
> **无论之前什么状态，任何系统唤醒后都直接进入新的工作周期**

**原因**:
- 屏保/睡眠/合盖本身就是眼睛休息
- 用户回来后应该全新开始，避免"刚打开就要休息"的体验

**触发事件**: 系统睡眠、屏幕锁定、屏保、显示器睡眠、合盖

### 2. 推迟机制 ⭐ (v1.1.0)
> **累计时长限制：所有推迟操作总计最多 10 分钟**

**原因**: 防止用户通过反复推迟绕过休息提醒

**实现**: 动态禁用按钮 + 实时状态显示

### 3. 时间计算
> **使用绝对时间而非相对计数**

**原因**: 避免累积误差，支持系统睡眠恢复

📖 **完整设计决策**: 参见 [docs/architecture.md](docs/architecture.md#9-关键技术决策)

## Architecture

**Native macOS Application** built with Swift and AppKit:
- Menu Bar Application with comprehensive menu system
- Full-Screen Break Overlay (multi-monitor support)
- SQLite + JSON dual-layer data persistence
- 5 languages support with runtime switching
- Smart session recovery after sleep/screensaver

📖 **详细技术架构**: 参见 [docs/architecture.md](docs/architecture.md)
- 组件关系图、数据流、计时机制详解
- 事件处理系统、持久化方案
- 完整的维护指南和问题排查

## 🏗️ Project Structure

**单一项目架构** (Swift Package Manager):
- 位置: `/Users/javenfang/Coding/20-20-20/`
- 无需 Xcode 项目文件，全部通过 Makefile 管理
- 核心文件: AppDelegate.swift、BreakOverlayWindow.swift、EventRecorder.swift、StatsDatabase.swift

📖 **完整文件说明**: 参见 [docs/architecture.md](docs/architecture.md#13-项目结构)

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
   - 测试系统唤醒行为：合盖/锁屏/屏保后应该重置为新的30分钟工作周期
   - 测试推迟功能：累计推迟不超过10分钟，按钮动态禁用

### 🐛 常见问题快速排查

**症状：倒计时不准确或版本混乱**
- **解决**：`make install` 重新安装最新版本

**症状：推迟功能异常**
- **检查**：推迟逻辑不应修改 `currentWorkDuration`

📖 **完整问题排查**: 参见 [docs/architecture.md](docs/architecture.md#101-常见问题排查)
- 详细的症状分析和解决方案
- 日志查看方法和数据库检查命令
- 性能监控指标

## 📱 App Store Readiness

- ✅ **Bundle ID**: `com.example.twentytwentytwenty`
- ✅ **App Name**: "20-20-20"
- ✅ **Version**: 1.0
- ✅ **Minimum macOS**: 12.0
- ✅ **Code Signing**: Configured
- ✅ **Size**: ~952KB (extremely lightweight)

The app is ready for App Store submission or direct distribution.