# anyGoShell

[中文文档](README.md)｜[English](README_English.md)

**A minimalist macOS utility for opening terminal from Finder toolbar.**

[![macOS](https://img.shields.io/badge/macOS-Sequoia%2015%2B-blue?logo=apple)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-6.2-orange?logo=swift)](https://swift.org)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)
[![GitHub](https://img.shields.io/badge/GitHub-tom--hanks/anyGoShell-black?logo=github)](https://github.com/tom-hanks/anyGoShell)

![Screenshot](screenshots/settings.jpg)

---

## Overview

anyGoShell provides a seamless bridge between Finder and your terminal. With a single click on the Finder toolbar, instantly open a terminal session in the current directory — no manual navigation required.

Designed for developers, power users, and anyone who frequently switches between file browsing and command-line operations.

## Features

| Feature | Description |
|---------|-------------|
| **Toolbar Integration** | Add to Finder toolbar via drag-and-drop (⌘ + drag) |
| **Smart Detection** | Auto-detects installed terminals, hides unavailable ones |
| **Native Icons** | Displays actual terminal app icons for visual clarity |
| **Custom Terminal** | Supports any terminal app via name input |
| **Fallback Logic** | Automatically uses Terminal.app if preferred option unavailable |
| **Lightweight** | Pure Swift implementation, minimal resource footprint |

### Supported Terminals

- **Terminal.app** — macOS built-in
- **iTerm2** — Popular third-party terminal
- **Warp** — Modern AI-powered terminal
- **Ghostty** — High-performance terminal
- **WezTerm** — Cross-platform multiplexer
- **Any Custom Terminal** — Enter app name directly

---

## Installation

### Homebrew (Recommended)

```bash
brew install tom-hanks/tap/anyGoShell
```

### Manual Build

```bash
# Clone repository
git clone https://github.com/tom-hanks/anyGoShell.git
cd anyGoShell

# Build and install
make install
```

---

## Quick Start

### Step 1: Add to Finder Toolbar

1. Open `/Applications` folder
2. Hold **⌘ (Command)** key
3. Drag `anyGoShell.app` to any Finder window's toolbar

### Step 2: Click to Launch

Click the toolbar icon — terminal opens at current directory instantly.

---

## Configuration

### GUI Settings

Double-click the app icon in `/Applications` to open settings panel.

### Command Line

```bash
# Terminal.app (default)
defaults write com.solarhell.anyGoShell PreferredTerminal Terminal

# iTerm2
defaults write com.solarhell.anyGoShell PreferredTerminal iTerm

# Warp / Ghostty / WezTerm
defaults write com.solarhell.anyGoShell PreferredTerminal Warp
defaults write com.solarhell.anyGoShell PreferredTerminal Ghostty
defaults write com.solarhell.anyGoShell PreferredTerminal WezTerm

# Custom terminal
defaults write com.solarhell.anyGoShell UseCustomTerminal -bool true
defaults write com.solarhell.anyGoShell CustomTerminalName "Alacritty"
```

---

## Development

### Build Commands

```bash
make help       # List all commands
make build      # Compile and create App Bundle
make install    # Install to /Applications
make clean      # Remove build artifacts
make run        # Launch application
make release    # Create distributable ZIP
```

### Project Structure

```
anyGoShell/
├── Package.swift           # SPM manifest
├── Makefile                # Build automation
├── Sources/
│   ├── main.swift          # Entry point
│   ├── Views.swift         # SwiftUI interface
│   ├── TerminalManager.swift
│   ├── Terminal.swift      # ScriptingBridge
│   ├── Finder.swift        # ScriptingBridge
│   ├── FinderManager.swift
│   └── L10n.swift          # Localization
├── Resources/
│   ├── Info.plist
│   ├── anyGoShell.entitlements
│   ├── AppIcon.icns
│   ├── en.lproj/
│   └── zh-Hans.lproj/
└── screenshots/
```

---

## Requirements

- **macOS Sequoia 15.0+**
- **Xcode 16+** (for building)

---

## Technical Details

anyGoShell uses Apple Events (AppleScript) to:

1. Query the frontmost Finder window for its current path
2. Fall back to Desktop path if no Finder window exists
3. Invoke the preferred terminal via AppleScript API
4. Exit automatically after terminal launches

---

## Contributing

Contributions are welcome. Please open an issue or submit a pull request on [GitHub](https://github.com/tom-hanks/anyGoShell).

---

## License

Released under the [MIT License](LICENSE).

---

## Links

- **Repository**: [github.com/tom-hanks/anyGoShell](https://github.com/tom-hanks/anyGoShell)
- **Issues**: [Report a bug](https://github.com/tom-hanks/anyGoShell/issues)
