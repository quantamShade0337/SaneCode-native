import Foundation

struct TaskContextBuilder {
    private let promptBuilder = HarnessPromptBuilder()

    func build(room: AgentRoom, repository: Repository) -> TaskContext {
        let basePrompt = promptBuilder.build(
            userPrompt: room.prompt,
            repository: repository,
            mode: room.mode,
            reasoning: room.reasoningLevel,
            access: room.accessMode
        )
        let selectedFiles = room.changedFiles.map(\.path)
        let browserContext = room.screenshots.prefix(5).map {
            "Screenshot: \($0.filePath ?? "not saved") · \($0.url) · \($0.device.rawValue)"
        }
        let attachedErrors = room.verificationRuns.last?.status == .failed ? [room.verificationRuns.last?.output ?? "Checks failed."] : []
        let diffSummary = room.changedFiles.isEmpty ? "No changed files." : "\(room.changedFiles.count) changed files: \(room.changedFiles.map(\.path).joined(separator: ", "))"
        let repositorySummary = "\(repository.name) · \(repository.branch ?? "no branch") · \(repository.packageManager ?? "unknown package manager") · \(repository.framework ?? "unknown framework")"
        let sections = sections(for: room, repository: repository, basePrompt: basePrompt, selectedFiles: selectedFiles, browserContext: browserContext, attachedErrors: attachedErrors, diffSummary: diffSummary)
        let includedSections = sections.filter(\.isIncluded)
        let fullPrompt = """
        \(basePrompt)

        INCLUDED CONTEXT:
        \(includedSections.map { "\($0.title):\n\($0.content)" }.joined(separator: "\n\n"))

        Context safety:
        - Do not intentionally include secrets.
        - .env files are excluded by default.
        - Noisy folders are excluded by default: node_modules, .next, dist, build, DerivedData, .git, vendor, .venv, __pycache__.
        - Sanecode builds this task prompt for the local Codex CLI. Codex may still inspect files through its own tools depending on its configuration.
        """
        let characterCount = fullPrompt.count

        return TaskContext(
            roomID: room.id,
            repositorySummary: repositorySummary,
            preset: room.contextPreset,
            sections: sections,
            selectedFiles: selectedFiles,
            mentionedFiles: mentionedFiles(in: room.prompt),
            attachedErrors: attachedErrors,
            attachedBrowserContext: browserContext,
            diffSummary: diffSummary,
            fullPromptPreview: fullPrompt,
            approximateCharacterCount: characterCount,
            approximateTokenCount: max(1, characterCount / 4),
            warnings: warnings(for: sections)
        )
    }

