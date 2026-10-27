import Foundation

struct HarnessPromptBuilder {
    private let systemPrompt = SystemPromptBuilder()
    private let modeBuilder = ModeInstructionBuilder()
    private let reasoningBuilder = ReasoningInstructionBuilder()
    private let accessBuilder = AccessModeInstructionBuilder()

    func build(userPrompt: String, repository: Repository, mode: RoomMode, reasoning: ReasoningLevel, access: AgentAccessMode) -> String {
        """
        \(systemPrompt.build())

        REPOSITORY CONTEXT:
        - Name: \(repository.name)
        - Path: \(repository.path)
        - Branch: \(repository.branch ?? "unknown")
        - Package manager: \(repository.packageManager ?? "unknown")
        - Framework: \(repository.framework ?? "unknown")
        - Detected checks: \(checks(for: repository))

        USER TASK:
        \(userPrompt)

        MODE:
        \(mode.rawValue)
        \(modeBuilder.build(for: mode))

        REASONING LEVEL:
        \(reasoning.rawValue)
        \(reasoningBuilder.build(for: reasoning))

        ACCESS MODE:
        \(access.rawValue)
        \(accessBuilder.build(for: access))

        SAFETY RULES:
        - Understand the task before editing.
        - Inspect the repository before changing files.
        - Repository evidence beats assumptions.
        - Search before guessing file paths.
        - Prefer the smallest safe diff.
        - Do not refactor unrelated code.
        - Do not run destructive commands.
        - Do not install packages unless necessary and approved.
        - Do not claim checks passed unless checks actually passed.
        - If checks were not run, say "Checks not run."
        - After changes, explain what changed and what remains.
        - Sanecode instructs the local Codex CLI to follow this access mode. Sanecode safety checks apply to commands run through Sanecode.

        EXPECTED OUTPUT FORMAT:
        Plan:
        - Short ordered steps taken or proposed
        Summary:
        - What changed
        Files changed:
        - Files changed
        Checks:
        - Checks run and results
        Limitations:
        - Limitations or risks
        Next suggested action:
        - Suggested next action
        Patch Proposal:
        - Only include this section when access mode is Suggest Edits or when you are proposing changes without applying them.
        """
    }

    private func checks(for repository: Repository) -> String {
        let commands = repository.detectedCommands.filter { $0.kind == .checks }.map(\.command)
        return commands.isEmpty ? "none detected" : commands.joined(separator: ", ")
    }

}
