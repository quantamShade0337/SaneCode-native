import Foundation

struct AgentMessage: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var roomID: UUID
    var kind: MessageKind
    var text: String
    var timestamp: Date = Date()
    var metadata: [String: String] = [:]
}
