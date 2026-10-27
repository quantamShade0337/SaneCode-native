import AppKit
import Foundation
import WebKit

struct ScreenshotManager {
    func capture(webView: WKWebView, roomID: UUID, device: PreviewDevice) async -> ScreenshotCapture? {
        guard let url = webView.url?.absoluteString else { return nil }
        let configuration = WKSnapshotConfiguration()
        configuration.rect = webView.bounds

        guard let image = try? await webView.takeSnapshot(configuration: configuration),
              let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let png = bitmap.representation(using: .png, properties: [:])
        else { return nil }

        let directory = screenshotsDirectory(roomID: roomID)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fileURL = directory.appendingPathComponent("preview-\(Self.timestamp()).png")
        do {
            try png.write(to: fileURL, options: [.atomic])
            return ScreenshotCapture(roomID: roomID, url: url, device: device, filePath: fileURL.path)
        } catch {
            return nil
        }
    }

    private func screenshotsDirectory(roomID: UUID) -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base
            .appendingPathComponent("Sanecode", isDirectory: true)
            .appendingPathComponent("Screenshots", isDirectory: true)
            .appendingPathComponent(roomID.uuidString, isDirectory: true)
    }

    private static func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss-SSS"
        return formatter.string(from: Date())
    }
}
