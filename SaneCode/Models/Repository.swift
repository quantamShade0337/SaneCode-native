import Foundation

struct Repository: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var path: String
    var branch: String?
    var isGitRepo: Bool
    var packageManager: String?
    var framework: String?
    var dirtyFileCount: Int
    var remoteURL: String?
    var statusSummary: [FileChange] = []
    var detectedCommands: [DetectedCommand] = []
    var lastOpenedAt: Date = Date()
    var securityScopedBookmark: Data?
    var bookmarkIsStale: Bool?
    var accessErrorMessage: String?
}
