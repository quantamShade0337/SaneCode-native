import Foundation

struct AgentRoom: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var repositoryID: UUID
    var repositoryPath: String
    var prompt: String
    var agent: AgentKind = .codex
    var mode: RoomMode = .auto
    var reasoningLevel: ReasoningLevel = .balanced
    var accessMode: AgentAccessMode = .acceptEdits
    var status: RoomStatus = .ready
    var currentStage: TaskStage = .idle
    var messages: [AgentMessage] = []
    var commandRuns: [CommandRun] = []
    var verificationRuns: [VerificationRun] = []
    var changedFiles: [FileChange] = []
    var diff: String = ""
    var safetySnapshot: GitSafetySnapshot?
    var hadPreExistingChanges: Bool = false
    var screenshots: [ScreenshotCapture] = []
    var queuedPrompts: [QueuedPrompt] = []
    var isQueuePaused: Bool = false
    var autoRunQueue: Bool = false
    var completionSummaries: [TaskCompletionSummary] = []
    var latestContextPreview: TaskContext?
    var gitBaselines: [GitBaseline] = []
    var changeSets: [RoomChangeSet] = []
    var failedChecks: [FailedCheck] = []
    var previewCaptures: [PreviewCapture] = []
    var contextPreset: ContextPreset = .standard
    var worktree: RoomWorktree?
    var compactedMemory: String = ""
    var latestPlan: AgentPlan?
    var patchProposals: [PatchProposal] = []
    var reviewRisks: [ReviewRisk] = []
    var latestRuntimeContract: AgentRuntimeContract?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(
        id: UUID = UUID(),
        title: String,
        repositoryID: UUID,
        repositoryPath: String,
        prompt: String,
        agent: AgentKind = .codex,
        mode: RoomMode = .auto,
        reasoningLevel: ReasoningLevel = .balanced,
        accessMode: AgentAccessMode = .acceptEdits
    ) {
        self.id = id
        self.title = title
        self.repositoryID = repositoryID
        self.repositoryPath = repositoryPath
        self.prompt = prompt
        self.agent = agent
        self.mode = mode
        self.reasoningLevel = reasoningLevel
        self.accessMode = accessMode
    }

    enum CodingKeys: String, CodingKey {
        case id, title, repositoryID, repositoryPath, prompt, agent, mode, reasoningLevel, accessMode, status, currentStage, messages, commandRuns, verificationRuns, changedFiles, diff, safetySnapshot, hadPreExistingChanges, screenshots, queuedPrompts, isQueuePaused, autoRunQueue, completionSummaries, latestContextPreview, gitBaselines, changeSets, failedChecks, previewCaptures, contextPreset, worktree, compactedMemory, latestPlan, patchProposals, reviewRisks, latestRuntimeContract, createdAt, updatedAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try c.decodeIfPresent(String.self, forKey: .title) ?? "Room"
        repositoryID = try c.decodeIfPresent(UUID.self, forKey: .repositoryID) ?? UUID()
        repositoryPath = try c.decodeIfPresent(String.self, forKey: .repositoryPath) ?? ""
        prompt = try c.decodeIfPresent(String.self, forKey: .prompt) ?? ""
        agent = try c.decodeIfPresent(AgentKind.self, forKey: .agent) ?? .codex
        mode = try c.decodeIfPresent(RoomMode.self, forKey: .mode) ?? .auto
        reasoningLevel = try c.decodeIfPresent(ReasoningLevel.self, forKey: .reasoningLevel) ?? .balanced
        accessMode = try c.decodeIfPresent(AgentAccessMode.self, forKey: .accessMode) ?? .acceptEdits
        status = try c.decodeIfPresent(RoomStatus.self, forKey: .status) ?? .ready
        currentStage = try c.decodeIfPresent(TaskStage.self, forKey: .currentStage) ?? .idle
        messages = try c.decodeIfPresent([AgentMessage].self, forKey: .messages) ?? []
        commandRuns = try c.decodeIfPresent([CommandRun].self, forKey: .commandRuns) ?? []
        verificationRuns = try c.decodeIfPresent([VerificationRun].self, forKey: .verificationRuns) ?? []
        changedFiles = try c.decodeIfPresent([FileChange].self, forKey: .changedFiles) ?? []
        diff = try c.decodeIfPresent(String.self, forKey: .diff) ?? ""
        safetySnapshot = try c.decodeIfPresent(GitSafetySnapshot.self, forKey: .safetySnapshot)
        hadPreExistingChanges = try c.decodeIfPresent(Bool.self, forKey: .hadPreExistingChanges) ?? false
        screenshots = try c.decodeIfPresent([ScreenshotCapture].self, forKey: .screenshots) ?? []
        queuedPrompts = try c.decodeIfPresent([QueuedPrompt].self, forKey: .queuedPrompts) ?? []
        isQueuePaused = try c.decodeIfPresent(Bool.self, forKey: .isQueuePaused) ?? false
        autoRunQueue = try c.decodeIfPresent(Bool.self, forKey: .autoRunQueue) ?? false
        completionSummaries = try c.decodeIfPresent([TaskCompletionSummary].self, forKey: .completionSummaries) ?? []
        latestContextPreview = try c.decodeIfPresent(TaskContext.self, forKey: .latestContextPreview)
        gitBaselines = try c.decodeIfPresent([GitBaseline].self, forKey: .gitBaselines) ?? []
        changeSets = try c.decodeIfPresent([RoomChangeSet].self, forKey: .changeSets) ?? []
        failedChecks = try c.decodeIfPresent([FailedCheck].self, forKey: .failedChecks) ?? []
        previewCaptures = try c.decodeIfPresent([PreviewCapture].self, forKey: .previewCaptures) ?? []
        contextPreset = try c.decodeIfPresent(ContextPreset.self, forKey: .contextPreset) ?? .standard
        worktree = try c.decodeIfPresent(RoomWorktree.self, forKey: .worktree)
        compactedMemory = try c.decodeIfPresent(String.self, forKey: .compactedMemory) ?? ""
        latestPlan = try c.decodeIfPresent(AgentPlan.self, forKey: .latestPlan)
        patchProposals = try c.decodeIfPresent([PatchProposal].self, forKey: .patchProposals) ?? []
        reviewRisks = try c.decodeIfPresent([ReviewRisk].self, forKey: .reviewRisks) ?? []
        latestRuntimeContract = try c.decodeIfPresent(AgentRuntimeContract.self, forKey: .latestRuntimeContract)
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try c.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }
}

