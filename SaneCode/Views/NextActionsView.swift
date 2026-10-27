import AppKit
import SwiftUI

struct NextActionsView: View {
    @EnvironmentObject private var app: AppViewModel

    private var room: AgentRoom? { app.selectedRoom }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if let room {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        statusSection(room)
                        stepsSection(room)
                    }
                    .padding(14)
                }
            } else {
                emptyState
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        HStack {
            Text("TASKS")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
            if let room {
                Text(room.updatedAt, style: .time)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    app.isRightPanelVisible = false
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .frame(width: 22, height: 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Hide Panel")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private func statusSection(_ room: AgentRoom) -> some View {
        let waitingCount = room.queuedPrompts.filter { $0.status == .waiting }.count

        VStack(alignment: .leading, spacing: 8) {
            Text("STATUS")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.tertiary)

            if room.status == .running || room.status == .planning {
                actionCard(
                    title: room.currentStage.label,
                    detail: "Agent is working.",
                    tint: .blue
                ) {
                    Button("Cancel") {
                        app.terminalViewModel.cancelCurrentCommand()
                    }
                    Button("View Terminal") {
                        app.selectedMainTab = .terminal
                    }
                }

            } else if room.status == .checksFailed {
                actionCard(title: "Checks failed", detail: "Ask the agent to repair it.", tint: .red) {
                    Button("Fix") { fixFailedCheck(room) }
                    Button("Terminal") { app.selectedMainTab = .terminal }
                }

            } else if room.latestPlan != nil {
                actionCard(title: "Plan ready", detail: "Review and approve.", tint: .blue) {
                    Button("Review") { app.selectedMainTab = .work }
                    Button("Approve") { approvePlan(room) }
                }

            } else if !room.patchProposals.isEmpty {
                actionCard(title: "Patch proposed", detail: "Apply or reject.", tint: .blue) {
                    Button("Review") { app.selectedMainTab = .work }
                    Button("Apply") { applyPatch(room) }
                }

            } else if waitingCount > 0 {
                actionCard(
                    title: "\(waitingCount) queued",
                    detail: room.isQueuePaused ? "Queue paused." : "Ready to run.",
                    tint: .secondary
                ) {
                    Button("Run Next") { runNext(room) }
                    Button(room.isQueuePaused ? "Resume" : "Pause") { toggleQueuePause(room) }
                }

            } else if !room.changedFiles.isEmpty {
                actionCard(
                    title: "\(room.changedFiles.count) changed",
                    detail: "Review before committing.",
                    tint: .orange
                ) {
                    Button("Review") { app.selectedMainTab = .changes }
                    Button("Run Checks") { runChecks(room) }
                }

            } else {
                actionCard(title: "Ready", detail: "Describe a task and run it.", tint: .secondary) {
                    Button("New Room") { app.showNewRoom = true }
                }
            }
        }
    }

    @ViewBuilder
    private func stepsSection(_ room: AgentRoom) -> some View {
        let allStages: [TaskStage] = [.inspecting, .planning, .executing, .checking, .reviewing, .done]
        let currentIndex = allStages.firstIndex(of: room.currentStage) ?? -1

        VStack(alignment: .leading, spacing: 8) {
            Text("STEPS")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.tertiary)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(allStages.enumerated()), id: \.element) { index, stage in
                    HStack(spacing: 10) {
                        ZStack {
                            if index < currentIndex || room.status == .checksPassed || room.status == .cancelled {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.green)
                            } else if stage == room.currentStage && (room.status == .running || room.status == .planning) {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 8, height: 8)
                                    .padding(3)
                            } else {
                                Circle()
                                    .stroke(Color.secondary.opacity(0.25), lineWidth: 1.5)
                                    .frame(width: 14, height: 14)
                            }
                        }
                        .frame(width: 14)

                        Text(stage.label)
                            .font(.system(size: 12))
                            .foregroundStyle(
                                index <= currentIndex ? .primary : Color.secondary.opacity(0.5)
                            )
                        Spacer()
                    }
                }
            }

            if room.status == .checksFailed {
                HStack(spacing: 10) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.red)
                        .frame(width: 14)
                    Text("Checks failed")
                        .font(.system(size: 12))
                        .foregroundStyle(.red)
                    Spacer()
                }
            }
        }

        if !room.messages.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("ACTIVITY")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.tertiary)
                Text("\(room.messages.count) messages")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                if let last = room.messages.last {
                    Text(last.text.prefix(80))
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                        .lineLimit(2)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "square.stack")
                .font(.system(size: 24))
                .foregroundStyle(.tertiary)
            Text("No room selected")
                .font(.callout)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func actionCard<Content: View>(
        title: String,
        detail: String,
        tint: Color,
        @ViewBuilder actions: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(tint == .secondary ? .primary : tint)
                Text(detail)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 6) {
                actions()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
        .overlay { RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.07), lineWidth: 1) }
    }

    private func runNext(_ room: AgentRoom) {
        guard let repo = app.selectedRepository, app.ensureRepositoryAccess(repo) else { return }
        let vm = AgentRoomViewModel(room: room)
        vm.runNext(repository: repo, terminal: app.terminalViewModel, settings: app.settingsStore, onSave: app.updateSelectedRoom)
    }

    private func runChecks(_ room: AgentRoom) {
        guard let repo = app.selectedRepository, app.ensureRepositoryAccess(repo) else { return }
        let vm = AgentRoomViewModel(room: room)
        vm.runChecks(repository: repo, terminal: app.terminalViewModel, onSave: app.updateSelectedRoom)
        app.selectedMainTab = .changes
    }

    private func fixFailedCheck(_ room: AgentRoom) {
        guard let repo = app.selectedRepository, app.ensureRepositoryAccess(repo) else { return }
        let vm = AgentRoomViewModel(room: room)
        vm.fixFailedCheck(repository: repo, terminal: app.terminalViewModel, settings: app.settingsStore, runImmediately: false, onSave: app.updateSelectedRoom)
        app.selectedMainTab = .work
    }

    private func toggleQueuePause(_ room: AgentRoom) {
        var updated = room
        updated.isQueuePaused.toggle()
        app.updateSelectedRoom(updated)
    }

    private func approvePlan(_ room: AgentRoom) {
        let vm = AgentRoomViewModel(room: room)
        vm.approvePlanIntoQueue(onSave: app.updateSelectedRoom)
        app.selectedMainTab = .work
    }

    private func applyPatch(_ room: AgentRoom) {
        guard let patch = room.patchProposals.first else { return }
        let vm = AgentRoomViewModel(room: room)
        vm.applyPatchProposal(patch, onSave: app.updateSelectedRoom)
        app.selectedMainTab = .changes
    }
}

