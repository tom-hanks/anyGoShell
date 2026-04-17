# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-04-16

### Added
- Initial release of anyGoShell
- Toolbar integration via drag-and-drop (⌘ + drag)
- Smart detection of installed terminals (Terminal.app, iTerm2, Warp, Ghostty, WezTerm)
- Native app icons display in settings UI
- Custom terminal support via name input
- Intelligent fallback mechanism when preferred terminal unavailable
- SwiftUI settings interface with dark mode support
- Chinese (zh-Hans) and English (en) localization
- Homebrew installation support via `tom-hanks/tap`

### Technical
- Pure Swift 6.0 implementation with Swift Package Manager
- Uses Apple Events (AppleScript) for Finder path detection
- ScriptingBridge integration for Terminal.app
- Minimal resource footprint (~2MB)