struct QueuedPrompt: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var roomID: UUID
    var text: String
    var mode: RoomMode
    var agent: AgentKind
    var reasoningLevel: ReasoningLevel = .balanced
    var accessMode: AgentAccessMode = .acceptEdits
    var runCondition: QueueRunCondition = .manual
    var status: QueuedPromptStatus = .waiting
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var startedAt: Date?
    var completedAt: Date?
    var resultSummary: String?
    var errorSummary: String?

    init(id: UUID = UUID(), roomID: UUID, text: String, mode: RoomMode, agent: AgentKind, reasoningLevel: ReasoningLevel = .balanced, accessMode: AgentAccessMode = .acceptEdits, runCondition: QueueRunCondition = .manual, status: QueuedPromptStatus = .waiting) {
        self.id = id
        self.roomID = roomID
        self.text = text
        self.mode = mode
        self.agent = agent
        self.reasoningLevel = reasoningLevel
        self.accessMode = accessMode
        self.runCondition = runCondition
        self.status = status
    }

    enum CodingKeys: String, CodingKey {
        case id, roomID, text, mode, agent, reasoningLevel, accessMode, runCondition, status, createdAt, updatedAt, startedAt, completedAt, resultSummary, errorSummary
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        roomID = try c.decodeIfPresent(UUID.self, forKey: .roomID) ?? UUID()
        text = try c.decodeIfPresent(String.self, forKey: .text) ?? ""
        mode = try c.decodeIfPresent(RoomMode.self, forKey: .mode) ?? .auto
        agent = try c.decodeIfPresent(AgentKind.self, forKey: .agent) ?? .codex
        reasoningLevel = try c.decodeIfPresent(ReasoningLevel.self, forKey: .reasoningLevel) ?? .balanced
        accessMode = try c.decodeIfPresent(AgentAccessMode.self, forKey: .accessMode) ?? .acceptEdits
        runCondition = try c.decodeIfPresent(QueueRunCondition.self, forKey: .runCondition) ?? .manual
        status = try c.decodeIfPresent(QueuedPromptStatus.self, forKey: .status) ?? .waiting
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try c.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
        startedAt = try c.decodeIfPresent(Date.self, forKey: .startedAt)
        completedAt = try c.decodeIfPresent(Date.self, forKey: .completedAt)
        resultSummary = try c.decodeIfPresent(String.self, forKey: .resultSummary)
        errorSummary = try c.decodeIfPresent(String.self, forKey: .errorSummary)
    }
}

