import SwiftUI

struct CommandInputView: View {
    @EnvironmentObject private var app: AppViewModel

    var body: some View {
        HStack {
            Text("$")
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
            TextField("Run a command in this repository", text: Binding(
                get: { app.terminalViewModel.userCommand },
                set: { app.terminalViewModel.userCommand = $0 }
            ))
                .textFieldStyle(.plain)
                .font(.system(.body, design: .monospaced))
                .onSubmit {
                    if let repo = app.selectedRepository {
                        guard app.ensureRepositoryAccess(repo) else { return }
                        app.terminalViewModel.runUserCommand(in: repo.path)
                    }
                }
            Button("Run") {
                if let repo = app.selectedRepository {
                    guard app.ensureRepositoryAccess(repo) else { return }
                    app.terminalViewModel.runUserCommand(in: repo.path)
                }
            }
        }
        .padding(10)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
