import SwiftUI

struct QueueSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Form {
            HStack {
                Text("Auto-run queue")
                Spacer()
                Text("Coming soon")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.quaternary, in: Capsule())
            }
            Toggle("Pause queue on failure", isOn: $viewModel.appSettings.pauseQueueOnFailure)
            Picker("Default run condition", selection: $viewModel.appSettings.defaultQueueRunCondition) {
                ForEach(QueueRunCondition.allCases) { condition in
                    Text(condition.rawValue).tag(condition)
                }
            }
            Text("Manual prompts never run without user action. Queues do not auto-run on app launch.")
                .foregroundStyle(.secondary)
            Button("Save") { viewModel.save() }
        }
        .padding()
    }
}
