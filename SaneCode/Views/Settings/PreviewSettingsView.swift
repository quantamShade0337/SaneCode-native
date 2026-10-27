import SwiftUI

struct PreviewSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Form {
            TextField("Default dev command", text: $viewModel.appSettings.previewSettings.defaultDevCommand)
            Toggle("Auto-detect localhost", isOn: $viewModel.appSettings.previewSettings.autoDetectLocalhost)
            Toggle("Open preview after starting dev server", isOn: $viewModel.appSettings.previewSettings.openPreviewAfterStartingServer)
            Toggle("Auto-reload after task", isOn: $viewModel.appSettings.previewSettings.autoReloadAfterTask)
            Picker("Default device", selection: $viewModel.appSettings.previewSettings.defaultDevice) {
                ForEach(PreviewDevice.allCases) { Text($0.rawValue).tag($0) }
            }
            TextField("Screenshot format", text: $viewModel.appSettings.previewSettings.screenshotFormat)
            Button("Save") { viewModel.save() }
        }
        .padding()
    }
}
