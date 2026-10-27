import Combine
import Foundation

final class DevServerManager: ObservableObject {
    private let runner = ShellRunner()
    @Published var status: DevServerStatus = .stopped
    @Published var detectedURL: String?

    func start(command: String, path: String, onOutput: @escaping @MainActor (String, CommandKind) -> Void) async {
        status = .starting
        let exitCode = await runner.run(command, in: path, onOutput: { [weak self] text, kind in
            onOutput(text, kind)
            if let url = Self.localhostURL(in: text) {
                self?.detectedURL = url
                self?.status = .running
            }
        }, kind: .server)
        if exitCode != 0, status != .running {
            status = .failed
        }
    }

    func stop() {
        runner.cancel()
        status = .stopped
    }

    static func localhostURL(in text: String) -> String? {
        let pattern = #"https?://(?:localhost|127\.0\.0\.1):\d+[^\s]*"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, range: range), let swiftRange = Range(match.range, in: text) else { return nil }
        return String(text[swiftRange])
    }
}
