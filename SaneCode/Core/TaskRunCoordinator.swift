import Foundation

struct TaskRunRequest {
    var prompt: String
    var agent: AgentKind
    var mode: RoomMode
    var reasoning: ReasoningLevel
    var access: AgentAccessMode
    var queuedPromptID: UUID?
}

enum TaskRunPreflightResult {
    case ready(command: String)
    case codexMissing
    case blocked(reason: String)
    case needsApproval(command: String, reason: String, risk: String)
}

enum TaskRunPhase: String {
    case preparingContext = "Preparing Context"
    case baselineCaptured = "Baseline Captured"
    case agentRunning = "Agent Running"
    case diffLoaded = "Diff Loaded"
    case reviewReady = "Review Ready"
    case failed = "Failed"
}

struct TaskRunExecutionState {
    var phase: TaskRunPhase
    var baseline: GitBaseline
    var startedAt: Date
}

@MainActor
final class TaskRunCoordinator {
    private let git: GitManager
    private let commandBuilder: AgentCommandBuilder
    private let contextBuilder: TaskContextBuilder
    private let outputParser: AgentOutputParser
    private let worktreeManager: WorktreeManager
    private let riskAnalyzer: ReviewRiskAnalyzer
    private let memoryCompactor: RoomMemoryCompactor

    init() {
        git = GitManager()
        commandBuilder = AgentCommandBuilder()
        contextBuilder = TaskContextBuilder()
        outputParser = AgentOutputParser()
        worktreeManager = WorktreeManager()
        riskAnalyzer = ReviewRiskAnalyzer()
        memoryCompactor = RoomMemoryCompactor()
    }

    func prepareWorkspace(room: inout AgentRoom, repository: Repository) -> Repository {
        guard repository.isGitRepo else { return repository }
        let worktree = worktreeManager.prepareWorktree(for: room, repository: repository)
        room.worktree = worktree
        var executionRepository = repository

        switch worktree.status {
        case .ready:
            room.repositoryPath = worktree.worktreePath
            executionRepository.path = worktree.worktreePath
            executionRepository.name = "\(repository.name) Room"
            append(.systemEvent, "Room is isolated in a git worktree at \(worktree.worktreePath).", to: &room)
        case .failed:
            room.repositoryPath = repository.path
            append(.systemEvent, "Could not create room worktree. Sanecode will use the original repository path. \(worktree.errorMessage ?? "")", to: &room)
        case .notCreated:
            break
        }

        return executionRepository
    }

    func preflight(room: inout AgentRoom, request: TaskRunRequest, repository: Repository, settings: SettingsStore) -> TaskRunPreflightResult {
        guard !request.prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .blocked(reason: "No task prompt was provided.")
        }

        let config: AgentConfiguration
        if request.agent == .codex {
            guard commandBuilder.codexAvailable() else {
                return .codexMissing
            }
            config = settings.agentConfigurations.first(where: { $0.kind == .codex }) ?? .codexDefault
        } else {
            config = settings.agentConfigurations.first(where: { $0.kind == .custom })
                ?? AgentConfiguration(name: "Custom Command", kind: .custom, executable: "echo", arguments: "{prompt}")
        }

        var contextRoom = room
        contextRoom.prompt = request.prompt
        contextRoom.agent = request.agent
        contextRoom.mode = request.mode
        contextRoom.reasoningLevel = request.reasoning
        contextRoom.accessMode = request.access

        let context = contextBuilder.build(room: contextRoom, repository: repository)
        room.latestContextPreview = context

