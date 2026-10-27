import AppKit
import SwiftUI

struct ContextCardView: View {
    @EnvironmentObject private var app: AppViewModel
    @ObservedObject var viewModel: AgentRoomViewModel
    var repository: Repository
    var save: (AgentRoom) -> Void
    @State private var expanded = false
    @State private var showFullContext = false

    private var context: TaskContext {
        viewModel.contextPreview(repository: repository)
    }

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 10) {
                // Always-visible header row
                HStack {
                    HStack(spacing: 6) {
                        Text("Context")
                            .font(.subheadline.weight(.semibold))
                        Text(sizeLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.quaternary, in: Capsule())
                        if !context.warnings.isEmpty {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                    Spacer()
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) { expanded.toggle() }
                    } label: {
                        Image(systemName: expanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                // Expandable detail
                if expanded {
                    Divider()

                    HStack {
                        Picker("Preset", selection: Binding(
                            get: { viewModel.room.contextPreset },
                            set: {
                                viewModel.room.contextPreset = $0
                                save(viewModel.room)
                            }
                        )) {
                            ForEach(ContextPreset.allCases) { preset in
                                Text(preset.rawValue).tag(preset)
                            }
                        }
                        .frame(width: 130)
                        Spacer()
                        Button("View") { showFullContext = true }
                        Button("Copy") { copyContext() }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    ProgressView(value: min(Double(context.approximateCharacterCount), 32_000), total: 32_000)
                    Text("\(context.approximateCharacterCount.formatted()) chars · ~\(context.approximateTokenCount ?? 0) tokens")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if !context.warnings.isEmpty {
                        ForEach(context.warnings, id: \.self) { warning in
                            Label(warning, systemImage: "exclamationmark.triangle")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showFullContext) {
            FullContextSheet(context: context)
        }
    }

    private var sizeLabel: String {
        switch context.approximateCharacterCount {
        case 0..<6_000: "Small"
        case 6_000..<18_000: "Medium"
        default: "Large"
        }
    }

    private func copyContext() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(context.fullPromptPreview, forType: .string)
        app.showToast("Context copied")
    }
}

private struct FullContextSheet: View {
    @Environment(\.dismiss) private var dismiss
    var context: TaskContext

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Full Context")
                        .font(.title3.weight(.semibold))
                    Text("Generated \(context.generatedAt, style: .time) · \(context.approximateCharacterCount.formatted()) characters")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Copy") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(context.fullPromptPreview, forType: .string)
                }
                Button("Done") { dismiss() }
            }
            .padding()
            Divider()
            ScrollView {
                Text(context.fullPromptPreview)
                    .font(.system(size: 12, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
        }
        .frame(width: 760, height: 620)
    }
}