    private func sections(
        for room: AgentRoom,
        repository: Repository,
        basePrompt: String,
        selectedFiles: [String],
        browserContext: [String],
        attachedErrors: [String],
        diffSummary: String
    ) -> [ContextSection] {
        let requiredKinds: Set<ContextSectionKind> = [.userTask, .systemContract, .accessMode, .safetyRules, .expectedOutput]
        let includedByPreset: Set<ContextSectionKind> = {
            switch room.contextPreset {
            case .minimal:
                return [.userTask, .systemContract, .roomMode, .reasoning, .accessMode, .repoSummary, .safetyRules, .expectedOutput, .enforcementNotes]
            case .standard:
                return [.userTask, .systemContract, .roomMode, .reasoning, .accessMode, .repoSummary, .gitStatus, .packageFramework, .detectedCommands, .changedFiles, .existingChangesWarning, .failedCheck, .browserContext, .screenshots, .safetyRules, .expectedOutput, .compactedMemory, .contextSignals, .enforcementNotes]
            case .full:
                return Set(ContextSectionKind.allCases)
            }
        }()

        func section(_ title: String, _ kind: ContextSectionKind, _ content: String, warning: String? = nil) -> ContextSection {
            ContextSection(
                title: title,
                kind: kind,
                content: content,
                isRequired: requiredKinds.contains(kind),
                isIncluded: requiredKinds.contains(kind) || includedByPreset.contains(kind),
                warning: warning,
                approximateCharacters: content.count
            )
        }

        let checks = repository.detectedCommands.map(\.command).joined(separator: ", ")
        let lastFailed = room.failedChecks.last?.errorExcerpt ?? attachedErrors.first ?? ""
        let signals = contextSignals(for: room)
        return [
            section("System contract", .systemContract, basePrompt),
            section("User task", .userTask, room.prompt),
            section("Repo summary", .repoSummary, "\(repository.name) at \(repository.path)"),
            section("Branch and git status", .gitStatus, "\(repository.branch ?? "unknown") · \(repository.dirtyFileCount) changed"),
            section("Package manager/framework", .packageFramework, "\(repository.packageManager ?? "unknown") · \(repository.framework ?? "unknown")"),
            section("Detected commands/checks", .detectedCommands, checks.isEmpty ? "None detected" : checks),
            section("Room mode", .roomMode, room.mode.rawValue),
            section("Reasoning level", .reasoning, room.reasoningLevel.rawValue),
            section("Access mode", .accessMode, room.accessMode.rawValue),
            section("Queue metadata", .queueMetadata, "\(room.queuedPrompts.filter { $0.status == .waiting }.count) waiting prompts"),
            section("Changed files summary", .changedFiles, diffSummary),
            section("Room-owned diff summary", .roomDiff, room.changeSets.last?.roomChangedFiles.map(\.path).joined(separator: ", ") ?? diffSummary),
            section("Existing changes warning", .existingChangesWarning, room.hadPreExistingChanges ? "This repo already had changes before this room started. Review carefully." : "No pre-existing changes recorded."),
            section("Last failed check", .failedCheck, lastFailed.isEmpty ? "None" : lastFailed),
            section("Terminal error", .terminalError, attachedErrors.first ?? "None"),
            section("Browser metadata", .browserContext, browserContext.joined(separator: "\n")),
            section("Screenshot metadata", .screenshots, room.screenshots.map { "\($0.filePath ?? "not saved") · \($0.url)" }.joined(separator: "\n")),
            section("Selected files", .selectedFiles, selectedFiles.joined(separator: ", "), warning: selectedFiles.first(where: isSecretLike).map { "Secret-like file excluded by default: \($0)" }),
            section("Mentioned files", .mentionedFiles, mentionedFiles(in: room.prompt).joined(separator: ", ")),
            section("Safety rules", .safetyRules, "No destructive commands. No dependency installs, migrations, git push, sudo, or secret access without approval. SafetyPolicy remains active for Full Access."),
            section("Expected output format", .expectedOutput, "Plan, Summary, Files changed, Checks, Limitations, Next suggested action. If suggesting edits only, include Patch Proposal."),
            section("Compacted room memory", .compactedMemory, room.compactedMemory.isEmpty ? "No compacted memory yet." : room.compactedMemory),
            section("Relevant context signals", .contextSignals, signals.isEmpty ? "No extra signals yet." : signals.joined(separator: "\n")),
            section("Enforcement notes", .enforcementNotes, "Access mode is included in the prompt. Sanecode can enforce commands it runs directly, but Codex CLI internals may still depend on local Codex configuration. Room worktrees isolate repository edits when available.")
        ]
    }

    private func contextSignals(for room: AgentRoom) -> [String] {
        var signals: [String] = []
        signals.append(contentsOf: room.changedFiles.prefix(10).map { "Changed file: \($0.path)" })
        if let failed = room.failedChecks.last(where: { $0.resolvedAt == nil }) {
            signals.append("Failed check: \(failed.command)")
        }
        if let capture = room.previewCaptures.last {
            signals.append("Preview \(capture.kind.rawValue): \(capture.url) on \(capture.viewport.rawValue)")
        }
        signals.append(contentsOf: room.reviewRisks.prefix(5).map { "Review risk: \($0.title) - \($0.detail)" })
        return signals
    }

    private func warnings(for sections: [ContextSection]) -> [String] {
        sections.compactMap(\.warning)
    }

    private func mentionedFiles(in text: String) -> [String] {
        text.split(separator: " ")
            .map(String.init)
            .filter { $0.contains("/") && !$0.contains("://") }
            .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "`'\".,:;()[]{}")) }
            .filter { !isSecretLike($0) && !isNoisyPath($0) }
    }

    private func isSecretLike(_ path: String) -> Bool {
        let lower = path.lowercased()
        return lower.contains(".env") || lower.contains("secret") || lower.hasSuffix(".pem") || lower.hasSuffix(".key")
    }

    private func isNoisyPath(_ path: String) -> Bool {
        ["node_modules", ".next", "dist", "build", "DerivedData", ".git", "vendor", ".venv", "__pycache__"].contains { path.contains($0) }
    }
}