        let build = commandBuilder.command(prompt: context.fullPromptPreview, configuration: config, accessMode: request.access, workingDirectory: repository.path)
        let command = build.command
        room.latestRuntimeContract = build.runtimeContract
        append(.systemEvent, "Runtime contract prepared: \(build.runtimeContract.eventStream), sandbox \(build.runtimeContract.sandboxMode), approval \(build.runtimeContract.approvalPolicy).", to: &room)
        switch SafetyPolicy(level: settings.settings.safetyLevel).classify(command: command) {
        case .blocked(let reason):
            return .blocked(reason: reason)
        case .requiresApproval(let reason, let risk):
            return .needsApproval(command: command, reason: reason, risk: risk)
        case .allowed:
            return .ready(command: command)
        }
    }

    func begin(room: inout AgentRoom, request: TaskRunRequest, repository: Repository?) -> TaskRunExecutionState {
        room.status = .running
        room.currentStage = .inspecting
        append(.systemEvent, "Preparing task context.", to: &room)

        markQueuedPromptRunning(request.queuedPromptID, in: &room)

        let baseline = git.baseline(
            path: room.repositoryPath,
            roomID: room.id,
            queuedPromptID: request.queuedPromptID,
            branch: repository?.branch
        )
        room.gitBaselines.append(baseline)

        let snapshot = git.safetySnapshot(path: room.repositoryPath, roomID: room.id)
        room.safetySnapshot = snapshot
        room.hadPreExistingChanges = snapshot.hadChanges

        room.currentStage = .planning
        append(.systemEvent, "Baseline captured before running the agent.", to: &room)
        if snapshot.hadChanges {
            append(.systemEvent, "This repo already had changes before this room started. Some changes may not belong to this room.", to: &room)
        }

        append(.systemEvent, "Task context created for \(request.agent.rawValue).", to: &room)
        append(.agentMessage, "Using \(request.agent.rawValue) in \(request.mode.rawValue) mode with \(request.reasoning.rawValue) reasoning and \(request.access.rawValue) access.", to: &room)
        room.currentStage = .executing

        return TaskRunExecutionState(phase: .agentRunning, baseline: baseline, startedAt: Date())
    }

    func recordCommandStart(_ command: String, room: inout AgentRoom) {
        append(.commandStarted, command, to: &room)
    }

    func finish(room: inout AgentRoom, request: TaskRunRequest, command: String, exit: Int32, output: String, state: TaskRunExecutionState) {
        room.commandRuns.append(CommandRun(
            roomID: room.id,
            command: command,
            workingDirectory: room.repositoryPath,
            output: output,
            exitCode: exit,
            startedAt: state.startedAt,
            endedAt: Date(),
            status: exit == 0 ? .succeeded : .failed,
            kind: .agent
        ))

        room.diff = git.diff(path: room.repositoryPath)
        let changeSet = git.changeSet(
            path: room.repositoryPath,
            roomID: room.id,
            queuedPromptID: request.queuedPromptID,
            baseline: state.baseline
        )
        room.changeSets.append(changeSet)
        room.changedFiles = changeSet.roomChangedFiles
        room.reviewRisks = riskAnalyzer.analyze(room: room)
        room.currentStage = exit == 0 ? .reviewing : .failed
        room.status = exit == 0 ? .needsReview : .checksFailed

        let checksRun = !room.verificationRuns.isEmpty
        let checksPassed = room.verificationRuns.last?.status == .succeeded
        let parsedOutput = outputParser.parse(output)
        let summary = TaskCompletionSummary(
            prompt: request.prompt,
            agent: request.agent,
            mode: request.mode,
            reasoningLevel: request.reasoning,
            accessMode: request.access,
            exitCode: exit,
            changedFilesCount: room.changedFiles.count,
            roomOwnedChangesCount: changeSet.roomChangedFiles.count,
            checksRun: checksRun,
            checksPassed: checksPassed,
            summary: parsedOutput.summary ?? summaryText(exit: exit, changeCount: changeSet.roomChangedFiles.count),
            limitations: parsedOutput.limitations ?? (checksRun ? "Checks were run." : "Checks not run."),
            nextSuggestedAction: parsedOutput.nextSuggestedAction ?? nextAction(exit: exit, changedFiles: changeSet.roomChangedFiles)
        )
        room.completionSummaries.insert(summary, at: 0)
        if !parsedOutput.planSteps.isEmpty {
            room.latestPlan = AgentPlan(roomID: room.id, queuedPromptID: request.queuedPromptID, steps: parsedOutput.planSteps)
        }
        if let patchProposal = parsedOutput.patchProposal {
            room.patchProposals.insert(PatchProposal(roomID: room.id, queuedPromptID: request.queuedPromptID, title: "Suggested Patch", body: patchProposal), at: 0)
        }
        room.compactedMemory = memoryCompactor.compact(room: room)
        updateQueuedPromptCompletion(request.queuedPromptID, exit: exit, summary: summary.summary, in: &room)
        if parsedOutput.hasStructuredOutput {
            append(.systemEvent, "Parsed structured agent summary from Codex output.", to: &room)
        }
        append(exit == 0 ? .commandFinished : .error, exit == 0 ? "Agent finished. Review changes before keeping them. Checks not run." : "Agent command failed.", to: &room)
    }

    private func summaryText(exit: Int32, changeCount: Int) -> String {
        exit == 0 ? "Agent completed. \(changeCount) files changed from this room." : "Agent command failed with exit code \(exit)."
    }

    private func nextAction(exit: Int32, changedFiles: [FileChange]) -> String {
        if exit != 0 { return "Ask Agent to Fix" }
        return changedFiles.isEmpty ? "Review the work log." : "Review Changes"
    }

    private func append(_ kind: MessageKind, _ text: String, to room: inout AgentRoom) {
        room.messages.append(AgentMessage(roomID: room.id, kind: kind, text: text))
        room.updatedAt = Date()
    }

    private func markQueuedPromptRunning(_ id: UUID?, in room: inout AgentRoom) {
        guard let id, let index = room.queuedPrompts.firstIndex(where: { $0.id == id }) else { return }
        room.queuedPrompts[index].status = .running
        room.queuedPrompts[index].startedAt = Date()
        room.queuedPrompts[index].updatedAt = Date()
    }

    private func updateQueuedPromptCompletion(_ id: UUID?, exit: Int32, summary: String, in room: inout AgentRoom) {
        guard let id, let index = room.queuedPrompts.firstIndex(where: { $0.id == id }) else { return }
        room.queuedPrompts[index].status = exit == 0 ? .completed : .failed
        room.queuedPrompts[index].completedAt = Date()
        room.queuedPrompts[index].updatedAt = Date()
        room.queuedPrompts[index].resultSummary = exit == 0 ? summary : nil
        room.queuedPrompts[index].errorSummary = exit == 0 ? nil : summary
    }
}
