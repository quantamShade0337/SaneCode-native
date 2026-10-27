import AppKit
import SwiftUI

struct ApprovalSheetView: View {
    var approval: (command: String, reason: String, risk: String)
    var onReject: () -> Void
    var onApprove: () -> Void

    private var riskColor: Color {
        let lower = approval.risk.lowercased()
        if lower.contains("high") || lower.contains("destruct") || lower.contains("delet") { return .red }
        if lower.contains("medium") || lower.contains("chang") || lower.contains("install") { return .orange }
        return .secondary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Approval required")
                        .font(.title3.weight(.semibold))
                    Text("The agent wants to run a command that needs your sign-off.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            VStack(alignment: .leading, spacing: 16) {
                // Command
                VStack(alignment: .leading, spacing: 6) {
                    Label("Command", systemImage: "terminal")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    HStack {
                        Text(approval.command)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(approval.command, forType: .string)
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.caption)
                        }
                        .buttonStyle(.borderless)
                        .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    }
                }

                // Reason + Risk
                HStack(alignment: .top, spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Why", systemImage: "info.circle")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(approval.reason)
                            .font(.callout)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 6) {
                        Label("Risk", systemImage: "exclamationmark.triangle")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(approval.risk)
                            .font(.callout)
                            .foregroundStyle(riskColor)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(24)

            Divider()

            // Actions
            HStack {
                Button("Reject") { onReject() }
                    .buttonStyle(.bordered)
                Spacer()
                Text("⌘ Return to approve")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Button("Approve Once") { onApprove() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
            }
            .padding(20)
        }
        .frame(width: 500)
    }
}
