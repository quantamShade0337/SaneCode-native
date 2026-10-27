import AppKit
import SwiftUI

struct AgentEventStreamView: View {
    var messages: [AgentMessage]

    var body: some View {
        if messages.isEmpty {
            EmptyStateView(
                title: "No activity yet",
                message: "Run a task to see the agent work log here.",
                systemImage: "sparkles"
            )
            .frame(minHeight: 120)
        } else {
            VStack(alignment: .leading, spacing: 2) {
                Text("Activity")
                    .font(.headline)
                    .padding(.bottom, 6)
                ForEach(messages) { message in
                    messageRow(message)
                }
            }
        }
    }

    @ViewBuilder
    private func messageRow(_ message: AgentMessage) -> some View {
        switch message.kind {
        case .userPrompt:
            UserPromptRow(message: message)
        case .agentMessage:
            AgentMessageRow(message: message)
        case .commandStarted, .commandFinished:
            CommandEventRow(message: message)
        case .commandOutput:
            CommandOutputRow(message: message)
        case .error:
            ErrorRow(message: message)
        case .systemEvent:
            SystemEventRow(message: message)
        default:
            MetaRow(message: message)
        }
    }
}

// MARK: - User prompt (task sent)

private struct UserPromptRow: View {
    var message: AgentMessage

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Spacer(minLength: 40)
            VStack(alignment: .trailing, spacing: 4) {
                Text(message.text)
                    .font(.callout)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 12))
                    .textSelection(.enabled)
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Agent message (response text)

private struct AgentMessageRow: View {
    var message: AgentMessage
    @State private var expanded = true

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.tint)
                .frame(width: 26, height: 26)
                .background(Color.accentColor.opacity(0.10), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Agent")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) { expanded.toggle() }
                    } label: {
                        Image(systemName: expanded ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                }
                if expanded {
                    Text(message.text)
                        .font(.callout)
                        .foregroundStyle(.primary)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 20)
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Command started / finished

private struct CommandEventRow: View {
    var message: AgentMessage

    private var isFinished: Bool { message.kind == .commandFinished }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isFinished ? "checkmark.circle.fill" : "play.circle.fill")
                .font(.system(size: 11))
                .foregroundStyle(isFinished ? .green : .secondary)
            Text(message.text)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Spacer()
            Text(message.timestamp, style: .time)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.quinary, in: RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - Command output (scrollable code block)

private struct CommandOutputRow: View {
    var message: AgentMessage
    @State private var expanded = false

    private var lines: [String] { message.text.components(separatedBy: "\n") }
    private var preview: String { lines.prefix(3).joined(separator: "\n") }
    private var isTruncated: Bool { lines.count > 3 }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "terminal")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                Text("Output")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                if let stream = message.metadata["stream"] {
                    Text(stream.uppercased())
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(stream == "jsonl" ? .green : .secondary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))
                }
                Spacer()
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(message.text, forType: .string)
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.caption2)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                if isTruncated {
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) { expanded.toggle() }
                    } label: {
                        Text(expanded ? "Collapse" : "Expand")
                            .font(.caption2)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)

            Divider()

            Text(expanded ? message.text : (isTruncated ? preview + "\n…" : message.text))
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.primary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
        }
        .background(Color(nsColor: .textBackgroundColor).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary.opacity(0.07), lineWidth: 1)
        }
    }
}

// MARK: - Error

private struct ErrorRow: View {
    var message: AgentMessage

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.octagon.fill")
                .font(.system(size: 13))
                .foregroundStyle(.red)
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Error")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.red)
                    Spacer()
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Text(message.text)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.red.opacity(0.85))
                    .textSelection(.enabled)
            }
        }
        .padding(10)
        .background(Color.red.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.red.opacity(0.18), lineWidth: 1)
        }
    }
}

// MARK: - System event (subtle divider row)

private struct SystemEventRow: View {
    var message: AgentMessage

    var body: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(Color.primary.opacity(0.08))
                .frame(height: 1)
            Text(message.text)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.tertiary)
                .lineLimit(1)
                .fixedSize()
            Rectangle()
                .fill(Color.primary.opacity(0.08))
                .frame(height: 1)
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Tool call / result / approval (compact)

private struct MetaRow: View {
    var message: AgentMessage

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .frame(width: 14)
            Text(message.kind.label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(message.text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Spacer()
            Text(message.timestamp, style: .time)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 3)
    }

    private var icon: String {
        switch message.kind {
        case .toolCall: return "wrench"
        case .toolResult: return "arrow.turn.up.left"
        case .approvalRequest: return "hand.raised"
        default: return "dot.radiowaves.left.and.right"
        }
    }
}
