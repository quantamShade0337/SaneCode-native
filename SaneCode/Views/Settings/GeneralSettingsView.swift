import SwiftUI

struct GeneralSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Toggle("Open last repository on launch", isOn: $viewModel.appSettings.openLastRepositoryOnLaunch)
            Toggle("Show welcome screen on launch", isOn: $viewModel.appSettings.showWelcomeOnLaunch)
            Toggle("Restore previous rooms", isOn: $viewModel.appSettings.restoreRooms)
            Toggle("Auto-save sessions", isOn: $viewModel.appSettings.autoSaveSessions)
            TextField("Default repository folder", text: $viewModel.appSettings.defaultRepoFolder)
            Stepper("Max session history: \(viewModel.appSettings.maxSessionHistory)", value: $viewModel.appSettings.maxSessionHistory, in: 10...500)
            Button("Save") { viewModel.save() }
        }
        .padding()
    }
}
