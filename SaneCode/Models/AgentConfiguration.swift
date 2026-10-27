import Foundation

struct AgentConfiguration: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var kind: AgentKind
    var executable: String
    var arguments: String
    var environment: [String: String] = [:]
    var usesRepositoryWorkingDirectory: Bool = true

    static let codexDefault = AgentConfiguration(
        name: "Codex",
        kind: .codex,
        executable: "codex",
        arguments: "exec --json {prompt}"
    )
}

struct SafetyDecision: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var command: String
    var approved: Bool
    var reason: String
    var createdAt: Date = Date()
}
