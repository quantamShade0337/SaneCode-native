import SwiftUI

struct StageTimelineView: View {
    var stage: TaskStage

    private let stages: [TaskStage] = [.inspecting, .planning, .executing, .checking, .reviewing, .done]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(stages, id: \.self) { item in
                HStack(spacing: 5) {
                    stageIcon(for: item)
                    Text(item.label)
                        .font(.caption.weight(.medium))
                }
                .foregroundStyle(color(for: item))
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(Color.primary.opacity(item == stage ? 0.07 : 0.03), in: Capsule())
                .overlay {
                    Capsule().stroke(color(for: item).opacity(item == stage ? 0.28 : 0.12), lineWidth: 1)
                }

                if item != stages.last {
                    Rectangle()
                        .fill(.quaternary)
                        .frame(width: 14, height: 1)
                }
            }
        }
    }

    @ViewBuilder
    private func stageIcon(for item: TaskStage) -> some View {
        let name = iconName(for: item)
        let isActive = item == stage && stage != .done && stage != .failed

        if isActive {
            Image(systemName: name)
                .font(.system(size: 12, weight: .medium))
                .symbolEffect(.variableColor.iterative.dimInactiveLayers, isActive: true)
        } else {
            Image(systemName: name)
                .font(.system(size: 12, weight: .medium))
        }
    }

    private func iconName(for item: TaskStage) -> String {
        if stage == .failed && item == .checking { return "xmark.circle.fill" }
        if item == stage { return "circle.dotted" }
        return completed(item) ? "checkmark.circle.fill" : "circle"
    }

    private func color(for item: TaskStage) -> Color {
        if stage == .failed && item == .checking { return .red }
        if item == stage { return .blue }
        return completed(item) ? .green : .secondary
    }

    private func completed(_ item: TaskStage) -> Bool {
        guard let current = stages.firstIndex(of: stage), let target = stages.firstIndex(of: item) else { return false }
        return target < current || stage == .done
    }
}
