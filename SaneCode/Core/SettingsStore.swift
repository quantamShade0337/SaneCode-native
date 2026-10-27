import Combine
import Foundation

final class SettingsStore: ObservableObject {
    @Published var settings: AppSettings
    @Published var agentConfigurations: [AgentConfiguration]

    let sessionStore: SessionStore

    init(sessionStore: SessionStore) {
        self.sessionStore = sessionStore
        let state = sessionStore.load()
        settings = state.settings
        agentConfigurations = state.agentConfigurations
        if let index = agentConfigurations.firstIndex(where: { $0.kind == .codex }) {
            if agentConfigurations[index].arguments == "\"{prompt}\"" {
                agentConfigurations[index].arguments = "{prompt}"
            }
            if agentConfigurations[index].arguments == "{prompt}" {
                agentConfigurations[index].arguments = AgentConfiguration.codexDefault.arguments
            }
        } else {
            agentConfigurations.insert(.codexDefault, at: 0)
        }
    }

    func save(repositories: [Repository]? = nil, rooms: [AgentRoom]? = nil) {
        let existing = sessionStore.load()
        sessionStore.save(PersistedState(
            repositories: repositories ?? existing.repositories,
            rooms: rooms ?? existing.rooms,
            settings: settings,
            agentConfigurations: agentConfigurations,
            commandHistory: existing.commandHistory
        ))
    }

    var storagePath: String {
        sessionStore.storagePath
    }
}
