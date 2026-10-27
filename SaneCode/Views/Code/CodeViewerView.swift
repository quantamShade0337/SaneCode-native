import AppKit
import SwiftUI

struct CodeViewerView: View {
    var rootPath: String
    var selectedPath: String?
    @State private var text = ""

    var body: some View {
        VStack(spacing: 0) {
            if let selectedPath {
                HStack {
                    Text(selectedPath)
                        .font(.headline)
                        .lineLimit(1)
                    Spacer()
                    Button("Open in Xcode") { NSWorkspace.shared.open(URL(fileURLWithPath: "\(rootPath)/\(selectedPath)")) }
                    Button("Open in VS Code") { openVSCode(selectedPath) }
                    Button("Reveal in Finder") {
                        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: "\(rootPath)/\(selectedPath)")])
                    }
                    Button("Copy Path") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString("\(rootPath)/\(selectedPath)", forType: .string)
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .padding(12)
                Divider()
                ScrollView([.vertical, .horizontal]) {
                    Text(lineNumbered(text))
                        .font(.system(size: 12, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                }
                .task(id: selectedPath) {
                    text = (try? String(contentsOfFile: "\(rootPath)/\(selectedPath)", encoding: .utf8)) ?? "Could not read this file as UTF-8."
                }
            } else {
                EmptyStateView(title: "No file selected", message: "Open a changed file or search files.", systemImage: "doc.text.magnifyingglass")
            }
        }
    }

    private func lineNumbered(_ value: String) -> String {
        value.split(separator: "\n", omittingEmptySubsequences: false).enumerated().map { index, line in
            String(format: "%4d  %@", index + 1, String(line))
        }.joined(separator: "\n")
    }

    private func openVSCode(_ selectedPath: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-lc", "code '\(rootPath)/\(selectedPath)'"]
        try? process.run()
    }
}
