import SwiftUI

struct SettingsView: View {
    @StateObject var viewModel: SettingsViewModel

    var body: some View {
        TabView {
            GeneralSettingsView(viewModel: viewModel).tabItem { Label("General", systemImage: "gear") }
            AgentSettingsView(viewModel: viewModel).tabItem { Label("Agents", systemImage: "cpu") }
            SafetySettingsView(viewModel: viewModel).tabItem { Label("Safety", systemImage: "lock.shield") }
            QueueSettingsView(viewModel: viewModel).tabItem { Label("Queue", systemImage: "text.badge.plus") }
            ContextSettingsView(viewModel: viewModel).tabItem { Label("Context", systemImage: "doc.text.magnifyingglass") }
            BackendHealthView().tabItem { Label("Health", systemImage: "waveform.path.ecg") }
            PreviewSettingsView(viewModel: viewModel).tabItem { Label("Preview", systemImage: "safari") }
            TerminalSettingsView(viewModel: viewModel).tabItem { Label("Terminal", systemImage: "terminal") }
            AppearanceSettingsView(viewModel: viewModel).tabItem { Label("Appearance", systemImage: "paintpalette") }
            StorageSettingsView(viewModel: viewModel).tabItem { Label("Storage", systemImage: "externaldrive") }
            AdvancedSettingsView(viewModel: viewModel).tabItem { Label("Advanced", systemImage: "wrench.adjustable") }
        }
        .padding()
    }
}
