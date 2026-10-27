import SwiftUI

struct RoomHeaderView: View {
    @EnvironmentObject private var app: AppViewModel
    @ObservedObject var viewModel: AgentRoomViewModel
    var repository: Repository

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(viewModel.room.title)
                    .font(.system(size: 22, weight: .semibold))
                HStack(spacing: 8) {
                    StatusBadge(
                        label: viewModel.room.status.label,
                        tint: statusTint(viewModel.room.status)
                    )
                    Text(viewModel.room.agent.rawValue)
                        .foregroundStyle(.secondary)
                    Text("·")
                        .foregroundStyle(.tertiary)
                    Text(viewModel.room.mode.rawValue)
                        .foregroundStyle(.secondary)
                    let waitingCount = viewModel.room.queuedPrompts.filter { $0.status == .waiting }.count
                    if waitingCount > 0 {
                        Text("·")
                            .foregroundStyle(.tertiary)
                        Text("\(waitingCount) waiting")
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.callout)
            }
            Spacer()
            HStack(spacing: 8) {
                ControlGroup {
                    Button {
                        guard app.ensureRepositoryAccess(repository) else { return }
                        viewModel.runTask(repository: repository, terminal: app.terminalViewModel, settings: app.settingsStore, onSave: app.updateSelectedRoom)
                    } label: {
                        Label("Run", systemImage: "play.fill")
                    }
                    Button {
                        viewModel.cancelTask(terminal: app.terminalViewModel, onSave: app.updateSelectedRoom)
                    } label: {
                        Label("Cancel", systemImage: "stop.fill")
                    }
                }
                .controlSize(.small)
                .frame(width: 130)

                ToolbarButton(title: "Run Checks", systemImage: "checkmark.seal") {
                    guard app.ensureRepositoryAccess(repository) else { return }
                    viewModel.runChecks(repository: repository, terminal: app.terminalViewModel, onSave: app.updateSelectedRoom)
                }
                ToolbarButton(title: "View Changes", systemImage: "doc.text.magnifyingglass") {
                    guard app.ensureRepositoryAccess(repository) else { return }
                    viewModel.loadDiff(repository: repository, onSave: app.updateSelectedRoom)
                    app.selectedMainTab = .changes
                }
            }
        }
    }

    private func statusTint(_ status: RoomStatus) -> Color {
        switch status {
        case .checksFailed: .red
        case .checksPassed: .green
        case .running, .planning: .blue
        case .needsReview: .orange
        default: .secondary
        }
    }
}
