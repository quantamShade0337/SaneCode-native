import Foundation

struct AppSettings: Codable, Equatable {
    var defaultAgent: AgentKind = .codex
    var safetyLevel: SafetyLevel = .normal
    var theme: ThemeChoice = .system
    var defaultRepoFolder: String = NSHomeDirectory()
    var restoreRooms: Bool = true
    var openLastRepositoryOnLaunch: Bool = false
    var showWelcomeOnLaunch: Bool = true
    var autoSaveSessions: Bool = true
    var maxSessionHistory: Int = 50
    var defaultReasoningLevel: ReasoningLevel = .balanced
    var defaultAccessMode: AgentAccessMode = .acceptEdits
    var defaultQueueRunCondition: QueueRunCondition = .manual
    var pauseQueueOnFailure: Bool = true
    var defaultContextPreset: ContextPreset = .standard
    var showApproximateTokenEstimate: Bool = true
    var terminalSettings: TerminalSettings = TerminalSettings()
    var previewSettings: PreviewSettings = PreviewSettings()

    init() {}

    enum CodingKeys: String, CodingKey {
        case defaultAgent, safetyLevel, theme, defaultRepoFolder, restoreRooms, openLastRepositoryOnLaunch, showWelcomeOnLaunch, autoSaveSessions, maxSessionHistory, defaultReasoningLevel, defaultAccessMode, defaultQueueRunCondition, pauseQueueOnFailure, defaultContextPreset, showApproximateTokenEstimate, terminalSettings, previewSettings
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        defaultAgent = try c.decodeIfPresent(AgentKind.self, forKey: .defaultAgent) ?? .codex
        safetyLevel = try c.decodeIfPresent(SafetyLevel.self, forKey: .safetyLevel) ?? .normal
        theme = try c.decodeIfPresent(ThemeChoice.self, forKey: .theme) ?? .system
        defaultRepoFolder = try c.decodeIfPresent(String.self, forKey: .defaultRepoFolder) ?? NSHomeDirectory()
        restoreRooms = try c.decodeIfPresent(Bool.self, forKey: .restoreRooms) ?? true
        openLastRepositoryOnLaunch = try c.decodeIfPresent(Bool.self, forKey: .openLastRepositoryOnLaunch) ?? false
        showWelcomeOnLaunch = try c.decodeIfPresent(Bool.self, forKey: .showWelcomeOnLaunch) ?? true
        autoSaveSessions = try c.decodeIfPresent(Bool.self, forKey: .autoSaveSessions) ?? true
        maxSessionHistory = try c.decodeIfPresent(Int.self, forKey: .maxSessionHistory) ?? 50
        defaultReasoningLevel = try c.decodeIfPresent(ReasoningLevel.self, forKey: .defaultReasoningLevel) ?? .balanced
        defaultAccessMode = try c.decodeIfPresent(AgentAccessMode.self, forKey: .defaultAccessMode) ?? .acceptEdits
        defaultQueueRunCondition = try c.decodeIfPresent(QueueRunCondition.self, forKey: .defaultQueueRunCondition) ?? .manual
        pauseQueueOnFailure = try c.decodeIfPresent(Bool.self, forKey: .pauseQueueOnFailure) ?? true
        defaultContextPreset = try c.decodeIfPresent(ContextPreset.self, forKey: .defaultContextPreset) ?? .standard
        showApproximateTokenEstimate = try c.decodeIfPresent(Bool.self, forKey: .showApproximateTokenEstimate) ?? true
        terminalSettings = try c.decodeIfPresent(TerminalSettings.self, forKey: .terminalSettings) ?? TerminalSettings()
        previewSettings = try c.decodeIfPresent(PreviewSettings.self, forKey: .previewSettings) ?? PreviewSettings()
    }
}

struct TerminalSettings: Codable, Equatable {
    var shell: String = "/bin/zsh"
    var fontSize: Double = 12
    var showTimestamps: Bool = false
    var autoScroll: Bool = true
    var maxOutputLines: Int = 5000
}

struct PreviewSettings: Codable, Equatable {
    var defaultDevCommand: String = ""
    var autoDetectLocalhost: Bool = true
    var openPreviewAfterStartingServer: Bool = true
    var autoReloadAfterTask: Bool = true
    var defaultDevice: PreviewDevice = .desktop
    var screenshotFormat: String = "png"
}
