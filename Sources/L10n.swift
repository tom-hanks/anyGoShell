import Foundation

enum L10n {
    private static let bundle = Bundle.main

    static let appSubtitle = NSLocalizedString("app.subtitle", bundle: bundle, comment: "")
    static let preferredTerminal = NSLocalizedString("settings.preferred_terminal", bundle: bundle, comment: "")
    static let notInstalled = NSLocalizedString("settings.not_installed", bundle: bundle, comment: "")
    static let fallbackNote = NSLocalizedString("settings.fallback_note", bundle: bundle, comment: "")
    static let instructionsTitle = NSLocalizedString("instructions.title", bundle: bundle, comment: "")
    static let step1Title = NSLocalizedString("instructions.step1.title", bundle: bundle, comment: "")
    static let step1Detail = NSLocalizedString("instructions.step1.detail", bundle: bundle, comment: "")
    static let step2Title = NSLocalizedString("instructions.step2.title", bundle: bundle, comment: "")
    static let step2Detail = NSLocalizedString("instructions.step2.detail", bundle: bundle, comment: "")
    static let settingsTitle = NSLocalizedString("instructions.settings.title", bundle: bundle, comment: "")
    static let settingsDetail = NSLocalizedString("instructions.settings.detail", bundle: bundle, comment: "")
    static let tipOpenSettings = NSLocalizedString("tip.open_settings", bundle: bundle, comment: "")

    // 自定义终端相关
    static let customTerminal = NSLocalizedString("settings.custom_terminal", bundle: bundle, comment: "")
    static let enterAppName = NSLocalizedString("settings.enter_app_name", bundle: bundle, comment: "")
    static let validate = NSLocalizedString("settings.validate", bundle: bundle, comment: "")
    static let terminalFound = NSLocalizedString("settings.terminal_found", bundle: bundle, comment: "")
    static let terminalNotFound = NSLocalizedString("settings.terminal_not_found", bundle: bundle, comment: "")
    static let customTerminalHint = NSLocalizedString("settings.custom_terminal_hint", bundle: bundle, comment: "")

    // GitHub 相关
    static let githubLink = NSLocalizedString("github.link", bundle: bundle, comment: "")
    static let githubTooltip = NSLocalizedString("github.tooltip", bundle: bundle, comment: "")

    // Finder Toolbar 相关
    static let toolbarSectionTitle = NSLocalizedString("toolbar.section_title", bundle: bundle, comment: "")
    static let toolbarAddToFinder = NSLocalizedString("toolbar.add_to_finder", bundle: bundle, comment: "")
    static let toolbarRemoveFromFinder = NSLocalizedString("toolbar.remove_from_finder", bundle: bundle, comment: "")
    static let toolbarAddTitle = NSLocalizedString("toolbar.add_title", bundle: bundle, comment: "")
    static let toolbarAddMessage = NSLocalizedString("toolbar.add_message", bundle: bundle, comment: "")
    static let toolbarAddInstructions = NSLocalizedString("toolbar.add_instructions", bundle: bundle, comment: "")
    static let toolbarRemoveFailed = NSLocalizedString("toolbar.remove_failed", bundle: bundle, comment: "")
    static let toolbarRemoveNotFound = NSLocalizedString("toolbar.remove_not_found", bundle: bundle, comment: "")
    static let toolbarRemoveSuccess = NSLocalizedString("toolbar.remove_success", bundle: bundle, comment: "")
}