struct TaskCompletionSummary: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var prompt: String
    var agent: AgentKind
    var mode: RoomMode
    var reasoningLevel: ReasoningLevel = .balanced
    var accessMode: AgentAccessMode = .acceptEdits
    var exitCode: Int32?
    var changedFilesCount: Int
    var roomOwnedChangesCount: Int = 0
    var checksRun: Bool
    var checksPassed: Bool
    var failedCheckID: UUID?
    var summary: String
    var limitations: String
    var nextSuggestedAction: String
    var createdAt: Date = Date()

    init(
        id: UUID = UUID(),
        prompt: String,
        agent: AgentKind,
        mode: RoomMode,
        reasoningLevel: ReasoningLevel = .balanced,
        accessMode: AgentAccessMode = .acceptEdits,
        exitCode: Int32?,
        changedFilesCount: Int,
        roomOwnedChangesCount: Int = 0,
        checksRun: Bool,
        checksPassed: Bool,
        failedCheckID: UUID? = nil,
        summary: String,
        limitations: String,
        nextSuggestedAction: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.prompt = prompt
        self.agent = agent
        self.mode = mode
        self.reasoningLevel = reasoningLevel
        self.accessMode = accessMode
        self.exitCode = exitCode
        self.changedFilesCount = changedFilesCount
        self.roomOwnedChangesCount = roomOwnedChangesCount
        self.checksRun = checksRun
        self.checksPassed = checksPassed
        self.failedCheckID = failedCheckID
        self.summary = summary
        self.limitations = limitations
        self.nextSuggestedAction = nextSuggestedAction
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id, prompt, agent, mode, reasoningLevel, accessMode, exitCode, changedFilesCount, roomOwnedChangesCount, checksRun, checksPassed, failedCheckID, summary, limitations, nextSuggestedAction, createdAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        prompt = try c.decodeIfPresent(String.self, forKey: .prompt) ?? ""
        agent = try c.decodeIfPresent(AgentKind.self, forKey: .agent) ?? .codex
        mode = try c.decodeIfPresent(RoomMode.self, forKey: .mode) ?? .auto
        reasoningLevel = try c.decodeIfPresent(ReasoningLevel.self, forKey: .reasoningLevel) ?? .balanced
        accessMode = try c.decodeIfPresent(AgentAccessMode.self, forKey: .accessMode) ?? .acceptEdits
        exitCode = try c.decodeIfPresent(Int32.self, forKey: .exitCode)
        changedFilesCount = try c.decodeIfPresent(Int.self, forKey: .changedFilesCount) ?? 0
        roomOwnedChangesCount = try c.decodeIfPresent(Int.self, forKey: .roomOwnedChangesCount) ?? changedFilesCount
        checksRun = try c.decodeIfPresent(Bool.self, forKey: .checksRun) ?? false
        checksPassed = try c.decodeIfPresent(Bool.self, forKey: .checksPassed) ?? false
        failedCheckID = try c.decodeIfPresent(UUID.self, forKey: .failedCheckID)
        summary = try c.decodeIfPresent(String.self, forKey: .summary) ?? ""
        limitations = try c.decodeIfPresent(String.self, forKey: .limitations) ?? ""
        nextSuggestedAction = try c.decodeIfPresent(String.self, forKey: .nextSuggestedAction) ?? "Review Changes"
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }
}

