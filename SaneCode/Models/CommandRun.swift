import Foundation

struct CommandRun: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var roomID: UUID?
    var command: String
    var workingDirectory: String
    var output: String = ""
    var errorOutput: String = ""
    var exitCode: Int32?
    var startedAt: Date = Date()
    var endedAt: Date?
    var status: CommandStatus = .idle
    var kind: CommandKind

    var combinedOutput: String {
        [output, errorOutput].filter { !$0.isEmpty }.joined(separator: "\n")
    }
}
