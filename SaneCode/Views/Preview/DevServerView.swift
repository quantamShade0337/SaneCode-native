import SwiftUI

struct DevServerView: View {
    @EnvironmentObject private var app: AppViewModel
    @ObservedObject var viewModel: PreviewViewModel
    var repository: Repository

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "safari")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text("Preview your app")
                .font(.title2.weight(.semibold))
            if let command = repository.detectedCommands.first(where: { $0.kind == .server })?.command {
                Text("Sanecode found a dev command:")
                    .foregroundStyle(.secondary)
                Text(command)
                    .font(.system(.body, design: .monospaced))
                    .padding(8)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
            } else {
                Text("No dev server command was detected.")
                    .foregroundStyle(.secondary)
            }
            Button("Start Preview") {
                guard app.ensureRepositoryAccess(repository) else { return }
                viewModel.startServer(repository: repository, terminal: app.terminalViewModel)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
