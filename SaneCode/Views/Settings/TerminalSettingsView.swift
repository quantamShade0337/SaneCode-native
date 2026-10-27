import SwiftUI

struct TerminalSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Form {
            TextField("Shell", text: $viewModel.appSettings.terminalSettings.shell)
            Slider(value: $viewModel.appSettings.terminalSettings.fontSize, in: 10...18) {
                Text("Font size")
            }
            Toggle("Show timestamps", isOn: $viewModel.appSettings.terminalSettings.showTimestamps)
            Toggle("Auto-scroll", isOn: $viewModel.appSettings.terminalSettings.autoScroll)
            Stepper("Max output lines: \(viewModel.appSettings.terminalSettings.maxOutputLines)", value: $viewModel.appSettings.terminalSettings.maxOutputLines, in: 500...50000, step: 500)
            Button("Save") { viewModel.save() }
        }
        .padding()
    }
}
