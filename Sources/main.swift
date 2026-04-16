import Cocoa
import SwiftUI

// 自动检测默认终端（首次运行时）
func detectDefaultTerminal() {
    let defaults = UserDefaults.standard
    if defaults.object(forKey: "PreferredTerminal") != nil { return }
    if FileManager.default.fileExists(atPath: "/Applications/iTerm.app") {
        defaults.set("iTerm", forKey: "PreferredTerminal")
    } else {
        defaults.set("Terminal", forKey: "PreferredTerminal")
    }
}

// ── 入口 ──

detectDefaultTerminal()

let showUIFlag = CommandLine.arguments.contains("--show-ui")

// 工具栏模式条件：Finder 必须是最前台应用
let finderIsFrontmost = NSWorkspace.shared.frontmostApplication?.bundleIdentifier == "com.apple.finder"

if showUIFlag || !finderIsFrontmost {
    AnyGoShellApp.main()
} else {
    var path = FinderManager.shared.getPathToFrontFinderWindowOrSelectedFile() ?? ""
    if path.isEmpty {
        path = FinderManager.shared.getDesktopPath() ?? ""
    }

    if path.isEmpty || path.hasPrefix("/Applications") {
        AnyGoShellApp.main()
    } else {
        TerminalManager.openTerminal(atPath: path)
    }
}
