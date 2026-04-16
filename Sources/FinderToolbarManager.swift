import Cocoa

@MainActor
class FinderToolbarManager {
    static let shared = FinderToolbarManager()

    private let appPath = "/Applications/anyGoShell.app"
    private let finderPrefsPath = "~/Library/Preferences/com.apple.finder.plist"

    /// 检查应用是否已添加到 Finder 工具栏
    func isAddedToToolbar() -> Bool {
        let plistPath = (finderPrefsPath as NSString).expandingTildeInPath

        guard let plistData = FileManager.default.contents(atPath: plistPath),
              let plist = try? PropertyListSerialization.propertyList(from: plistData, options: .mutableContainers, format: nil) as? [String: Any],
              let toolbarConfig = plist["NSToolbar Configuration Browser"] as? [String: Any],
              let itemPlists = toolbarConfig["TB Item Plists"] as? [String: [String: Any]] else {
            return false
        }

        // 检查是否有包含 anyGoShell 的项
        for (_, item) in itemPlists {
            if let urlString = item["_CFURLString"] as? String,
               urlString.contains("anyGoShell") {
                return true
            }
        }

        return false
    }

    /// 添加应用到 Finder 工具栏（引导用户手动添加）
    func addToToolbar() -> Bool {
        // 使用 AppleScript 打开引导窗口
        let script = """
        tell application "Finder"
            activate
            open (path to applications folder as text)
        end tell

        tell application "System Events"
            tell process "Finder"
                set frontmost to true
            end tell
        end tell
        """

        var error: NSDictionary?
        NSAppleScript(source: script)?.executeAndReturnError(&error)

        // 显示提示
        showAlert(
            title: L10n.toolbarAddTitle,
            message: L10n.toolbarAddMessage,
            informativeText: L10n.toolbarAddInstructions
        )

        return true
    }

    /// 从 Finder 工具栏移除应用
    func removeFromToolbar() -> Bool {
        let plistPath = (finderPrefsPath as NSString).expandingTildeInPath

        guard let plistData = FileManager.default.contents(atPath: plistPath),
              var plist = try? PropertyListSerialization.propertyList(from: plistData, options: .mutableContainers, format: nil) as? [String: Any],
              var toolbarConfig = plist["NSToolbar Configuration Browser"] as? [String: Any],
              var itemPlists = toolbarConfig["TB Item Plists"] as? [String: [String: Any]],
              var itemIdentifiers = toolbarConfig["TB Item Identifiers"] as? [String] else {
            showAlert(title: L10n.toolbarRemoveFailed, message: L10n.toolbarRemoveNotFound)
            return false
        }

        // 找到并移除包含 anyGoShell 的项
        var removedKey: String?
        for (key, item) in itemPlists {
            if let urlString = item["_CFURLString"] as? String,
               urlString.contains("anyGoShell") {
                removedKey = key
                break
            }
        }

        if let key = removedKey {
            itemPlists.removeValue(forKey: key)
            toolbarConfig["TB Item Plists"] = itemPlists

            // 移除对应的 identifier
            let index = Int(key) ?? -1
            if index >= 0 && index < itemIdentifiers.count {
                itemIdentifiers.remove(at: index)
                toolbarConfig["TB Item Identifiers"] = itemIdentifiers
            }

            plist["NSToolbar Configuration Browser"] = toolbarConfig

            // 保存 plist
            guard let newData = try? PropertyListSerialization.data(fromPropertyList: plist, format: .binary, options: 0) else {
                return false
            }

            try? newData.write(to: URL(fileURLWithPath: plistPath))

            // 显示成功提示
            showAlert(title: L10n.toolbarRemoveSuccess, message: "")

            // 重启 Finder
            restartFinder()

            return true
        }

        showAlert(title: L10n.toolbarRemoveFailed, message: L10n.toolbarRemoveNotFound)
        return false
    }

    /// 重启 Finder
    private func restartFinder() {
        let script = """
        do shell script "killall Finder"
        """
        var error: NSDictionary?
        NSAppleScript(source: script)?.executeAndReturnError(&error)
    }

    /// 显示提示对话框
    private func showAlert(title: String, message: String, informativeText: String? = nil) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = title
            alert.informativeText = informativeText ?? message
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
}