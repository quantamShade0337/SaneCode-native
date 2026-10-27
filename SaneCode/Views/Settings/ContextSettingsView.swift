import SwiftUI

struct ContextSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Picker("Default context preset", selection: $viewModel.appSettings.defaultContextPreset) {
                ForEach(ContextPreset.allCases) { preset in
                    Text(preset.rawValue).tag(preset)
                }
            }
            Toggle("Show approximate token estimate", isOn: $viewModel.appSettings.showApproximateTokenEstimate)
            Text("Sanecode excludes .env files, secret-like files, and noisy folders from context previews by default.")
                .foregroundStyle(.secondary)
            Button("Save") { viewModel.save() }
        }
        .padding()
    }
}
