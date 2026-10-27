import SwiftUI

struct AppearanceSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section("Theme") {
                Picker("Theme", selection: $viewModel.appSettings.theme) {
                    ForEach(ThemeChoice.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.radioGroup)
            }
            Section("Coming soon") {
                HStack {
                    Text("Accent color")
                    Spacer()
                    Text("Coming soon")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.quaternary, in: Capsule())
                }
                HStack {
                    Text("Editor font")
                    Spacer()
                    Text("System monospaced")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Density")
                    Spacer()
                    Text("Comfortable")
                        .foregroundStyle(.secondary)
                }
            }
            Section {
                Button("Save") { viewModel.save() }
            }
        }
        .padding()
    }
}
