import Foundation

struct AccessModeInstructionBuilder {
    func build(for access: AgentAccessMode) -> String {
        switch access {
        case .planOnly:
            "Do not edit files. Do not run modifying commands. Inspect and propose a plan only. Include files likely to change. Include risks and recommended checks."
        case .suggestEdits:
            "Do not apply edits directly. Suggest precise patches or file changes. Provide diff-style proposals if practical. Do not run modifying commands."
        case .acceptEdits:
            "May edit files. Prefer minimal diffs. Do not install dependencies without approval. Do not run build/test/lint automatically unless user asks or app flow triggers it. After editing, summarize files changed and checks to run."
        case .buildAndCheck:
            "May edit files. May run safe detected build/test/lint/typecheck commands. If checks fail, may attempt focused fixes. Still obey SafetyPolicy. Do not install dependencies, run migrations, deploy, or push without approval."
        case .fullAccess:
            "May edit files and run safe local commands needed to complete the task. May run build/test/lint/dev inspection commands. Still obey SafetyPolicy. Dangerous/destructive actions are still blocked or approval-required. This is not no safety. Prefer minimal diffs and clear verification."
        }
    }
}
