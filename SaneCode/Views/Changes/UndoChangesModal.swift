import SwiftUI

struct UndoChangesModal: View {
    @EnvironmentObject private var app: AppViewModel
    @Environment(\.dismiss) private var dismiss
    var repository: Repository
    var room: AgentRoom
    @State private var deleteUntracked = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Undo changes?").font(.title3.weight(.semibold))
            Text("This will revert tracked file changes from this room. Untracked files will not be deleted unless selected.")
                .foregroundStyle(.secondary)
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(room.changedFiles.filter { $0.status != .untracked }) { file in
                        Text(file.path)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 130)
            Toggle("Also delete untracked files", isOn: $deleteUntracked)
                .disabled(true)
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Undo Tracked Changes", role: .destructive) {
                    guard app.ensureRepositoryAccess(repository) else { return }
                    let viewModel = AgentRoomViewModel(room: room)
                    viewModel.undoChanges(repository: repository, onSave: app.updateSelectedRoom)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 500)
    }
}
