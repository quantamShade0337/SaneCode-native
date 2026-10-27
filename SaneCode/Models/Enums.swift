import Foundation

enum MainTab: String, CaseIterable, Codable, Identifiable {
    case work = "Work"
    case code = "Code"
    case changes = "Changes"
    case preview = "Preview"
    case terminal = "Terminal"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .work: "sparkles"
        case .code: "chevron.left.forwardslash.chevron.right"
        case .changes: "arrow.left.arrow.right"
        case .preview: "eye"
        case .terminal: "terminal"
        }
    }
}

enum RoomStatus: String, CaseIterable, Codable {
    case ready
    case planning
    case running
    case needsReview
    case checksPassed
    case checksFailed
    case cancelled
    case reverted

    var label: String {
        switch self {
        case .ready: "Ready"
        case .planning: "Planning"
        case .running: "Running"
        case .needsReview: "Needs Review"
        case .checksPassed: "Checks Passed"
        case .checksFailed: "Checks Failed"
        case .cancelled: "Cancelled"
        case .reverted: "Reverted"
        }
    }
}

enum TaskStage: String, CaseIterable, Codable {
    case idle
    case inspecting
    case planning
    case executing
    case checking
    case reviewing
    case done
    case failed
    case cancelled

    var label: String {
        switch self {
        case .idle: "Ready"
        case .inspecting: "Inspecting"
        case .planning: "Planning"
        case .executing: "Working"
        case .checking: "Running Checks"
        case .reviewing: "Reviewing"
        case .done: "Done"
        case .failed: "Failed"
        case .cancelled: "Cancelled"
        }
    }
}

enum AgentKind: String, CaseIterable, Codable, Identifiable {
    case codex = "Codex"
    case custom = "Custom Command"

    var id: String { rawValue }
}

enum RoomMode: String, CaseIterable, Codable, Identifiable {
    case auto = "Auto"
    case bugFix = "Bug Fix"
    case feature = "Feature"
    case uiChange = "UI Change"
    case refactor = "Refactor"
    case explain = "Explain"
    case test = "Test"
    case reviewOnly = "Review Only"

    var id: String { rawValue }
}

enum QueuedPromptStatus: String, CaseIterable, Codable {
    case waiting
    case running
    case completed
    case failed
    case cancelled
    case skipped

    var label: String {
        switch self {
        case .waiting: "Waiting"
        case .running: "Running"
        case .completed: "Completed"
        case .failed: "Failed"
        case .cancelled: "Cancelled"
        case .skipped: "Skipped"
        }
    }
}

enum QueueRunCondition: String, CaseIterable, Codable, Identifiable {
    case manual = "Manual"
    case afterPreviousCompletes = "After Previous Completes"
    case onlyIfChecksPass = "Only If Checks Pass"
    case onlyIfChecksFail = "Only If Checks Fail"
    case onlyIfPreviousTaskFails = "Only If Previous Task Fails"

    var id: String { rawValue }
}

enum ContextPreset: String, CaseIterable, Codable, Identifiable {
    case minimal = "Minimal"
    case standard = "Standard"
    case full = "Full"

    var id: String { rawValue }
}

enum ContextSectionKind: String, CaseIterable, Codable {
    case userTask
    case systemContract
    case repoSummary
    case gitStatus
    case packageFramework
    case detectedCommands
    case roomMode
    case reasoning
    case accessMode
    case queueMetadata
    case changedFiles
    case roomDiff
    case existingChangesWarning
    case failedCheck
    case terminalError
    case browserContext
    case screenshots
    case selectedFiles
    case mentionedFiles
    case safetyRules
    case expectedOutput
    case compactedMemory
    case contextSignals
    case enforcementNotes
}

enum WorktreeStatus: String, CaseIterable, Codable {
    case notCreated = "Not Created"
    case ready = "Ready"
    case failed = "Failed"
}

enum ReviewRiskSeverity: String, CaseIterable, Codable {
    case info = "Info"
    case warning = "Warning"
    case high = "High"
}

enum ChangeAttributionConfidence: String, CaseIterable, Codable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"
}

enum PreviewCaptureKind: String, CaseIterable, Codable, Identifiable {
    case before = "Before"
    case after = "After"
    case general = "General"

