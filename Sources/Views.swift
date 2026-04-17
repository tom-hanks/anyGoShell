import Cocoa
import SwiftUI

// MARK: - 版本更新检测与自动安装

enum UpdateError: Error, LocalizedError {
    case invalidURL
    case noZipAsset
    case downloadFailed
    case unzipFailed
    case noAppFound
    case replaceFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "下载链接无效"
        case .noZipAsset: return "未找到 zip 下载文件"
        case .downloadFailed: return "下载失败"
        case .unzipFailed: return "解压失败"
        case .noAppFound: return "未找到应用文件"
        case .replaceFailed: return "替换应用失败"
        }
    }
}

struct UpdateInfo {
    let version: String
    let downloadURL: String  // zip 下载链接
    let releaseNotes: String?
}

@MainActor
class UpdateChecker: ObservableObject {
    static let shared = UpdateChecker()

    @Published var updateInfo: UpdateInfo?
    @Published var isChecking = false
    @Published var isDownloading = false
    @Published var downloadProgress: Double = 0
    @Published var statusMessage: String = ""

    private let repoURL = "https://api.github.com/repos/tom-hanks/anyGoShell/releases/latest"

    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    func checkForUpdates(showAlert: Bool = false) {
        isChecking = true
        statusMessage = "正在检查..."

        Task {
            do {
                let info = try await fetchLatestRelease()
                await MainActor.run {
                    self.isChecking = false
                    self.statusMessage = ""
                    if let info = info, isNewerVersion(info.version) {
                        self.updateInfo = info
                        if showAlert {
                            showUpdateAvailableAlert(info: info)
                        }
                    } else if showAlert {
                        showNoUpdateAlert()
                    }
                }
            } catch {
                await MainActor.run {
                    self.isChecking = false
                    self.statusMessage = ""
                    if showAlert {
                        showErrorAlert(error: error)
                    }
                }
            }
        }
    }

