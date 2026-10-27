import SwiftUI

struct AgentRoomView: View {
    @EnvironmentObject private var app: AppViewModel
    var repository: Repository
    @StateObject var viewModel: AgentRoomViewModel

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    RoomHeaderView(viewModel: viewModel, repository: repository)
                    StageTimelineView(stage: viewModel.room.currentStage)
                    workCards
                    WorkflowIntelligenceCardView(viewModel: viewModel, save: app.updateSelectedRoom)
                    FailedCheckRepairCardView(viewModel: viewModel, repository: repository, terminal: app.terminalViewModel, settings: app.settingsStore, save: app.updateSelectedRoom)
                    if !viewModel.room.queuedPrompts.isEmpty {
                        QueueCardView(viewModel: viewModel, repository: repository, runNext: {
                            guard app.ensureRepositoryAccess(repository) else { return }
                            viewModel.runNext(repository: repository, terminal: app.terminalViewModel, settings: app.settingsStore, onSave: app.updateSelectedRoom)
                        }, save: app.updateSelectedRoom)
                    }
                    if let summary = viewModel.room.completionSummaries.first {
                        completionSummaryCard(summary)
                    }
                    ContextCardView(viewModel: viewModel, repository: repository, save: app.updateSelectedRoom)
                    AgentEventStreamView(messages: viewModel.room.messages)
                }
                .padding(18)
            }
            Divider()
            PromptComposerView(viewModel: viewModel, repository: repository)
        }
        .alert("Codex CLI not found", isPresented: $viewModel.codexMissing) {
            Button("Use Custom Command") { viewModel.selectedAgent = .custom }
            Button("Open Agent Settings") {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
        } message: {
            Text("Sanecode could not find `codex` in your PATH.")
        }
        .sheet(isPresented: Binding(get: { viewModel.pendingApproval != nil }, set: { if !$0 { viewModel.pendingApproval = nil } })) {
            if let approval = viewModel.pendingApproval {
                ApprovalSheetView(
                    approval: approval,
                    onReject: { viewModel.pendingApproval = nil },
                    onApprove: {
                        viewModel.approvePendingCommand(terminal: app.terminalViewModel, onSave: app.updateSelectedRoom)
                    }
                )
            }
        }
        .onChange(of: app.selectedRoom) { _, selectedRoom in
            guard let selectedRoom, selectedRoom.id == viewModel.room.id else { return }
            viewModel.room = selectedRoom
            viewModel.selectedAgent = selectedRoom.agent
            viewModel.selectedMode = selectedRoom.mode
            viewModel.selectedReasoningLevel = selectedRoom.reasoningLevel
            viewModel.selectedAccessMode = selectedRoom.accessMode
        }
    }

    @ViewBuilder
    private var workCards: some View {
        let hasChanges = !viewModel.room.changedFiles.isEmpty
        let hasResult = viewModel.room.verificationRuns.last != nil
        let hasWarning = viewModel.room.hadPreExistingChanges

        if hasChanges || hasResult || hasWarning {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 10)], spacing: 10) {
                if hasChanges {
                    infoCard(
                        "Changed files",
                        systemImage: "doc.on.doc",
                        text: viewModel.room.changedFiles.map(\.path).joined(separator: "\n")
                    )
                }
                if hasResult {
                    infoCard(
                        "Latest result",
                        systemImage: "checkmark.seal",
                        text: viewModel.room.verificationRuns.last.map { $0.status == .succeeded ? "Checks passed." : "Checks failed." } ?? ""
                    )
                }
                if hasWarning {
                    infoCard(
                        "Existing changes",
                        systemImage: "exclamationmark.triangle",
                        text: "This repo had changes before this room started. Some may not belong to this room."
                    )
                }
            }
        }
    }

    private func infoCard(_ title: String, systemImage: String, text: String) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 8) {
                Label(title, systemImage: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(text)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func completionSummaryCard(_ summary: TaskCompletionSummary) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Latest Summary")
                        .font(.headline)
                    Spacer()
                    StatusBadge(label: summary.exitCode == 0 ? "Completed" : "Failed", tint: summary.exitCode == 0 ? .green : .red)
                }
                Text(summary.summary)
                    .font(.callout)
                HStack {
                    Label("\(summary.roomOwnedChangesCount) changes from this room", systemImage: "doc.on.doc")
                    Label(summary.checksRun ? (summary.checksPassed ? "Checks passed" : "Checks failed") : "Checks not run", systemImage: "checkmark.seal")
                    Label(summary.nextSuggestedAction, systemImage: "arrow.right.circle")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                if !summary.limitations.isEmpty {
                    Text(summary.limitations)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
