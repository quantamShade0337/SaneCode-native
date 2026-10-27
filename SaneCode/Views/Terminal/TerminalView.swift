import SwiftUI

struct TerminalView: View {
    @EnvironmentObject private var app: AppViewModel

    var body: some View {
        VStack(spacing: 0) {
            TerminalHeaderView()
            Divider()
            terminalOutput
            Divider()
            CommandInputView()
        }
        .onAppear {
            if app.terminalViewModel.selectedTerminalTab == .user, let repo = app.selectedRepository, app.ensureRepositoryAccess(repo) {
                app.terminalViewModel.startPTYIfNeeded(in: repo.path)
            }
        }
        .onChange(of: app.terminalViewModel.selectedTerminalTab) { _, tab in
            if tab == .user, let repo = app.selectedRepository, app.ensureRepositoryAccess(repo) {
                app.terminalViewModel.startPTYIfNeeded(in: repo.path)
            }
        }
    }

    private var terminalOutput: some View {
        ScrollView {
            Text(app.terminalViewModel.output(for: app.terminalViewModel.selectedTerminalTab).isEmpty ? "$" : app.terminalViewModel.output(for: app.terminalViewModel.selectedTerminalTab))
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.primary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
        }
        .background(Color(nsColor: .textBackgroundColor))
    }
}

private struct TerminalHeaderView: View {
    @EnvironmentObject private var app: AppViewModel

    var body: some View {
        HStack {
            Text("Terminal").font(.headline)
            TerminalTabBarView()
            Spacer()
            if let repo = app.selectedRepository {
                Text("repo: \(repo.name) · \(repo.branch ?? "no branch")")
                    .foregroundStyle(.secondary)
            }
            Button("Clear") { app.terminalViewModel.clearOutput() }
            Button("Copy") { app.terminalViewModel.copyOutput() }
            Button("Stop") { app.terminalViewModel.cancelCurrentCommand() }
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .padding(10)
    }
}
