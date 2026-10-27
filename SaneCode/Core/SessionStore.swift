import Foundation

struct PersistedState: Codable {
    var repositories: [Repository] = []
    var rooms: [AgentRoom] = []
    var settings: AppSettings = AppSettings()
    var agentConfigurations: [AgentConfiguration] = [.codexDefault]
    var commandHistory: [String] = []
}

final class SessionStore {
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let fileURL: URL

    init() {
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = base.appendingPathComponent("Sanecode", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        fileURL = directory.appendingPathComponent("state.json")
    }

    func load() -> PersistedState {
        guard
            let data = try? Data(contentsOf: fileURL),
            let state = try? decoder.decode(PersistedState.self, from: data)
        else { return PersistedState() }
        return state
    }

    func save(_ state: PersistedState) {
        guard let data = try? encoder.encode(state) else { return }
        try? data.write(to: fileURL, options: [.atomic])
    }

    func clearSessionHistory() {
        save(PersistedState())
    }

    func exportState() throws -> URL {
        let exportURL = fileURL.deletingLastPathComponent().appendingPathComponent("Sanecode Sessions Export.json")
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try? FileManager.default.removeItem(at: exportURL)
            try FileManager.default.copyItem(at: fileURL, to: exportURL)
        } else {
            let data = try encoder.encode(PersistedState())
            try data.write(to: exportURL, options: [.atomic])
        }
        return exportURL
    }

    func clearCachedScreenshots() {
        let screenshots = fileURL.deletingLastPathComponent().appendingPathComponent("Screenshots", isDirectory: true)
        try? FileManager.default.removeItem(at: screenshots)
        try? FileManager.default.createDirectory(at: screenshots, withIntermediateDirectories: true)
    }

    var storagePath: String {
        fileURL.deletingLastPathComponent().path
    }
}
