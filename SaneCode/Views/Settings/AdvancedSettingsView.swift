import SwiftUI

struct AdvancedSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @State private var showResetConfirm = false

    var body: some View {
        Form {
            Section {
                Label("These features are in development and not yet available.", systemImage: "hammer")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            }
            Section("Experimental") {
                comingSoon("Show debug logs")
                comingSoon("Enable raw command mode")
                comingSoon("Enable experimental browser capture")
            }
            Section("Danger Zone") {
                Button("Reset Sanecode…", role: .destructive) {
                    showResetConfirm = true
                }
            }
        }
        .padding()
        .confirmationDialog("Reset Sanecode?", isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button("Reset", role: .destructive) { viewModel.reset() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will clear all rooms, repositories, and settings. This cannot be undone.")
        }
    }

    private func comingSoon(_ label: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text("Coming soon")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(.quaternary, in: Capsule())
        }
    }
}
