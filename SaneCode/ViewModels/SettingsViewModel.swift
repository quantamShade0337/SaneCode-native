import Combine
import Foundation

final class SettingsViewModel: ObservableObject {
    @Published var appSettings: AppSettings
    @Published var agentConfigs: [AgentConfiguration]
    @Published var codexFound = false
    @Published var codexPath: String?
    @Published var storageMessage = ""

    private let settingsStore: SettingsStore
    private let builder = AgentCommandBuilder()

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
        appSettings = settingsStore.settings
        agentConfigs = settingsStore.agentConfigurations
        codexPath = builder.codexPath()
        codexFound = codexPath != nil
    }

    func save() {
        settingsStore.settings = appSettings
        settingsStore.agentConfigurations = agentConfigs
        settingsStore.save()
    }

    func testAgent() {
        codexPath = builder.codexPath()
        codexFound = codexPath != nil
    }

    func updateSafetyLevel(_ level: SafetyLevel) {
        appSettings.safetyLevel = level
        save()
    }

    func codexCommandPreview() -> String {
        let config = agentConfigs.first(where: { $0.kind == .codex }) ?? .codexDefault
        return builder.commandPreview(prompt: "Improve the selected code safely.", configuration: config)
    }

    var storagePath: String {
        settingsStore.storagePath
    }

    func clearSessionHistory() {
        settingsStore.sessionStore.clearSessionHistory()
        storageMessage = "Session history cleared."
    }

    func clearCachedScreenshots() {
        settingsStore.sessionStore.clearCachedScreenshots()
        storageMessage = "Cached screenshots cleared."
    }

    func exportSessions() {
        do {
            let url = try settingsStore.sessionStore.exportState()
            storageMessage = "Exported sessions to \(url.path)"
        } catch {
            storageMessage = "Could not export sessions: \(error.localizedDescription)"
        }
    }

    func reset() {
        settingsStore.sessionStore.clearSessionHistory()
        settingsStore.sessionStore.clearCachedScreenshots()
        appSettings = AppSettings()
        agentConfigs = [.codexDefault]
        save()
        storageMessage = "Sanecode has been reset."
    }
}
