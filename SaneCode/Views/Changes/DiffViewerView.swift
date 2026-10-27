import AppKit
import SwiftUI

struct DiffViewerView: View {
    var diff: String
    var title: String = "Raw Diff"
    var isFallback: Bool = false
    @State private var selectedHunkID: DiffHunk.ID?

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            HStack(spacing: 0) {
                if hunks.count > 1 {
                    hunkSidebar
                    Divider()
                }
                diffTextView
            }
        }
    }

    private var hunks: [DiffHunk] {
        DiffHunkParser().parse(diff)
    }

    private var visibleText: String {
        selectedHunkID.flatMap { id in hunks.first(where: { $0.id == id })?.text } ?? diff
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .lineLimit(1)
                if isFallback {
                    Text("Showing raw unified diff.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            let stats = diffStats(diff)
            HStack(spacing: 6) {
                Text("+\(stats.additions)")
                    .font(.system(.callout, design: .monospaced).weight(.medium))
                    .foregroundStyle(.green)
                Text("-\(stats.deletions)")
                    .font(.system(.callout, design: .monospaced).weight(.medium))
                    .foregroundStyle(.red)
            }
            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(visibleText, forType: .string)
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
        }
        .padding(10)
    }

    private var hunkSidebar: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                Button("Full Diff") { selectedHunkID = nil }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                ForEach(hunks) { hunk in
                    hunkButton(hunk)
                }
            }
            .padding(8)
        }
        .frame(width: 220)
    }

    private func hunkButton(_ hunk: DiffHunk) -> some View {
        Button {
            selectedHunkID = hunk.id
        } label: {
            Text(hunk.title)
                .font(.system(.caption2, design: .monospaced))
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .padding(6)
        .background(selectedHunkID == hunk.id ? Color.secondary.opacity(0.14) : Color.clear, in: RoundedRectangle(cornerRadius: 5))
    }

    private var diffTextView: some View {
        ScrollView([.vertical, .horizontal]) {
            if visibleText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("No diff to show.")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .padding(14)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(visibleText.components(separatedBy: "\n").enumerated()), id: \.offset) { _, line in
                        Text(line.isEmpty ? " " : line)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(lineColor(line))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 1)
                            .background(lineBackground(line))
                    }
                }
                .padding(.vertical, 10)
                .textSelection(.enabled)
            }
        }
    }

    private func lineColor(_ line: String) -> Color {
        if line.hasPrefix("+") && !line.hasPrefix("+++") { return Color(nsColor: .systemGreen) }
        if line.hasPrefix("-") && !line.hasPrefix("---") { return Color(nsColor: .systemRed) }
        if line.hasPrefix("@@") { return .blue }
        if line.hasPrefix("diff ") || line.hasPrefix("index ") || line.hasPrefix("--- ") || line.hasPrefix("+++ ") { return .secondary }
        return .primary
    }

    private func lineBackground(_ line: String) -> Color {
        if line.hasPrefix("+") && !line.hasPrefix("+++") { return Color.green.opacity(0.07) }
        if line.hasPrefix("-") && !line.hasPrefix("---") { return Color.red.opacity(0.07) }
        if line.hasPrefix("@@") { return Color.blue.opacity(0.05) }
        return .clear
    }

    private func diffStats(_ diff: String) -> (additions: Int, deletions: Int) {
        let lines = diff.split(separator: "\n")
        let additions = lines.filter { $0.hasPrefix("+") && !$0.hasPrefix("+++") }.count
        let deletions = lines.filter { $0.hasPrefix("-") && !$0.hasPrefix("---") }.count
        return (additions, deletions)
    }
}