    private func showUpdateAvailableAlert(info: UpdateInfo) {
        let alert = NSAlert()
        alert.messageText = "发现新版本 v\(info.version)"
        alert.informativeText = "当前版本: v\(currentVersion)\n\n点击「更新」按钮在界面上下载安装"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "好的")
        alert.runModal()
    }

    private func showNoUpdateAlert() {
        let alert = NSAlert()
        alert.messageText = "暂无更新"
        alert.informativeText = "当前已是最新版本 v\(currentVersion)"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "好的")
        alert.runModal()
    }

    private func showErrorAlert(error: Error) {
        let alert = NSAlert()
        alert.messageText = "更新失败"
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .warning
        alert.addButton(withTitle: "好的")
        alert.runModal()
    }

    func downloadAndInstall() {
        guard let info = updateInfo else { return }

        isDownloading = true
        downloadProgress = 0
        statusMessage = "正在下载..."

        Task { @MainActor in
            do {
                // 使用 URLSession.download 下载 zip
                downloadProgress = 0.1

                let zipURL = try await downloadZip(from: info.downloadURL)

                downloadProgress = 0.5
                statusMessage = "正在解压..."

                // 解压
                let appURL = try await unzip(zipURL: zipURL)

                downloadProgress = 0.8
                statusMessage = "正在安装..."

                // 替换应用
                try await replaceApp(newAppURL: appURL)

                downloadProgress = 1.0
                statusMessage = "更新完成！"

                // 清理临时文件
                cleanupTempFiles(zipURL: zipURL, extractDir: appURL.deletingLastPathComponent())

                // 延迟重启
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.restartApp()
                }
            } catch {
                isDownloading = false
                statusMessage = ""
                showErrorAlert(error: error)
            }
        }
    }

    private func downloadZip(from urlString: String) async throws -> URL {
        guard let url = URL(string: urlString) else {
            throw UpdateError.invalidURL
        }

        let tempDir = FileManager.default.temporaryDirectory
        let zipURL = tempDir.appendingPathComponent("anyGoShell-update.zip")

        // 删除旧文件
        try? FileManager.default.removeItem(at: zipURL)

        // 使用 URLSession.download（自动处理重定向）
        let (localURL, response) = try await URLSession.shared.download(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw UpdateError.downloadFailed
        }

        // GitHub 可能返回 302 重定向，download 会自动跟随
        if httpResponse.statusCode == 200 || httpResponse.statusCode == 302 {
            try FileManager.default.moveItem(at: localURL, to: zipURL)
            return zipURL
        } else {
            throw UpdateError.downloadFailed
        }
    }

    private func unzip(zipURL: URL) async throws -> URL {
        let extractDir = FileManager.default.temporaryDirectory.appendingPathComponent("anyGoShell-extract")

        // 清理旧目录
        try? FileManager.default.removeItem(at: extractDir)
        try FileManager.default.createDirectory(at: extractDir, withIntermediateDirectories: true)

        // 使用 unzip 命令解压
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-q", "-o", zipURL.path, "-d", extractDir.path]

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            throw UpdateError.unzipFailed
        }

        // 查找解压后的 .app
        let contents = try FileManager.default.contentsOfDirectory(atPath: extractDir.path)
        guard let appName = contents.first(where: { $0.hasSuffix(".app") }) else {
            throw UpdateError.noAppFound
        }

        return extractDir.appendingPathComponent(appName)
    }

    private func replaceApp(newAppURL: URL) async throws {
        let installURL = URL(fileURLWithPath: "/Applications/anyGoShell.app")

        // 删除旧应用
        if FileManager.default.fileExists(atPath: installURL.path) {
            try FileManager.default.removeItem(at: installURL)
        }

        // 复制新应用
        try FileManager.default.copyItem(at: newAppURL, to: installURL)
    }

    private func cleanupTempFiles(zipURL: URL, extractDir: URL) {
        try? FileManager.default.removeItem(at: zipURL)
        try? FileManager.default.removeItem(at: extractDir)
    }

    private func fetchLatestRelease() async throws -> UpdateInfo? {
        let url = URL(string: repoURL)!
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        guard let tagName = json?["tag_name"] as? String else { return nil }
        let version = tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName

        // 获取 zip asset 的下载链接
        let assets = json?["assets"] as? [[String: Any]]
        let zipAsset = assets?.first { asset in
            (asset["name"] as? String)?.hasSuffix(".zip") ?? false
        }

        guard let downloadURL = zipAsset?["browser_download_url"] as? String else {
            throw UpdateError.noZipAsset
        }

        let releaseNotes = json?["body"] as? String

        return UpdateInfo(version: version, downloadURL: downloadURL, releaseNotes: releaseNotes)
    }

    private func isNewerVersion(_ remote: String) -> Bool {
        return remote.compare(currentVersion, options: .numeric) == .orderedDescending
    }

    private func restartApp() {
        // 使用 shell 命令延迟重启
        let script = """
        sleep 1
        open /Applications/anyGoShell.app
        """
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", script]
        try? process.run()

        NSApp.terminate(nil)
    }
}

// MARK: - SwiftUI App（不带 @main，由 main.swift 手动调用）

