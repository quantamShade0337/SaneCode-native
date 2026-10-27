import SwiftUI

struct AgentSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Picker("Default agent", selection: $viewModel.appSettings.defaultAgent) {
                ForEach(AgentKind.allCases) { Text($0.rawValue).tag($0) }
            }
            .frame(maxWidth: 360, alignment: .leading)
            Picker("Default reasoning level", selection: $viewModel.appSettings.defaultReasoningLevel) {
                ForEach(ReasoningLevel.allCases) { Text($0.rawValue).tag($0) }
            }
            .frame(maxWidth: 360, alignment: .leading)
            Picker("Default access mode", selection: $viewModel.appSettings.defaultAccessMode) {
                ForEach(AgentAccessMode.allCases) { Text($0.rawValue).tag($0) }
            }
            .frame(maxWidth: 360, alignment: .leading)

            CardView {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Codex CLI")
                                .font(.headline)
                            Text(viewModel.codexFound ? "Codex CLI ready." : "Codex CLI was not found.")
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        StatusBadge(label: viewModel.codexFound ? "Found" : "Missing", tint: viewModel.codexFound ? .green : .red)
                    }
                    Text("Executable path")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(viewModel.codexPath ?? "Not found in PATH")
                        .font(.system(.callout, design: .monospaced))
                        .textSelection(.enabled)
                    ForEach($viewModel.agentConfigs) { $config in
                        if config.kind == .codex {
                            TextField("Arguments template", text: $config.arguments)
                                .textFieldStyle(.roundedBorder)
                            HStack {
                                Button("Use JSON Event Stream") {
                                    config.arguments = AgentConfiguration.codexDefault.arguments
                                }
                                Text("Recommended: `codex exec --json` keeps the model local through CLI and lets Sanecode show structured tool, command, and result events.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    Text("Preview")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(viewModel.codexCommandPreview())
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                    Button("Test Codex") { viewModel.testAgent() }
                }
            }

            CardView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Custom agents")
                        .font(.headline)
                    ForEach($viewModel.agentConfigs) { $config in
                        if config.kind == .custom {
                            TextField("Name", text: $config.name)
                                .textFieldStyle(.roundedBorder)
                            TextField("Executable", text: $config.executable)
                                .textFieldStyle(.roundedBorder)
                            TextField("Arguments", text: $config.arguments)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    Button("Add Custom Command") {
                        viewModel.agentConfigs.append(AgentConfiguration(name: "Custom Command", kind: .custom, executable: "", arguments: "{prompt}"))
                    }
                }
            }
            HStack {
                Spacer()
                Button("Save") { viewModel.save() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}
