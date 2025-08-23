# 20-20-20 Eye Protection App for macOS

<div align="center">

![20-20-20 App Icon](Sources/TwentyTwentyTwenty/Resources/statusbar_icon@2x.png)

*A minimal menu bar application that enforces the 20-20-20 rule to protect your eyes*

[![macOS](https://img.shields.io/badge/macOS-12.0+-blue.svg)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.0-orange.svg)](https://swift.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

[Download](#-installation) • [Features](#-features) • [Usage](#-usage) • [Build](#️-building-from-source) • [中文](README_CN.md)

</div>

## About

The **20-20-20 rule** is a simple guideline to reduce eye strain: every 20 minutes, look at something 20 feet (6 meters) away for at least 20 seconds. This lightweight macOS app helps you follow this rule automatically.

## ✨ Features

### 🎯 Core Functionality
- **20-20-20 Mode**: Default timing (20 min work, 20 sec break)
- **Custom Mode**: Adjustable work time (10-60 min) and break time (10-600 sec)
- **Instant Break**: "Break Now" option for immediate rest
- **Smart Postpone**: Delay breaks by 1, 2, or 5 minutes

### 🖥️ User Interface
- **Menu Bar Integration**: Unobtrusive status bar presence
- **Full-Screen Reminders**: Modal break notifications
- **Keyboard Shortcuts**: Quick postpone actions (⌘1, ⌘2, ⌘5)
- **Optional Countdown**: Display remaining time in menu bar

### 🌍 Internationalization
- **5 Languages**: English, 简体中文, Español, 日本語, 한국어
- **Auto-Detection**: Automatically uses your system language
- **Runtime Switching**: Change language without restart

### ⚙️ System Integration
- **Launch at Login**: Start automatically with macOS
- **Persistent Settings**: All preferences saved automatically
- **Dark Mode Support**: Adapts to system appearance

## 📸 Screenshots

### Menu Bar Interface
<img src="screenshots/menu_bar_interface.png" alt="20-20-20 Menu Bar Interface" width="500">

*The app lives quietly in your menu bar with a custom icon and comprehensive settings menu.*

### Break Reminder
<img src="screenshots/break_reminder.png" alt="20-20-20 Break Reminder" width="500">

*When it's time to rest, a full-screen reminder appears with postpone options and keyboard shortcuts.*

## 🚀 Installation

### Option 1: Download Release (Recommended)
1. Download the latest `20-20-20-Eye-Protection-App-v1.0.0.dmg` from [Releases](https://github.com/javenfang/20-20-20-Mac-App/releases)
2. Double-click the DMG file to open it
3. Drag `20-20-20.app` to the `Applications` folder
4. Eject the DMG and delete the DMG file

**⚠️ First Launch (Unsigned App):**
- Right-click the app in Applications folder
- Select **"Open"** from the context menu
- Click **"Open"** in the confirmation dialog
- The app will now launch normally

**Alternative method:**
- Double-click the app in Applications folder
- macOS will show "cannot be opened because the developer cannot be verified"
- Click "Cancel"
- Go to **System Preferences** → **Security & Privacy** → **General**
- You'll see a message about "20-20-20" being blocked, click **"Open Anyway"**
- Click **"Open"** in the confirmation dialog

### Option 2: Build from Source
See [Building from Source](#building-from-source) section below.

## 🎮 Usage

### Getting Started
1. Launch the app - it will appear in your menu bar
2. Click the status bar icon to access settings
3. Choose between 20-20-20 mode or customize your timing
4. The app will remind you when it's time for a break!

### Keyboard Shortcuts
During break reminders:
- **⌘1** - Postpone for 1 minute
- **⌘2** - Postpone for 2 minutes  
- **⌘5** - Postpone for 5 minutes

### Settings
- **Mode Selection**: Switch between default and custom timing
- **Custom Timing**: Adjust work (10-60 min) and break (10-600 sec) durations
- **Language**: Choose from 5 supported languages
- **Auto-Start**: Launch automatically when you log in
- **Menu Bar Countdown**: Optionally show remaining time

## 🛠️ Building from Source

### Prerequisites
- **macOS 12.0+**
- **Xcode 14.0+** or **Swift 5.0+**

### Development Build (Swift Package Manager)
```bash
git clone https://github.com/javenfang/20-20-20-Mac-App.git
cd 20-20-20-Mac-App
make build
make run
```

### Creating Distribution Package
```bash
# Build standalone app bundle
make build-app

# Create DMG for distribution
make dmg
```

### Release Build (Xcode)
For App Store distribution:
```bash
# Clone and navigate to project
git clone https://github.com/javenfang/20-20-20-Mac-App.git
cd 20-20-20-Mac-App

# Use the Xcode project for release builds
# (Located at /path/to/TwentyTwentyApp/ - see CLAUDE.md for details)
```

## 📁 Project Structure

```
20-20-20-Mac-App/
├── Sources/
│   └── TwentyTwentyTwenty/
│       ├── AppDelegate.swift           # Main application logic
│       ├── BreakOverlayWindow.swift    # Break reminder window
│       ├── main.swift                  # Entry point
│       └── Resources/                  # Status bar icons
├── Package.swift                       # Swift Package Manager config
├── Makefile                           # Build shortcuts
├── CLAUDE.md                          # Technical documentation
└── README.md                          # This file
```

## 🌟 Why This App?

### Lightweight & Efficient
- **Tiny footprint**: Only 952KB installed size
- **No background processing**: Minimal CPU and memory usage
- **No network**: Completely offline, your privacy protected

### Thoughtfully Designed
- **Non-intrusive**: Lives quietly in your menu bar
- **Flexible**: Customize timing to match your workflow
- **Accessible**: Full keyboard navigation and shortcuts
- **International**: Works in your preferred language

### Open Source
- **Transparent**: Full source code available
- **Customizable**: Modify to fit your needs
- **Community-driven**: Contributions welcome

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

### Development Setup
1. Clone the repository
2. Open in Xcode or use Swift Package Manager
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Inspired by the 20-20-20 rule recommended by eye care professionals
- Built with Swift and AppKit for native macOS experience
- Icons designed for clarity and system integration

## ❤️ Support

If this app helps protect your eyes and improve your screen time habits, consider:
- ⭐ Starring this repository
- 🐛 Reporting issues or suggesting features
- 🔄 Sharing with friends and colleagues

---

<div align="center">

**Take care of your eyes - they're the only pair you've got! 👀**

Made with ❤️ for healthier screen time

</div>