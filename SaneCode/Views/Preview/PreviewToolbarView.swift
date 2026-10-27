import AppKit
import SwiftUI

struct PreviewToolbarView: View {
    @EnvironmentObject private var app: AppViewModel
    @ObservedObject var viewModel: PreviewViewModel
    var repository: Repository

    var body: some View {
        HStack {
            Button { viewModel.bridge.goBack() } label: { Image(systemName: "chevron.left") }
            Button { viewModel.bridge.goForward() } label: { Image(systemName: "chevron.right") }
            Button { viewModel.reload() } label: { Image(systemName: "arrow.clockwise") }
            TextField("http://localhost:3000", text: $viewModel.url)
                .textFieldStyle(.roundedBorder)
                .onSubmit { viewModel.loadURL() }
            Button("Start Preview") {
                guard app.ensureRepositoryAccess(repository) else { return }
                viewModel.startServer(repository: repository, terminal: app.terminalViewModel)
            }
            Button("Stop") { viewModel.stopServer() }
            Picker("Device", selection: $viewModel.selectedDevice) {
                ForEach(PreviewDevice.allCases) { device in
                    Text(device.rawValue).tag(device)
                }
            }
            .frame(width: 140)
            Button {
                if let url = URL(string: viewModel.url) { NSWorkspace.shared.open(url) }
            } label: {
                Image(systemName: "arrow.up.forward.square")
            }
            Button("Screenshot") {
                if let room = app.selectedRoom {
                    viewModel.captureScreenshot(roomID: room.id) { capture in
                        var updated = room
                        updated.screenshots.insert(capture, at: 0)
                        updated.updatedAt = Date()
                        app.updateSelectedRoom(updated)
                    }
                }
            }
            Button("Mark as Before") { mark(.before) }
            Button("Mark as After") { mark(.after) }
            Button("Send to Agent") {
                if let capture = viewModel.screenshots.first {
                    sendToAgent(capture)
                }
            }
            Button("Improve From Preview") { improveFromPreview() }
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .padding(10)
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

    private func mark(_ kind: PreviewCaptureKind) {
        guard var room = app.selectedRoom else { return }
        let capture = viewModel.makePreviewCapture(roomID: room.id, kind: kind)
        room.previewCaptures.removeAll { $0.kind == kind }
        room.previewCaptures.insert(capture, at: 0)
        app.updateSelectedRoom(room)
    }

    private func improveFromPreview() {
        guard var room = app.selectedRoom else { return }
        let before = room.previewCaptures.first(where: { $0.kind == .before })
        let after = room.previewCaptures.first(where: { $0.kind == .after }) ?? viewModel.makePreviewCapture(roomID: room.id, kind: .general)
        room.prompt += """

        Improve from preview:
        - Current URL: \(after.url)
        - Device: \(after.viewport.rawValue)
        - Before: \(before?.url ?? "not marked")
        - Current/After screenshot: \(after.screenshotPath ?? "metadata only")
        - Changed files from this room: \(room.changedFiles.map(\.path).joined(separator: ", "))

        You are improving the UI based on the current preview state. Preserve functionality. Match the existing design system. Prefer minimal component-level edits. Use the provided URL/viewport/screenshot metadata as visual context. After changes, summarize what changed and suggest running checks.
        """
        app.updateSelectedRoom(room)
        app.selectedMainTab = .work
    }
}
