import Foundation

struct VerificationRun: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var roomID: UUID
    var command: String
    var output: String = ""
    var exitCode: Int32?
    var startedAt: Date = Date()
    var endedAt: Date?
    var status: CommandStatus = .idle
}