struct AnyGoShellApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var updateChecker = UpdateChecker.shared

    var body: some Scene {
        WindowGroup {
            MainView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 480, height: 600)
        .commands {
            CommandGroup(replacing: .newItem) {}

            // 添加"检查更新"菜单项到应用菜单
            CommandGroup(after: .appInfo) {
                Button("检查更新...") {
                    updateChecker.checkForUpdates(showAlert: true)
                }
                .keyboardShortcut("U", modifiers: .command)
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        // 启动时自动检查更新（静默检查，不弹窗）
        UpdateChecker.shared.checkForUpdates(showAlert: false)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

// MARK: - Views

// MARK: - 更新提示横幅（有新版本时显示）

struct UpdateBannerView: View {
    @StateObject private var updateChecker = UpdateChecker.shared

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 16) {
                // 更新图标
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: updateChecker.isDownloading ? "arrow.down.circle" : "arrow.down.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.green)
                }

                // 版本信息
                VStack(alignment: .leading, spacing: 2) {
                    if updateChecker.isDownloading {
                        Text(updateChecker.statusMessage)
                            .font(.system(size: 13, weight: .semibold))
                        // 进度条
                        ProgressView(value: updateChecker.downloadProgress, total: 1.0)
                            .progressViewStyle(.linear)
                            .frame(width: 100)
                    } else {
                        Text("有新版本可用")
                            .font(.system(size: 13, weight: .semibold))
                        Text("v\(updateChecker.updateInfo?.version ?? "?")")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // 更新按钮
                Button(action: {
                    updateChecker.downloadAndInstall()
                }) {
                    HStack(spacing: 6) {
                        if updateChecker.isDownloading {
                            Text("\(Int(updateChecker.downloadProgress * 100))%")
                                .font(.system(size: 11, weight: .medium))
                        } else {
                            Image(systemName: "arrow.down.circle")
                            Text("更新")
                        }
                    }
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(updateChecker.isDownloading ? Color.gray : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .disabled(updateChecker.isDownloading)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.green.opacity(0.05))
        }
    }
}

struct MainView: View {
    @AppStorage("PreferredTerminal") private var preferredTerminal = "Terminal"
    @AppStorage("UseCustomTerminal") private var useCustomTerminal = false
    @AppStorage("CustomTerminalName") private var customTerminalName = ""
    @State private var customTerminalValidated: Bool? = nil
    @State private var isAddedToToolbar: Bool = false
    @StateObject private var updateChecker = UpdateChecker.shared

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    // Header - 精致的品牌区域
                    VStack(spacing: 8) {
                        // 应用图标
                        if let iconImage = NSImage(named: "icon") {
                            Image(nsImage: iconImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 72, height: 72)
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        } else {
                            Image(systemName: "terminal.fill")
                                .font(.system(size: 56))
                                .foregroundStyle(.blue.gradient)
                        }

                        // 标题行
                        HStack(spacing: 10) {
                            Text("anyGoShell")
                                .font(.system(size: 22, weight: .bold, design: .rounded))

                            // GitHub 链接
                            Link(destination: URL(string: "https://github.com/tom-hanks/anyGoShell")!) {
                                Image(nsImage: NSImage(named: "GitHub")!)
                                    .resizable()
                                    .frame(width: 18, height: 18)
                                    .opacity(0.7)
                            }
                            .buttonStyle(.plain)
                            .help(L10n.githubTooltip)
                        }

                        // 版本行：版本号 + 更新按钮
                        HStack(spacing: 12) {
                            // 当前版本
                            Text("v\(updateChecker.currentVersion)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)

                            // 更新按钮
                            Button(action: {
                                updateChecker.checkForUpdates(showAlert: true)
                            }) {
                                HStack(spacing: 4) {
                                    if updateChecker.isChecking {
                                        ProgressView()
                                            .scaleEffect(0.6)
                                            .frame(width: 12, height: 12)
                                    } else {
                                        Image(systemName: "arrow.up.circle")
                                    }
                                    Text(updateChecker.isChecking ? "检查中..." : "检查更新")
                                }
                                .font(.system(size: 11, weight: .medium))
                            }
                            .buttonStyle(.bordered)
                            .disabled(updateChecker.isChecking || updateChecker.isDownloading)
                            .controlSize(.small)

                            // 新版本提示
                            if let info = updateChecker.updateInfo {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .foregroundColor(.green)
                                    Text("新版本 v\(info.version)")
                                        .foregroundColor(.green)
                                }
                                .font(.system(size: 11, weight: .medium))
                            }
                        }

                        // 副标题
                        Text(L10n.appSubtitle)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 8)

                Divider()
                    .padding(.horizontal)

                // Finder Toolbar Section
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "folder")
                            .foregroundColor(.orange)
                        Text(L10n.toolbarSectionTitle)
                            .font(.headline)
                        Spacer()
                    }

                    Button(action: {
                        if isAddedToToolbar {
                            _ = FinderToolbarManager.shared.removeFromToolbar()
                        } else {
                            _ = FinderToolbarManager.shared.addToToolbar()
                        }
                        // 刷新状态
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            isAddedToToolbar = FinderToolbarManager.shared.isAddedToToolbar()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: isAddedToToolbar ? "minus.circle" : "plus.circle")
                            Text(isAddedToToolbar ? L10n.toolbarRemoveFromFinder : L10n.toolbarAddToFinder)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(isAddedToToolbar ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .onAppear {
                        isAddedToToolbar = FinderToolbarManager.shared.isAddedToToolbar()
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)
                .padding(.horizontal)

                Divider()
                    .padding(.horizontal)

                // Settings Section
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "gear")
                            .foregroundColor(.blue)
                        Text(L10n.preferredTerminal)
                            .font(.headline)
                        Spacer()
                    }

                    // 预设终端列表（始终显示）
                    let installed = TerminalManager.Terminal.allCases.filter { $0.isInstalled }

                    Picker("", selection: $preferredTerminal) {
                        ForEach(installed, id: \.rawValue) { terminal in
                            HStack {
                                if let icon = getAppIcon(for: terminal.appPath) {
                                    Image(nsImage: icon)
                                        .resizable()
                                        .frame(width: 20, height: 20)
                                }
                                Text(terminal.displayName)
                            }
                            .tag(terminal.rawValue)
                        }

                        // 自定义终端选项
                        HStack {
                            Image(systemName: "pencil.circle")
                                .foregroundColor(.purple)
                            Text(L10n.customTerminal)
                        }
                        .tag("Custom")
                    }
                    .pickerStyle(.radioGroup)
                    .labelsHidden()
                    .onChange(of: preferredTerminal) { _, newValue in
                        // 选中预设终端时，取消自定义终端勾选
                        if newValue != "Custom" {
                            useCustomTerminal = false
                            customTerminalValidated = nil
                        } else {
                            useCustomTerminal = true
                            if customTerminalName.isEmpty {
                                customTerminalName = "cmux"
                            }
                        }
                    }

                    // 自定义终端输入区（仅当选中 Custom 时显示）
                    if preferredTerminal == "Custom" {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                TextField(L10n.enterAppName, text: $customTerminalName)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 200)
                                Button(L10n.validate) {
                                    customTerminalValidated = TerminalManager.isCustomTerminalInstalled(name: customTerminalName)
                                }
                                .buttonStyle(.bordered)

                                if let validated = customTerminalValidated {
                                    Image(systemName: validated ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(validated ? .green : .red)
                                    Text(validated ? L10n.terminalFound : L10n.terminalNotFound)
                                        .font(.caption)
                                        .foregroundColor(validated ? .green : .red)
                                }
                            }

                            Text(L10n.customTerminalHint)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 5)
                    }

                    Text(L10n.fallbackNote)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)
                .padding(.horizontal)

                Divider()
                    .padding(.horizontal)

                // Usage Instructions
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                            Text(L10n.instructionsTitle)
                                .font(.headline)
                            Spacer()
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            instructionRow(
                                icon: "1.circle.fill", color: .blue,
                                title: L10n.step1Title,
                                detail: L10n.step1Detail
                            )

                            Divider()

                            instructionRow(
                                icon: "2.circle.fill", color: .green,
                                title: L10n.step2Title,
                                detail: L10n.step2Detail
                            )

                            Divider()

                            instructionRow(
                                icon: "gearshape.fill", color: .orange,
                                title: L10n.settingsTitle,
                                detail: L10n.settingsDetail
                            )
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }
            }

            // 更新横幅（有新版本时显示在底部）
            if updateChecker.updateInfo != nil {
                UpdateBannerView()
            }
        }
        .frame(width: 480, height: 600)
    }

    private func instructionRow(icon: String, color: Color, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.body)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(detail)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func getAppIcon(for appPath: String) -> NSImage? {
        guard FileManager.default.fileExists(atPath: appPath) else { return nil }
        let icon = NSWorkspace.shared.icon(forFile: appPath)
        icon.size = NSSize(width: 20, height: 20)
        return icon
    }
}
