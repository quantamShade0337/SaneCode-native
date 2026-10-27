import SwiftUI

struct NewRoomModal: View {
    @EnvironmentObject private var app: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var prompt = ""
    @State private var agent: AgentKind = .codex
    @State private var mode: RoomMode = .auto
    @State private var showAdvanced = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("What are we working on?")
                    .font(.title2.weight(.semibold))
                Text("Sanecode will inspect the repo, run the agent, and show you the changes.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            TextField("Make the dashboard cleaner", text: $prompt, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)

            DisclosureGroup("Advanced options", isExpanded: $showAdvanced) {
                Form {
                    Picker("Agent", selection: $agent) {
                        ForEach(AgentKind.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Picker("Mode", selection: $mode) {
                        ForEach(RoomMode.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Text("Branch behavior: current working tree")
                        .foregroundStyle(.secondary)
                    Text("Checks: auto-detected command if available")
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)
            }
            .font(.callout)

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Start") {
                    let title = prompt.split(separator: " ").prefix(5).joined(separator: " ")
                    if var room = app.createRoom(title: title.isEmpty ? "New room" : title, prompt: prompt, select: true) {
                        room.agent = agent
                        room.mode = mode
                        app.updateSelectedRoom(room)
                    }
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 560)
    }
}