    var id: String { rawValue }
}

enum ReasoningLevel: String, CaseIterable, Codable, Identifiable {
    case fast = "Fast"
    case balanced = "Balanced"
    case deep = "Deep"

    var id: String { rawValue }

    var helpText: String {
        switch self {
        case .fast: "For small changes and quick answers."
        case .balanced: "Normal planning and verification for most tasks."
        case .deep: "For complex bugs, refactors, architecture, or multi-step tasks."
        }
    }
}

enum AgentAccessMode: String, CaseIterable, Codable, Identifiable {
    case planOnly = "Plan Only"
    case suggestEdits = "Suggest Edits"
    case acceptEdits = "Accept Edits"
    case buildAndCheck = "Build & Check"
    case fullAccess = "Full Access"

    var id: String { rawValue }

    var shortDescription: String {
        switch self {
        case .planOnly: "Agent can inspect and plan, but should not change files."
        case .suggestEdits: "Agent should suggest patches for you to review, without applying them."
        case .acceptEdits: "Agent can edit files. You review changes before keeping them."
        case .buildAndCheck: "Agent can edit files and run safe build/test/lint commands."
        case .fullAccess: "Agent gets the most freedom Sanecode allows, but dangerous actions are still blocked."
        }
    }

    var capabilities: [String] {
        switch self {
        case .planOnly:
            ["Inspect repository", "Write a plan", "No file edits"]
        case .suggestEdits:
            ["Inspect repository", "Suggest patches", "No direct edits"]
        case .acceptEdits:
            ["Edit files", "Show changes", "No installs without approval"]
        case .buildAndCheck:
            ["Edit files", "Run safe checks", "Fix focused check failures"]
        case .fullAccess:
            ["Edit files", "Run safe local commands", "SafetyPolicy still blocks dangerous actions"]
        }
    }
}

enum MessageKind: String, Codable {
    case userPrompt
    case agentMessage
    case toolCall
    case toolResult
    case commandStarted
    case commandOutput
    case commandFinished
    case error
    case approvalRequest
    case systemEvent

    var label: String {
        switch self {
        case .userPrompt: "Task"
        case .agentMessage: "Agent"
        case .toolCall: "Tool"
        case .toolResult: "Result"
        case .commandStarted: "Command Started"
        case .commandOutput: "Command Output"
        case .commandFinished: "Command Finished"
        case .error: "Error"
        case .approvalRequest: "Approval"
        case .systemEvent: "Sanecode"
        }
    }
}

enum CommandStatus: String, Codable {
    case idle
    case running
    case succeeded
    case failed
    case cancelled
}

enum CommandKind: String, CaseIterable, Codable, Identifiable {
    case user = "Mine"
    case agent = "Agent"
    case checks = "Checks"
    case server = "Server"

    var id: String { rawValue }
}

enum FileChangeStatus: String, Codable {
    case modified = "M"
    case added = "A"
    case deleted = "D"
    case renamed = "R"
    case untracked = "?"

    var label: String {
        switch self {
        case .modified: "Modified"
        case .added: "Added"
        case .deleted: "Deleted"
        case .renamed: "Renamed"
        case .untracked: "Untracked"
        }
    }
}

enum DevServerStatus: String, Codable {
    case stopped
    case starting
    case running
    case failed

    var label: String {
        switch self {
        case .stopped: "Stopped"
        case .starting: "Starting"
        case .running: "Running"
        case .failed: "Failed"
        }
    }
}

enum PreviewDevice: String, CaseIterable, Codable, Identifiable {
    case desktop = "Desktop"
    case tablet = "Tablet"
    case phone = "Phone"
    case custom = "Custom"

    var id: String { rawValue }
}

enum SafetyLevel: String, CaseIterable, Codable, Identifiable {
    case strict = "Strict"
    case normal = "Normal"
    case fast = "Fast"
    case readOnly = "Read-only"

    var id: String { rawValue }
}

enum SafetyClassification: Equatable {
    case allowed
    case requiresApproval(reason: String, risk: String)
    case blocked(reason: String)
}

enum ThemeChoice: String, CaseIterable, Codable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var id: String { rawValue }
}
