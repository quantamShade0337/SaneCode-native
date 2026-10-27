import Foundation

struct BrowserSession: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var roomID: UUID
    var currentURL: String?
    var devServerCommand: String?
    var devServerStatus: DevServerStatus = .stopped
    var viewport: PreviewDevice = .desktop
    var screenshots: [ScreenshotCapture] = []
}

struct ScreenshotCapture: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var roomID: UUID
    var url: String
    var device: PreviewDevice
    var filePath: String?
    var createdAt: Date = Date()
}
