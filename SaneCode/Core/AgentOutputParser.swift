import Foundation

struct ParsedAgentOutput: Equatable {
    var summary: String?
    var filesChanged: [String]
    var checks: String?
    var limitations: String?
    var nextSuggestedAction: String?
    var planSteps: [String]
    var patchProposal: String?

    var hasStructuredOutput: Bool {
        summary != nil || !filesChanged.isEmpty || checks != nil || limitations != nil || nextSuggestedAction != nil || !planSteps.isEmpty || patchProposal != nil
    }
}

struct AgentOutputParser {
    private enum Section: String, CaseIterable {
        case summary = "summary"
        case filesChanged = "files changed"
        case checks = "checks"
        case limitations = "limitations"
        case nextSuggestedAction = "next suggested action"
        case plan = "plan"
        case patchProposal = "patch proposal"
    }

    func parse(_ output: String) -> ParsedAgentOutput {
        var buckets: [Section: [String]] = [:]
        var current: Section?

        for rawLine in output.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if let section = sectionHeader(in: line) {
                current = section
                continue
            }

            guard let current, !line.isEmpty else { continue }
            buckets[current, default: []].append(cleanBullet(line))
        }

        return ParsedAgentOutput(
            summary: joined(buckets[.summary]),
            filesChanged: buckets[.filesChanged] ?? [],
            checks: joined(buckets[.checks]),
            limitations: joined(buckets[.limitations]),
            nextSuggestedAction: joined(buckets[.nextSuggestedAction]),
            planSteps: buckets[.plan] ?? [],
            patchProposal: joined(buckets[.patchProposal])
        )
    }

    private func sectionHeader(in line: String) -> Section? {
        let normalized = line
            .lowercased()
            .trimmingCharacters(in: CharacterSet(charactersIn: "#*: "))
        return Section.allCases.first { normalized == $0.rawValue || normalized == "\($0.rawValue):" }
    }

    private func cleanBullet(_ line: String) -> String {
        line.replacingOccurrences(of: #"^[-*]\s+"#, with: "", options: .regularExpression)
    }

    private func joined(_ lines: [String]?) -> String? {
        guard let lines else { return nil }
        let value = lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
