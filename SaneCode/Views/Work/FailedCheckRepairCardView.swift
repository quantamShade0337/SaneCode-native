import AppKit
import SwiftUI

struct FailedCheckRepairCardView: View {
    @EnvironmentObject private var app: AppViewModel
    @ObservedObject var viewModel: AgentRoomViewModel
    var repository: Repository
    var terminal: TerminalViewModel
    var settings: SettingsStore
    var save: (AgentRoom) -> Void

    var body: some View {
        if let failed = viewModel.room.failedChecks.last(where: { $0.resolvedAt == nil }) {
            CardView {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Checks failed", systemImage: "xmark.octagon.fill")
                            .font(.headline)
                            .foregroundStyle(.red)
                        Spacer()
                        StatusBadge(label: "Exit \(failed.exitCode)", tint: .red)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Command")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(failed.command)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                    }
                    Text(failed.errorExcerpt.isEmpty ? "No useful error excerpt found." : failed.errorExcerpt)
                        .font(.system(.caption, design: .monospaced))
                        .lineLimit(8)
                        .textSelection(.enabled)
                    HStack {
                        Button("Fix Failed Check") {
                            viewModel.fixFailedCheck(repository: repository, terminal: terminal, settings: settings, runImmediately: true, onSave: save)
                        }
                        .buttonStyle(.borderedProminent)
                        Button("Copy Error") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(failed.errorExcerpt, forType: .string)
                        }
                        Button("Open Checks Output") {
                            app.terminalViewModel.selectedTerminalTab = .checks
                            app.selectedMainTab = .terminal
                        }
                        Button("View Changes") {
                            app.selectedMainTab = .changes
                        }
                    }
                    .controlSize(.small)
                }
            }
        }
    }
}
