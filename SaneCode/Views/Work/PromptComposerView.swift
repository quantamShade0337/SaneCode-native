import SwiftUI

struct PromptComposerView: View {
    @EnvironmentObject private var app: AppViewModel
    @ObservedObject var viewModel: AgentRoomViewModel
    var repository: Repository
    @State private var showOptions = false
    @FocusState private var inputFocused: Bool

    private var isRunning: Bool {
        viewModel.isRunning || viewModel.room.status == .running
    }

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            VStack(spacing: 8) {
                // Text input
                TextField("Describe what to build or fix...", text: $viewModel.room.prompt, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .lineLimit(1...6)
                    .focused($inputFocused)
                    .onSubmit { }

                // Bottom chip bar
                HStack(spacing: 4) {
                    agentChip
                    reasoningChip
                    modeChip
                    accessChip

                    Spacer()

                    if !viewModel.room.prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Button {
                            guard app.ensureRepositoryAccess(repository) else { return }
                            viewModel.addToQueue(onSave: app.updateSelectedRoom)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "text.badge.plus")
                                    .font(.system(size: 11))
                                Text("Queue")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 7))
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        guard app.ensureRepositoryAccess(repository) else { return }
                        viewModel.appendMessage(viewModel.room.prompt, onSave: app.updateSelectedRoom)
                        viewModel.runTask(repository: repository, terminal: app.terminalViewModel, settings: app.settingsStore, onSave: app.updateSelectedRoom)
                    } label: {
                        Image(systemName: isRunning ? "plus.circle.fill" : "arrow.up.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(
                                viewModel.room.prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? Color.secondary.opacity(0.3)
                                : Color.accentColor
                            )
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.return, modifiers: .command)
                    .disabled(viewModel.room.prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .help(isRunning ? "Add to Queue (⌘↩)" : "Run Task (⌘↩)")
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, 12)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .popover(isPresented: $showOptions, arrowEdge: .top) {
            optionsPopover
        }
        .onAppear { inputFocused = true }
    }

    private var agentChip: some View {
        chipPicker(
            label: viewModel.selectedAgent.rawValue,
            systemImage: "cpu"
        ) {
            Picker("Agent", selection: $viewModel.selectedAgent) {
                ForEach(AgentKind.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.inline)
            .labelsHidden()
        }
    }

    private var reasoningChip: some View {
        chipPicker(
            label: viewModel.selectedReasoningLevel.rawValue,
            systemImage: "brain"
        ) {
            Picker("Reasoning", selection: $viewModel.selectedReasoningLevel) {
                ForEach(ReasoningLevel.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.inline)
            .labelsHidden()
        }
    }

    private var modeChip: some View {
        chipPicker(
            label: viewModel.selectedMode.rawValue,
            systemImage: "wrench.and.screwdriver"
        ) {
            Picker("Mode", selection: $viewModel.selectedMode) {
                ForEach(RoomMode.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.inline)
            .labelsHidden()
        }
    }

    private var accessChip: some View {
        chipPicker(
            label: viewModel.selectedAccessMode.rawValue,
            systemImage: "lock.open"
        ) {
            Picker("Access", selection: $viewModel.selectedAccessMode) {
                ForEach(AgentAccessMode.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.inline)
            .labelsHidden()
        }
    }

    private func chipPicker<MenuContent: View>(
        label: String,
        systemImage: String,
        @ViewBuilder menu: () -> MenuContent
    ) -> some View {
        Menu {
            menu()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 10))
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 6))
        }
        .menuStyle(.borderlessButton)
    }

    private var optionsPopover: some View {
        Form {
            Section("Agent & Mode") {
                Picker("Agent", selection: $viewModel.selectedAgent) {
                    ForEach(AgentKind.allCases) { Text($0.rawValue).tag($0) }
                }
                Picker("Mode", selection: $viewModel.selectedMode) {
                    ForEach(RoomMode.allCases) { Text($0.rawValue).tag($0) }
                }
            }
            Section("Reasoning & Access") {
                Picker("Reasoning", selection: $viewModel.selectedReasoningLevel) {
                    ForEach(ReasoningLevel.allCases) { Text($0.rawValue).tag($0) }
                }
                Picker("Access", selection: $viewModel.selectedAccessMode) {
                    ForEach(AgentAccessMode.allCases) { Text($0.rawValue).tag($0) }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 310)
        .padding(.vertical, 4)
    }
}