struct TaskContext: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var roomID: UUID
    var generatedAt: Date = Date()
    var repositorySummary: String
    var preset: ContextPreset = .standard
    var sections: [ContextSection] = []
    var selectedFiles: [String] = []
    var mentionedFiles: [String] = []
    var attachedErrors: [String] = []
    var attachedBrowserContext: [String] = []
    var diffSummary: String
    var fullPromptPreview: String
    var approximateCharacterCount: Int
    var approximateTokenCount: Int?
    var warnings: [String] = []

    init(
        id: UUID = UUID(),
        roomID: UUID,
        generatedAt: Date = Date(),
        repositorySummary: String,
        preset: ContextPreset = .standard,
        sections: [ContextSection] = [],
        selectedFiles: [String] = [],
        mentionedFiles: [String] = [],
        attachedErrors: [String] = [],
        attachedBrowserContext: [String] = [],
        diffSummary: String,
        fullPromptPreview: String,
        approximateCharacterCount: Int,
        approximateTokenCount: Int? = nil,
        warnings: [String] = []
    ) {
        self.id = id
        self.roomID = roomID
        self.generatedAt = generatedAt
        self.repositorySummary = repositorySummary
        self.preset = preset
        self.sections = sections
        self.selectedFiles = selectedFiles
        self.mentionedFiles = mentionedFiles
        self.attachedErrors = attachedErrors
        self.attachedBrowserContext = attachedBrowserContext
        self.diffSummary = diffSummary
        self.fullPromptPreview = fullPromptPreview
        self.approximateCharacterCount = approximateCharacterCount
        self.approximateTokenCount = approximateTokenCount
        self.warnings = warnings
    }

    enum CodingKeys: String, CodingKey {
        case id, roomID, generatedAt, repositorySummary, preset, sections, selectedFiles, mentionedFiles, attachedErrors, attachedBrowserContext, diffSummary, fullPromptPreview, approximateCharacterCount, approximateTokenCount, warnings
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        roomID = try c.decodeIfPresent(UUID.self, forKey: .roomID) ?? UUID()
        generatedAt = try c.decodeIfPresent(Date.self, forKey: .generatedAt) ?? Date()
        repositorySummary = try c.decodeIfPresent(String.self, forKey: .repositorySummary) ?? ""
        preset = try c.decodeIfPresent(ContextPreset.self, forKey: .preset) ?? .standard
        sections = try c.decodeIfPresent([ContextSection].self, forKey: .sections) ?? []
        selectedFiles = try c.decodeIfPresent([String].self, forKey: .selectedFiles) ?? []
        mentionedFiles = try c.decodeIfPresent([String].self, forKey: .mentionedFiles) ?? []
        attachedErrors = try c.decodeIfPresent([String].self, forKey: .attachedErrors) ?? []
        attachedBrowserContext = try c.decodeIfPresent([String].self, forKey: .attachedBrowserContext) ?? []
        diffSummary = try c.decodeIfPresent(String.self, forKey: .diffSummary) ?? ""
        fullPromptPreview = try c.decodeIfPresent(String.self, forKey: .fullPromptPreview) ?? ""
        approximateCharacterCount = try c.decodeIfPresent(Int.self, forKey: .approximateCharacterCount) ?? fullPromptPreview.count
        approximateTokenCount = try c.decodeIfPresent(Int.self, forKey: .approximateTokenCount) ?? max(1, approximateCharacterCount / 4)
        warnings = try c.decodeIfPresent([String].self, forKey: .warnings) ?? []
    }
}

struct ContextSection: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var kind: ContextSectionKind
    var content: String
    var isRequired: Bool
    var isIncluded: Bool
    var warning: String?
    var approximateCharacters: Int
}

struct GitBaseline: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var roomID: UUID
    var queuedPromptID: UUID?
    var createdAt: Date = Date()
    var branch: String?
    var statusPorcelain: String
    var diff: String
    var trackedChangedFiles: [FileChange]
    var untrackedFiles: [FileChange]
    var wasDirty: Bool
}

