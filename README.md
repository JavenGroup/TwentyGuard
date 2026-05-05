# TwentyGuard

<div align="center">

![TwentyGuard status bar icon](Sources/TwentyGuard/Resources/statusbar_icon@2x.png)

**Strict 20-20-20 breaks for macOS.**

[![macOS](https://img.shields.io/badge/macOS-12.0+-blue.svg)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

[Download](#installation) · [Features](#features) · [Build](#build-from-source) · [中文](README_CN.md)

</div>

TwentyGuard is a native macOS menu bar app for people who keep working through
their eye breaks. It follows the 20-20-20 rule, supports custom work rhythms,
limits repeated postpones, reports eye-health patterns, and can lock the screen
at night when you need a real boundary.

## Features

- **Strict break overlay**: full-screen rest prompts across multiple monitors.
- **20-20-20 mode**: 20 minutes of screen use, then a 20 second eye break.
- **Custom mode**: screen-use presets from 10 to 60 minutes, including 15, 25,
  35, and 45 minute options.
- **Postpone limits**: postpone by 1, 2, or 5 minutes without delaying breaks
  forever.
- **Eye health report**: opens with a clear verdict, then shows completion,
  postpone, and recent-day details.
- **Night screen lock**: gradually tightens screen-use time in the evening, then
  fully blocks screen use until the configured morning time.
- **Local-first**: settings, logs, and statistics stay on your Mac.
- **5 languages**: English, Simplified Chinese, Spanish, Japanese, and Korean.

## Installation

1. Download the latest `TwentyGuard-v1.5.0.dmg` from
   [Releases](https://github.com/JavenGroup/TwentyGuard/releases).
2. Open the DMG.
3. Drag `TwentyGuard.app` into `Applications`.
4. Launch TwentyGuard from Applications.

The v1.5.0 DMG is Developer ID signed, Apple-notarized, and accepted by
Gatekeeper. SHA-256:

```text
8824ab01248c4534f2ea2c19d758ebff2da68d186b5023022f11274ca2ed0e88
```

Local builds created from source may require right-clicking the app and choosing
**Open** on the first launch.

## Usage

- Click the menu bar icon to switch between 20-20-20 mode and custom mode.
- Use **Break Now** when you want an immediate rest.
- During a break, use `Command-1`, `Command-2`, or `Command-5` to postpone within
  the configured limit.
- Open **Eye Health Report** to see whether today's pattern is healthy or which
  behavior needs attention.
- Enable **Night Screen Lock** if you want the app to enforce an evening cutoff.

## Build From Source

Requirements:

- macOS 12.0+
- Xcode command line tools or Swift 5.9+

```bash
git clone https://github.com/JavenGroup/TwentyGuard.git
cd TwentyGuard
make build
make run
```

Build and install the app bundle:

```bash
make build-app
make install
make launch
```

Create a local DMG:

```bash
make dmg
```

Create a public release DMG after installing a Developer ID Application
certificate and storing notarization credentials:

```bash
make release \
  TEAM_ID=<team-id> \
  DEVELOPER_ID_APPLICATION="Developer ID Application: <name> (<team-id>)"
```

## Project Structure

```text
TwentyGuard/
├── Sources/
│   ├── TwentyGuard/       # macOS app target
│   └── TwentyGuardCore/   # shared policy and statistics logic
├── docs/                         # product and technical notes
├── marketing/                    # launch positioning and public copy drafts
├── scripts/                      # release helpers
├── Info.plist
├── Makefile
└── Package.swift
```

The Swift package, targets, executable, bundle metadata, build output, install
path, and release assets all use the TwentyGuard name.

## Privacy

TwentyGuard does not need network access for its core behavior. Settings,
session logs, and statistics are stored locally on your Mac.

## Contributing

Issues and pull requests are welcome. For major behavior changes, open an issue
first so the product intent stays clear: calm UI, strict breaks, local-first
data.

## License

MIT License. See [LICENSE](LICENSE).
