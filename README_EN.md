<div align="center">

# FinderClip

<img src="https://img.shields.io/badge/macOS-12.0+-blue.svg" alt="macOS">
<img src="https://img.shields.io/badge/Swift-5.9-orange.svg" alt="Swift">
<img src="https://img.shields.io/badge/license-MIT-green.svg" alt="License">

**Intuitive Cut & Paste Experience for macOS Finder**

English | [简体中文](README.md)

</div>

---

## ✨ Introduction

FinderClip is a lightweight macOS menu bar app that brings the familiar **⌘X** and **⌘V** shortcuts to Finder for cutting and moving files, just like in Windows.

## 🎯 Features

| Feature | Description |
|---------|-------------|
| ✂️ **True Cut** | Use ⌘X to cut files in Finder |
| 📋 **Smart Paste** | Use ⌘V to move files to destination |
| 🎯 **Context Detection** | Auto-detect file selection vs text editing |
| 🔔 **Visual Feedback** | Clear notifications for cut/paste operations |
| ⏱️ **Timeout Protection** | Auto-clear cut state after 5 minutes |
| ⌨️ **Quick Cancel** | Press Esc to cancel cut operation |
| 🚀 **Launch at Login** | Support for auto-start on boot |

## 📖 Usage

### Basic Operations

```
1. ⌘X  - Select files in Finder and press ⌘X to cut
2. ⌘V  - Navigate to destination and press ⌘V to move
3. Esc - Press Esc to cancel cut state
```

### Demo

<div align="center">
  <img src="docs/demo.gif" alt="Demo" width="600">
</div>

## 🚀 Quick Start

### Requirements

- macOS 12.0 or later
- Xcode Command Line Tools

### Build from Source

```bash
# Clone the repository
git clone https://github.com/Wcowin/Mac-Finder-Clipboard.git
cd Mac-Finder-Clipboard

# Generate app icon (first time only)
./create_icon.sh

# Build the app
./build_app.sh

# Run the app
open FinderClip.app
```

### First Time Setup

1. After running, a scissors icon ✂️ will appear in the menu bar
2. Click the icon → "Open Accessibility Settings"
3. Check FinderClip in System Settings
4. Done! Now you can use ⌘X to cut files in Finder

## 🛠 Technical Implementation

### Core Technologies

- **CGEvent API** - Intercept global keyboard events
- **Accessibility API** - Detect focused element state
- **UserNotifications** - Modern notification system
- **ServiceManagement** - Launch at login support

### How It Works

```
User presses ⌘X
    ↓
Check if in Finder
    ↓
Check if in text editing mode
    ↓
Simulate ⌘C to copy files
    ↓
Mark cut mode
    ↓
User presses ⌘V
    ↓
Convert to ⌘⌥V (system cut & paste)
    ↓
Files moved
```

## 📁 Project Structure

```
Mac-Finder-Clipboard/
├── main.swift                    # App entry point
├── AppDelegate.swift             # App delegate and menu bar
├── FinderCutPasteManager.swift   # Core functionality
├── Info.plist                    # App configuration
├── FinderClip.entitlements       # Permissions
├── build_app.sh                  # Build script
├── create_icon.sh                # Icon generation script
├── AppIcon.icns                  # App icon
├── LICENSE                       # MIT License
├── .gitignore                    # Git ignore file
└── README.md                     # Documentation
```

## 🤝 Contributing

Issues and Pull Requests are welcome!

## 📄 License

This project is licensed under the [MIT License](LICENSE).

## 👨‍💻 Author

**Wcowin** - [GitHub](https://github.com/Wcowin)

## ⭐ Star History

If this project helps you, please give it a Star ⭐

---

<div align="center">
  Made with ❤️ by Wcowin
</div>
