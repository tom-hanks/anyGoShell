// 移植自 OpenInTerminal - OpenInTerminalCore/App.swift (Terminal 部分)

import Cocoa
import ScriptingBridge

class TerminalManager {
    enum Terminal: String, CaseIterable {
        case terminal = "Terminal"
        case iterm = "iTerm"
        case warp = "Warp"
        case ghostty = "Ghostty"
        case wezterm = "WezTerm"
        case cmux = "CMUX"

        var displayName: String {
            switch self {
            case .terminal: return "Terminal.app"
            case .iterm: return "iTerm2"
            case .warp: return "Warp"
            case .ghostty: return "Ghostty"
            case .wezterm: return "WezTerm"
            case .cmux: return "CMUX"
            }
        }

        var appPath: String {
            switch self {
            case .terminal: return "/System/Applications/Utilities/Terminal.app"
            case .iterm: return "/Applications/iTerm.app"
            case .warp: return "/Applications/Warp.app"
            case .ghostty: return "/Applications/Ghostty.app"
            case .wezterm: return "/Applications/WezTerm.app"
            case .cmux: return "/Applications/cmux.app"
            }
        }

        var isInstalled: Bool {
            FileManager.default.fileExists(atPath: appPath)
        }
    }

    static func openTerminal(atPath path: String) {
        let defaults = UserDefaults.standard
        let terminalName = defaults.string(forKey: "PreferredTerminal") ?? "Terminal"

        // 选中自定义终端
        if terminalName == "Custom" {
            let customName = defaults.string(forKey: "CustomTerminalName") ?? ""
            if customName.isEmpty {
                openAppleTerminal(atPath: path)
            } else {
                openCustomTerminal(name: customName, atPath: path)
            }
            return
        }

        // 预设终端
        var terminal = Terminal(rawValue: terminalName) ?? .terminal
        if !terminal.isInstalled {
            terminal = .terminal
        }

        switch terminal {
        case .terminal:
            openAppleTerminal(atPath: path)
        case .iterm:
            openITerm(atPath: path)
        case .warp:
            openWarp(atPath: path)
        case .ghostty:
            openGhostty(atPath: path)
        case .wezterm:
            openWezTerm(atPath: path)
        case .cmux:
            openCmux(atPath: path)
        }
    }

    /// 自定义终端 — 使用 open -a 命令打开任意终端
    static func openCustomTerminal(name: String, atPath path: String) {
        let escapedPath = path.specialCharEscaped(2)
        let escapedName = name.specialCharEscaped(2)
        let source = """
        do shell script "open -a \(escapedName) \(escapedPath)"
        """
        var error: NSDictionary?
        NSAppleScript(source: source)?.executeAndReturnError(&error)
    }

    /// 检查自定义终端是否存在
    static func isCustomTerminalInstalled(name: String) -> Bool {
        // 尝试通过应用名称查找
        let appPath = "/Applications/\(name).app"
        if FileManager.default.fileExists(atPath: appPath) {
            return true
        }
        // 使用 mdfind 搜索
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/mdfind")
        task.arguments = ["kMDItemKind == 'Application'", "-name", name]
        let pipe = Pipe()
        task.standardOutput = pipe
        try? task.run()
        task.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        return output.trimmingCharacters(in: .whitespacesAndNewlines).contains(".app")
    }

    /// Terminal.app — 移植自 OpenInTerminal 的 ScriptingBridge 方式
    private static func openAppleTerminal(atPath path: String) {
        let url = URL(fileURLWithPath: path)
        guard let terminal = SBApplication(bundleIdentifier: "com.apple.Terminal") as TerminalApplication?,
              let open = terminal.open else {
            return
        }
        open([url])
        terminal.activate()
    }

    /// iTerm2 — 移植自 OpenInTerminal 的 shell 命令方式
    private static func openITerm(atPath path: String) {
        let escapedPath = path.specialCharEscaped(2)
        let source = """
        do shell script "open -a iTerm \(escapedPath)"
        """
        var error: NSDictionary?
        NSAppleScript(source: source)?.executeAndReturnError(&error)
    }

    /// Warp
    private static func openWarp(atPath path: String) {
        let escapedPath = path.specialCharEscaped(2)
        let source = """
        do shell script "open -a Warp \(escapedPath)"
        """
        var error: NSDictionary?
        NSAppleScript(source: source)?.executeAndReturnError(&error)
    }

    /// Ghostty
    private static func openGhostty(atPath path: String) {
        let escapedPath = path.specialCharEscaped(2)
        let source = """
        do shell script "open -a Ghostty \(escapedPath)"
        """
        var error: NSDictionary?
        NSAppleScript(source: source)?.executeAndReturnError(&error)
    }

    /// WezTerm
    private static func openWezTerm(atPath path: String) {
        let escapedPath = path.specialCharEscaped(2)
        let source = """
        do shell script "open -a WezTerm \(escapedPath)"
        """
        var error: NSDictionary?
        NSAppleScript(source: source)?.executeAndReturnError(&error)
    }

    /// CMUX
    private static func openCmux(atPath path: String) {
        let escapedPath = path.specialCharEscaped(2)
        let source = """
        do shell script "open -a cmux \(escapedPath)"
        """
        var error: NSDictionary?
        NSAppleScript(source: source)?.executeAndReturnError(&error)
    }
}

// 移植自 OpenInTerminal - String+Extension.swift
extension String {
    func specialCharEscaped(_ escapeCount: Int = 1) -> String {
        var result = self
        let specialChars = [" ", "(", ")", "&", "|", ";", "\"", "'", "<", ">", "`", "!", "{", "}", "[", "]", "$", "#", "^", "~", "?", "*", "\\"]
        let escape = String(repeating: "\\", count: escapeCount)
        for char in specialChars {
            result = result.replacingOccurrences(of: char, with: escape + char)
        }
        return result
    }
}
