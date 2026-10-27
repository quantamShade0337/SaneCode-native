import Foundation

struct FailedCheckExtractor {
    func makeFailedCheck(roomID: UUID, queuedPromptID: UUID?, command: String, exitCode: Int32, output: String) -> FailedCheck {
        FailedCheck(
            roomID: roomID,
            queuedPromptID: queuedPromptID,
            command: command,
            exitCode: exitCode,
            fullOutput: output,
            errorExcerpt: excerpt(from: output)
        )
    }

    func excerpt(from output: String) -> String {
        let lines = output.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        let keywords = ["error", "failed", "exception", "cannot find", "module not found", "type error", "syntax error", "referenceerror", "traceback", "fatal"]
        let matching = lines.filter { line in
            let lower = line.lowercased()
            return keywords.contains { lower.contains($0) }
        }
        let tail = lines.suffix(120)
        let combined = (matching + tail).suffix(150)
        return combined.joined(separator: "\n")
    }
}
