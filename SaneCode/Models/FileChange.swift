import Foundation

struct FileChange: Identifiable, Codable, Equatable {
    var id: String { path + status.rawValue }
    var path: String
    var status: FileChangeStatus
    var additions: Int = 0
    var deletions: Int = 0
}
