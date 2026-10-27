import Combine
import Foundation

final class AgentRoomViewModel: ObservableObject {
    @Published var room: AgentRoom
    @Published var isRunning = false
    @Published var selectedAgent: AgentKind
    @Published var selectedMode: RoomMode
    @Published var selectedReasoningLevel: ReasoningLevel
    @Published var selectedAccessMode: AgentAccessMode
    @Published var pendingApproval: (command: String, reason: String, risk: String)?
    @Published var codexMissing = false

    private let git = GitManager()
    private let contextBuilder = TaskContextBuilder()
    private let verificationManager = VerificationManager()
    private let failedCheckExtractor = FailedCheckExtractor()
    private let repairPromptBuilder = RepairPromptBuilder()
    private let taskCoordinator = TaskRunCoordinator()
    private let cliEventAdapter = CLIEventAdapter()
    private let worktreeManager = WorktreeManager()
    private var pendingApprovalRequest: TaskRunRequest?
    private var pendingApprovalRepository: Repository?
    private var pendingApprovalSettings: SettingsStore?

    init(room: AgentRoom) {
        self.room = room
        selectedAgent = room.agent
        selectedMode = room.mode
        selectedReasoningLevel = room.reasoningLevel
        selectedAccessMode = room.accessMode
    }

    func runTask(repository: Repository, terminal: TerminalViewModel, settings: SettingsStore, onSave: @escaping (AgentRoom) -> Void) {
        let prompt = room.prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return }
        if isRunning || room.status == .running {
            addToQueue(text: prompt, onSave: onSave)
            return
        }
        startPrompt(text: prompt, agent: selectedAgent, mode: selectedMode, reasoning: selectedReasoningLevel, access: selectedAccessMode, queuedPromptID: nil, repository: repository, terminal: terminal, settings: settings, onSave: onSave)
    }

    func addToQueue(text: String? = nil, condition: QueueRunCondition = .manual, onSave: @escaping (AgentRoom) -> Void) {
        let prompt = (text ?? room.prompt).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return }
        let queued = QueuedPrompt(roomID: room.id, text: prompt, mode: selectedMode, agent: selectedAgent, reasoningLevel: selectedReasoningLevel, accessMode: selectedAccessMode, runCondition: condition)
        room.queuedPrompts.append(queued)
        append(.systemEvent, "Added prompt to queue.")
        onSave(room)
    }

    func runNext(repository: Repository, terminal: TerminalViewModel, settings: SettingsStore, onSave: @escaping (AgentRoom) -> Void) {
        guard !isRunning, room.status != .running else { return }
        guard let next = nextEligiblePrompt() else { return }
        room.isQueuePaused = false
        startPrompt(text: next.text, agent: next.agent, mode: next.mode, reasoning: next.reasoningLevel, access: next.accessMode, queuedPromptID: next.id, repository: repository, terminal: terminal, settings: settings, onSave: onSave)
    }

    func pauseQueue(onSave: @escaping (AgentRoom) -> Void) {
        room.isQueuePaused = true
        onSave(room)
    }

    func resumeQueue(onSave: @escaping (AgentRoom) -> Void) {
        room.isQueuePaused = false
        onSave(room)
    }

    func clearQueue(onSave: @escaping (AgentRoom) -> Void) {
        room.queuedPrompts.removeAll { $0.status == .waiting || $0.status == .skipped }
        onSave(room)
    }

    func removeQueuedPrompt(_ prompt: QueuedPrompt, onSave: @escaping (AgentRoom) -> Void) {
        room.queuedPrompts.removeAll { $0.id == prompt.id && $0.status != .running }
        onSave(room)
    }

    func updateQueuedPrompt(_ prompt: QueuedPrompt, text: String, onSave: @escaping (AgentRoom) -> Void) {
        guard let index = room.queuedPrompts.firstIndex(where: { $0.id == prompt.id }) else { return }
        room.queuedPrompts[index].text = text
        room.queuedPrompts[index].updatedAt = Date()
        onSave(room)
    }

    func updateQueuedPromptSettings(_ prompt: QueuedPrompt, agent: AgentKind? = nil, mode: RoomMode? = nil, reasoning: ReasoningLevel? = nil, access: AgentAccessMode? = nil, condition: QueueRunCondition? = nil, onSave: @escaping (AgentRoom) -> Void) {
        guard let index = room.queuedPrompts.firstIndex(where: { $0.id == prompt.id }) else { return }
        if let agent { room.queuedPrompts[index].agent = agent }
        if let mode { room.queuedPrompts[index].mode = mode }
        if let reasoning { room.queuedPrompts[index].reasoningLevel = reasoning }
        if let access { room.queuedPrompts[index].accessMode = access }
        if let condition { room.queuedPrompts[index].runCondition = condition }
        room.queuedPrompts[index].updatedAt = Date()
        onSave(room)
    }

    func moveQueuedPrompt(_ prompt: QueuedPrompt, direction: Int, onSave: @escaping (AgentRoom) -> Void) {
        guard let index = room.queuedPrompts.firstIndex(where: { $0.id == prompt.id }) else { return }
        let target = index + direction
        guard room.queuedPrompts.indices.contains(target) else { return }
        room.queuedPrompts.swapAt(index, target)
        onSave(room)
    }

    func fixFailedCheck(repository: Repository, terminal: TerminalViewModel, settings: SettingsStore, runImmediately: Bool, onSave: @escaping (AgentRoom) -> Void) {
        guard let failed = room.failedChecks.last(where: { $0.resolvedAt == nil }) ?? room.failedChecks.last else { return }
        guard failed.repairAttempts < 2 else {
            append(.systemEvent, "Repair paused after 2 attempts. Review the check output before trying again.")
            onSave(room)
            return
        }
        let repairText = repairPromptBuilder.build(room: room, repository: repository, failedCheck: failed)
        let repairAccess = room.accessMode == .planOnly || room.accessMode == .suggestEdits ? room.accessMode : .buildAndCheck
        let queued = QueuedPrompt(roomID: room.id, text: repairText, mode: .bugFix, agent: room.agent, reasoningLevel: maxReasoning(room.reasoningLevel, .balanced), accessMode: repairAccess, runCondition: .onlyIfChecksFail)
        room.queuedPrompts.insert(queued, at: 0)
        if let index = room.failedChecks.firstIndex(where: { $0.id == failed.id }) {
            room.failedChecks[index].repairPromptID = queued.id
            room.failedChecks[index].repairAttempts += 1
        }
        append(.systemEvent, repairAccess == .planOnly || repairAccess == .suggestEdits ? "Created repair prompt. Switch to Build & Check for this repair if you want Sanecode to edit and rerun checks." : "Created focused repair prompt for failed check.")
        onSave(room)
        if runImmediately, repairAccess != .planOnly, repairAccess != .suggestEdits {
            runNext(repository: repository, terminal: terminal, settings: settings, onSave: onSave)
        }
    }

    func contextPreview(repository: Repository) -> TaskContext {
        var current = room
        current.agent = selectedAgent
        current.mode = selectedMode
        current.reasoningLevel = selectedReasoningLevel
        current.accessMode = selectedAccessMode
        return contextBuilder.build(room: current, repository: repository)
    }

    private func startPrompt(
        text: String,
        agent: AgentKind,
        mode: RoomMode,
        reasoning: ReasoningLevel,
        access: AgentAccessMode,
        queuedPromptID: UUID?,
        repository: Repository,
        terminal: TerminalViewModel,
        settings: SettingsStore,
        onSave: @escaping (AgentRoom) -> Void
    ) {
        room.agent = agent
        room.mode = mode
        room.reasoningLevel = reasoning
        room.accessMode = access
        room.prompt = text
        room.updatedAt = Date()

        let executionRepository = taskCoordinator.prepareWorkspace(room: &room, repository: repository)
        let request = TaskRunRequest(prompt: text, agent: agent, mode: mode, reasoning: reasoning, access: access, queuedPromptID: queuedPromptID)
        switch taskCoordinator.preflight(room: &room, request: request, repository: executionRepository, settings: settings) {
        case .ready(let command):
            Task { await execute(command: command, request: request, repository: executionRepository, terminal: terminal, settings: settings, onSave: onSave) }
        case .codexMissing:
            codexMissing = true
            append(.error, "Codex CLI not found. Configure a custom command or install Codex CLI.")
            onSave(room)
        case .blocked(let reason):
            append(.error, "Command blocked. \(reason)")
            onSave(room)
        case .needsApproval(let command, let reason, let risk):
            pendingApprovalRequest = request
            pendingApprovalRepository = executionRepository
            pendingApprovalSettings = settings
            pendingApproval = (command, reason, risk)
            append(.approvalRequest, "Approval needed for \(command)")
            onSave(room)
        }
    }

    func approvePendingCommand(terminal: TerminalViewModel, onSave: @escaping (AgentRoom) -> Void) {
        guard let pendingApproval else { return }
        let request = pendingApprovalRequest ?? TaskRunRequest(prompt: room.prompt, agent: room.agent, mode: room.mode, reasoning: room.reasoningLevel, access: room.accessMode, queuedPromptID: nil)
        let repository = pendingApprovalRepository
        let settings = pendingApprovalSettings
        self.pendingApproval = nil
        pendingApprovalRequest = nil
        pendingApprovalRepository = nil
        pendingApprovalSettings = nil
        Task { await execute(command: pendingApproval.command, request: request, repository: repository, terminal: terminal, settings: settings, onSave: onSave) }
    }

    func cancelTask(terminal: TerminalViewModel, onSave: @escaping (AgentRoom) -> Void) {
        terminal.cancelCurrentCommand()
        isRunning = false
        room.status = .cancelled
        room.currentStage = .cancelled
        markRunningQueuedPrompt(status: .cancelled, result: "Task cancelled.", error: nil)
        append(.systemEvent, "Task cancelled.")
        onSave(room)
    }

    func runChecks(repository: Repository, terminal: TerminalViewModel, onSave: @escaping (AgentRoom) -> Void) {
        var checkRepository = repository
        checkRepository.path = executionPath(fallback: repository.path)
        guard let command = verificationManager.bestCheckCommand(for: checkRepository)?.command else {
            append(.systemEvent, "No checks found. Configure a check command in Settings.")
            onSave(room)
            return
        }
        Task {
            room.currentStage = .checking
            room.status = .running
            append(.commandStarted, "Run Checks: \(command)")
            onSave(room)
            let started = Date()
            let exit = await terminal.run(command, in: checkRepository.path, kind: .checks)
            let output = terminal.checksOutput
            let verification = VerificationRun(
                roomID: room.id,
                command: command,
                output: output,
                exitCode: exit,
                startedAt: started,
                endedAt: Date(),
                status: exit == 0 ? .succeeded : .failed
            )
            room.verificationRuns.append(verification)
            if exit != 0 {
                let failed = failedCheckExtractor.makeFailedCheck(roomID: room.id, queuedPromptID: nil, command: command, exitCode: exit, output: output)
                room.failedChecks.append(failed)
            } else {
                room.failedChecks = room.failedChecks.map {
                    var check = $0
                    if check.resolvedAt == nil { check.resolvedAt = Date() }
                    return check
                }
            }
            room.status = exit == 0 ? .checksPassed : .checksFailed
            room.currentStage = exit == 0 ? .done : .failed
            if var summary = room.completionSummaries.last {
                summary.checksRun = true
                summary.checksPassed = exit == 0
                summary.failedCheckID = exit == 0 ? nil : room.failedChecks.last?.id
                summary.nextSuggestedAction = exit == 0 ? "Review changes or keep them." : "Fix Failed Check"
                room.completionSummaries[room.completionSummaries.count - 1] = summary
            }
            append(exit == 0 ? .commandFinished : .error, exit == 0 ? "Checks passed." : "Checks failed.")
            onSave(room)
        }
    }

    func loadDiff(repository: Repository, onSave: @escaping (AgentRoom) -> Void) {
        room.currentStage = .reviewing
        let path = executionPath(fallback: repository.path)
        room.diff = git.diff(path: path)
        room.changedFiles = git.changesSinceSnapshot(path: path, snapshot: room.safetySnapshot)
        room.status = room.changedFiles.isEmpty ? .ready : .needsReview
        room.updatedAt = Date()
        onSave(room)
    }

    func undoChanges(repository: Repository, onSave: @escaping (AgentRoom) -> Void) {
        do {
            let path = executionPath(fallback: repository.path)
            try git.revertTrackedChanges(path: path, files: room.changedFiles)
            room.changedFiles = git.changesSinceSnapshot(path: path, snapshot: room.safetySnapshot)
            room.diff = git.diff(path: path)
            room.status = .reverted
            room.currentStage = .done
            append(.systemEvent, "Tracked changes were undone. Untracked files were left in place.")
        } catch {
            append(.error, "Could not undo changes: \(error.localizedDescription)")
        }
        onSave(room)
    }

    func askAgentToFix(onSave: @escaping (AgentRoom) -> Void) {
        room.prompt = "Fix the failing checks and keep the current intent. Latest output:\n\n\(room.verificationRuns.last?.output ?? "")"
        append(.userPrompt, room.prompt)
        onSave(room)
    }

    func appendMessage(_ text: String, kind: MessageKind = .userPrompt, onSave: @escaping (AgentRoom) -> Void) {
        append(kind, text)
        onSave(room)
    }

    func keepRoomChanges(onSave: @escaping (AgentRoom) -> Void) {
        guard let worktree = room.worktree, worktree.status == .ready else {
            room.status = .checksPassed
            room.currentStage = .done
            append(.systemEvent, "Changes kept in the current repository.")
            onSave(room)
            return
        }

        let result = worktreeManager.keepTrackedChanges(from: worktree)
        let untrackedResult = worktreeManager.keepUntrackedFiles(room.changeSets.last?.untrackedFiles ?? [], from: worktree)
        if result.success {
            room.status = .checksPassed
            room.currentStage = .done
            append(.systemEvent, "\(result.message) \(untrackedResult.message)")
        } else {
            append(.error, "Could not keep room changes: \(result.message)")
        }
        onSave(room)
    }

    func discardRoomWorktree(onSave: @escaping (AgentRoom) -> Void) {
        guard let worktree = room.worktree else { return }
        let result = worktreeManager.discardWorktree(worktree)
        if result.success {
            room.worktree = nil
            room.status = .reverted
            room.currentStage = .done
            append(.systemEvent, result.message)
        } else {
            append(.error, "Could not discard room worktree: \(result.message)")
        }
        onSave(room)
    }

    func approvePlanIntoQueue(onSave: @escaping (AgentRoom) -> Void) {
        guard let plan = room.latestPlan, !plan.steps.isEmpty else { return }
        for step in plan.steps {
            let prompt = QueuedPrompt(
                roomID: room.id,
                text: step,
                mode: room.mode,
                agent: room.agent,
                reasoningLevel: room.reasoningLevel,
                accessMode: room.accessMode,
                runCondition: .manual
            )
            room.queuedPrompts.append(prompt)
        }
        append(.systemEvent, "Approved plan and added \(plan.steps.count) steps to the queue.")
        onSave(room)
    }

    func rejectLatestPlan(onSave: @escaping (AgentRoom) -> Void) {
        room.latestPlan = nil
        append(.systemEvent, "Plan dismissed.")
        onSave(room)
    }

    func applyPatchProposal(_ proposal: PatchProposal, onSave: @escaping (AgentRoom) -> Void) {
        let result = worktreeManager.applyPatchProposal(proposal.body, to: executionPath(fallback: room.repositoryPath))
        if result.success {
            room.patchProposals.removeAll { $0.id == proposal.id }
            room.diff = git.diff(path: executionPath(fallback: room.repositoryPath))
            room.changedFiles = git.changesSinceSnapshot(path: executionPath(fallback: room.repositoryPath), snapshot: room.safetySnapshot)
            room.status = .needsReview
            room.currentStage = .reviewing
            append(.systemEvent, result.message)
        } else {
            append(.error, "Could not apply patch proposal: \(result.message)")
        }
        onSave(room)
    }

    func rejectPatchProposal(_ proposal: PatchProposal, onSave: @escaping (AgentRoom) -> Void) {
        room.patchProposals.removeAll { $0.id == proposal.id }
        append(.systemEvent, "Patch proposal dismissed.")
        onSave(room)
    }

    private func execute(command: String, request: TaskRunRequest, repository: Repository?, terminal: TerminalViewModel, settings: SettingsStore?, onSave: @escaping (AgentRoom) -> Void) async {
        isRunning = true
        let state = taskCoordinator.begin(room: &room, request: request, repository: repository)
        taskCoordinator.recordCommandStart(command, room: &room)
        onSave(room)

        let exit = await terminal.run(command, in: room.repositoryPath, kind: .agent) { [weak self] chunk in
            guard let self else { return }
            let events = cliEventAdapter.events(from: chunk, roomID: room.id)
            guard !events.isEmpty else { return }
            room.messages.append(contentsOf: events)
            room.updatedAt = Date()
            onSave(room)
        }
        taskCoordinator.finish(room: &room, request: request, command: command, exit: exit, output: terminal.agentOutput, state: state)
        isRunning = false
        onSave(room)

        if exit == 0, let repository, shouldRerunFailedCheck(after: request) {
            await rerunFailedCheckAfterRepair(request: request, repository: repository, terminal: terminal, onSave: onSave)
        }

        if exit == 0, room.autoRunQueue, !room.isQueuePaused, let repository, let settings, let next = nextEligiblePrompt() {
            // Auto-run is opt-in. It never starts on app launch; only after an explicit running task completes.
            onSave(room)
            startPrompt(text: next.text, agent: next.agent, mode: next.mode, reasoning: next.reasoningLevel, access: next.accessMode, queuedPromptID: next.id, repository: repository, terminal: terminal, settings: settings, onSave: onSave)
        } else if exit != 0 {
            room.isQueuePaused = true
            onSave(room)
        }
    }

    private func append(_ kind: MessageKind, _ text: String) {
        room.messages.append(AgentMessage(roomID: room.id, kind: kind, text: text))
        room.updatedAt = Date()
    }

    private func shouldRerunFailedCheck(after request: TaskRunRequest) -> Bool {
        guard let queuedPromptID = request.queuedPromptID else { return false }
        guard request.access == .buildAndCheck || request.access == .fullAccess else { return false }
        return room.failedChecks.contains { $0.repairPromptID == queuedPromptID && $0.resolvedAt == nil }
    }

    private func rerunFailedCheckAfterRepair(request: TaskRunRequest, repository: Repository, terminal: TerminalViewModel, onSave: @escaping (AgentRoom) -> Void) async {
        guard let queuedPromptID = request.queuedPromptID,
              let failedIndex = room.failedChecks.lastIndex(where: { $0.repairPromptID == queuedPromptID && $0.resolvedAt == nil })
        else { return }

        let failed = room.failedChecks[failedIndex]
        room.currentStage = .checking
        room.status = .running
        append(.commandStarted, "Rerun failed check: \(failed.command)")
        onSave(room)

        let started = Date()
        let exit = await terminal.run(failed.command, in: repository.path, kind: .checks)
        let output = terminal.checksOutput
        let verification = VerificationRun(
            roomID: room.id,
            command: failed.command,
            output: output,
            exitCode: exit,
            startedAt: started,
            endedAt: Date(),
            status: exit == 0 ? .succeeded : .failed
        )
        room.verificationRuns.append(verification)

        if exit == 0 {
            room.failedChecks[failedIndex].resolvedAt = Date()
            room.status = .checksPassed
            room.currentStage = .done
            updateLatestSummary(checksRun: true, checksPassed: true, failedCheckID: nil, nextAction: "Review changes or keep them.")
            append(.commandFinished, "Failed check passed after repair.")
        } else {
            let newFailure = failedCheckExtractor.makeFailedCheck(roomID: room.id, queuedPromptID: request.queuedPromptID, command: failed.command, exitCode: exit, output: output)
            room.failedChecks.append(newFailure)
            room.status = .checksFailed
            room.currentStage = .failed
            updateLatestSummary(checksRun: true, checksPassed: false, failedCheckID: newFailure.id, nextAction: "Fix Failed Check")
            append(.error, "Check still fails after repair.")
        }

        onSave(room)
    }

    private func updateLatestSummary(checksRun: Bool, checksPassed: Bool, failedCheckID: UUID?, nextAction: String) {
        guard !room.completionSummaries.isEmpty else { return }
        room.completionSummaries[0].checksRun = checksRun
        room.completionSummaries[0].checksPassed = checksPassed
        room.completionSummaries[0].failedCheckID = failedCheckID
        room.completionSummaries[0].nextSuggestedAction = nextAction
        room.completionSummaries[0].limitations = checksRun ? (checksPassed ? "Checks passed." : "Checks failed.") : "Checks not run."
    }

    private func executionPath(fallback: String) -> String {
        if let worktree = room.worktree, worktree.status == .ready {
            return worktree.worktreePath
        }
        return fallback
    }

    private func nextEligiblePrompt() -> QueuedPrompt? {
        room.queuedPrompts.first { prompt in
            guard prompt.status == .waiting else { return false }
            switch prompt.runCondition {
            case .manual:
                return true
            case .afterPreviousCompletes:
                return room.completionSummaries.first?.exitCode == 0
            case .onlyIfChecksPass:
                return room.verificationRuns.last?.status == .succeeded
            case .onlyIfChecksFail:
                return room.verificationRuns.last?.status == .failed || room.failedChecks.contains(where: { $0.resolvedAt == nil })
            case .onlyIfPreviousTaskFails:
                guard let exitCode = room.completionSummaries.first?.exitCode else { return false }
                return exitCode != 0
            }
        }
    }

    private func maxReasoning(_ lhs: ReasoningLevel, _ rhs: ReasoningLevel) -> ReasoningLevel {
        func rank(_ level: ReasoningLevel) -> Int {
            switch level {
            case .fast: 0
            case .balanced: 1
            case .deep: 2
            }
        }
        return rank(lhs) >= rank(rhs) ? lhs : rhs
    }

    private func markRunningQueuedPrompt(status: QueuedPromptStatus, result: String?, error: String?) {
        guard let index = room.queuedPrompts.firstIndex(where: { $0.status == .running }) else { return }
        room.queuedPrompts[index].status = status
        room.queuedPrompts[index].completedAt = Date()
        room.queuedPrompts[index].updatedAt = Date()
        room.queuedPrompts[index].resultSummary = result
        room.queuedPrompts[index].errorSummary = error
    }
}
