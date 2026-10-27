import Foundation

struct BackendHealthItem: Identifiable, Equatable {
    var id: String { name }
    var name: String
    var status: String
    var detail: String
    var isHealthy: Bool
}

struct BackendHealthReport: Equatable {
    var generatedAt: Date = Date()
    var items: [BackendHealthItem]

    var hasFailures: Bool {
        items.contains { !$0.isHealthy }
    }
}

struct BackendHealthChecker {
    private let commandBuilder = AgentCommandBuilder()

    func check(sessionStore: SessionStore, repositories: [Repository], rooms: [AgentRoom]) -> BackendHealthReport {
        var items: [BackendHealthItem] = []
        let storageURL = URL(fileURLWithPath: sessionStore.storagePath)

        items.append(BackendHealthItem(
            name: "Local storage",
            status: FileManager.default.fileExists(atPath: storageURL.path) ? "Ready" : "Missing",
            detail: storageURL.path,
            isHealthy: FileManager.default.fileExists(atPath: storageURL.path)
        ))

        let codexPath = commandBuilder.codexPath()
        items.append(BackendHealthItem(
            name: "Codex CLI",
            status: codexPath == nil ? "Missing" : "Ready",
            detail: codexPath ?? "Install Codex CLI or configure a custom command.",
            isHealthy: codexPath != nil
        ))

        let inaccessibleRepos = repositories.filter { $0.accessErrorMessage != nil }
        items.append(BackendHealthItem(
            name: "Repository access",
            status: inaccessibleRepos.isEmpty ? "Ready" : "\(inaccessibleRepos.count) need attention",
            detail: inaccessibleRepos.first?.accessErrorMessage ?? "\(repositories.count) repositories restored.",
            isHealthy: inaccessibleRepos.isEmpty
        ))

        let staleWorktrees = rooms.compactMap(\.worktree).filter { $0.status == .ready && !FileManager.default.fileExists(atPath: $0.worktreePath) }
        items.append(BackendHealthItem(
            name: "Room worktrees",
            status: staleWorktrees.isEmpty ? "Ready" : "\(staleWorktrees.count) stale",
            detail: staleWorktrees.first?.worktreePath ?? "\(rooms.compactMap(\.worktree).count) tracked worktrees.",
            isHealthy: staleWorktrees.isEmpty
        ))

        return BackendHealthReport(items: items)
    }
}
