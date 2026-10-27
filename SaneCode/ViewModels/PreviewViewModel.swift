import Combine
import Foundation

final class PreviewViewModel: ObservableObject {
    @Published var url = ""
    @Published var isServerRunning = false
    @Published var serverCommand = ""
    @Published var selectedDevice: PreviewDevice = .desktop
    @Published var screenshots: [ScreenshotCapture] = []

    let bridge = BrowserBridge()
    private let serverManager = DevServerManager()
    private let screenshotManager = ScreenshotManager()

    func startServer(repository: Repository, terminal: TerminalViewModel) {
        let detected = repository.detectedCommands.first(where: { $0.kind == .server })?.command
        let command = serverCommand.isEmpty ? (detected ?? "") : serverCommand
        guard !command.isEmpty else { return }
        serverCommand = command
        isServerRunning = true
        Task {
            await serverManager.start(command: command, path: repository.path) { text, kind in
                terminal.append(text, kind: kind)
                if let foundURL = DevServerManager.localhostURL(in: text) {
                    self.url = foundURL
                    self.bridge.load(foundURL)
                }
            }
            isServerRunning = serverManager.status == .running
        }
    }

    func stopServer() {
        serverManager.stop()
        isServerRunning = false
    }

    func restartServer(repository: Repository, terminal: TerminalViewModel) {
        stopServer()
        startServer(repository: repository, terminal: terminal)
    }

    func loadURL() {
        bridge.load(url)
    }

    func reload() {
        bridge.reload()
    }

    func captureScreenshot(roomID: UUID, onCapture: @escaping (ScreenshotCapture) -> Void) {
        Task {
            if let capture = await screenshotManager.capture(webView: bridge.webView, roomID: roomID, device: selectedDevice) {
                screenshots.insert(capture, at: 0)
                onCapture(capture)
            }
        }
    }

    func loadScreenshots(from room: AgentRoom?) {
        screenshots = room?.screenshots ?? []
    }

    func makePreviewCapture(roomID: UUID, kind: PreviewCaptureKind) -> PreviewCapture {
        PreviewCapture(
            roomID: roomID,
            kind: kind,
            url: url.isEmpty ? (bridge.currentURL.isEmpty ? "No URL" : bridge.currentURL) : url,
            viewport: selectedDevice,
            screenshotPath: screenshots.first?.filePath
        )
    }
}
