import SwiftUI

struct QueueCardView: View {
    @ObservedObject var viewModel: AgentRoomViewModel
    var repository: Repository
    var runNext: () -> Void
    var save: (AgentRoom) -> Void

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Queue")
                            .font(.headline)
                        Text("\(waitingCount) waiting · auto-run \(viewModel.room.autoRunQueue ? "on" : "off")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Toggle("Auto-run", isOn: Binding(
                        get: { viewModel.room.autoRunQueue },
                        set: {
                            viewModel.room.autoRunQueue = $0
                            save(viewModel.room)
                        }
                    ))
                    .toggleStyle(.switch)
                    .controlSize(.small)
                }

                if viewModel.room.queuedPrompts.isEmpty {
                    Text("No prompts waiting.")
                        .foregroundStyle(.secondary)
                } else {
                    VStack(spacing: 4) {
                        ForEach(viewModel.room.queuedPrompts) { prompt in
                            QueueRowView(prompt: prompt, viewModel: viewModel, save: save)
                        }
                    }
                }

                HStack {
                    Button("Run Next", action: runNext)
                        .buttonStyle(.borderedProminent)
                        .disabled(waitingCount == 0 || viewModel.isRunning || viewModel.room.status == .running)
                    Button(viewModel.room.isQueuePaused ? "Resume Queue" : "Pause Queue") {
                        viewModel.room.isQueuePaused ? viewModel.resumeQueue(onSave: save) : viewModel.pauseQueue(onSave: save)
                    }
                    Button("Clear Queue") {
                        viewModel.clearQueue(onSave: save)
                    }
                    .disabled(waitingCount == 0)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }

    private var waitingCount: Int {
        viewModel.room.queuedPrompts.filter { $0.status == .waiting }.count
    }
}

private struct QueueRowView: View {
    var prompt: QueuedPrompt
    @ObservedObject var viewModel: AgentRoomViewModel
    var save: (AgentRoom) -> Void
    @State private var showSettings = false

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(tint(for: prompt.status))
                .frame(width: 7, height: 7)
                .padding(.leading, 2)

            StatusBadge(label: prompt.status.label, tint: tint(for: prompt.status))
                .frame(width: 88, alignment: .leading)

            TextField("Queued prompt", text: Binding(
                get: { prompt.text },
                set: { viewModel.updateQueuedPrompt(prompt, text: $0, onSave: save) }
            ))
            .textFieldStyle(.plain)
            .disabled(prompt.status == .running || prompt.status == .completed)

            Text("\(prompt.mode.rawValue) · \(prompt.reasoningLevel.rawValue)")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .lineLimit(1)

            Button {
                showSettings.toggle()
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 12))
            }
            .buttonStyle(.borderless)
            .disabled(prompt.status == .running || prompt.status == .completed)
            .popover(isPresented: $showSettings, arrowEdge: .trailing) {
                queueRowSettingsPopover
            }

            Button {
                viewModel.moveQueuedPrompt(prompt, direction: -1, onSave: save)
            } label: {
                Image(systemName: "chevron.up")
            }
            .buttonStyle(.borderless)
            .disabled(prompt.status == .running)

            Button {
                viewModel.moveQueuedPrompt(prompt, direction: 1, onSave: save)
            } label: {
                Image(systemName: "chevron.down")
            }
            .buttonStyle(.borderless)
            .disabled(prompt.status == .running)

            Button {
                viewModel.removeQueuedPrompt(prompt, onSave: save)
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.borderless)
            .disabled(prompt.status == .running)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.quinary, in: RoundedRectangle(cornerRadius: 6))
    }

    private var queueRowSettingsPopover: some View {
        Form {
            Section("Agent & Mode") {
                Picker("Agent", selection: Binding(
                    get: { prompt.agent },
                    set: { viewModel.updateQueuedPromptSettings(prompt, agent: $0, onSave: save) }
                )) {
                    ForEach(AgentKind.allCases) { Text($0.rawValue).tag($0) }
                }
                Picker("Mode", selection: Binding(
                    get: { prompt.mode },
                    set: { viewModel.updateQueuedPromptSettings(prompt, mode: $0, onSave: save) }
                )) {
                    ForEach(RoomMode.allCases) { Text($0.rawValue).tag($0) }
                }
            }
            Section("Reasoning & Access") {
                Picker("Reasoning", selection: Binding(
                    get: { prompt.reasoningLevel },
                    set: { viewModel.updateQueuedPromptSettings(prompt, reasoning: $0, onSave: save) }
                )) {
                    ForEach(ReasoningLevel.allCases) { Text($0.rawValue).tag($0) }
                }
                Picker("Access", selection: Binding(
                    get: { prompt.accessMode },
                    set: { viewModel.updateQueuedPromptSettings(prompt, access: $0, onSave: save) }
                )) {
                    ForEach(AgentAccessMode.allCases) { Text($0.rawValue).tag($0) }
                }
                Picker("Run condition", selection: Binding(
                    get: { prompt.runCondition },
                    set: { viewModel.updateQueuedPromptSettings(prompt, condition: $0, onSave: save) }
                )) {
                    ForEach(QueueRunCondition.allCases) { Text($0.rawValue).tag($0) }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 310)
        .padding(.vertical, 4)
    }

    private func tint(for status: QueuedPromptStatus) -> Color {
        switch status {
        case .waiting: .secondary
        case .running: .blue
        case .completed: .green
        case .failed: .red
        case .cancelled, .skipped: .orange
        }
    }
}
