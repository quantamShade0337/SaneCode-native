import SwiftUI

struct StorageSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @State private var showClearConfirm = false

    var body: some View {
        Form {
            Section("Storage location") {
                Text("Sanecode stores all data locally on your Mac.")
                    .foregroundStyle(.secondary)
                HStack {
                    Text(viewModel.storagePath)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                    Spacer()
                    Button("Reveal") {
                        let url = URL(fileURLWithPath: viewModel.storagePath)
                        NSWorkspace.shared.activateFileViewerSelecting([url])
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }

            Section("Data management") {
                Button("Export sessions") {
                    viewModel.exportSessions()
                }
                Button("Clear cached screenshots") {
                    viewModel.clearCachedScreenshots()
                }
                Button("Clear session history", role: .destructive) {
                    showClearConfirm = true
                }
            }

            if !viewModel.storageMessage.isEmpty {
                Section {
                    Label(viewModel.storageMessage, systemImage: "checkmark.circle")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }
        }
        .padding()
        .confirmationDialog("Clear session history?", isPresented: $showClearConfirm, titleVisibility: .visible) {
            Button("Clear", role: .destructive) { viewModel.clearSessionHistory() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes all session history. Your repositories and settings are kept.")
        }
    }
}
