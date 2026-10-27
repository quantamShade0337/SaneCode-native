import SwiftUI

struct WorkflowIntelligenceCardView: View {
    @ObservedObject var viewModel: AgentRoomViewModel
    var save: (AgentRoom) -> Void

    private var room: AgentRoom { viewModel.room }

    var body: some View {
        if hasContent {
            CardView {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Workflow Intelligence")
                            .font(.headline)
                        Spacer()
                        if room.worktree?.status == .ready {
                            StatusBadge(label: "Isolated", tint: .green)
                        }
                    }

                    if let worktree = room.worktree {
                        Label(worktree.status == .ready ? "Room worktree: \(worktree.worktreePath)" : "Worktree unavailable: \(worktree.errorMessage ?? "Unknown error")", systemImage: worktree.status == .ready ? "square.split.2x1" : "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .textSelection(.enabled)
                    }

                    if let contract = room.latestRuntimeContract {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Runtime Contract")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                Spacer()
                                StatusBadge(label: contract.eventStream, tint: contract.eventStream.contains("JSON") ? .green : .secondary)
                            }
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 8)], alignment: .leading, spacing: 6) {
                                Label(contract.sandboxMode, systemImage: "shippingbox")
                                Label(contract.approvalPolicy, systemImage: "hand.raised")
                                Label(contract.accessMode.rawValue, systemImage: "lock")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            Text(contract.commandPreview)
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(.tertiary)
                                .lineLimit(2)
                                .textSelection(.enabled)
                            ForEach(contract.enforcementNotes.prefix(3), id: \.self) { note in
                                Label(note, systemImage: "checkmark.shield")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    if let plan = room.latestPlan, !plan.steps.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Latest Plan")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Button("Approve Plan") {
                                    viewModel.approvePlanIntoQueue(onSave: save)
                                }
                                .buttonStyle(.borderedProminent)
                                Button("Dismiss") {
                                    viewModel.rejectLatestPlan(onSave: save)
                                }
                                .buttonStyle(.bordered)
                            }
                            .controlSize(.small)
                            ForEach(Array(plan.steps.prefix(6).enumerated()), id: \.offset) { index, step in
                                Text("\(index + 1). \(step)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    if !room.reviewRisks.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Review Signals")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            ForEach(room.reviewRisks.prefix(5)) { risk in
                                Label("\(risk.title): \(risk.detail)", systemImage: icon(for: risk.severity))
                                    .font(.caption)
                                    .foregroundStyle(color(for: risk.severity))
                            }
                        }
                    }

                    if let patch = room.patchProposals.first {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Suggested Patch")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Button("Apply Patch") {
                                    viewModel.applyPatchProposal(patch, onSave: save)
                                }
                                .buttonStyle(.borderedProminent)
                                Button("Reject") {
                                    viewModel.rejectPatchProposal(patch, onSave: save)
                                }
                                .buttonStyle(.bordered)
                            }
                            .controlSize(.small)
                            Text(patch.body)
                                .font(.system(.caption, design: .monospaced))
                                .lineLimit(8)
                                .textSelection(.enabled)
                        }
                    }
                }
            }
        }
    }

    private var hasContent: Bool {
        room.worktree != nil || room.latestPlan != nil || !room.reviewRisks.isEmpty || !room.patchProposals.isEmpty
    }

    private func icon(for severity: ReviewRiskSeverity) -> String {
        switch severity {
        case .info: "info.circle"
        case .warning: "exclamationmark.triangle"
        case .high: "xmark.octagon"
        }
    }

    private func color(for severity: ReviewRiskSeverity) -> Color {
        switch severity {
        case .info: .secondary
        case .warning: .orange
        case .high: .red
        }
    }
}
