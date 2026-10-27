import SwiftUI

struct ScreenshotCaptureView: View {
    @EnvironmentObject private var app: AppViewModel
    @ObservedObject var viewModel: PreviewViewModel

    private var hasPreviewContent: Bool {
        !viewModel.screenshots.isEmpty || !(app.selectedRoom?.previewCaptures.isEmpty ?? true)
    }

    private var hasCompare: Bool {
        app.selectedRoom?.previewCaptures.contains(where: { $0.kind == .before }) == true &&
        app.selectedRoom?.previewCaptures.contains(where: { $0.kind == .after }) == true
    }

    var body: some View {
        if hasPreviewContent {
            Divider()
            VStack(spacing: 0) {
                if let room = app.selectedRoom,
                   let before = room.previewCaptures.last(where: { $0.kind == .before }),
                   let after = room.previewCaptures.last(where: { $0.kind == .after }) {
                    compareCard(before: before, after: after)
                    Divider()
                }
                ScrollView(.horizontal) {
                    HStack(spacing: 10) {
                        ForEach(app.selectedRoom?.previewCaptures ?? []) { capture in
                            previewCaptureCard(capture)
                        }
                        ForEach(viewModel.screenshots) { screenshot in
                            screenshotCard(screenshot)
                        }
                    }
                    .padding(8)
                }
            }
            .frame(height: hasCompare ? 156 : 96)
            .background(Color(nsColor: .windowBackgroundColor))
        }
    }

    private func compareCard(before: PreviewCapture, after: PreviewCapture) -> some View {
        HStack(spacing: 12) {
            Label("Before/After", systemImage: "rectangle.split.2x1")
                .font(.caption.weight(.semibold))
            VStack(alignment: .leading, spacing: 2) {
                Text("Before: \(before.url)")
                    .lineLimit(1)
                Text("\(before.viewport.rawValue) · \(before.createdAt, style: .time)")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .leading, spacing: 2) {
                Text("After: \(after.url)")
                    .lineLimit(1)
                Text("\(after.viewport.rawValue) · \(after.createdAt, style: .time)")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.caption)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }

    private func previewCaptureCard(_ capture: PreviewCapture) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            StatusBadge(label: capture.kind.rawValue, systemImage: "rectangle.inset.filled", tint: capture.kind == .before ? .blue : .green)
            Text(capture.url)
                .font(.caption2)
                .lineLimit(1)
            Text("\(capture.viewport.rawValue) · \(capture.createdAt, style: .time)")
                .font(.caption2)
                .foregroundStyle(.secondary)
            if capture.screenshotPath == nil {
                Text("Screenshot image capture is not available yet. Sanecode saved preview metadata.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .frame(width: 220, height: 70, alignment: .leading)
        .padding(8)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8).stroke(.quaternary)
        }
    }

    private func screenshotCard(_ screenshot: ScreenshotCapture) -> some View {
        HStack(spacing: 8) {
            if let path = screenshot.filePath, let image = NSImage(contentsOfFile: path) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 104, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(.quaternary)
                    .frame(width: 104, height: 64)
                    .overlay(Image(systemName: "photo"))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("Screenshot captured")
                    .font(.caption.weight(.semibold))
                Text(screenshot.url)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text("\(screenshot.device.rawValue) · \(screenshot.createdAt, style: .time)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                HStack {
                    Button("Send to Agent") { sendToAgent(screenshot) }
                    if let path = screenshot.filePath {
                        Button("Reveal") {
                            NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
                        }
                    }
                }
                .buttonStyle(.borderless)
            }
            .frame(width: 220, alignment: .leading)
        }
        .padding(6)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.quaternary)
        }
    }

    private func sendToAgent(_ capture: ScreenshotCapture) {
        guard var room = app.selectedRoom else { return }
        let context = """

        Screenshot context:
        - Path: \(capture.filePath ?? "not saved")
        - URL: \(capture.url)
        - Device: \(capture.device.rawValue)
        - Captured: \(capture.createdAt.formatted(date: .abbreviated, time: .standard))
        """
        room.prompt += context
        room.updatedAt = Date()
        app.updateSelectedRoom(room)
        app.selectedMainTab = .work
    }
}