struct RoomChangeSet: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var roomID: UUID
    var queuedPromptID: UUID?
    var createdAt: Date = Date()
    var baselineID: UUID
    var roomChangedFiles: [FileChange]
    var existingChangedFiles: [FileChange]
    var untrackedFiles: [FileChange]
    var attributionConfidence: ChangeAttributionConfidence
    var warningMessage: String?
}

struct FailedCheck: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var roomID: UUID
    var queuedPromptID: UUID?
    var command: String
    var exitCode: Int32
    var fullOutput: String
    var errorExcerpt: String
    var createdAt: Date = Date()
    var resolvedAt: Date?
    var repairPromptID: UUID?
    var repairAttempts: Int = 0

    init(
        id: UUID = UUID(),
        roomID: UUID,
        queuedPromptID: UUID? = nil,
        command: String,
        exitCode: Int32,
        fullOutput: String,
        errorExcerpt: String,
        createdAt: Date = Date(),
        resolvedAt: Date? = nil,
        repairPromptID: UUID? = nil,
        repairAttempts: Int = 0
    ) {
        self.id = id
        self.roomID = roomID
        self.queuedPromptID = queuedPromptID
        self.command = command
        self.exitCode = exitCode
        self.fullOutput = fullOutput
        self.errorExcerpt = errorExcerpt
        self.createdAt = createdAt
        self.resolvedAt = resolvedAt
        self.repairPromptID = repairPromptID
        self.repairAttempts = repairAttempts
    }

    enum CodingKeys: String, CodingKey {
        case id, roomID, queuedPromptID, command, exitCode, fullOutput, errorExcerpt, createdAt, resolvedAt, repairPromptID, repairAttempts
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        roomID = try c.decodeIfPresent(UUID.self, forKey: .roomID) ?? UUID()
        queuedPromptID = try c.decodeIfPresent(UUID.self, forKey: .queuedPromptID)
        command = try c.decodeIfPresent(String.self, forKey: .command) ?? ""
        exitCode = try c.decodeIfPresent(Int32.self, forKey: .exitCode) ?? 1
        fullOutput = try c.decodeIfPresent(String.self, forKey: .fullOutput) ?? ""
        errorExcerpt = try c.decodeIfPresent(String.self, forKey: .errorExcerpt) ?? ""
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        resolvedAt = try c.decodeIfPresent(Date.self, forKey: .resolvedAt)
        repairPromptID = try c.decodeIfPresent(UUID.self, forKey: .repairPromptID)
        repairAttempts = try c.decodeIfPresent(Int.self, forKey: .repairAttempts) ?? 0
    }
}

struct PreviewCapture: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var roomID: UUID
    var kind: PreviewCaptureKind
    var url: String
    var viewport: PreviewDevice
    var screenshotPath: String?
    var createdAt: Date = Date()
}

struct GitSafetySnapshot: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var roomID: UUID
    var status: [FileChange]
    var diff: String
    var createdAt: Date = Date()

    var hadChanges: Bool {
        !status.isEmpty || !diff.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct RoomWorktree: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var roomID: UUID
    var originalPath: String
    var worktreePath: String
    var branch: String?
    var status: WorktreeStatus
    var createdAt: Date = Date()
    var errorMessage: String?
}

struct AgentPlan: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var roomID: UUID
    var queuedPromptID: UUID?
    var steps: [String]
    var createdAt: Date = Date()
}

struct PatchProposal: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var roomID: UUID
    var queuedPromptID: UUID?
    var title: String
    var body: String
    var createdAt: Date = Date()
}

struct ReviewRisk: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var detail: String
    var severity: ReviewRiskSeverity
}

struct AgentRuntimeContract: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var agent: AgentKind
    var commandPreview: String
    var workingDirectory: String
    var eventStream: String
    var sandboxMode: String
    var approvalPolicy: String
    var accessMode: AgentAccessMode
    var enforcementNotes: [String]
    var createdAt: Date = Date()
}
