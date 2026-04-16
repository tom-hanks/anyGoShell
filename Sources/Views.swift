import Cocoa
import SwiftUI

// MARK: - SwiftUI App（不带 @main，由 main.swift 手动调用）

struct AnyGoShellApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            MainView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 480, height: 600)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

// MARK: - Views

struct MainView: View {
    @AppStorage("PreferredTerminal") private var preferredTerminal = "Terminal"
    @AppStorage("UseCustomTerminal") private var useCustomTerminal = false
    @AppStorage("CustomTerminalName") private var customTerminalName = ""
    @State private var customTerminalValidated: Bool? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Header
                VStack(spacing: 6) {
                    // 使用自定义应用图标
                    if let iconImage = NSImage(named: "icon") {
                        Image(nsImage: iconImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 64, height: 64)
                    } else {
                        Image(systemName: "terminal.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.blue.gradient)
                    }

                    // 标题和 GitHub 链接
                    HStack(spacing: 12) {
                        Text("anyGoShell")
                            .font(.title2)
                            .fontWeight(.bold)

                        Link(destination: URL(string: "https://github.com/tom-hanks/anyGoShell")!) {
                            HStack(spacing: 6) {
                                Image(nsImage: NSImage(named: "GitHub")!)
                                    .resizable()
                                    .frame(width: 16, height: 16)
                                Text(L10n.githubLink)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .help(L10n.githubTooltip)
                    }

                    Text(L10n.appSubtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 16)

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
