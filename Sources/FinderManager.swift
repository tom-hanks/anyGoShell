// 移植自 OpenInTerminal - OpenInTerminalCore/FinderManager.swift

import Cocoa
import ScriptingBridge

final class FinderManager: Sendable {

    static let shared = FinderManager()

    /// Get path to front Finder window or selected file.
    /// If the selected one is file, return its parent path.
    func getPathToFrontFinderWindowOrSelectedFile() -> String? {
        guard let fullUrl = getFullUrlToFrontFinderWindowOrSelectedFile() else {
            return nil
        }

        var isDirectory: ObjCBool = false

        guard FileManager.default.fileExists(atPath: fullUrl.path, isDirectory: &isDirectory) else {
            return nil
        }

        // if the selected is a file, then delete last path component
        guard isDirectory.boolValue else {
            return fullUrl.deletingLastPathComponent().path
        }

        return fullUrl.path
    }

    /// Get full url to front Finder window or selected file
    func getFullUrlToFrontFinderWindowOrSelectedFile() -> URL? {
        let finder = SBApplication(bundleIdentifier: "com.apple.finder")! as FinderApplication

        guard let selection = finder.selection,
              let selectionItems = selection.get() else {
            return nil
        }

        var target: FinderItem

        if let firstItem = (selectionItems as! Array<AnyObject>).first {
            // Files or folders selected
            target = firstItem as! FinderItem
        } else {
            // Check if there are finder windows opened
            guard let windows = finder.FinderWindows?(),
                  let firstWindow = windows.firstObject else {
                return nil
            }
            target = (firstWindow as! FinderFinderWindow).target?.get() as! FinderItem
        }

        guard let targetUrl = target.URL,
              let url = URL(string: targetUrl) else {
            return nil
        }

        return url
    }

    func getDesktopPath() -> String? {
        let homePath = NSHomeDirectory()
        guard let homeUrl = URL(string: homePath) else { return nil }
        return homeUrl.appendingPathComponent("Desktop").path
    }
}
