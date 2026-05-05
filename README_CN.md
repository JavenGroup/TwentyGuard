# TwentyGuard

<div align="center">

![TwentyGuard 状态栏图标](Sources/TwentyGuard/Resources/statusbar_icon@2x.png)

**严格执行 20-20-20 护眼休息的 macOS 菜单栏应用。**

[![macOS](https://img.shields.io/badge/macOS-12.0+-blue.svg)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

[下载安装](#安装) · [功能特性](#功能特性) · [源码构建](#源码构建) · [English](README.md)

</div>

TwentyGuard 是一款原生 macOS 菜单栏应用，适合那些明知道该休息、但总会继续盯着屏幕的人。它基于
20-20-20 护眼法则，支持自定义工作节奏，限制反复推迟，提供眼睛健康统计，并可以在晚上逐步收紧屏幕使用时间，最后进入夜间禁用。

## 功能特性

- **强制休息遮罩**：在多个屏幕上显示全屏休息提示。
- **20-20-20 模式**：使用屏幕 20 分钟后，进行 20 秒眼睛休息。
- **自定义模式**：支持 10 到 60 分钟的屏幕使用时长，包括 15、25、35、45 分钟。
- **推迟上限**：可以推迟 1、2、5 分钟，但不能无限推迟。
- **眼睛健康报告**：先给出今天的判断，再显示完成率、推迟情况和近几天明细。
- **夜间禁用**：晚上先逐步缩短可用时间，到设定时间后完全禁用屏幕，早上自动恢复。
- **本地优先**：设置、日志和统计数据都保存在本机。
- **多语言**：支持 English、简体中文、Español、日本語、한국어。

## 安装

1. 从 [Releases](https://github.com/JavenGroup/TwentyGuard/releases) 下载最新的 `TwentyGuard-v1.5.0.dmg`。
2. 打开 DMG。
3. 将 `TwentyGuard.app` 拖入 `Applications`。
4. 从应用程序中启动 TwentyGuard。

v1.5.0 DMG 已使用 Developer ID 签名，通过 Apple 公证，并被 Gatekeeper
接受。SHA-256：

```text
8824ab01248c4534f2ea2c19d758ebff2da68d186b5023022f11274ca2ed0e88
```

从源码本地构建的版本，首次启动可能需要右键点击应用，然后选择 **打开**。

## 使用

- 点击菜单栏图标，可以切换 20-20-20 模式和自定义模式。
- 需要立即休息时，选择 **现在休息**。
- 休息遮罩出现时，可以用 `Command-1`、`Command-2`、`Command-5` 在允许范围内推迟。
- 打开 **眼睛健康报告**，可以快速看到今天是否健康，以及主要问题在哪里。
- 开启 **夜间禁用** 后，可以让应用在晚上强制建立屏幕边界。

## 源码构建

环境要求：

- macOS 12.0+
- Xcode 命令行工具或 Swift 5.9+

```bash
git clone https://github.com/JavenGroup/TwentyGuard.git
cd TwentyGuard
make build
make run
```

构建并安装应用：

```bash
make build-app
make install
make launch
```

创建本地 DMG：

```bash
make dmg
```

安装 Developer ID Application 证书并保存公证凭据后，创建公开发布 DMG：

```bash
make release \
  TEAM_ID=<team-id> \
  DEVELOPER_ID_APPLICATION="Developer ID Application: <name> (<team-id>)"
```

## 项目结构

```text
TwentyGuard/
├── Sources/
│   ├── TwentyGuard/       # macOS 应用 target
│   └── TwentyGuardCore/   # 共享策略与统计逻辑
├── docs/                         # 产品与技术文档
├── marketing/                    # 推广定位与文案草稿
├── scripts/                      # 发布辅助脚本
├── Info.plist
├── Makefile
└── Package.swift
```

Swift package、target、可执行文件、bundle 元数据、构建产物、安装路径和发布资产都统一使用 TwentyGuard 命名。

## 隐私

TwentyGuard 的核心功能不需要网络访问。设置、会话日志和统计数据都保存在你的 Mac 本机。

## 贡献

欢迎提交 issue 和 pull request。涉及核心行为的修改，建议先开 issue 讨论，保持产品方向清晰：界面克制、休息严格、数据本地优先。

## 开源许可

MIT License。详见 [LICENSE](LICENSE)。
