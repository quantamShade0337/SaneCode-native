import Foundation

struct ModeInstructionBuilder {
    func build(for mode: RoomMode) -> String {
        switch mode {
        case .auto:
            "Choose the safest appropriate workflow. Ask only for the necessary scope. Prefer minimal changes. If the task looks like explanation/review, avoid editing."
        case .bugFix:
            "Locate the likely cause before editing. Prefer reproducing or inspecting the failure first. Make the smallest targeted fix. Avoid unrelated refactors. Run or suggest relevant checks. If checks fail, analyze the error before changing more code."
        case .feature:
            "Follow existing project patterns. Avoid new dependencies unless clearly necessary and approved. Keep the implementation minimal but complete. Update related types/tests if obvious."
        case .uiChange:
            "Preserve functionality. Match the existing design system. Prefer component-level edits. Use Preview context if available. Avoid unrelated business logic changes. Suggest preview/check steps after editing."
        case .refactor:
            "Preserve behavior. Avoid mixing feature work with refactor. Keep changes easy to review. Require stronger checks if practical. Do not refactor unrelated modules."
        case .explain:
            "Read-only. Do not edit files. Do not run modifying commands. Explain clearly using repo evidence. Mention relevant files and code paths."
        case .test:
            "Follow the existing test framework. Add or improve tests around the requested behavior. Avoid changing production behavior unless necessary. Run tests if allowed."
        case .reviewOnly:
            "Do not edit files. Review current git diff or selected files. Summarize risks, bugs, regressions, unnecessary changes, and suggested improvements. Provide actionable feedback."
        }
    }
}
