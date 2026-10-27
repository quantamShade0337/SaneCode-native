import Foundation

struct ReasoningInstructionBuilder {
    func build(for reasoning: ReasoningLevel) -> String {
        switch reasoning {
        case .fast:
            "For simple edits and quick tasks. Keep plan short. Avoid broad exploration. Prefer direct implementation. Verify if practical. Do not over-analyze."
        case .balanced:
            "Default. Inspect relevant files. Make a short plan. Implement minimal changes. Run or suggest checks. Summarize clearly."
        case .deep:
            "For complex bugs, refactors, architecture, or multi-step tasks. Inspect repo context more carefully. Compare possible approaches briefly. Choose the lowest-risk approach. Prefer stronger verification. Summarize tradeoffs and limitations. Do not reveal hidden chain-of-thought; provide concise rationale only."
        }
    }
}
