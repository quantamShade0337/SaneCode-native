import Foundation

struct VerificationManager {
    func bestCheckCommand(for repository: Repository) -> DetectedCommand? {
        repository.detectedCommands.first(where: { $0.kind == .checks && $0.isPrimary })
            ?? repository.detectedCommands.first(where: { $0.kind == .checks })
    }
}
