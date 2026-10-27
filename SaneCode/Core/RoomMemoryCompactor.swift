import Foundation

struct RoomMemoryCompactor {
    func compact(room: AgentRoom, maxCharacters: Int = 4_000) -> String {
        var lines: [String] = []

        if let summary = room.completionSummaries.first {
            lines.append("Latest task: \(summary.summary)")
            lines.append("Checks: \(summary.checksRun ? (summary.checksPassed ? "passed" : "failed") : "not run")")
            lines.append("Next: \(summary.nextSuggestedAction)")
        }

        if !room.changedFiles.isEmpty {
            lines.append("Changed files: \(room.changedFiles.map(\.path).prefix(12).joined(separator: ", "))")
        }

        if let failed = room.failedChecks.last(where: { $0.resolvedAt == nil }) {
            lines.append("Open failed check: \(failed.command), exit \(failed.exitCode)")
            lines.append("Error excerpt: \(failed.errorExcerpt.prefix(700))")
        }

        if let plan = room.latestPlan, !plan.steps.isEmpty {
            lines.append("Latest plan: \(plan.steps.joined(separator: " | "))")
        }

        let recentMessages = room.messages.suffix(12).map { "\($0.kind.label): \($0.text.prefix(240))" }
        lines.append(contentsOf: recentMessages)

        let memory = lines.joined(separator: "\n")
        if memory.count <= maxCharacters { return memory }
        return String(memory.suffix(maxCharacters))
    }
}
