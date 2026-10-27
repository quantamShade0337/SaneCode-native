import Foundation

struct DetectedCommand: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var command: String
    var kind: CommandKind
    var isPrimary: Bool = false
}
